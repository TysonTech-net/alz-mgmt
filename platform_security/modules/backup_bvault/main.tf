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

  # Pull in extensions (may be empty)
  ext_blob = try(var.policy_extensions.blob, {})
  ext_disk = try(var.policy_extensions.disk, {})
  ext_pg   = try(var.policy_extensions.postgresql, {})
  ext_k8s  = try(var.policy_extensions.kubernetes, {})
  ext_pgfx = try(var.policy_extensions.postgresql_flexible, {})

  # Collision sets (default names ∩ extension names)
  blob_collisions = setintersection(toset(keys(local.default_policy_configs.blob)), toset(keys(local.ext_blob)))
  disk_collisions = setintersection(toset(keys(local.default_policy_configs.disk)), toset(keys(local.ext_disk)))
  pg_collisions   = setintersection(toset(keys(local.default_policy_configs.postgresql)), toset(keys(local.ext_pg)))
  k8s_collisions  = setintersection(toset(keys(local.default_policy_configs.kubernetes)), toset(keys(local.ext_k8s)))
  pgfx_collisions = setintersection(toset(keys(local.default_policy_configs.postgresql_flexible)), toset(keys(local.ext_pgfx)))

  # Effective config = defaults + add-only extensions
  policy_configs = {
    blob                = merge(local.default_policy_configs.blob, local.ext_blob)
    disk                = merge(local.default_policy_configs.disk, local.ext_disk)
    postgresql          = merge(local.default_policy_configs.postgresql, local.ext_pg)
    kubernetes          = merge(local.default_policy_configs.kubernetes, local.ext_k8s)
    postgresql_flexible = merge(local.default_policy_configs.postgresql_flexible, local.ext_pgfx)
  }
}

# Guard clauses to prevent policy name collisions
resource "terraform_data" "guards" {
  lifecycle {
    precondition {
      condition = (
        length(local.blob_collisions) == 0 &&
        length(local.disk_collisions) == 0 &&
        length(local.pg_collisions) == 0 &&
        length(local.k8s_collisions) == 0 &&
        length(local.pgfx_collisions) == 0
      )
      error_message = format(
        "policy_extensions must not redefine existing policy names. Collisions: blob=%s, disk=%s, postgresql=%s, kubernetes=%s, postgresql_flexible=%s",
        join(", ", tolist(local.blob_collisions)),
        join(", ", tolist(local.disk_collisions)),
        join(", ", tolist(local.pg_collisions)),
        join(", ", tolist(local.k8s_collisions)),
        join(", ", tolist(local.pgfx_collisions))
      )
    }
  }
}



# Create the resource group only when create_resource_group is true
resource "azurerm_resource_group" "backup_group" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.rg_tags
}

# Get current subscription information
data "azurerm_subscription" "current" {}

# Locals block to reference either the created or existing resource group
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.backup_group[0].name : var.resource_group_name
  resource_group_id   = var.create_resource_group ? azurerm_resource_group.backup_group[0].id : "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location            = var.create_resource_group ? azurerm_resource_group.backup_group[0].location : var.location
}

