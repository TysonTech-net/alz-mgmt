###############################################################################
# Subscription
###############################################################################

subscription = "8e923053-d9a8-4cf2-b87a-f71cef932b8b"

###############################################################################
# Connectivity Configuration
###############################################################################

connectivity_type = "hub_and_spoke"

# Map platform_shared hub keys to region names
# This enables workload stacks to correctly associate hub resources with regions
hub_region_mapping = {
  primary   = "uksouth"
  secondary = "ukwest"
}

platform_shared_state = {
  resource_group_name  = "rg-alz-mgmt-state-uksouth-001"
  storage_account_name = "stoalzmgmuks001ybcn"
  container_name       = "mgmt-tfstate"
  key                  = "terraform.tfstate"
  subscription_id      = "f09a5d16-c8db-4d7c-bce4-a2781c659cde"
}

###############################################################################
# Naming Convention
###############################################################################
# All resource names are auto-generated based on this naming convention.
# Region abbreviations are automatically derived using the avm-utl-regions module.
# Override individual names by uncommenting and modifying them in the
# vending or management sections below.
#
# Pattern examples:
#   Resource Groups: rg-{workload}-{env}-{purpose}-{region_abbr}-{instance}
#   Virtual Networks: vnet-{workload}-{env}-{region_abbr}-{instance}
#   Route Tables: rt-{workload}-{env}-{region_abbr}-{instance}
#   UMIs: id-{workload}-{env}-{region_abbr}-{instance}
#   Backup RSVs: rsv-backup-{workload}-{env}-{region_abbr}-{instance}
#   ASR RSVs: rsv-asr-{workload}-{env}-{region_abbr}-{instance}
#   Key Vaults: kv{workload}{region_abbr}{random?}{instance}
#   Subnets: snet-{workload}-{env}-{purpose}-{region_abbr}-{instance}

naming = {
  env      = "prod"
  workload = "security"
  instance = "001"
}

###############################################################################
# Tags
###############################################################################

tags = {
  deployed_by = "terraform"
  source      = "scc-workload-resources"
  Environment = "production"
  Owner       = "platform-team"
  CostCenter  = "IT-Security"
}

###############################################################################
# Vending - Subscription Resources (VNets, Resource Groups, etc.)
###############################################################################

vending = {
  # Primary region - full deployment
  uksouth = {
    location = "uksouth"

    # Resource Groups
    # Auto-generated names:
    #   network:    rg-security-prod-network-uks-001
    #   management: rg-security-prod-mgmt-uks-001
    resource_group_creation_enabled = true
    resource_groups = {
      network = {
        # name         = "rg-security-prod-network-uks-001"  # Auto-generated
        # lock_enabled = false  # Enable resource lock (CanNotDelete)
      }
      management = {
        # name         = "rg-security-prod-mgmt-uks-001"  # Auto-generated
        # lock_enabled = false  # Enable resource lock (CanNotDelete)
      }
    }

    # Virtual Networks
    # Auto-generated name: vnet-security-prod-uks-001
    # /26 VNet - 64 addresses
    virtual_network_enabled = true
    virtual_networks = {
      security = {
        # name = "vnet-security-prod-uks-001"  # Auto-generated
        address_space      = ["10.0.6.0/26"]
        resource_group_key = "network"

        # Hub peering (auto-configured from platform_shared remote state)
        hub_peering_enabled   = true
        hub_peering_direction = "both"

        # Peering options: spoke -> hub
        hub_peering_options_tohub = {
          allow_forwarded_traffic       = true
          allow_gateway_transit         = false
          allow_virtual_network_access  = true
          do_not_verify_remote_gateways = false
          enable_only_ipv6_peering      = false
          peer_complete_vnets           = true
          use_remote_gateways           = false
        }

        subnets = {
          tenable = {
            name             = "snet-security-prod-tenable-uks-001"
            address_prefixes = ["10.0.6.0/28"]
          }
          syslog = {
            name             = "snet-security-prod-syslog-uks-001"
            address_prefixes = ["10.0.6.16/28"]
          }
        }
      }
    }
  }

  # Secondary region - DR only (minimal config)
  ukwest = {
    location = "ukwest"

    # User Managed Identity - DISABLED: Not needed in DR region
    umi_enabled = false

    # Resource Groups
    resource_group_creation_enabled = true
    resource_groups = {
      network = {
        # name         = "rg-security-prod-network-ukw-001"  # Auto-generated
      }
      management = {
        # name         = "rg-security-prod-mgmt-ukw-001"  # Auto-generated
      }
    }

    # Virtual Networks
    # /26 VNet - 64 addresses
    virtual_network_enabled = true
    virtual_networks = {
      security = {
        # name = "vnet-security-prod-ukw-001"  # Auto-generated
        address_space      = ["10.1.6.0/26"]
        resource_group_key = "network"

        # Hub peering (auto-configured from platform_shared remote state)
        hub_peering_enabled   = true
        hub_peering_direction = "both"

        # Peering options: spoke -> hub
        hub_peering_options_tohub = {
          allow_forwarded_traffic       = true
          allow_gateway_transit         = false
          allow_virtual_network_access  = true
          do_not_verify_remote_gateways = false
          enable_only_ipv6_peering      = false
          peer_complete_vnets           = true
          use_remote_gateways           = false
        }

        subnets = {
          tenable = {
            name             = "snet-security-prod-tenable-ukw-001"
            address_prefixes = ["10.1.6.0/28"]
          }
          syslog = {
            name             = "snet-security-prod-syslog-ukw-001"
            address_prefixes = ["10.1.6.16/28"]
          }
        }
      }
    }
  }
}

