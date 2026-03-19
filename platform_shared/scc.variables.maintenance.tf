###############################################################################
# SCC Custom: Maintenance Configurations (Azure Update Manager)
###############################################################################
# Centrally defined patch schedules for workload VMs across the organisation.
# VMs in workload subscriptions reference these by resource ID.
###############################################################################

variable "scc_maintenance_configurations_enabled" {
  type        = bool
  default     = true
  description = "Enable or disable deployment of maintenance configurations."
}

variable "scc_maintenance_resource_group_name" {
  type        = string
  default     = null
  description = "Resource group name for maintenance configurations. Defaults to the management resource group if not specified."
}

variable "scc_maintenance_configurations" {
  type = map(object({
    # Required
    name  = string
    scope = string # Extension, Host, InGuestPatch, OSImage, SQLDB, SQLManagedInstance

    # Optional
    location             = optional(string)
    visibility           = optional(string, "Custom")
    extension_properties = optional(map(string), {})

    # Install Patches (required when scope = InGuestPatch)
    install_patches = optional(object({
      linux = optional(object({
        classifications_to_include    = optional(list(string), ["Critical", "Security"])
        package_name_masks_to_exclude = optional(list(string), [])
        package_name_masks_to_include = optional(list(string), [])
      }))
      reboot_setting = optional(string) # Always, IfRequired, Never
      windows = optional(object({
        classifications_to_include   = optional(list(string), ["Critical", "Security"])
        exclude_kbs_requiring_reboot = optional(bool)
        kb_numbers_to_exclude        = optional(list(string), [])
        kb_numbers_to_include        = optional(list(string), [])
      }))
    }))

    # Maintenance Window
    window = optional(object({
      duration             = optional(string, "02:00") # HH:mm format
      expiration_date_time = optional(string)          # YYYY-MM-DD hh:mm
      recur_every          = string                    # e.g., "Month Second Wednesday"
      start_date_time      = string                    # YYYY-MM-DD hh:mm
      time_zone            = string                    # e.g., "GMT Standard Time"
    }))

    # Telemetry
    enable_telemetry = optional(bool)

    # Tags
    tags = optional(map(string))

    # Lock
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }))

    # Role Assignments
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})

    # Dynamic Scope (optional - enables tag-based VM targeting)
    dynamic_scope = optional(object({
      enabled = optional(bool, false)
      name    = optional(string)
      filter = object({
        # Resource groups to include (optional - if empty, all RGs in subscription)
        resource_groups = optional(list(string), [])
        # Resource types to target (defaults to VMs)
        resource_types = optional(list(string), ["Microsoft.Compute/virtualMachines"])
        # OS types to filter (Linux, Windows, or both)
        os_types = optional(list(string), ["Linux", "Windows"])
        # Locations to filter (optional - if empty, all locations)
        locations = optional(list(string), [])
        # Tag filter for VM targeting (e.g., MaintenanceWindow = patch_wave_1_windows)
        tag_filter = optional(string)
        # Tag filter operators: Any, All
        tag_filter_operator = optional(string, "Any")
        # Structured tags filter (alternative to tag_filter string)
        tags = optional(map(list(string)), {})
      })
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
A map of maintenance configurations for Azure Update Manager.

These are centrally defined in the Management subscription and can be referenced
by VMs in workload subscriptions via their resource IDs.

Default patch groups are scheduled after Patch Tuesday (2nd Tuesday of each month):
- Wave 1: Wednesday at 22:00 GMT (day after Patch Tuesday)
- Wave 2: Thursday at 22:00 GMT (24 hours later)

This ensures:
- Patches are available (released on Patch Tuesday)
- 24+ hour stagger between groups to catch issues
- Out of work hours (10pm UK time)

Example:
```hcl
scc_maintenance_configurations = {
  patch_wave_1 = {
    name  = "mc-patch-wave-1-uks"
    scope = "InGuestPatch"
    install_patches = {
      reboot_setting = "IfRequired"
      windows = {
        classifications_to_include = ["Critical", "Security", "UpdateRollup"]
      }
    }
    window = {
      duration        = "02:00"
      recur_every     = "Month Second Wednesday"
      start_date_time = "2024-01-10 22:00"
      time_zone       = "GMT Standard Time"
    }
  }
}
```
DESCRIPTION
}

variable "scc_maintenance_dynamic_scope_subscriptions" {
  type        = list(string)
  default     = []
  description = <<DESCRIPTION
List of subscription IDs to include in maintenance configuration dynamic scopes.
Dynamic scopes allow VMs to be automatically assigned to maintenance configurations
based on tags, rather than requiring explicit per-VM assignments.

When a subscription is added to this list, VMs in that subscription with matching
tags (e.g., MaintenanceWindow = "patch_wave_1_windows") will automatically be
included in the corresponding maintenance window.

Example:
```hcl
scc_maintenance_dynamic_scope_subscriptions = [
  "00000000-0000-0000-0000-000000000001",  # Platform Management
  "00000000-0000-0000-0000-000000000002",  # Workload Subscription 1
]
```
DESCRIPTION
}