# Create Backup Vaults based on the vaults_to_deploy variable
resource "azurerm_data_protection_backup_vault" "vaults" {
  for_each            = toset(var.vaults_to_deploy)                           # Creates a vault for each type in the list (lr, zr, gr)
  name                = "${var.name_prefix}-${each.value}-${var.name_suffix}" # Example: myprefix-lr-mysuffix
  location            = local.location
  resource_group_name = local.resource_group_name
  datastore_type      = "VaultStore"                       # Using VaultStore as per documentation
  redundancy          = local.redundancy_types[each.value] # Sets the redundancy type based on vault type

  # Enable cross-region restore for GR vaults if specified
  cross_region_restore_enabled = each.value == "gr" ? var.cross_region_restore_enabled : null

  # Set soft delete retention duration
  retention_duration_in_days = var.retention_duration_in_days

  # Set immutability policy
  immutability = var.immutability

  # Set soft delete state
  soft_delete = var.soft_delete

  # Create a system-assigned managed identity for the vault
  identity {
    type = "SystemAssigned"
  }

  # Apply tags
  tags = var.rg_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Create a backup policy instance for each vault type and policy combination
resource "azurerm_data_protection_backup_policy_blob_storage" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.blob, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  # Create a unique name for each policy based on the vault type and policy name (e.g. "Blob-14d-ZR")
  name     = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  vault_id = azurerm_data_protection_backup_vault.vaults[each.value.vault_type].id

  # Define backup schedule
  backup_repeating_time_intervals = ["R/2025-01-01T21:00:00Z/P1D"] # Daily backup at 9:00 PM UTC

  # Required default retention durations
  operational_default_retention_duration = "P${each.value.policy_config.retention.daily}D"
  vault_default_retention_duration = "P${max(
    each.value.policy_config.retention.daily,
    each.value.policy_config.retention.weekly * 7,
    each.value.policy_config.retention.monthly * 30,
    each.value.policy_config.retention.yearly * 365
  )}D"

  # Define retention rules
  retention_rule {
    name     = "Daily"
    priority = 10
    life_cycle {
      duration        = "P${each.value.policy_config.retention.daily}D"
      data_store_type = "VaultStore"
    }
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  # Add weekly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
    content {
      name     = "Weekly"
      priority = 20
      life_cycle {
        duration        = "P${each.value.policy_config.retention.weekly * 7}D"
        data_store_type = "VaultStore"
      }
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }

  # Add monthly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
    content {
      name     = "Monthly"
      priority = 30
      life_cycle {
        duration        = "P${each.value.policy_config.retention.monthly * 30}D"
        data_store_type = "VaultStore"
      }
      criteria {
        absolute_criteria = "FirstOfMonth"
      }
    }
  }

  # Add yearly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
    content {
      name     = "Yearly"
      priority = 40
      life_cycle {
        duration        = "P${each.value.policy_config.retention.yearly * 365}D"
        data_store_type = "VaultStore"
      }
      criteria {
        absolute_criteria = "FirstOfYear"
      }
    }
  }
}

resource "azurerm_data_protection_backup_policy_disk" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.disk, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  name     = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  vault_id = azurerm_data_protection_backup_vault.vaults[each.value.vault_type].id

  # Define backup schedule - daily backup at 21:00 AM UTC
  backup_repeating_time_intervals = ["R/2025-01-01T21:00:00Z/P1D"]

  # Weekly rules have highest priority
  # Daily rules come next
  # Default retention is only applied if no other rules match a particular backup
  default_retention_duration = "P90D"
  time_zone                  = "UTC"

  retention_rule {
    name     = "Daily"
    duration = "P${each.value.policy_config.retention.daily}D"
    priority = 20
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
    content {
      name     = "Weekly"
      duration = "P${min(each.value.policy_config.retention.weekly * 7, 360)}D"
      priority = 30
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }

  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
    content {
      name     = "Monthly-Compatible"
      duration = "P${min(each.value.policy_config.retention.monthly * 30, 360)}D"
      priority = 40
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }

  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []

    content {
      name     = "Yearly-Compatible"
      duration = "P360D" # Max allowed by Azure
      priority = 50
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }
}

# Create a backup policy instance for each vault type and PostgreSQL policy combination
resource "azurerm_data_protection_backup_policy_postgresql" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.postgresql, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  # Create a unique name for each policy
  name                = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  resource_group_name = local.resource_group_name
  vault_name          = azurerm_data_protection_backup_vault.vaults[each.value.vault_type].name

  # Define backup schedule - weekly backup at 21:00 PM UTC on Sunday
  backup_repeating_time_intervals = ["R/2025-01-01T21:00:00Z/P1W"]

  # Default retention duration based on the longest retention period
  default_retention_duration = "P${max(
    each.value.policy_config.retention.daily,
    each.value.policy_config.retention.weekly * 7,
    each.value.policy_config.retention.monthly * 30,
    each.value.policy_config.retention.yearly * 365
  )}D"

  # Optional time zone setting
  time_zone = "UTC"

  # Daily retention rule
  retention_rule {
    name     = "Daily"
    duration = "P${each.value.policy_config.retention.daily}D"
    priority = 20
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  # Add weekly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
    content {
      name     = "Weekly"
      duration = "P${each.value.policy_config.retention.weekly * 7}D"
      priority = 30
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }

  # Add monthly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
    content {
      name     = "Monthly"
      duration = "P${each.value.policy_config.retention.monthly * 30}D"
      priority = 40
      criteria {
        absolute_criteria = "FirstOfMonth"
      }
    }
  }

  # Add yearly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
    content {
      name     = "Yearly"
      duration = "P${each.value.policy_config.retention.yearly * 365}D"
      priority = 50
      criteria {
        absolute_criteria = "FirstOfYear"
      }
    }
  }
}

