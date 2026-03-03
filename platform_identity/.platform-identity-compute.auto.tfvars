###############################################################################
# Compute Configuration
###############################################################################

compute_enabled = false  # Disabled due to uksouth capacity constraints

###############################################################################
# Compute - Domain Controllers
###############################################################################
# VMs are configured with modern security standards:
# - Gen2 compatible images (Windows Server 2022 Azure Edition)
# - Encryption at host enabled
# - Secure Boot enabled (Trusted Launch)
# - vTPM enabled (Trusted Launch)
# - Premium SSD OS disks
# - Accelerated networking
#
# Auto-generated resource names follow the naming convention:
#   VMs: vm-{purpose}-{region_abbr}-{instance}
#   NICs: nic-{vm_name}-{nic_key}
#
# Maintenance Windows (Azure Update Manager - Dynamic Scoping):
#   VMs are automatically assigned to maintenance windows via tags.
#   The MaintenanceWindow tag is injected based on the maintenance_window setting.
#
#   DC01 -> maintenance_window = "patch_wave_1_windows"
#           Patches Wednesday after Patch Tuesday at 22:00 GMT
#   DC02 -> maintenance_window = "patch_wave_2_windows"
#           Patches Thursday after Patch Tuesday at 22:00 GMT
#
#   This ensures DCs are patched on different days for high availability.
#
# Note: Zones removed due to UK South capacity constraints.

