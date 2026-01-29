customer = "evri"

connectivity_mode = "vwan"
connectivity_vhub_primary = {
  name                = "vhub-evri-shared-hub-prod-uks-001"
  resource_group_name = "rg-shared-hub-prod-uks-network-001"
}

spoke_network_config_primary = {
  resource_group = {
    name = "rg-shared-security-prod-uks-network-001"
    tags = {
      Description = "Security Networking Resources"
      Service     = "Security-Network"
    }
  }
  virtual_network_settings = {
    name          = "vnet-evri-shared-security-prod-uks-001"
    address_space = ["10.200.11.0/24"]
    dns_servers   = ["10.200.1.4", "10.200.1.5"]
  }

  subnets = {
    mgmt = {
      name                       = "snet-evri-shared-security-prod-uks-001"
      address_prefixes           = ["10.200.11.0/27"]
      network_security_group_key = "activedirectory"
      route_table_key            = null
      service_endpoints          = []
    }
  }

  network_security_groups = {
    activedirectory = {
      name           = "nsg-snet-evri-shared-security-prod-uks-001"
      security_rules = []
      tags = {
        Description = "NSG for Security Subnet"
      }
    }
  }

  route_tables  = {}
  common_routes = []

  tags = {
    Description = "Security Networking Resources"
    Service     = "Security-Network"
  }
}

windows_virtual_machines = {}

tags = {
  Environment = "Prod"
  CostCentre  = "Domain Integrations"
  Criticality = "Mission Critical"
  Owner       = "Infrastructure@hermesuk.onmicrosoft.com"
}