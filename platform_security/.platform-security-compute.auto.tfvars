###############################################################################
# Compute Configuration
###############################################################################

compute_enabled = true  # Disabled - VM definitions ready for future deployment

###############################################################################
# Compute - Security VMs (Tenable Sensors, Syslog Servers)
###############################################################################
# VMs are configured with modern security standards:
# - Encryption at host enabled (where supported)
# - Premium SSD OS disks
# - Accelerated networking
#
# Tenable VMs:
#   - Marketplace image: Tenable Core + Tenable Nessus (BYOL)
#   - OS: Oracle Linux 8 (Gen2)
#   - Note: Trusted Launch (secure_boot/vtpm) may not be supported
#
# Syslog Servers:
#   - Standard Linux image
#   - Purpose: Centralized log collection
#
# Maintenance Windows (Azure Update Manager - Dynamic Scoping):
#   VMs are automatically assigned to maintenance windows via tags.
#   Wave 1 (patch_wave_1_linux): Wednesday after Patch Tuesday at 22:00 GMT
#   Wave 2 (patch_wave_2_linux): Thursday after Patch Tuesday at 22:00 GMT

compute = {
  ###########################################################################
  # UK South - Primary Region
  ###########################################################################
  uksouth = {
    location = "uksouth"

    # Resource Groups by purpose
    vm_resource_groups = {
      tenable = {
        name = "rg-security-prod-tenable-uks-001"
      }
      syslog = {
        name = "rg-security-prod-syslog-uks-001"
      }
    }

    # ASR Configuration - Replicate to UK West
    asr_config = {
      target_location = "ukwest"

      # Use existing ASR vault in UK West
      use_existing_vault        = true
      vault_name                = "rsv-asr-security-prod-ukw-001"
      vault_resource_group_name = "rg-security-prod-mgmt-ukw-001"

      # Replication policy
      recovery_point_retention_in_minutes          = 1440 # 24 hours
      app_consistent_snapshot_frequency_in_minutes = 240  # 4 hours

      # Target resource group for replicated disks
      target_resource_group_name = "rg-security-prod-mgmt-ukw-001"

      # Target network for failover VMs
      target_network_name           = "vnet-security-prod-ukw-001"
      target_network_resource_group = "rg-security-prod-network-ukw-001"
    }

    vms = {
      #########################################################################
      # Tenable Sensor - UK South (no zone - capacity constraints)
      #########################################################################
      tenable_01 = {
        name               = "vmsecuksten001"
        resource_group_key = "tenable"
        os_type            = "Linux"
        sku_size           = "Standard_B4ls_v2"

        # Patching - Tenable marketplace image doesn't support AutomaticByPlatform
        patch_mode            = "ImageDefault"
        patch_assessment_mode = "ImageDefault"

        # Tenable Core + Nessus (BYOL) - Marketplace Image
        source_image_reference = {
          publisher = "tenable"
          offer     = "tenablecorenessus"
          sku       = "tenablecoreol8nessusbyol"
          version   = "latest"
        }

        # Marketplace plan (required for Tenable)
        plan = {
          name      = "tenablecoreol8nessusbyol"
          product   = "tenablecorenessus"
          publisher = "tenable"
        }

        # OS Disk - 128GB Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 128
        }

        # Network interface - Tenable subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.0.6.4"
                subnet_reference = {
                  vnet_key   = "security"
                  subnet_key = "tenable"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings
        # Note: Marketplace images may not support Trusted Launch
        encryption_at_host_enabled = true
        secure_boot_enabled        = false
        vtpm_enabled               = false

        # Maintenance Window - Linux Wave 1
        maintenance_window = "patch_wave_1_linux"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-security-prod-tenable-ukw-001"
          target_static_ip   = "10.1.6.5"
        }

        tags = {
          Application = "Tenable"
          Role        = "VulnerabilityScanner"
        }
      }

      #########################################################################
      # Syslog Server - UK South (no zone - capacity constraints)
      #########################################################################
      syslog_01 = {
        name               = "vmsecukslog001"
        resource_group_key = "syslog"
        os_type            = "Linux"
        sku_size           = "Standard_D2s_v5"


        # Ubuntu 22.04 LTS Gen2
        source_image_reference = {
          publisher = "Canonical"
          offer     = "0001-com-ubuntu-server-jammy"
          sku       = "22_04-lts-gen2"
          version   = "latest"
        }

        # OS Disk - 256GB Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 256
        }

        # Network interface - Syslog subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.0.6.20"
                subnet_reference = {
                  vnet_key   = "security"
                  subnet_key = "syslog"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings (Gen2/Trusted Launch)
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true

        # Maintenance Window - Linux Wave 2 (staggered from Tenable)
        maintenance_window = "patch_wave_2_linux"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-security-prod-syslog-ukw-001"
          target_static_ip   = "10.1.6.21"
        }

        tags = {
          Application = "Syslog"
          Role        = "LogCollector"
        }
      }
    }
  }

  ###########################################################################
  # UK West - Secondary/DR Region
  ###########################################################################
  ukwest = {
    location = "ukwest"

    # Resource Groups by purpose
    vm_resource_groups = {
      tenable = {
        name = "rg-security-prod-tenable-ukw-001"
      }
      syslog = {
        name = "rg-security-prod-syslog-ukw-001"
      }
    }

    vms = {
      #########################################################################
      # Tenable Sensor - UK West
      #########################################################################
      tenable_01 = {
        name               = "vmsecukwten002"
        resource_group_key = "tenable"
        os_type            = "Linux"
        sku_size           = "Standard_B4ls_v2"

        # Patching - Tenable marketplace image doesn't support AutomaticByPlatform
        patch_mode            = "ImageDefault"
        patch_assessment_mode = "ImageDefault"

        # Tenable Core + Nessus (BYOL) - Marketplace Image
        source_image_reference = {
          publisher = "tenable"
          offer     = "tenablecorenessus"
          sku       = "tenablecoreol8nessusbyol"
          version   = "latest"
        }

        # Marketplace plan (required for Tenable)
        plan = {
          name      = "tenablecoreol8nessusbyol"
          product   = "tenablecorenessus"
          publisher = "tenable"
        }

        # OS Disk - 128GB Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 128
        }

        # Network interface - Tenable subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.1.6.4"
                subnet_reference = {
                  vnet_key   = "security"
                  subnet_key = "tenable"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings
        # Note: Marketplace images may not support Trusted Launch
        encryption_at_host_enabled = true
        secure_boot_enabled        = false
        vtpm_enabled               = false

        # Maintenance Window - Linux Wave 1
        maintenance_window = "patch_wave_1_linux"

        tags = {
          Application = "Tenable"
          Role        = "VulnerabilityScanner"
        }
      }

      #########################################################################
      # Syslog Server - UK West
      #########################################################################
      syslog_01 = {
        name               = "vmsecukwlog002"
        resource_group_key = "syslog"
        os_type            = "Linux"
        sku_size           = "Standard_D2s_v5"


        # Ubuntu 22.04 LTS Gen2
        source_image_reference = {
          publisher = "Canonical"
          offer     = "0001-com-ubuntu-server-jammy"
          sku       = "22_04-lts-gen2"
          version   = "latest"
        }

        # OS Disk - 256GB Premium SSD
        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 256
        }

        # Network interface - Syslog subnet
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.1.6.20"
                subnet_reference = {
                  vnet_key   = "security"
                  subnet_key = "syslog"
                }
              }
            }
          }
        }

        # Authentication
        admin_password = "a4tE9fzovFUh9b6TXYeP"

        # Security settings (Gen2/Trusted Launch)
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true

        # Maintenance Window - Linux Wave 2 (staggered from Tenable)
        maintenance_window = "patch_wave_2_linux"

        tags = {
          Application = "Syslog"
          Role        = "LogCollector"
        }
      }
    }
  }
}
