###############################################################################
# SCC Custom: Maintenance Configurations (Azure Update Manager)
###############################################################################
# Centrally defined patch schedules for workload VMs across the organisation.
# VMs in workload subscriptions reference these by resource ID.
#
# Default patch groups are scheduled after Patch Tuesday (2nd Tuesday of month):
# - Wave 1: Wednesday at 22:00 GMT (day after Patch Tuesday)
# - Wave 2: Thursday at 22:00 GMT (24 hours later)
#
# This ensures:
# - Patches are available (released on Patch Tuesday)
# - 24+ hour stagger between groups to catch issues
# - Out of work hours (10pm UK time)
###############################################################################

module "scc_maintenance_configuration" {
  source  = "Azure/avm-res-maintenance-maintenanceconfiguration/azurerm"
  version = "0.1.0"

  for_each = var.scc_maintenance_configurations_enabled ? var.scc_maintenance_configurations : {}

  # Required - use local.management_resource_settings which has template strings resolved
  name                = each.value.name
  resource_group_name = coalesce(var.scc_maintenance_resource_group_name, local.management_resource_settings.resource_group_name, "rg-management-${local.management_resource_settings.location}")
  location            = coalesce(each.value.location, local.management_resource_settings.location)
  scope               = each.value.scope

  # Optional
  visibility           = each.value.visibility
  extension_properties = each.value.extension_properties
  install_patches      = each.value.install_patches
  window               = each.value.window

  # Telemetry
  enable_telemetry = coalesce(each.value.enable_telemetry, var.enable_telemetry)

  # Tags - merge default tags (from config module) with per-resource tags (per-resource takes precedence)
  tags = merge(coalesce(local.management_resource_settings.tags, {}), coalesce(each.value.tags, {}))

  # Security
  lock             = each.value.lock
  role_assignments = each.value.role_assignments

  providers = {
    azurerm = azurerm.management
  }
}

###############################################################################
# SCC Custom: Maintenance Configuration Dynamic Scopes
###############################################################################
# Dynamic scopes enable automatic VM assignment based on tags.
# Instead of explicitly assigning each VM to a maintenance configuration,
# VMs are automatically included when they have the matching tag:
#   MaintenanceWindow = "<configuration_key>"  (e.g., "patch_wave_1_windows")
#
# This simplifies VM deployment - just add the appropriate tag to VMs
# and they will be automatically scheduled for patching.
###############################################################################

locals {
  # Build a flattened map of subscription + maintenance config for dynamic scopes
  # Only include configs where dynamic_scope is enabled
  # Uses coalescelist: prefers tfvars override, falls back to all platform subscriptions
  maintenance_dynamic_scopes = merge([
    for sub_id in coalescelist(var.scc_maintenance_dynamic_scope_subscriptions, local.scc_maintenance_platform_subscriptions) : {
      for config_key, config in var.scc_maintenance_configurations :
      "${sub_id}_${config_key}" => {
        subscription_id              = sub_id
        config_key                   = config_key
        maintenance_configuration_id = module.scc_maintenance_configuration[config_key].resource_id
        name                         = coalesce(try(config.dynamic_scope.name, null), "dscope-${config.name}-${substr(sub_id, 0, 8)}")
        filter                       = try(config.dynamic_scope.filter, null)
      }
      if var.scc_maintenance_configurations_enabled && try(config.dynamic_scope.enabled, false)
    }
  ]...)
}

resource "azurerm_maintenance_assignment_dynamic_scope" "scc" {
  for_each = local.maintenance_dynamic_scopes

  name                         = each.value.name
  maintenance_configuration_id = each.value.maintenance_configuration_id

  filter {
    # Locations - if empty, all locations are included
    locations = try(each.value.filter.locations, [])

    # OS types to filter
    os_types = try(each.value.filter.os_types, ["Linux", "Windows"])

    # Resource groups - if empty, all RGs in subscription
    resource_groups = try(each.value.filter.resource_groups, [])

    # Resource types to target
    resource_types = try(each.value.filter.resource_types, ["Microsoft.Compute/virtualMachines"])

    # Tag matching logic - "Any" means VM must match at least one tag filter
    tag_filter = try(each.value.filter.tag_filter, "Any")

    # Default tag filter: VMs with MaintenanceWindow = "<config_key>"
    # e.g., MaintenanceWindow = "patch_wave_1_windows"
    tags {
      tag    = "MaintenanceWindow"
      values = [each.value.config_key]
    }
  }

  provider = azurerm.management
}

###############################################################################
# Note: Dynamic scope assignments require the maintenance configuration
# to already exist. The depends_on in the module above ensures this.
#
# For VMs to be included in a maintenance window, add the tag:
#   MaintenanceWindow = "<config_key>"
#
# Example tags for VMs:
#   MaintenanceWindow = "patch_wave_1_windows"  -> Patches Wednesday 22:00
#   MaintenanceWindow = "patch_wave_2_windows"  -> Patches Thursday 22:00
#   MaintenanceWindow = "patch_wave_1_linux"    -> Patches Wednesday 23:00
#   MaintenanceWindow = "patch_wave_2_linux"    -> Patches Thursday 23:00
###############################################################################