# Create a backup policy instance for each vault type and Kubernetes Cluster policy combination
resource "azurerm_data_protection_backup_policy_kubernetes_cluster" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.kubernetes, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  # Create a unique name for each policy
  name                = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  resource_group_name = local.resource_group_name
  vault_name          = azurerm_data_protection_backup_vault.vaults[each.value.vault_type].name

  # Define backup schedule - weekly backup at 21:00 PM UTC on Sunday
  backup_repeating_time_intervals = ["R/2025-01-01T21:00:00Z/P1W"]

  # Optional time zone setting
  time_zone = "UTC"

  # Default retention rule - Max 30 days for default rule
  default_retention_rule {
    life_cycle {
      data_store_type = "OperationalStore"
      duration        = "P${min(each.value.policy_config.retention.daily, 30)}D"
    }
  }

  # Daily retention rule - Max 30 days for operational store
  retention_rule {
    name     = "Daily"
    priority = 20
    life_cycle {
      data_store_type = "OperationalStore"
      duration        = "P${min(each.value.policy_config.retention.daily, 30)}D"
    }
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  # Add weekly retention if specified - Max 360 days for weekly
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
    content {
      name     = "Weekly"
      priority = 30
      life_cycle {
        data_store_type = "OperationalStore"
        duration        = "P${min(each.value.policy_config.retention.weekly * 7, 360)}D"
      }
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }

  # Add monthly retention if specified - Max 360 days for monthly
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
    content {
      name     = "Monthly"
      priority = 40
      life_cycle {
        data_store_type = "OperationalStore"
        duration        = "P${min(each.value.policy_config.retention.monthly * 30, 360)}D"
      }
      criteria {
        absolute_criteria = "FirstOfMonth"
      }
    }
  }

  # Add yearly retention if specified - Max 360 days for yearly
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
    content {
      name     = "Yearly"
      priority = 50
      life_cycle {
        data_store_type = "OperationalStore"
        duration        = "P${min(each.value.policy_config.retention.yearly * 365, 360)}D"
      }
      criteria {
        absolute_criteria = "FirstOfYear"
      }
    }
  }
}

# Create a backup policy instance for each vault type and PostgreSQL Flexible Server policy combination
resource "azurerm_data_protection_backup_policy_postgresql_flexible_server" "this" {
  for_each = merge(flatten([
    for vault_type in var.vaults_to_deploy : {
      for policy_name, policy_config in try(local.policy_configs.postgresql_flexible, {}) :
      "${vault_type}_${policy_name}" => {
        vault_type    = vault_type
        policy_name   = policy_name
        policy_config = policy_config
      }
    }
  ])...)

  # Create a unique name for each policy
  name     = "${each.value.policy_name}-${upper(each.value.vault_type)}"
  vault_id = azurerm_data_protection_backup_vault.vaults[each.value.vault_type].id

  # Define backup schedule - weekly backup at 21:00 PM UTC on Sunday
  backup_repeating_time_intervals = ["R/2025-01-01T21:00:00Z/P1W"]

  # Optional time zone setting
  time_zone = "UTC"

  # Default retention rule
  default_retention_rule {
    life_cycle {
      data_store_type = "VaultStore"
      duration        = "P${each.value.policy_config.retention.daily}D"
    }
  }

  # Daily retention rule
  retention_rule {
    name     = "Daily"
    priority = 20
    life_cycle {
      data_store_type = "VaultStore"
      duration        = "P${each.value.policy_config.retention.daily}D"
    }
    criteria {
      absolute_criteria = "FirstOfDay"
    }
  }

  # Add weekly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.weekly > 0 ? [1] : []
    content {
      name     = "Weekly"
      priority = 30
      life_cycle {
        data_store_type = "VaultStore"
        duration        = "P${each.value.policy_config.retention.weekly * 7}D"
      }
      criteria {
        absolute_criteria = "FirstOfWeek"
      }
    }
  }

  # Add monthly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.monthly > 0 ? [1] : []
    content {
      name     = "Monthly"
      priority = 40
      life_cycle {
        data_store_type = "VaultStore"
        duration        = "P${each.value.policy_config.retention.monthly * 30}D"
      }
      criteria {
        absolute_criteria = "FirstOfMonth"
      }
    }
  }

  # Add yearly retention if specified
  dynamic "retention_rule" {
    for_each = each.value.policy_config.retention.yearly > 0 ? [1] : []
    content {
      name     = "Yearly"
      priority = 50
      life_cycle {
        data_store_type = "VaultStore"
        duration        = "P${each.value.policy_config.retention.yearly * 365}D"
      }
      criteria {
        absolute_criteria = "FirstOfYear"
      }
    }
  }
}