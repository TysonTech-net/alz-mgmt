terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

locals {
  # Map short codes to full Azure redundancy type names
  redundancy_types = {
    "lr" = "LocallyRedundant" # Data replicated within the same datacenter
    "zr" = "ZoneRedundant"    # Data replicated across availability zones
    "gr" = "GeoRedundant"     # Data replicated to a secondary region
  }

  # Boolean flags to check which vault types will be deployed
  has_lr = contains(var.vaults_to_deploy, "lr")
  has_zr = contains(var.vaults_to_deploy, "zr")
  has_gr = contains(var.vaults_to_deploy, "gr")

  ext_vms  = try(var.policy_extensions.vms, {})
  ext_fs   = try(var.policy_extensions.azfiles, {})
  ext_sql  = try(var.policy_extensions.sql_server_in_azure_vm, {})
  ext_hana = try(var.policy_extensions.sap_hana_in_azure_vm, {})

  # Intersections (collisions) between defaults and extensions
  vms_collisions  = setintersection(toset(keys(local.default_policy_configs.vms)), toset(keys(local.ext_vms)))
  fs_collisions   = setintersection(toset(keys(local.default_policy_configs.azfiles)), toset(keys(local.ext_fs)))
  sql_collisions  = setintersection(toset(keys(local.default_policy_configs.sql_server_in_azure_vm)), toset(keys(local.ext_sql)))
  hana_collisions = setintersection(toset(keys(local.default_policy_configs.sap_hana_in_azure_vm)), toset(keys(local.ext_hana)))

  # Effective config: defaults + extensions (we'll guard collisions with a precondition)
  policy_configs = {
    vms                    = merge(local.default_policy_configs.vms, local.ext_vms)
    azfiles                = merge(local.default_policy_configs.azfiles, local.ext_fs)
    sql_server_in_azure_vm = merge(local.default_policy_configs.sql_server_in_azure_vm, local.ext_sql)
    sap_hana_in_azure_vm   = merge(local.default_policy_configs.sap_hana_in_azure_vm, local.ext_hana)
  }
}


# Define local variables for private endpoint construction
locals {
  # Create a flattened list of vault-subnet combinations for private endpoints
  # This enables creating multiple private endpoints per vault (one per subnet)
  vault_subnet_combinations = flatten([
    for vault_key, vault in azurerm_recovery_services_vault.vaults : [
      for subnet_index, subnet_id in var.private_endpoint_subnet_ids : {
        vault_key    = vault_key
        vault        = vault
        subnet_index = subnet_index
        subnet_id    = subnet_id
      }
    ]
  ])
}

# Guard clauses to prevent policy name collisions
resource "terraform_data" "guards" {
  lifecycle {
    precondition {
      condition = (
        length(local.vms_collisions) == 0
        && length(local.fs_collisions) == 0
        && length(local.sql_collisions) == 0
        && length(local.hana_collisions) == 0
      )
      error_message = format(
        "policy_extensions must not redefine existing policy names. Collisions found: vms=%s, azfiles=%s, sql=%s, sap_hana=%s",
        join(", ", tolist(local.vms_collisions)),
        join(", ", tolist(local.fs_collisions)),
        join(", ", tolist(local.sql_collisions)),
        join(", ", tolist(local.hana_collisions))
      )
    }

    precondition {
      condition     = var.enable_azure_policy ? length(trim(var.root_id)) > 0 : true
      error_message = "root_id must be set when enable_azure_policy = true."
    }
  }
}

# Create the resource group only when create_resource_group is true
resource "azurerm_resource_group" "rsv_group" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.rg_tags
}

# Locals block to reference either the created or existing resource group
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.rsv_group[0].name : var.resource_group_name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.rsv_group[0].id : "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location            = var.create_resource_group ? azurerm_resource_group.rsv_group[0].location : var.location
}

