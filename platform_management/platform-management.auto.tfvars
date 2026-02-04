subscription_ids = {
  management   = "f09a5d16-c8db-4d7c-bce4-a2781c659cde"
  connectivity = "91f98b99-3946-4096-8191-1078a530c5fd"
}

starter_locations = ["uksouth", "ukwest"]

starter_locations_short = {
  uksouth = "uks"
  ukwest  = "ukw"
}

naming = {
  env      = "prod"
  workload = "mgmt"
  instance = "001"
}

hubs = {
  primary = {
    location                = "uksouth"
    resource_group_name     = "rg-mgmt-prod-network-uks-001"
    hub_vnet_id             = "/subscriptions/91f98b99-3946-4096-8191-1078a530c5fd/resourceGroups/rg-hub-prod-network-uks-001/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-uks-001"
    hub_resource_group_name = "rg-hub-prod-network-uks-001"
    virtual_network_settings = {
      name          = "vnet-mgmt-prod-uks-001"
      address_space = ["10.10.0.0/22"]
      peer_to_hub   = true
      peer_to_hub_settings = {
        use_remote_gateways           = false
        allow_gateway_transit         = false
        create_reverse_peering        = true
        reverse_use_remote_gateways   = false
        reverse_allow_gateway_transit = false
      }
    }
    network_security_groups = {
      default = {
        name = "nsg-mgmt-prod-uks-001"
      }
    }
    route_tables = {
      default = {
        name                          = "rt-mgmt-prod-uks-001"
        bgp_route_propagation_enabled = false
        routes = [
          {
            name                   = "default-to-fw"
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.0.0.4"
          }
        ]
      }
    }
    subnets = {
      mgmt = {
        name                       = "snet-mgmt-prod-mgmt-uks-001"
        address_prefixes           = ["10.10.0.0/24"]
        network_security_group_key = "default"
        route_table_key            = "default"
      }
      logicmonitor = {
        name                       = "snet-mgmt-prod-lm-uks-001"
        address_prefixes           = ["10.10.1.0/26"]
        network_security_group_key = "default"
        route_table_key            = "default"
      }
    }
    common_routes = []
    tags          = {}
  }
  secondary = {
    location                = "ukwest"
    resource_group_name     = "rg-mgmt-prod-network-ukw-001"
    hub_vnet_id             = "/subscriptions/91f98b99-3946-4096-8191-1078a530c5fd/resourceGroups/rg-hub-prod-network-ukw-001/providers/Microsoft.Network/virtualNetworks/vnet-hub-prod-ukw-001"
    hub_resource_group_name = "rg-hub-prod-network-ukw-001"
    virtual_network_settings = {
      name          = "vnet-mgmt-prod-ukw-001"
      address_space = ["10.11.0.0/22"]
      peer_to_hub   = true
      peer_to_hub_settings = {
        use_remote_gateways           = false
        allow_gateway_transit         = false
        create_reverse_peering        = true
        reverse_use_remote_gateways   = false
        reverse_allow_gateway_transit = false
      }
    }
    network_security_groups = {
      default = {
        name = "nsg-mgmt-prod-ukw-001"
      }
    }
    route_tables = {
      default = {
        name                          = "rt-mgmt-prod-ukw-001"
        bgp_route_propagation_enabled = false
        routes = [
          {
            name                   = "default-to-fw"
            address_prefix         = "0.0.0.0/0"
            next_hop_type          = "VirtualAppliance"
            next_hop_in_ip_address = "10.1.0.4"
          }
        ]
      }
    }
    subnets = {
      mgmt = {
        name                       = "snet-mgmt-prod-mgmt-ukw-001"
        address_prefixes           = ["10.11.0.0/24"]
        network_security_group_key = "default"
        route_table_key            = "default"
      }
      logicmonitor = {
        name                       = "snet-mgmt-prod-lm-ukw-001"
        address_prefixes           = ["10.11.1.0/26"]
        network_security_group_key = "default"
        route_table_key            = "default"
      }
    }
    common_routes = []
    tags          = {}
  }
}

vms = {}
