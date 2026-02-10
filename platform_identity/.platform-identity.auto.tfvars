###############################################################################
# Subscription
###############################################################################

subscription = "ae1373b1-92fd-4659-9c71-c5695fea28c8"

###############################################################################
# Connectivity Configuration
###############################################################################

connectivity_type = "hub_and_spoke"

platform_shared_state = {
  resource_group_name  = "rg-alz-mgmt-state-uksouth-001"
  storage_account_name = "stoalzmgmuks001ybcn"
  container_name       = "mgmt-tfstate"
  key                  = "terraform.tfstate"
  subscription_id      = "f09a5d16-c8db-4d7c-bce4-a2781c659cde"
}

###############################################################################
# Tags
###############################################################################

tags = {
  deployed_by = "terraform"
  Environment = "production"
  Owner       = "platform-team"
  CostCenter  = "IT-Infrastructure"
}

###############################################################################
# Vending - Subscription Resources (VNets, Resource Groups, etc.)
###############################################################################

vending = {
  # Primary region - full deployment
  uksouth = {
    location = "uksouth"

    # Resource Groups
    resource_group_creation_enabled = true
    resource_groups = {
      network = {
        name = "rg-identity-prod-network-uks-001"
      }
      management = {
        name = "rg-identity-prod-mgmt-uks-001"
      }
    }

    # Virtual Networks - will auto-peer to hub from platform_shared
    virtual_network_enabled = true
    virtual_networks = {
      identity = {
        name                     = "vnet-identity-prod-uks-001"
        address_space            = ["10.0.4.0/24"]
        resource_group_key       = "network"
        hub_peering_enabled      = true
        hub_peering_direction    = "both"
        hub_peering_name_tohub   = "peer-identity-to-hub-uks"
        hub_peering_name_fromhub = "peer-hub-to-identity-uks"
        subnets = {
          domain_controllers = {
            name             = "snet-dc-uks-001"
            address_prefixes = ["10.0.4.0/27"]
          }
          identity_services = {
            name             = "snet-identity-uks-001"
            address_prefixes = ["10.0.4.32/27"]
          }
        }
      }
    }
  }

  # Secondary region - DR only (minimal config)
  ukwest = {
    location = "ukwest"

    # Resource Groups
    resource_group_creation_enabled = true
    resource_groups = {
      network = {
        name = "rg-identity-prod-network-ukw-001"
      }
      management = {
        name = "rg-identity-prod-mgmt-ukw-001"
      }
    }

    # Virtual Networks - will auto-peer to hub from platform_shared
    virtual_network_enabled = true
    virtual_networks = {
      identity = {
        name                     = "vnet-identity-prod-ukw-001"
        address_space            = ["10.1.4.0/24"]
        resource_group_key       = "network"
        hub_peering_enabled      = true
        hub_peering_direction    = "both"
        hub_peering_name_tohub   = "peer-identity-to-hub-ukw"
        hub_peering_name_fromhub = "peer-hub-to-identity-ukw"
        subnets = {
          domain_controllers = {
            name             = "snet-dc-ukw-001"
            address_prefixes = ["10.1.4.0/27"]
          }
          identity_services = {
            name             = "snet-identity-ukw-001"
            address_prefixes = ["10.1.4.32/27"]
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
  # Primary region - full deployment with backup and key vault
  uksouth = {
    location                       = "uksouth"
    management_resource_group_name = "rg-identity-prod-mgmt-uks-001"

    # Backup Recovery Services Vault
    deploy_management_backup_recovery_services_vault   = true
    management_backup_rsv_name                         = "rsv-identity-prod-uks-001"
    management_backup_rsv_storage_mode_type            = "GeoRedundant"
    management_backup_rsv_cross_region_restore_enabled = true
    management_backup_rsv_soft_delete_enabled          = true

    # Site Recovery - for DR replication to ukwest
    deploy_management_site_recovery_recovery_services_vault = true
    management_site_recovery_rsv_name                       = "rsv-asr-identity-prod-uks-001"
    management_site_recovery_rsv_storage_mode_type          = "GeoRedundant"

    # Key Vault (name must be globally unique, 3-24 chars, alphanumeric only)
    deploy_management_key_vault        = true
    management_kv_name                 = "kvidentityuks001x7b2"
    management_kv_tenant_id            = "b83e0c30-64d5-4a55-9981-cc4f28dd2078"
    management_kv_sku_name             = "premium"
    management_kv_purge_protection_enabled = true
  }

  # Secondary region - DR target (receives replicated VMs, minimal local resources)
  ukwest = {
    location                       = "ukwest"
    management_resource_group_name = "rg-identity-prod-mgmt-ukw-001"

    # Backup RSV - for local backups in DR region
    deploy_management_backup_recovery_services_vault   = true
    management_backup_rsv_name                         = "rsv-identity-prod-ukw-001"
    management_backup_rsv_storage_mode_type            = "LocallyRedundant"
    management_backup_rsv_cross_region_restore_enabled = false
    management_backup_rsv_soft_delete_enabled          = true

    # Site Recovery - target vault for failover
    deploy_management_site_recovery_recovery_services_vault = true
    management_site_recovery_rsv_name                       = "rsv-asr-identity-prod-ukw-001"
    management_site_recovery_rsv_storage_mode_type          = "LocallyRedundant"

    # Key Vault (name must be globally unique, 3-24 chars, alphanumeric only)
    deploy_management_key_vault        = true
    management_kv_name                 = "kvidentityukw001x7b2"
    management_kv_tenant_id            = "b83e0c30-64d5-4a55-9981-cc4f28dd2078"
    management_kv_sku_name             = "premium"
    management_kv_purge_protection_enabled = true
  }
}