# Create Recovery Services Vaults based on the vaults_to_deploy variable
resource "azurerm_recovery_services_vault" "vaults" {
  for_each            = toset(var.vaults_to_deploy)                           # Creates a vault for each type in the list (lr, zr, gr)
  name                = "${var.name_prefix}-${each.value}-${var.name_suffix}" # Example: myprefix-lr-mysuffix
  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = "Standard"                         # Azure only supports Standard SKU for Recovery Services Vaults
  storage_mode_type   = local.redundancy_types[each.value] # Sets the redundancy type based on vault type

  soft_delete_enabled           = true                                                        # Enable soft-delete for protection against accidental deletion
  public_network_access_enabled = length(var.private_endpoint_subnet_ids) == 0 ? true : false # Disable public access if private endpoints are used
  cross_region_restore_enabled  = each.value == "gr" ? var.cross_region_restore_enabled : false

  # Configure monitoring settings
  monitoring {
    alerts_for_all_job_failures_enabled            = true
    alerts_for_critical_operation_failures_enabled = false
  }

  immutability = var.immutability # Set immutability policy (Disabled, Unlocked, or Locked)

  lifecycle {
    ignore_changes = [
      monitoring # Ignore changes to monitoring as it might be modified outside Terraform
    ]
  }

  # Create a system-assigned managed identity for the vault
  identity {
    type = "SystemAssigned"
  }
}

# Create private endpoints for each vault in each subnet
resource "azurerm_private_endpoint" "vault_pe" {
  for_each = {
    for combination in local.vault_subnet_combinations :
    "${combination.vault_key}-${combination.subnet_index}" => combination
  }

  name                = "${var.name_prefix}-${each.value.vault_key}-${var.name_suffix}-pe-${each.value.subnet_index}"
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = each.value.subnet_id # Connect to the specified subnet

  # Create the private service connection to the vault
  private_service_connection {
    name                           = "${each.value.vault.name}-psc-${each.value.subnet_index}"
    private_connection_resource_id = each.value.vault.id
    subresource_names              = ["AzureBackup"] # Connect to the AzureBackup service
    is_manual_connection           = false           # Automatic connection (requires appropriate permissions)
  }

  # Associate with DNS zones to enable private DNS resolution
  private_dns_zone_group {
    name                 = "${each.value.vault.name}-pdnsg-${each.value.subnet_index}"
    private_dns_zone_ids = var.private_dns_zone_group_ids
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

################################################# VM BACKUP POLICIES ###################################################

resource "azurerm_backup_policy_vm" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.vms, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  # Create a unique name for each policy based on the vault type and policy name (e.g. "Standard-14d-ZR")
  name                           = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  resource_group_name            = local.resource_group_name
  recovery_vault_name            = azurerm_recovery_services_vault.vaults[each.value.vault_type].name
  policy_type                    = each.value.policy_config.policy_type # V1 for standard, V2 for enhanced
  timezone                       = "UTC"
  instant_restore_retention_days = 5 # Keep instant restore points for 5 days

  # Define backup schedule
  backup {
    frequency     = each.value.policy_config.backup.frequency                      # Daily or Hourly
    time          = each.value.policy_config.backup.time                           # Time to start the backup
    hour_interval = lookup(each.value.policy_config.backup, "hour_interval", null) # For hourly, how often
    hour_duration = lookup(each.value.policy_config.backup, "hour_duration", null) # For hourly, how long
  }

  # Configure daily retention
  retention_daily {
    count = each.value.policy_config.retention.daily # Number of days to keep daily backups
  }

  # Configure weekly retention if specified
  dynamic "retention_weekly" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : [] # Only create if weekly > 0
    content {
      count    = each.value.policy_config.retention.weekly
      weekdays = ["Saturday"] # Keep Saturday backups for weekly retention
    }
  }

  # Configure monthly retention if specified
  dynamic "retention_monthly" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : [] # Only create if monthly > 0
    content {
      count = each.value.policy_config.retention.monthly
      days  = [1] # Keep the 1st day of month backup for monthly retention
    }
  }

  # Configure yearly retention if specified
  dynamic "retention_yearly" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : [] # Only create if yearly > 0
    content {
      count  = each.value.policy_config.retention.yearly
      days   = [1]         # Keep the 1st day of month backup
      months = ["January"] # Use January for yearly retention
    }
  }
}

############################################### AZURE FILES BACKUP POLICIES ############################################

