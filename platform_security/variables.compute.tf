###############################################################################
# Variables - Compute (Virtual Machines)
###############################################################################

variable "compute" {
  type = map(object({
    # Location defaults to the map key (region name) if not specified
    location = optional(string)

    # Telemetry
    enable_telemetry = optional(bool, true)

    # Tags
    tags = optional(map(string), {})

    # Log Analytics Workspace for diagnostics
    log_analytics_workspace_id = optional(string)

    # VM Resource Groups (optional - can use vending RGs instead)
    vm_resource_groups = optional(map(object({
      name     = optional(string)
      location = optional(string)
      tags     = optional(map(string))
    })), {})

    # Virtual Machines
    vms = optional(map(object({
      # Required
      name = string

      # Resource Group - either key reference or explicit name
      resource_group_key  = optional(string)
      resource_group_name = optional(string)

      # Location and Availability
      location = optional(string)
      zone     = optional(string)

      # VM Configuration
      os_type  = optional(string, "Windows")
      sku_size = optional(string, "Standard_D2s_v5")

      # Source Image - Gen2 compatible
      source_image_reference = optional(object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      }))
      source_image_resource_id = optional(string)

      # Marketplace Plan (required for third-party images like Tenable)
      plan = optional(object({
        name      = string
        product   = string
        publisher = string
      }))

      # OS Disk - defaults to Premium SSD with encryption
      os_disk = optional(object({
        caching                          = optional(string, "ReadWrite")
        storage_account_type             = optional(string, "Premium_LRS")
        disk_size_gb                     = optional(number)
        disk_encryption_set_id           = optional(string)
        name                             = optional(string)
        secure_vm_disk_encryption_set_id = optional(string)
        security_encryption_type         = optional(string)
        write_accelerator_enabled        = optional(bool, false)
      }))

      # Data Disks
      data_disk_managed_disks = optional(map(object({
        name                             = string
        storage_account_type             = optional(string, "Premium_LRS")
        lun                              = number
        caching                          = optional(string, "None")
        create_option                    = optional(string, "Empty")
        disk_size_gb                     = optional(number)
        disk_encryption_set_id           = optional(string)
        secure_vm_disk_encryption_set_id = optional(string)
        security_encryption_type         = optional(string)
        write_accelerator_enabled        = optional(bool, false)
      })))

      # Network Interfaces
      network_interfaces = map(object({
        name                           = optional(string)
        accelerated_networking_enabled = optional(bool, true)
        ip_forwarding_enabled          = optional(bool, false)
        dns_servers                    = optional(list(string))
        edge_zone                      = optional(string)
        internal_dns_name_label        = optional(string)
        tags                           = optional(map(string))

        ip_configurations = map(object({
          name                          = optional(string)
          private_ip_address            = optional(string)
          private_ip_address_allocation = optional(string, "Dynamic")
          private_ip_address_version    = optional(string, "IPv4")
          is_primary_ipconfiguration    = optional(bool, true)
          subnet_id                     = optional(string)
          # Reference subnet by key from vending config
          subnet_reference = optional(object({
            vnet_key   = string
            subnet_key = string
          }))
          public_ip_address_id = optional(string)
        }))
      }))

      # Authentication
      admin_username                     = optional(string, "azureadmin")
      admin_password                     = optional(string)
      generate_admin_password_or_ssh_key = optional(bool)

      # Telemetry
      enable_telemetry = optional(bool, true)

      # Managed Identity
      managed_identities = optional(object({
        system_assigned            = optional(bool, false)
        user_assigned_resource_ids = optional(set(string), [])
      }))

      # Security - Modern defaults for Gen2 VMs
      encryption_at_host_enabled = optional(bool, true)
      secure_boot_enabled        = optional(bool, true)
      vtpm_enabled               = optional(bool, true)

      # Patching
      patch_mode               = optional(string, "AutomaticByPlatform")
      patch_assessment_mode    = optional(string, "AutomaticByPlatform")
      enable_automatic_updates = optional(bool, true)
      hotpatching_enabled      = optional(bool, false)

      # Boot Diagnostics
      boot_diagnostics                     = optional(bool, true)
      boot_diagnostics_storage_account_uri = optional(string)

      # Licensing
      license_type = optional(string)

      # Extensions
      extensions = optional(map(object({
        name                        = string
        publisher                   = string
        type                        = string
        type_handler_version        = string
        auto_upgrade_minor_version  = optional(bool, true)
        automatic_upgrade_enabled   = optional(bool, false)
        failure_suppression_enabled = optional(bool, false)
        settings                    = optional(string)
        protected_settings          = optional(string)
        provision_after_extensions  = optional(list(string))
        tags                        = optional(map(string))
      })))

      # Shutdown Schedule
      shutdown_schedules = optional(map(object({
        daily_recurrence_time = string
        timezone              = string
        notification_settings = optional(object({
          enabled         = optional(bool, false)
          email           = optional(string)
          time_in_minutes = optional(number, 30)
          webhook_url     = optional(string)
        }))
      })))

      # Backup
      azure_backup_configurations = optional(map(object({
        recovery_vault_resource_id = string
        backup_policy_resource_id  = string
      })))

      # Site Recovery (VM-level overrides)
      asr_enabled = optional(bool, false)
      asr = optional(object({
        enabled                             = optional(bool, false)
        target_resource_group_key           = optional(string)
        target_resource_group_id            = optional(string)
        target_network_id                   = optional(string)
        target_subnet_name                  = optional(string)
        target_static_ip                    = optional(string)
        target_zone                         = optional(string)
        target_availability_set_id          = optional(string)
        target_proximity_placement_group_id = optional(string)
        target_disk_type                    = optional(string)
        target_disk_encryption_set_id       = optional(string)
        multi_vm_group_name                 = optional(string)
      }))

      # Maintenance Configuration (Azure Update Manager)
      # Recommended: Use maintenance_window tag for dynamic scoping
      maintenance_window = optional(string)
      # Legacy Option 1: Reference central config by key (from platform_shared)
      maintenance_configuration_key = optional(string)
      # Legacy Option 2: Specify resource IDs directly (for custom/external configs)
      maintenance_configuration_resource_ids = optional(map(string))

      # Tags
      tags = optional(map(string), {})
    })), {})

    # Backup Defaults - applied to all VMs in this region
    backup_defaults = optional(object({
      recovery_vault_resource_id = string
      backup_policy_resource_id  = string
    }))

    # ASR Configuration - Region-level Site Recovery settings
    asr_config = optional(object({
      target_location                              = string
      use_existing_vault                           = optional(bool, false)
      vault_name                                   = optional(string)
      vault_resource_group_name                    = optional(string)
      vault_resource_group_key                     = optional(string)
      recovery_point_retention_in_minutes          = optional(number, 1440)
      app_consistent_snapshot_frequency_in_minutes = optional(number, 240)
      target_network_id                            = optional(string)
      target_network_name                          = optional(string)
      target_network_resource_group                = optional(string)
      target_subnet_name                           = optional(string)
      target_resource_group_id                     = optional(string)
      target_resource_group_name                   = optional(string)
      target_resource_group_key                    = optional(string)
      enable_capacity_reservation                  = optional(bool, false)
      capacity_reservation_sku                     = optional(string)
    }))
  }))
  default     = {}
  description = <<DESCRIPTION
A map of compute configurations keyed by region for deploying virtual machines.

Each key represents a region (e.g., "uksouth", "ukwest") and the value contains all the configuration
for deploying virtual machines in that region.

VMs are configured with modern security defaults:
- Gen2 compatible images
- Encryption at host enabled
- Secure Boot enabled
- vTPM enabled
- Premium SSD OS disks
- Accelerated networking

Example:
```hcl
compute = {
  uksouth = {
    location = "uksouth"
    vms = {
      dc01 = {
        name     = "vm-dc-uks-001"
        zone     = "1"
        sku_size = "Standard_D2s_v5"
        source_image_reference = {
          publisher = "MicrosoftWindowsServer"
          offer     = "WindowsServer"
          sku       = "2022-datacenter-azure-edition-smalldisk"
          version   = "latest"
        }
        network_interfaces = {
          primary = {
            ip_configurations = {
              ipconfig1 = {
                subnet_reference = {
                  vnet_key   = "identity"
                  subnet_key = "domain_controllers"
                }
              }
            }
          }
        }
      }
    }
  }
}
```
DESCRIPTION
}