compute = {
  # Primary region - 2 Domain Controllers
  uksouth = {
    # location defaults to "uksouth" from map key

    # ASR Configuration - Replicate to UK West
    asr_config = {
      target_location = "ukwest"

      # Use existing ASR vault in UK West
      use_existing_vault        = true
      vault_name                = "rsv-asr-identity-prod-ukw-001"
      vault_resource_group_name = "rg-identity-prod-mgmt-ukw-001"

      # Replication policy
      recovery_point_retention_in_minutes          = 1440 # 24 hours
      app_consistent_snapshot_frequency_in_minutes = 240  # 4 hours

      # Target resource group for replicated disks
      target_resource_group_name = "rg-identity-prod-mgmt-ukw-001"

      # Target network for failover VMs
      target_network_name           = "vnet-identity-prod-ukw-001"
      target_network_resource_group = "rg-identity-prod-network-ukw-001"
    }

    vms = {
      # Domain Controller 1 (no zone - capacity constraints)
      dc01 = {
        name     = "vm-dc-uks-001"
        sku_size = "Standard_B2ms"

        # Windows Server 2022 Datacenter Azure Edition (Gen2)
        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-g2"
          version   = "latest"
        }

        # OS Disk - Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 128
        }

        # Data disk for NTDS/SYSVOL
        data_disk_managed_disks = {
          ntds = {
            name                 = "disk-dc-uks-001-ntds"
            storage_account_type = "Premium_LRS"
            lun                  = 0
            caching              = "None"
            create_option        = "Empty"
            disk_size_gb         = 32
          }
        }

        # Network interface - Domain Controllers subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Dynamic"
                subnet_reference = {
                  vnet_key   = "identity"
                  subnet_key = "domain_controllers"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings (Gen2/Trusted Launch)
        encryption_at_host_enabled = true   # Auto-registered by VM module
        secure_boot_enabled        = true
        vtpm_enabled               = true

        # Patching
        patch_mode               = "AutomaticByPlatform"
        patch_assessment_mode    = "AutomaticByPlatform"
        enable_automatic_updates = true

        # Telemetry
        enable_telemetry = true

        # Use existing management resource group from vending
        resource_group_name = "rg-identity-prod-mgmt-uks-001"

        # Maintenance Window - automatically assigned via dynamic scope
        # Wave 1: Wednesday after Patch Tuesday at 22:00 GMT
        maintenance_window = "patch_wave_1_windows"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-identity-prod-dc-ukw-001"
          target_static_ip   = "10.1.4.5"
        }
      }

      # Domain Controller 2 (no zone - capacity constraints)
      dc02 = {
        name     = "vm-dc-uks-002"
        sku_size = "Standard_B2ms"

        # Windows Server 2022 Datacenter Azure Edition (Gen2)
        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-g2"
          version   = "latest"
        }

        # OS Disk - Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 128
        }

        # Data disk for NTDS/SYSVOL
        data_disk_managed_disks = {
          ntds = {
            name                 = "disk-dc-uks-002-ntds"
            storage_account_type = "Premium_LRS"
            lun                  = 0
            caching              = "None"
            create_option        = "Empty"
            disk_size_gb         = 32
          }
        }

        # Network interface - Domain Controllers subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Dynamic"
                subnet_reference = {
                  vnet_key   = "identity"
                  subnet_key = "domain_controllers"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings (Gen2/Trusted Launch)
        encryption_at_host_enabled = true   # Auto-registered by VM module
        secure_boot_enabled        = true
        vtpm_enabled               = true

        # Patching
        patch_mode               = "AutomaticByPlatform"
        patch_assessment_mode    = "AutomaticByPlatform"
        enable_automatic_updates = true

        # Telemetry
        enable_telemetry = true

        # Use existing management resource group from vending
        resource_group_name = "rg-identity-prod-mgmt-uks-001"

        # Maintenance Window - automatically assigned via dynamic scope
        # Wave 2: Thursday after Patch Tuesday at 22:00 GMT (staggered from DC01)
        maintenance_window = "patch_wave_2_windows"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-identity-prod-dc-ukw-001"
          target_static_ip   = "10.1.4.6"
        }
      }
    }
  }

  # Secondary region (DR) - 2 Domain Controllers
  # Note: ukwest does not support availability zones
  ukwest = {
    # location defaults to "ukwest" from map key

    vms = {
      # Domain Controller 1 (no zone - ukwest doesn't support AZs)
      dc01 = {
        name     = "vm-dc-ukw-001"
        sku_size = "Standard_B2ms"

        # Windows Server 2022 Datacenter Azure Edition (Gen2)
        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-g2"
          version   = "latest"
        }

        # OS Disk - Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 128
        }

        # Data disk for NTDS/SYSVOL
        data_disk_managed_disks = {
          ntds = {
            name                 = "disk-dc-ukw-001-ntds"
            storage_account_type = "Premium_LRS"
            lun                  = 0
            caching              = "None"
            create_option        = "Empty"
            disk_size_gb         = 32
          }
        }

        # Network interface - Domain Controllers subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Dynamic"
                subnet_reference = {
                  vnet_key   = "identity"
                  subnet_key = "domain_controllers"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings (Gen2/Trusted Launch)
        encryption_at_host_enabled = true   # Auto-registered by VM module
        secure_boot_enabled        = true
        vtpm_enabled               = true

        # Patching
        patch_mode               = "AutomaticByPlatform"
        patch_assessment_mode    = "AutomaticByPlatform"
        enable_automatic_updates = true

        # Telemetry
        enable_telemetry = true

        # Use existing management resource group from vending
        resource_group_name = "rg-identity-prod-mgmt-ukw-001"

        # Maintenance Window - automatically assigned via dynamic scope
        # Wave 1: Wednesday after Patch Tuesday at 22:00 GMT
        maintenance_window = "patch_wave_1_windows"
      }

      # Domain Controller 2 (no zone - ukwest doesn't support AZs)
      dc02 = {
        name     = "vm-dc-ukw-002"
        sku_size = "Standard_B2ms"

        # Windows Server 2022 Datacenter Azure Edition (Gen2)
        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-g2"
          version   = "latest"
        }

        # OS Disk - Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 128
        }

        # Data disk for NTDS/SYSVOL
        data_disk_managed_disks = {
          ntds = {
            name                 = "disk-dc-ukw-002-ntds"
            storage_account_type = "Premium_LRS"
            lun                  = 0
            caching              = "None"
            create_option        = "Empty"
            disk_size_gb         = 32
          }
        }

        # Network interface - Domain Controllers subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Dynamic"
                subnet_reference = {
                  vnet_key   = "identity"
                  subnet_key = "domain_controllers"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings (Gen2/Trusted Launch)
        encryption_at_host_enabled = true   # Auto-registered by VM module
        secure_boot_enabled        = true
        vtpm_enabled               = true

        # Patching
        patch_mode               = "AutomaticByPlatform"
        patch_assessment_mode    = "AutomaticByPlatform"
        enable_automatic_updates = true

        # Telemetry
        enable_telemetry = true

        # Use existing management resource group from vending
        resource_group_name = "rg-identity-prod-mgmt-ukw-001"

        # Maintenance Window - automatically assigned via dynamic scope
        # Wave 2: Thursday after Patch Tuesday at 22:00 GMT (staggered from DC01)
        maintenance_window = "patch_wave_2_windows"
      }
    }
  }
}
