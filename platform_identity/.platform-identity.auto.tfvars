###############################################
# Platform Identity Subscription Configuration
###############################################

subscription_ids = {
  identity     = "ae1373b1-92fd-4659-9c71-c5695fea28c8"
  connectivity = "91f98b99-3946-4096-8191-1078a530c5fd"
}

primary_location       = "uksouth"
primary_location_short = "uks"
customer_prefix        = ""

naming = {
  env      = "prod"
  workload = "identity"
  instance = "001"
}

tags = {
  owner       = "platform-team"
  cost_centre = "IT"
}

###############################################
# Network Configuration
###############################################

virtual_network = {
  address_space = ["10.100.0.0/24"]
  dns_servers   = [] # Populated from platform_shared outputs
}

subnets = {
  identity = {
    address_prefixes           = ["10.100.0.0/26"]
    network_security_group_key = "identity"
    route_table_key            = "default"
  }
}

network_security_groups = {
  identity = {
    security_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
      }
    ]
  }
}

route_tables = {
  default = {
    bgp_route_propagation_enabled = false
  }
}

common_routes = [
  {
    name                   = "to-firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4" # Update with actual firewall IP
  }
]

###############################################
# Hub Connectivity (vWAN)
###############################################

# virtual_hub_id = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Network/virtualHubs/vhub-..." # From platform_shared outputs

###############################################
# Private DNS (from platform_shared outputs)
###############################################

# private_dns_zone_ids = {}
# dns_forwarding_ruleset_id = null

###############################################
# Management Toggles
###############################################

create_management_rg           = true
create_log_analytics_workspace = true
create_management_kv           = true
create_backup_rsv              = true
