###############################################################################
# Subscription
###############################################################################

subscription = "ae1373b1-92fd-4659-9c71-c5695fea28c8"

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
  workload = "identity"
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
    # Auto-generated names:
    #   network:    rg-identity-prod-network-uks-001
    #   management: rg-identity-prod-mgmt-uks-001
    resource_group_creation_enabled = true
    resource_groups = {
      network = {
        # name         = "rg-identity-prod-network-uks-001"  # Auto-generated
        # lock_enabled = false  # Enable resource lock (CanNotDelete)
      }
      management = {
        # name         = "rg-identity-prod-mgmt-uks-001"  # Auto-generated
        # lock_enabled = false  # Enable resource lock (CanNotDelete)
      }
    }

    # Virtual Networks
    # Auto-generated name: vnet-identity-prod-uks-001
    # Auto-generated peering names:
    #   to hub:   peer-identity-to-hub-uks
    #   from hub: peer-hub-to-identity-uks
    virtual_network_enabled = true
    virtual_networks = {
      identity = {
        # name = "vnet-identity-prod-uks-001"  # Auto-generated
        address_space      = ["10.0.4.0/24"]
        resource_group_key = "network"

        # VNet options (uncomment to customize)
        # dns_servers             = []     # Custom DNS servers (defaults to Azure DNS or hub DNS)
        # flow_timeout_in_minutes = 4      # TCP idle timeout (4-30 minutes)
        # ddos_protection_enabled = false  # Enable DDoS Protection Standard
        # ddos_protection_plan_id = ""     # DDoS Protection Plan resource ID (required if enabled)

        # Hub peering (auto-configured from platform_shared remote state)
        hub_peering_enabled   = true
        hub_peering_direction = "both"
        # hub_peering_name_tohub   = "peer-identity-to-hub-uks"    # Auto-generated
        # hub_peering_name_fromhub = "peer-hub-to-identity-uks"    # Auto-generated

        # Peering options: spoke -> hub
        # These control traffic flow from this workload VNet to the hub
        hub_peering_options_tohub = {
          allow_forwarded_traffic       = true  # default: true - Allow traffic forwarded from other VNets
          allow_gateway_transit         = false # default: false - Allow hub to use this VNet's gateway (spoke has no gateway)
          allow_virtual_network_access  = true  # default: true - Allow VMs in hub to access VMs in this VNet
          do_not_verify_remote_gateways = false # default: false - Verify hub gateway exists before peering
          enable_only_ipv6_peering      = false # default: false - IPv6 only peering
          peer_complete_vnets           = true  # default: true - Peer entire VNet (not just specific address spaces)
          use_remote_gateways           = false # default: true - Use hub's VPN/ExpressRoute gateway (disabled: no gateway deployed)
          # local_peered_address_spaces  = []   # default: [] - Specific local address spaces to peer
          # local_peered_subnets         = []   # default: [] - Specific local subnets to peer
          # remote_peered_address_spaces = []   # default: [] - Specific hub address spaces to peer
          # remote_peered_subnets        = []   # default: [] - Specific hub subnets to peer
        }

        # Peering options: hub -> spoke (created on hub VNet)
        # These control traffic flow from the hub to this workload VNet
        # hub_peering_options_fromhub = {
        #   allow_forwarded_traffic       = true  # default: true - Allow forwarded traffic to this VNet
        #   allow_gateway_transit         = true  # default: true - Allow this peering to use hub's gateway
        #   allow_virtual_network_access  = true  # default: true - Allow VMs in this VNet to access hub VMs
        #   do_not_verify_remote_gateways = false # default: false - Verify spoke gateway exists
        #   enable_only_ipv6_peering      = false # default: false - IPv6 only peering
        #   peer_complete_vnets           = true  # default: true - Peer entire VNet
        #   use_remote_gateways           = false # default: false - Hub doesn't use spoke's gateway
        # }

        subnets = {
          domain_controllers = {
            name             = "snet-identity-prod-dc-uks-001"
            address_prefixes = ["10.0.4.0/27"]
            # Subnet options (uncomment to customize)
            # service_endpoints                             = ["Microsoft.Storage", "Microsoft.KeyVault"]
            # private_endpoint_network_policies             = "Enabled"   # Enabled, Disabled, NetworkSecurityGroupEnabled, RouteTableEnabled
            # private_link_service_network_policies_enabled = true
            # default_outbound_access_enabled               = false       # Azure default outbound access
            # delegations = [
            #   {
            #     name = "delegation-name"
            #     service_delegation = {
            #       name = "Microsoft.Web/serverFarms"  # Service to delegate to
            #     }
            #   }
            # ]
          }
          identity_services = {
            name             = "snet-identity-prod-idsvc-uks-001"
            address_prefixes = ["10.0.4.32/27"]
          }
        }
      }
    }

    # Role Assignments (uncomment to assign roles at subscription scope)
    # role_assignment_enabled = true
    # role_assignments = {
    #   contributor_group = {
    #     principal_id = "00000000-0000-0000-0000-000000000000"  # Azure AD Object ID
    #     definition   = "Contributor"  # Role name or ID
    #     # principal_type = "Group"  # User, Group, ServicePrincipal
    #   }
    # }

    # Budgets (uncomment to enable cost management)
    # budget_enabled = true
    # budgets = {
    #   monthly = {
    #     name              = "budget-identity-prod-monthly"
    #     amount            = 1000
    #     time_grain        = "Monthly"
    #     time_period_start = "2024-01-01T00:00:00Z"
    #     time_period_end   = "2025-12-31T23:59:59Z"
    #     notifications = {
    #       actual_80_percent = {
    #         enabled        = true
    #         operator       = "GreaterThan"
    #         threshold      = 80
    #         threshold_type = "Actual"
    #         contact_emails = ["platform-team@example.com"]
    #       }
    #       forecast_100_percent = {
    #         enabled        = true
    #         operator       = "GreaterThan"
    #         threshold      = 100
    #         threshold_type = "Forecasted"
    #         contact_emails = ["platform-team@example.com"]
    #       }
    #     }
    #   }
    # }

    # Custom Network Security Groups (uncomment to add custom rules)
    # The stack auto-creates NSGs for each subnet with Azure default rules at priority 4000+
    # network_security_group_enabled = true
    # network_security_groups = {
    #   custom = {
    #     name               = "nsg-identity-prod-custom-uks-001"
    #     resource_group_key = "network"
    #     security_rules = {
    #       allow_rdp_from_bastion = {
    #         name                       = "Allow-RDP-From-Bastion"
    #         priority                   = 100
    #         direction                  = "Inbound"
    #         access                     = "Allow"
    #         protocol                   = "Tcp"
    #         source_address_prefix      = "10.0.0.64/26"  # Bastion subnet
    #         source_port_range          = "*"
    #         destination_address_prefix = "*"
    #         destination_port_range     = "3389"
    #       }
    #     }
    #   }
    # }
  }

  # Secondary region - DR only (minimal config)
  ukwest = {
    location = "ukwest"

    # User Managed Identity - DISABLED: Not needed in DR region
    # Primary region UMI is sufficient for workload operations
    umi_enabled = false

    # Resource Groups
    # Auto-generated names:
    #   network:    rg-identity-prod-network-ukw-001
    #   management: rg-identity-prod-mgmt-ukw-001
    resource_group_creation_enabled = true
    resource_groups = {
      network = {
        # name         = "rg-identity-prod-network-ukw-001"  # Auto-generated
        # lock_enabled = false  # Enable resource lock (CanNotDelete)
      }
      management = {
        # name         = "rg-identity-prod-mgmt-ukw-001"  # Auto-generated
        # lock_enabled = false  # Enable resource lock (CanNotDelete)
      }
    }

    # Virtual Networks
    # Auto-generated name: vnet-identity-prod-ukw-001
    virtual_network_enabled = true
    virtual_networks = {
      identity = {
        # name = "vnet-identity-prod-ukw-001"  # Auto-generated
        address_space      = ["10.1.4.0/24"]
        resource_group_key = "network"

        # VNet options (uncomment to customize)
        # dns_servers             = []     # Custom DNS servers
        # flow_timeout_in_minutes = 4      # TCP idle timeout
        # ddos_protection_enabled = false  # Enable DDoS Protection Standard
        # ddos_protection_plan_id = ""     # DDoS Protection Plan resource ID

        # Hub peering (auto-configured from platform_shared remote state)
        hub_peering_enabled   = true
        hub_peering_direction = "both"
        # hub_peering_name_tohub   = "peer-identity-to-hub-ukw"    # Auto-generated
        # hub_peering_name_fromhub = "peer-hub-to-identity-ukw"    # Auto-generated

        # Peering options: spoke -> hub
        hub_peering_options_tohub = {
          allow_forwarded_traffic       = true  # default: true
          allow_gateway_transit         = false # default: false
          allow_virtual_network_access  = true  # default: true
          do_not_verify_remote_gateways = false # default: false
          enable_only_ipv6_peering      = false # default: false
          peer_complete_vnets           = true  # default: true
          use_remote_gateways           = false # default: true - Disabled: no gateway deployed in hub
        }

        # Peering options: hub -> spoke (uncomment to customize)
        # hub_peering_options_fromhub = {
        #   allow_forwarded_traffic       = true  # default: true
        #   allow_gateway_transit         = true  # default: true
        #   allow_virtual_network_access  = true  # default: true
        #   do_not_verify_remote_gateways = false # default: false
        #   enable_only_ipv6_peering      = false # default: false
        #   peer_complete_vnets           = true  # default: true
        #   use_remote_gateways           = false # default: false
        # }

        subnets = {
          domain_controllers = {
            name             = "snet-identity-prod-dc-ukw-001"
            address_prefixes = ["10.1.4.0/27"]
            # service_endpoints                             = []
            # private_endpoint_network_policies             = "Enabled"
            # private_link_service_network_policies_enabled = true
            # default_outbound_access_enabled               = false
          }
          identity_services = {
            name             = "snet-identity-prod-idsvc-ukw-001"
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
  # Primary region - backup only, no ASR (ASR target is ukwest)
  uksouth = {
    location = "uksouth"

    # Resource Group - use existing (created by vending module)
    use_existing_management_resource_group = true
    management_resource_group_name         = "rg-identity-prod-mgmt-uks-001"

    ###########################################################################
    # Backup Recovery Services Vault
    ###########################################################################
    deploy_management_backup_recovery_services_vault   = true
    management_backup_rsv_name                         = "rsv-backup-identity-prod-uks-001"
    management_backup_rsv_storage_mode_type            = "GeoRedundant"
    management_backup_rsv_cross_region_restore_enabled = true
    management_backup_rsv_soft_delete_enabled          = true

    ###########################################################################
    # Site Recovery RSV - DISABLED in primary region
    ###########################################################################
    deploy_management_site_recovery_recovery_services_vault = false
    management_site_recovery_rsv_name                       = "rsv-asr-identity-prod-uks-001"

    ###########################################################################
    # Key Vault - DISABLED (name auto-generated with random suffix)
    ###########################################################################
    deploy_management_key_vault = false
    # management_kv_name        = "kvidenuksxxxx001"  # Auto-generated: kv{workload4}{region}{random4}{instance}
    management_kv_tenant_id     = "6eb56c2c-7ac1-42d9-b587-4d6ec70d05e6"
  }

  # Secondary/failover region - backup + ASR
  ukwest = {
    location = "ukwest"

    # Resource Group - use existing (created by vending module)
    use_existing_management_resource_group = true
    management_resource_group_name         = "rg-identity-prod-mgmt-ukw-001"

    ###########################################################################
    # Backup Recovery Services Vault
    ###########################################################################
    deploy_management_backup_recovery_services_vault   = true
    management_backup_rsv_name                         = "rsv-backup-identity-prod-ukw-001"
    management_backup_rsv_storage_mode_type            = "LocallyRedundant"
    management_backup_rsv_cross_region_restore_enabled = false
    management_backup_rsv_soft_delete_enabled          = true

    ###########################################################################
    # Site Recovery RSV - Target vault for ASR failover
    ###########################################################################
    deploy_management_site_recovery_recovery_services_vault = true
    management_site_recovery_rsv_name                       = "rsv-asr-identity-prod-ukw-001"
    management_site_recovery_rsv_storage_mode_type          = "LocallyRedundant"

    ###########################################################################
    # Key Vault - DISABLED (name auto-generated with random suffix)
    ###########################################################################
    deploy_management_key_vault = false
    # management_kv_name        = "kvidenukwxxxx001"  # Auto-generated: kv{workload4}{region}{random4}{instance}
    management_kv_tenant_id     = "6eb56c2c-7ac1-42d9-b587-4d6ec70d05e6"
  }
}
