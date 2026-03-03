###############################################################################
# SCC Custom: Maintenance Configurations (Azure Update Manager)
###############################################################################
# Centrally defined patch schedules for workload VMs across the organisation.
#
# Default patch groups are scheduled after Patch Tuesday (2nd Tuesday of month):
# - Wave 1: Wednesday at 22:00 GMT (day after Patch Tuesday)
# - Wave 2: Thursday at 22:00 GMT (24 hours later)
#
# This ensures:
# - Patches are available (released on Patch Tuesday)
# - 24+ hour stagger between groups to catch issues
# - Out of work hours (10pm UK time)
#
# VM Assignment via Dynamic Scoping:
# Instead of explicit per-VM assignments, VMs are automatically included
# in maintenance windows based on tags. Add this tag to VMs:
#   MaintenanceWindow = "<config_key>"  (e.g., "patch_wave_1_windows")
###############################################################################

scc_maintenance_configurations_enabled = true

###############################################################################
# Dynamic Scope Subscriptions
###############################################################################
# List of subscription IDs where VMs should be automatically assigned to
# maintenance windows based on their MaintenanceWindow tag.
# Add workload subscription IDs here as they are onboarded.

scc_maintenance_dynamic_scope_subscriptions = [
  # "f09a5d16-c8db-4d7c-bce4-a2781c659cde",  # Platform Management (uncomment when ready)
]

scc_maintenance_configurations = {
  ###########################################################################
  # Patch Wave 1 - Windows
  # Wednesday after Patch Tuesday at 22:00 GMT
  ###########################################################################
  patch_wave_1_windows = {
    name  = "mc-patch-wave1-windows"
    scope = "InGuestPatch"

    extension_properties = {
      InGuestPatchMode = "User"
    }

    install_patches = {
      reboot_setting = "IfRequired"
      windows = {
        classifications_to_include = ["Critical", "Security", "UpdateRollup", "Definition"]
      }
    }

    window = {
      duration        = "02:00"
      recur_every     = "Month Second Wednesday"
      start_date_time = "2024-01-10 22:00"
      time_zone       = "GMT Standard Time"
    }

    tags = {
      purpose = "patch-management"
      wave    = "1"
      os      = "windows"
    }

    # Dynamic Scope - automatically assign VMs with tag: MaintenanceWindow = "patch_wave_1_windows"
    dynamic_scope = {
      enabled = true
      filter = {
        os_types       = ["Windows"]
        resource_types = ["Microsoft.Compute/virtualMachines"]
      }
    }
  }

  ###########################################################################
  # Patch Wave 2 - Windows
  # Thursday after Patch Tuesday at 22:00 GMT (24 hours after Wave 1)
  ###########################################################################
  patch_wave_2_windows = {
    name  = "mc-patch-wave2-windows"
    scope = "InGuestPatch"

    extension_properties = {
      InGuestPatchMode = "User"
    }

    install_patches = {
      reboot_setting = "IfRequired"
      windows = {
        classifications_to_include = ["Critical", "Security", "UpdateRollup", "Definition"]
      }
    }

    window = {
      duration        = "02:00"
      recur_every     = "Month Second Thursday"
      start_date_time = "2024-01-11 22:00"
      time_zone       = "GMT Standard Time"
    }

    tags = {
      purpose = "patch-management"
      wave    = "2"
      os      = "windows"
    }

    # Dynamic Scope - automatically assign VMs with tag: MaintenanceWindow = "patch_wave_2_windows"
    dynamic_scope = {
      enabled = true
      filter = {
        os_types       = ["Windows"]
        resource_types = ["Microsoft.Compute/virtualMachines"]
      }
    }
  }

  ###########################################################################
  # Patch Wave 1 - Linux
  # Wednesday after Patch Tuesday at 23:00 GMT (staggered from Windows)
  ###########################################################################
  patch_wave_1_linux = {
    name  = "mc-patch-wave1-linux"
    scope = "InGuestPatch"

    extension_properties = {
      InGuestPatchMode = "User"
    }

    install_patches = {
      reboot_setting = "IfRequired"
      linux = {
        classifications_to_include = ["Critical", "Security"]
      }
    }

    window = {
      duration        = "02:00"
      recur_every     = "Month Second Wednesday"
      start_date_time = "2024-01-10 23:00"
      time_zone       = "GMT Standard Time"
    }

    tags = {
      purpose = "patch-management"
      wave    = "1"
      os      = "linux"
    }

    # Dynamic Scope - automatically assign VMs with tag: MaintenanceWindow = "patch_wave_1_linux"
    dynamic_scope = {
      enabled = true
      filter = {
        os_types       = ["Linux"]
        resource_types = ["Microsoft.Compute/virtualMachines"]
      }
    }
  }

  ###########################################################################
  # Patch Wave 2 - Linux
  # Thursday after Patch Tuesday at 23:00 GMT (24 hours after Wave 1)
  ###########################################################################
  patch_wave_2_linux = {
    name  = "mc-patch-wave2-linux"
    scope = "InGuestPatch"

    extension_properties = {
      InGuestPatchMode = "User"
    }

    install_patches = {
      reboot_setting = "IfRequired"
      linux = {
        classifications_to_include = ["Critical", "Security"]
      }
    }

    window = {
      duration        = "02:00"
      recur_every     = "Month Second Thursday"
      start_date_time = "2024-01-11 23:00"
      time_zone       = "GMT Standard Time"
    }

    tags = {
      purpose = "patch-management"
      wave    = "2"
      os      = "linux"
    }

    # Dynamic Scope - automatically assign VMs with tag: MaintenanceWindow = "patch_wave_2_linux"
    dynamic_scope = {
      enabled = true
      filter = {
        os_types       = ["Linux"]
        resource_types = ["Microsoft.Compute/virtualMachines"]
      }
    }
  }
}
