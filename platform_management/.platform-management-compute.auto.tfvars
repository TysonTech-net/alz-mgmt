###############################################################################
# Compute Configuration
###############################################################################

compute_enabled = true

###############################################################################
# Compute - Management VMs (Jump Servers, LogicMonitor Collectors)
###############################################################################
# VMs are configured with modern security standards:
# - Gen2 compatible images (Windows Server 2022 Azure Edition)
# - Encryption at host enabled
# - Secure Boot enabled (Trusted Launch)
# - vTPM enabled (Trusted Launch)
# - Premium SSD OS disks
# - Accelerated networking
#
# Resource Groups are created per purpose:
#   - rg-mgmt-prod-jump-{region}-001: Jump Servers
#   - rg-mgmt-prod-lm-{region}-001: LogicMonitor Collectors
#
# Maintenance Windows (Azure Update Manager - Dynamic Scoping):
#   Jump Servers and Collector 01 -> patch_wave_1_windows (Wednesday)
#   Collector 02 -> patch_wave_2_windows (Thursday)

compute = {
  ###########################################################################
  # UK South - Primary Region
  ###########################################################################
  uksouth = {
    location = "uksouth"

    # Resource Groups by purpose
    vm_resource_groups = {
      jump = {
        name = "rg-mgmt-prod-jump-uks-001"
      }
      logicmonitor = {
        name = "rg-mgmt-prod-lm-uks-001"
      }
    }

    # ASR Configuration - Replicate to UK West
    asr_config = {
      target_location = "ukwest"

      # Master toggle for ASR infrastructure (fabrics, containers, storage, etc.)
      # Set to false to disable without removing config
      infrastructure_enabled = true

      # Use existing ASR vault in UK West
      use_existing_vault        = true
      vault_name                = "rsv-asr-mgmt-prod-ukw-001"
      vault_resource_group_name = "rg-mgmt-prod-mgmt-ukw-001"

      # Replication policy
      recovery_point_retention_in_minutes          = 1440 # 24 hours
      app_consistent_snapshot_frequency_in_minutes = 240  # 4 hours

      # Target resource group for replicated disks
      target_resource_group_name = "rg-mgmt-prod-mgmt-ukw-001"

      # Target network for failover VMs
      target_network_name           = "vnet-mgmt-prod-ukw-001"
      target_network_resource_group = "rg-mgmt-prod-network-ukw-001"
    }

    vms = {
      #########################################################################
      # Jump Server - UK South (no zone - capacity constraints)
      #########################################################################
      jump_server_01 = {
        name               = "vmmgmtuksjmp001"
        resource_group_key = "jump"
        sku_size           = "Standard_D2s_v5"

        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }

        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 80
        }

        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.0.5.4"
                subnet_reference = {
                  vnet_key   = "management"
                  subnet_key = "jump_servers"
                }
              }
            }
          }
        }

        admin_password             = "a4tE9fzovFUh9b6TXYeP"
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true
        maintenance_window         = "patch_wave_1_windows"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-mgmt-prod-jump-ukw-001"
          target_static_ip   = "10.1.5.5"
        }

        tags = {
          Application = "JumpServer"
          Role        = "RemoteAccess"
        }
      }

      #########################################################################
      # LogicMonitor Collector 1 - UK South (no zone - capacity constraints)
      #########################################################################
      lm_collector_01 = {
        name               = "vmmgmtukslm001"
        resource_group_key = "logicmonitor"
        sku_size           = "Standard_D2s_v5"

        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }

        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 80
        }

        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.0.5.20"
                subnet_reference = {
                  vnet_key   = "management"
                  subnet_key = "logicmonitor"
                }
              }
            }
          }
        }

        admin_password             = "a4tE9fzovFUh9b6TXYeP"
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true
        maintenance_window         = "patch_wave_1_windows"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-mgmt-prod-lm-ukw-001"
          target_static_ip   = "10.1.5.22"
        }

        tags = {
          Application = "LogicMonitor"
          Role        = "Collector"
        }
      }

      #########################################################################
      # LogicMonitor Collector 2 - UK South (no zone - capacity constraints)
      #########################################################################
      lm_collector_02 = {
        name               = "vmmgmtukslm002"
        resource_group_key = "logicmonitor"
        sku_size           = "Standard_D2s_v5"

        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }

        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 80
        }

        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.0.5.21"
                subnet_reference = {
                  vnet_key   = "management"
                  subnet_key = "logicmonitor"
                }
              }
            }
          }
        }

        admin_password             = "a4tE9fzovFUh9b6TXYeP"
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true
        maintenance_window         = "patch_wave_2_windows"

        # ASR - Replicate to UK West
        asr = {
          enabled            = true
          target_subnet_name = "snet-mgmt-prod-lm-ukw-001"
          target_static_ip   = "10.1.5.23"
        }

        tags = {
          Application = "LogicMonitor"
          Role        = "Collector"
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
      jump = {
        name = "rg-mgmt-prod-jump-ukw-001"
      }
      logicmonitor = {
        name = "rg-mgmt-prod-lm-ukw-001"
      }
    }

    vms = {
      #########################################################################
      # Jump Server - UK West
      #########################################################################
      jump_server_01 = {
        name               = "vmmgmtukwjmp002"
        resource_group_key = "jump"
        sku_size           = "Standard_D2s_v5"

        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }

        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 80
        }

        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.1.5.4"
                subnet_reference = {
                  vnet_key   = "management"
                  subnet_key = "jump_servers"
                }
              }
            }
          }
        }

        admin_password             = "a4tE9fzovFUh9b6TXYeP"
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true
        maintenance_window         = "patch_wave_1_windows"

        tags = {
          Application = "JumpServer"
          Role        = "RemoteAccess"
        }
      }

      #########################################################################
      # LogicMonitor Collector 1 - UK West
      #########################################################################
      lm_collector_01 = {
        name               = "vmmgmtukwlm001"
        resource_group_key = "logicmonitor"
        sku_size           = "Standard_D2s_v5"

        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }

        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 80
        }

        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.1.5.20"
                subnet_reference = {
                  vnet_key   = "management"
                  subnet_key = "logicmonitor"
                }
              }
            }
          }
        }

        admin_password             = "a4tE9fzovFUh9b6TXYeP"
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true
        maintenance_window         = "patch_wave_1_windows"

        tags = {
          Application = "LogicMonitor"
          Role        = "Collector"
        }
      }

      #########################################################################
      # LogicMonitor Collector 2 - UK West
      #########################################################################
      lm_collector_02 = {
        name               = "vmmgmtukwlm002"
        resource_group_key = "logicmonitor"
        sku_size           = "Standard_D2s_v5"

        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }

        os_disk = {
          caching              = "ReadWrite"
          storage_account_type = "Premium_LRS"
          disk_size_gb         = 80
        }

        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                private_ip_address_allocation = "Static"
                private_ip_address            = "10.1.5.21"
                subnet_reference = {
                  vnet_key   = "management"
                  subnet_key = "logicmonitor"
                }
              }
            }
          }
        }

        admin_password             = "a4tE9fzovFUh9b6TXYeP"
        encryption_at_host_enabled = true
        secure_boot_enabled        = true
        vtpm_enabled               = true
        maintenance_window         = "patch_wave_2_windows"

        tags = {
          Application = "LogicMonitor"
          Role        = "Collector"
        }
      }
    }
  }
}
