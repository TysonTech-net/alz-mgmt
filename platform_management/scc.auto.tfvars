customer = "evri"

connectivity_mode = "vwan"
connectivity_vhub_primary = {
  name                = "vhub-evri-shared-hub-prod-uks-001"
  resource_group_name = "rg-shared-hub-prod-uks-network-001"
}

service_health_email_addresses = ["infrastructure@hermesuk.onmicrosoft.com"]

spoke_network_config_primary = {
  resource_group = {
    name = "rg-shared-management-prod-uks-network-001"
    tags = {
      Description = "Management Networking Resources"
      Service     = "Management-Network"
    }
  }
  virtual_network_settings = {
    name          = "vnet-evri-shared-management-prod-uks-001"
    address_space = ["10.200.10.0/24"]
    dns_servers   = ["10.200.1.4", "10.200.1.5"]
  }

  subnets = {
    mgmt = {
      name                       = "snet-evri-shared-management-prod-uks-001"
      address_prefixes           = ["10.200.10.0/24"]
      network_security_group_key = "default"
      # route_table_key            = ""
      service_endpoints = []
    }
  }

  network_security_groups = {
    default = {
      name           = "nsg-snet-evri-shared-management-prod-uks-001"
      security_rules = []
      tags = {
        Description = "NSG for Management Subnet"
      }
    }
  }

  route_tables = {}

  common_routes = []

  tags = {
    Description = "Management Networking Resources"
    Service     = "Management-Network"
  }
}

maintenance_configurations = {
  # Group 1: Pilot / Non-Critical
  "mc-noncritical-monthly-uks-01" = {
    tag                     = "NonCritical-Monthly-Every2ndTuesday-Offset-2days-2200hrs"
    recur_every             = "Month Second Thursday"
    start_date_time         = "2025-01-01 22:00"
    duration                = "03:55"
    time_zone               = "GMT Standard Time" # Changed to GMT to align with UK business hours (22:00)
    reboot                  = "IfRequired"
    windows_classifications = ["Critical", "Security", "UpdateRollup", "Definition", "Updates"]
    linux_classifications   = ["Critical", "Security"]
  },

  # Group 2: Critical
  "mc-critical-monthly-uks-01" = {
    tag                     = "Critical-Monthly-Every2ndTuesday-Offset-4days-2200hrs"
    recur_every             = "Month Second Saturday"
    start_date_time         = "2025-01-01 22:00"
    duration                = "03:55"
    time_zone               = "GMT Standard Time"
    reboot                  = "IfRequired"
    windows_classifications = ["Critical", "Security", "UpdateRollup", "Definition", "Updates"]
    linux_classifications   = ["Critical", "Security"]
  },

  # Group 3: Critical HA
  "mc-critical-ha-monthly-uks-01" = {
    tag                     = "Critical-Monthly-HA-Every2ndTuesday-Offset-11days-2200hrs"
    recur_every             = "Month Third Saturday"
    start_date_time         = "2025-01-01 22:00"
    duration                = "03:55"
    time_zone               = "GMT Standard Time"
    reboot                  = "IfRequired"
    windows_classifications = ["Critical", "Security", "UpdateRollup", "Definition", "Updates"]
    linux_classifications   = ["Critical", "Security"]
  }
}