###############################################################################
# Management - Workload Management Resources (RSV, Key Vault, etc.)
###############################################################################

management = {
  # Primary region - backup only, no ASR (ASR target is ukwest)
  uksouth = {
    location = "uksouth"

    # Resource Group - use existing (created by vending module)
    use_existing_management_resource_group = true
    management_resource_group_name         = "rg-security-prod-mgmt-uks-001"

    ###########################################################################
    # Backup Recovery Services Vault
    ###########################################################################
    deploy_management_backup_recovery_services_vault   = true
    management_backup_rsv_name                         = "rsv-backup-security-prod-uks-001"
    management_backup_rsv_storage_mode_type            = "GeoRedundant"
    management_backup_rsv_cross_region_restore_enabled = true
    management_backup_rsv_soft_delete_enabled          = true

    ###########################################################################
    # Site Recovery RSV - DISABLED in primary region
    ###########################################################################
    deploy_management_site_recovery_recovery_services_vault = false
    management_site_recovery_rsv_name                       = "rsv-asr-security-prod-uks-001"

    ###########################################################################
    # Key Vault - DISABLED (name auto-generated with random suffix)
    ###########################################################################
    deploy_management_key_vault = false
    # management_kv_name        = "kvsecuuksxxxx001"  # Auto-generated: kv{workload4}{region}{random4}{instance}
    management_kv_tenant_id     = "6eb56c2c-7ac1-42d9-b587-4d6ec70d05e6"
  }

  # Secondary/failover region - backup + ASR
  ukwest = {
    location = "ukwest"

    # Resource Group - use existing (created by vending module)
    use_existing_management_resource_group = true
    management_resource_group_name         = "rg-security-prod-mgmt-ukw-001"

    ###########################################################################
    # Backup Recovery Services Vault
    ###########################################################################
    deploy_management_backup_recovery_services_vault   = true
    management_backup_rsv_name                         = "rsv-backup-security-prod-ukw-001"
    management_backup_rsv_storage_mode_type            = "LocallyRedundant"
    management_backup_rsv_cross_region_restore_enabled = false
    management_backup_rsv_soft_delete_enabled          = true

    ###########################################################################
    # Site Recovery RSV - Target vault for ASR failover
    ###########################################################################
    deploy_management_site_recovery_recovery_services_vault = true
    management_site_recovery_rsv_name                       = "rsv-asr-security-prod-ukw-001"
    management_site_recovery_rsv_storage_mode_type          = "LocallyRedundant"

    ###########################################################################
    # Key Vault - DISABLED (name auto-generated with random suffix)
    ###########################################################################
    deploy_management_key_vault = false
    # management_kv_name        = "kvsecuukwxxxx001"  # Auto-generated: kv{workload4}{region}{random4}{instance}
    management_kv_tenant_id     = "6eb56c2c-7ac1-42d9-b587-4d6ec70d05e6"
  }
}