resource "azurerm_backup_policy_file_share" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.azfiles, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  # Create a unique name for each policy based on the vault type and policy name (e.g. "AzFiles-14d-GR")
  name                = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  resource_group_name = local.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vaults[each.value.vault_type].name
  timezone            = "UTC"

  # Define backup schedule for Azure Files
  backup {
    frequency = each.value.policy_config.backup.frequency # Hourly backups for Azure Files
    hourly {
      interval        = each.value.policy_config.backup.hourly.interval
      start_time      = each.value.policy_config.backup.hourly.start_time
      window_duration = each.value.policy_config.backup.hourly.window_duration
    }
  }

  # Configure daily retention
  retention_daily {
    count = each.value.policy_config.retention.daily
  }

  # Configure weekly retention if specified
  dynamic "retention_weekly" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
    content {
      count    = each.value.policy_config.retention.weekly
      weekdays = ["Saturday"]
    }
  }

  # Configure monthly retention if specified
  dynamic "retention_monthly" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
    content {
      count = each.value.policy_config.retention.monthly
      days  = [1]
    }
  }

  # Configure yearly retention if specified
  dynamic "retention_yearly" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
    content {
      count  = each.value.policy_config.retention.yearly
      days   = [1]
      months = ["January"]
    }
  }
}

############################################### SQL SERVER BACKUP POLICIES ############################################

resource "azurerm_backup_policy_vm_workload" "sql_server_in_azure_vm" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.sql_server_in_azure_vm, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  name                = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  resource_group_name = local.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vaults[each.value.vault_type].name
  workload_type       = "SQLDataBase"

  settings {
    time_zone           = "UTC"
    compression_enabled = false
  }

  # Full backup policy
  protection_policy {
    policy_type = "Full"

    backup {
      frequency = each.value.policy_config.full_backup.frequency
      time      = each.value.policy_config.full_backup.time
      weekdays  = lookup(each.value.policy_config.full_backup, "weekdays", null)
    }

    retention_daily {
      count = each.value.policy_config.retention.daily
    }

    # Configure weekly retention if specified
    dynamic "retention_weekly" {
      for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
      content {
        count    = each.value.policy_config.retention.weekly
        weekdays = ["Saturday"]
      }
    }

    # Configure monthly retention if specified
    dynamic "retention_monthly" {
      for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
      content {
        count       = each.value.policy_config.retention.monthly
        format_type = "Weekly"
        weekdays    = ["Saturday"]
        weeks       = ["First"]
      }
    }

    # Configure yearly retention if specified
    dynamic "retention_yearly" {
      for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
      content {
        count       = each.value.policy_config.retention.yearly
        format_type = "Weekly"
        months      = ["January"]
        weekdays    = ["Saturday"]
        weeks       = ["First"]
      }
    }
  }

  # Log backup policy
  protection_policy {
    policy_type = "Log"

    backup {
      frequency_in_minutes = each.value.policy_config.log_backup.frequency_in_minutes
    }

    simple_retention {
      count = each.value.policy_config.log_backup.retention_days
    }
  }
}

################################################ SAP HANA BACKUP POLICIES ##############################################

resource "azurerm_backup_policy_vm_workload" "sap_hana_in_azure_vm" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.sap_hana_in_azure_vm, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  name                = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  resource_group_name = local.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vaults[each.value.vault_type].name
  workload_type       = "SAPHanaDatabase"

  settings {
    time_zone           = "UTC"
    compression_enabled = false
  }

  # Full backup policy
  protection_policy {
    policy_type = "Full"

    backup {
      frequency = each.value.policy_config.full_backup.frequency
      time      = each.value.policy_config.full_backup.time
      weekdays  = lookup(each.value.policy_config.full_backup, "weekdays", null)
    }

    retention_daily {
      count = each.value.policy_config.retention.daily
    }

    # Configure weekly retention if specified
    dynamic "retention_weekly" {
      for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
      content {
        count    = each.value.policy_config.retention.weekly
        weekdays = ["Saturday"]
      }
    }

    # Configure monthly retention if specified
    dynamic "retention_monthly" {
      for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
      content {
        count       = each.value.policy_config.retention.monthly
        format_type = "Weekly"
        weekdays    = ["Saturday"]
        weeks       = ["First"]
      }
    }

    # Configure yearly retention if specified
    dynamic "retention_yearly" {
      for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
      content {
        count       = each.value.policy_config.retention.yearly
        format_type = "Weekly"
        months      = ["January"]
        weekdays    = ["Saturday"]
        weeks       = ["First"]
      }
    }
  }

  # Log backup policy
  protection_policy {
    policy_type = "Log"

    backup {
      frequency_in_minutes = each.value.policy_config.log_backup.frequency_in_minutes
    }

    simple_retention {
      count = each.value.policy_config.log_backup.retention_days
    }
  }
}