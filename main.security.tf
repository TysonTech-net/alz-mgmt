locals {
  security_location   = var.starter_locations[0]
  security_rg_name    = try(var.custom_replacements.names.security_log_analytics_resource_group_name, "rg-sec-logs-${local.security_location}")
  security_law_name   = try(var.custom_replacements.names.security_log_analytics_workspace_name, "law-sec-${local.security_location}")
}

# Security subscription resources (guarded by security_resources_enabled)
module "security_log_analytics_rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  count            = var.security_resources_enabled ? 1 : 0
  name             = local.security_rg_name
  location         = local.security_location
  enable_telemetry = var.enable_telemetry
  tags             = coalesce(module.config.outputs.tags, null)

  providers = {
    azurerm = azurerm.security
  }
}

module "security_log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  count = var.security_resources_enabled ? 1 : 0

  name                = local.security_law_name
  location            = local.security_location
  resource_group_name = local.security_rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 90
  daily_cap_gb        = 0
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  tags               = coalesce(module.config.outputs.tags, null)

  enable_telemetry = var.enable_telemetry

  providers = {
    azurerm = azurerm.security
    azapi   = azapi.security
  }

  depends_on = [
    module.security_log_analytics_rg
  ]
}

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "security" {
  count = var.security_resources_enabled ? 1 : 0

  workspace_id = module.security_log_analytics_workspace[0].id

  provider = azurerm.security
}
