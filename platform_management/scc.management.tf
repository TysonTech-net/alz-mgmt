resource "azurerm_resource_group" "management" {
  provider = azurerm.management
  name     = module.config.custom_replacements.scc_custom_management_resource_group_name
  location = local.primary_location
  tags     = local.final_tags
}

resource "azurerm_monitor_data_collection_rule" "windows_event_logs" {
  name                = module.config.custom_replacements.scc_custom_dcr_windows_eventlogs_name
  location            = local.primary_location
  resource_group_name = local.management_log_resource_group_name
  description         = "Default DCR for Windows Servers logging to ${local.log_analytics_workspace_id}"

  destinations {
    log_analytics {
      workspace_resource_id = local.log_analytics_workspace_id
      name                  = local.log_analytics_workspace_name
    }
  }

  data_flow {
    streams       = ["Microsoft-Event"]
    destinations  = [local.log_analytics_workspace_name]
    output_stream = "Microsoft-Event"
    transform_kql = "source"
  }

  data_sources {
    windows_event_log {
      name    = "eventLogsDataSource"
      streams = ["Microsoft-WindowsEvent"]
      x_path_queries = [
        "System!*[System[(Level=1 or Level=2 or Level=3)]]",
        "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
      ]
    }
  }

  depends_on = [module.management_resources]

  tags = merge(
    local.final_tags,
    {
      Description = "Data Collection Rule for Windows Event Logs"
      Service     = "Management-Monitoring"
    }
  )
}

resource "azurerm_resource_group" "patch_management" {
  provider = azurerm.management
  name     = "rg-${local.base_name_primary}-patch-mgmt-001"
  location = local.primary_location
  tags     = local.final_tags
}

module "update_vms_by_tag" {
  source = "../_modules-custom/update_vms_by_tag"

  providers = { azurerm = azurerm.management }

  resource_group_name = azurerm_resource_group.patch_management.name
  location            = local.primary_location

  maintenance_configurations = var.maintenance_configurations

  management_group_id        = "/providers/Microsoft.Management/managementGroups/${var.customer}"
  policy_assignment_location = local.primary_location # required for MI on DeployIfNotExists

  # tag_key                            = "PatchGroup"
  # grant_contributor_to_assignment_mi = true

  tags = merge(
    local.final_tags,
    {
      Description = "Patch Management Resources"
      Service     = "Management-Patch"
    }
  )
}

resource "azurerm_monitor_action_group" "central_service_health" {
  provider            = azurerm.management
  name                = "Ops-Action-Group-ServiceHealth"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "ServiceAlert"
  enabled             = true

  # One email receiver per address (unique names)
  dynamic "email_receiver" {
    for_each = { for idx, addr in var.service_health_email_addresses : idx => addr }
    content {
      name                    = "ServiceAlertNotification-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  depends_on = [module.management_resources]
  tags = merge(
    local.final_tags,
    {
      Description = "Action group for service health alerts"
      Service     = "Management-Alerts"
    }
  )
}

module "kv_shared_primary" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                = "kvemgmtprod${local.primary_location_short}01"
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.management.name
  tenant_id           = var.root_parent_management_group_id

  sku_name                   = "premium"
  soft_delete_retention_days = 90
  purge_protection_enabled   = false

  public_network_access_enabled = true

  # network_acls = {
  #   bypass                     = "AzureServices"
  #   default_action             = "Deny"
  #   ip_rules                   = []
  #   virtual_network_subnet_ids = []Ca
  # }

  # private_endpoints = {
  #   primary = {
  #     name               = "pe-kvmgmtprod${local.primary_location_short}01"
  #     subnet_resource_id = module.spoke_network_primary.subnet_ids["mgmt"]
  #     tags               = var.tags
  #   }
  # }

  tags = merge(
    local.final_tags,
    {
      Description = "Management Key Vault"
      Service     = "Management-KeyVault"
    }
  )
}

resource "azurerm_monitor_action_group" "cost_alerts" {
  provider            = azurerm.management
  name                = "Ops-Action-Group-CostAlerts"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "CostAlert"
  enabled             = true

  # One email receiver per address (unique names)
  dynamic "email_receiver" {
    for_each = { for idx, addr in var.service_health_email_addresses : idx => addr }
    content {
      name                    = "ServiceAlertNotification-${email_receiver.key}"
      email_address           = email_receiver.value
      use_common_alert_schema = true
    }
  }

  depends_on = [module.management_resources]
  tags = merge(
    local.final_tags,
    {
      Description = "Action group for service health alerts"
      Service     = "Management-Alerts"
    }
  )
}

locals {
  log_analytics_ingestion_thresholds_gb = {
    "2gb"  = 2
    "5gb"  = 5
    "10gb" = 10
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "log_analytics_daily_ingestion" {
  provider = azurerm.management

  for_each = local.log_analytics_ingestion_thresholds_gb

  name                 = "log-shared-management-prod-${local.primary_location_short}-001-ingestion-${each.key}"
  resource_group_name  = local.management_log_resource_group_name
  location             = local.primary_location
  description          = "Alert when Log Analytics daily ingestion exceeds ${each.value} GB in ${local.primary_location}."
  severity             = 2
  enabled              = true
  evaluation_frequency = "PT1H"
  window_duration      = "P1D"

  scopes = [
    local.log_analytics_workspace_id
  ]

  criteria {
    query = <<-KQL
      Usage
      | where TimeGenerated > ago(1d)
      | where IsBillable == true
      | summarize TotalIngestedGB = sum(Quantity) / 1024.0
    KQL

    time_aggregation_method = "Total"
    metric_measure_column   = "TotalIngestedGB"

    threshold = each.value
    operator  = "GreaterThan"

    failing_periods {
      number_of_evaluation_periods             = 1
      minimum_failing_periods_to_trigger_alert = 1
    }
  }

  action {
    action_groups = [
      azurerm_monitor_action_group.cost_alerts.id
    ]
  }

  tags = merge(
    local.final_tags,
    {
      Description = "Alert on Log Analytics daily ingestion > ${each.value} GB"
      Service     = "Management-Monitoring"
    }
  )
}