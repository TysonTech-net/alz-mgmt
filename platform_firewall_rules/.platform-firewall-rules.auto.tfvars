connectivity_subscription_id = "91f98b99-3946-4096-8191-1078a530c5fd"

platform_shared_state = {
  resource_group_name  = "rg-alz-mgmt-state-uksouth-001"
  storage_account_name = "stoalzmgmuks001ybcn"
  container_name       = "mgmt-tfstate"
  key                  = "terraform.tfstate"
  subscription_id      = "f09a5d16-c8db-4d7c-bce4-a2781c659cde"
}

hub_region_mapping = {
  primary   = "uksouth"
  secondary = "ukwest"
}

naming = {
  env      = "prod"
  workload = "hub"
  instance = "001"
}

regions = {
  primary = {
    location              = "uksouth"
    resource_group_name   = "rg-hub-prod-network-uks-001"
    bastion_subnet_prefix = "10.0.0.64/26"
  }
  secondary = {
    location              = "ukwest"
    resource_group_name   = "rg-hub-prod-network-ukw-001"
    bastion_subnet_prefix = "10.1.0.64/26"
  }
}

###############################################################################
# IP Groups - All CIDRs defined here for easy updates
# Update these values to change what's allowed through the firewall
###############################################################################

ip_groups = {
  primary = {
    # Identity domain controllers (DC subnet only)
    identity_dcs = ["10.0.4.0/27"]

    # All Azure spoke networks (Management, Identity, Security, Workloads)
    # These get ADDS access + spoke ↔ on_prem traffic
    spokes = [
      "10.0.4.0/24",   # Identity VNet
      "10.0.5.0/26",   # Management
      "10.0.6.0/27",   # Security
      "10.177.0.0/24", # AudioCodes Production
      "10.177.2.0/24", # AudioCodes SBC Production
      "10.177.4.0/24", # AudioCodes NLE
      "10.177.6.0/24", # AudioCodes SBC NLE
    ]

    # Spoke networks in other regions (cross-region connectivity)
    remote_spokes = [
      "10.1.4.0/24",   # Identity DR
      "10.1.5.0/26",   # Management DR
      "10.1.6.0/27",   # Security DR
      "10.177.1.0/24", # AudioCodes Production DR
      "10.177.3.0/24", # AudioCodes SBC Production DR
      "10.177.5.0/24", # AudioCodes NLE DR
      "10.177.7.0/24", # AudioCodes SBC NLE DR
    ]

    # Jumpbox/management subnets (SSH + RDP access to all spokes)
    jumpboxes = ["10.0.5.0/26"] # Management spoke

    # On-premises networks (VPN/ExpressRoute connected)
    on_prem = []

    # External DCs for AD replication/enrollment (DC promotion, cross-forest trusts)
    replication_dcs = []

    # LogicMonitor monitoring
    # collectors = Management spoke VMs running LM collector
    # targets    = /16 network CIDR that collectors monitor
    logicmonitor = {
      collectors = ["10.0.5.0/26"] # Management spoke
      targets    = ["10.0.0.0/16"] # All monitored networks
    }

    tenable = {
      scanners = ["10.0.6.0/28"] # snet-security-prod-tenable-uks-001
    }
  }

  secondary = {
    # Identity domain controllers (DC subnet only)
    identity_dcs = ["10.1.4.0/27"]

    spokes = [
      "10.1.4.0/24",   # Identity DR VNet
      "10.1.5.0/26",   # Management DR
      "10.1.6.0/27",   # Security DR
      "10.177.1.0/24", # AudioCodes Production DR
      "10.177.3.0/24", # AudioCodes SBC Production DR
      "10.177.5.0/24", # AudioCodes NLE DR
      "10.177.7.0/24", # AudioCodes SBC NLE DR
    ]

    # Spoke networks in other regions (cross-region connectivity)
    remote_spokes = [
      "10.0.4.0/24",   # Identity
      "10.0.5.0/26",   # Management
      "10.0.6.0/27",   # Security
      "10.177.0.0/24", # AudioCodes Production
      "10.177.2.0/24", # AudioCodes SBC Production
      "10.177.4.0/24", # AudioCodes NLE
      "10.177.6.0/24", # AudioCodes SBC NLE
    ]

    # Jumpbox/management subnets (SSH + RDP access to all spokes)
    jumpboxes = ["10.1.5.0/26"] # Management spoke DR

    on_prem         = []
    replication_dcs = []
    logicmonitor = {
      collectors = ["10.1.5.0/26"] # Management spoke DR
      targets    = ["10.1.0.0/16"] # All monitored networks DR
    }

    tenable = {
      scanners = ["10.1.6.0/28"] # snet-security-prod-tenable-ukw-001
    }
  }
}

###############################################################################
# Rule Settings - Override module defaults for this customer
# Customer has no on-prem connectivity (no VPN/ExpressRoute)
###############################################################################

rule_settings = {
  enable_cross_region_spokes = true  # Cross-region spoke ↔ remote spoke default rules
  enable_spokes_to_on_prem   = false # No on-prem connectivity
  enable_on_prem_adds        = false # No on-prem ADDS access needed
  enable_on_prem_kerberos    = false # No on-prem Kerberos needed
  enable_tenable             = true  # Tenable vulnerability scanning
}

###############################################################################
# Traffic Rules - Override default spoke_to_spoke ports
# Default would be TCP 22/80/443/445/3389/5985-5986 (too broad)
# Bastion doesn't transit the firewall, so SSH/RDP/WinRM are unnecessary
# SMB is handled by identity_dcs rules; HTTP should be explicit custom rules
###############################################################################

traffic_rules = {
  spoke_to_spoke = {
    ports     = ["443"]
    protocols = ["TCP"]
  }
}

###############################################################################
# Custom IP Groups - AudioCodes network segments
# Referenced by key name in custom_network_collections rules
# e.g. source_ip_groups = ["ac_sbc_mgmt"]
###############################################################################

custom_ip_groups = {
  primary = {
    # AudioCodes
    ac_ovoc           = ["10.177.0.4", "10.177.0.132"]       # OVOC mgmt NIC + websocket NIC
    ac_ump            = ["10.177.0.5"]                       # UMP server
    ac_service_server = ["10.177.0.6"]                       # Service Server
    ac_sbc_mgmt       = ["10.177.2.32/27", "10.177.3.32/27"] # SBC mgmt subnets (uksouth + ukwest)
    ac_sbc_trust      = ["10.177.2.64/27", "10.177.3.64/27"] # SBC media/trust subnets
    ac_sbc_untrust    = ["10.177.2.96/27", "10.177.3.96/27"] # SBC signaling/untrust subnets

    # AudioCodes NLE
    ac_nle_ovoc           = ["10.177.4.4", "10.177.4.132"]       # NLE OVOC mgmt + websocket
    ac_nle_ump            = ["10.177.4.5"]                       # NLE UMP
    ac_nle_service_server = ["10.177.4.6"]                       # NLE Service Server
    ac_nle_sbc_mgmt       = ["10.177.6.32/27", "10.177.7.32/27"] # NLE SBC mgmt subnets (uksouth + ukwest)
    ac_nle_sbc_trust      = ["10.177.6.64/27", "10.177.7.64/27"] # NLE SBC media/trust subnets
    ac_nle_sbc_untrust    = ["10.177.6.96/27", "10.177.7.96/27"] # NLE SBC signaling/untrust subnets
  }
  secondary = {
    # AudioCodes
    ac_ovoc           = ["10.177.0.4", "10.177.0.132"] # OVOC mgmt + websocket (cross-region target)
    ac_ump            = ["10.177.0.5"]                 # UMP (uksouth — cross-region target)
    ac_service_server = ["10.177.0.6"]                 # Service Server (uksouth — cross-region target)
    ac_sbc_mgmt       = ["10.177.3.32/27"]             # SBC mgmt subnet (ukwest only)
    ac_sbc_trust      = ["10.177.3.64/27"]             # SBC media/trust subnet (ukwest only)
    ac_sbc_untrust    = ["10.177.3.96/27"]             # SBC signaling/untrust subnet (ukwest only)

    # AudioCodes NLE DR (expected IPs post-ASR failover to ukwest)
    ac_nle_ovoc           = ["10.177.5.4", "10.177.5.132"] # NLE OVOC DR mgmt + websocket
    ac_nle_ump            = ["10.177.5.5"]                 # NLE UMP DR
    ac_nle_service_server = ["10.177.5.6"]                 # NLE Service Server DR
    ac_nle_sbc_mgmt       = ["10.177.7.32/27"]             # NLE SBC mgmt subnet (ukwest only)
    ac_nle_sbc_trust      = ["10.177.7.64/27"]             # NLE SBC media/trust subnet (ukwest only)
    ac_nle_sbc_untrust    = ["10.177.7.96/27"]             # NLE SBC signaling/untrust subnet (ukwest only)
  }
}

###############################################################################
# Custom DNAT Rules - Per region
# Inbound NAT rules for customer-specific applications (e.g., AudioCodes)
# NOTE: Update translated_address values with actual internal IPs
###############################################################################

custom_dnat_collections = {
  primary = {
    "AudioCodes-Production" = {
      priority = 100
      rules = [
        {
          name                = "Internet-to-OVOC-Prod"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "20.108.150.98"
          destination_port    = "443"
          translated_address  = "10.177.0.132"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "MarkJefford-to-OVOC-Prod"
          source_addresses    = ["82.71.60.157"] # Mark Jefford (AudioCodes)
          destination_address = "20.108.150.98"
          destination_port    = "443"
          translated_address  = "10.177.0.132"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-UMP-Prod"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "85.210.217.17"
          destination_port    = "443"
          translated_address  = "10.177.0.5"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-ServiceServer-Prod"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "20.90.239.119"
          destination_port    = "443"
          translated_address  = "10.177.0.6"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
      ]
    }
    "AudioCodes-NLE" = {
      priority = 101
      rules = [
        {
          name                = "Internet-to-OVOC-NLE"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "51.143.231.109"
          destination_port    = "443"
          translated_address  = "10.177.4.132"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-UMP-NLE"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "20.254.18.209"
          destination_port    = "443"
          translated_address  = "10.177.4.5"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-ServiceServer-NLE"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "20.49.150.215"
          destination_port    = "443"
          translated_address  = "10.177.4.6"
          translated_port     = "443"
          protocols           = ["TCP"]
        },
      ]
    }
  }

  secondary = {
    "AudioCodes-Production" = {
      priority = 100
      rules = [
        {
          name                = "Internet-to-OVOC-Prod-DR"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "51.142.166.241"
          destination_port    = "443"
          translated_address  = "10.178.0.4" # TODO: Update with actual DR IP
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-UMP-Prod-DR"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "20.162.65.22"
          destination_port    = "443"
          translated_address  = "10.178.0.5" # TODO: Update with actual DR IP
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-ServiceServer-Prod-DR"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "20.90.18.13"
          destination_port    = "443"
          translated_address  = "10.178.0.6" # TODO: Update with actual DR IP
          translated_port     = "443"
          protocols           = ["TCP"]
        },
      ]
    }
    "AudioCodes-NLE" = {
      priority = 101
      rules = [
        {
          name                = "Internet-to-OVOC-NLE-DR"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "51.141.98.36"
          destination_port    = "443"
          translated_address  = "10.177.5.132" # TODO: Update when NLE DR VMs deployed
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-UMP-NLE-DR"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "51.104.56.39"
          destination_port    = "443"
          translated_address  = "10.177.5.5" # TODO: Update when NLE DR VMs deployed
          translated_port     = "443"
          protocols           = ["TCP"]
        },
        {
          name                = "Internet-to-ServiceServer-NLE-DR"
          source_addresses    = ["94.10.126.47"] # AudioCodes office (Mireille)
          destination_address = "51.142.157.27"
          destination_port    = "443"
          translated_address  = "10.177.5.6" # TODO: Update when NLE DR VMs deployed
          translated_port     = "443"
          protocols           = ["TCP"]
        },
      ]
    }
  }
}

###############################################################################
# Custom Network Rules - AudioCodes traffic
# All rules use IP group references (custom_ip_groups keys)
# See: https://docs.audiocodes.com for port requirements
###############################################################################

custom_network_collections = {
  primary = {
    #---------------------------------------------------------------------------
    # SBC management ↔ OVOC / Service Server
    #---------------------------------------------------------------------------
    "AudioCodes-SBC-Management" = {
      priority = 701
      rules = [
        {
          name                  = "SBC-to-OVOC-QoE"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["5001"]
          protocols             = ["TCP"]
        },
        {
          name                  = "SBC-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-to-OVOC-NTP"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["123"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-to-ServiceServer-Syslog"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_service_server"]
          destination_ports     = ["514"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-to-ServiceServer-DR"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_service_server"]
          destination_ports     = ["925"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-SBC-SNMP"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_sbc_mgmt"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-SBC-SNMP-Inform"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_sbc_mgmt"]
          destination_ports     = ["80", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-SBC-SSH"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_sbc_mgmt"]
          destination_ports     = ["22"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # OVOC ↔ UMP / Service Server (server-to-server management)
    #---------------------------------------------------------------------------
    "AudioCodes-Server-Management" = {
      priority = 702
      rules = [
        {
          name                  = "OVOC-to-UMP-SS-SNMP"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_ump", "ac_service_server"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "UMP-SS-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_ump", "ac_service_server"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-UMP-HTTP"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_ump"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
        {
          name                  = "UMP-to-OVOC-SBC-HTTP"
          source_ip_groups      = ["ac_ump"]
          destination_ip_groups = ["ac_ovoc", "ac_sbc_mgmt"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # SBC → Internet (Teams & Gamma VoIP)
    #---------------------------------------------------------------------------
    "AudioCodes-SBC-Internet" = {
      priority = 703
      rules = [
        {
          name                  = "SBC-Media-to-Internet-RTP"
          source_ip_groups      = ["ac_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["3478-3481", "49152-59999"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-Trust-to-Internet-SIP-TLS"
          source_ip_groups      = ["ac_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["5061"]
          protocols             = ["TCP"]
        },
        {
          name                  = "SBC-Untrust-to-Internet-SIP"
          source_ip_groups      = ["ac_sbc_untrust"]
          destination_addresses = ["*"]
          destination_ports     = ["5060"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "SBC-Untrust-to-Gamma-Media"
          source_ip_groups      = ["ac_sbc_untrust"]
          destination_addresses = ["151.2.135.15", "151.2.135.16", "151.2.139.11", "151.2.139.12"]
          destination_ports     = ["6000-40000"]
          protocols             = ["UDP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # TEMP: Mark Jefford SIP trunk test (remove after testing complete)
    #---------------------------------------------------------------------------
    "Temp-Mark-SIP-Trunk-Test" = {
      priority = 710
      rules = [
        {
          name                  = "SBC-to-Mark-All"
          source_ip_groups      = ["ac_sbc_trust", "ac_sbc_untrust"]
          destination_addresses = ["82.71.60.157"]
          destination_ports     = ["*"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "Mark-to-SBC-All"
          source_addresses      = ["82.71.60.157"]
          destination_ip_groups = ["ac_sbc_trust", "ac_sbc_untrust"]
          destination_ports     = ["*"]
          protocols             = ["TCP", "UDP"]
        }
      ]
    }

    #---------------------------------------------------------------------------
    # NLE: OVOC ↔ UMP / Service Server (server-to-server management)
    #---------------------------------------------------------------------------
    "AudioCodes-NLE-Server-Management" = {
      priority = 705
      rules = [
        {
          name                  = "NLE-OVOC-to-UMP-SS-SNMP"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_ump", "ac_nle_service_server"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-UMP-SS-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_nle_ump", "ac_nle_service_server"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-UMP-HTTP"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_ump"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
        {
          name                  = "NLE-UMP-to-OVOC-SBC-HTTP"
          source_ip_groups      = ["ac_nle_ump"]
          destination_ip_groups = ["ac_nle_ovoc", "ac_nle_sbc_mgmt"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # NLE: SBC management ↔ OVOC / Service Server
    #---------------------------------------------------------------------------
    "AudioCodes-NLE-SBC-Management" = {
      priority = 706
      rules = [
        {
          name                  = "NLE-SBC-to-OVOC-QoE"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["5001"]
          protocols             = ["TCP"]
        },
        {
          name                  = "NLE-SBC-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-to-OVOC-NTP"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["123"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-to-ServiceServer-Syslog"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_service_server"]
          destination_ports     = ["514"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-to-ServiceServer-DR"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_service_server"]
          destination_ports     = ["925"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-SBC-SNMP"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-SBC-SNMP-Inform"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_ports     = ["80", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-SBC-SSH"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_ports     = ["22"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # NLE: SBC → Internet (Teams & Gamma VoIP)
    #---------------------------------------------------------------------------
    "AudioCodes-NLE-SBC-Internet" = {
      priority = 707
      rules = [
        {
          name                  = "NLE-SBC-Media-to-Internet-RTP"
          source_ip_groups      = ["ac_nle_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["3478-3481", "49152-59999"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-Trust-to-Internet-SIP-TLS"
          source_ip_groups      = ["ac_nle_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["5061"]
          protocols             = ["TCP"]
        },
        {
          name                  = "NLE-SBC-Untrust-to-Internet-SIP"
          source_ip_groups      = ["ac_nle_sbc_untrust"]
          destination_addresses = ["*"]
          destination_ports     = ["5060"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "NLE-SBC-Untrust-to-Gamma-Media"
          source_ip_groups      = ["ac_nle_sbc_untrust"]
          destination_addresses = ["151.2.135.15", "151.2.135.16", "151.2.139.11", "151.2.139.12"]
          destination_ports     = ["6000-40000"]
          protocols             = ["UDP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # OVOC & UMP → Microsoft Services (Office365 service tag, TCP 443)
    #---------------------------------------------------------------------------
    "AudioCodes-Microsoft-Services" = {
      priority = 708
      rules = [
        {
          name                  = "OVOC-Prod-to-Office365"
          source_ip_groups      = ["ac_ovoc"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
        {
          name                  = "UMP-Prod-to-Office365"
          source_ip_groups      = ["ac_ump"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
        {
          name                  = "OVOC-NLE-to-Office365"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
        {
          name                  = "UMP-NLE-to-Office365"
          source_ip_groups      = ["ac_nle_ump"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
      ]
    }
  }

  secondary = {
    #---------------------------------------------------------------------------
    # SBC management ↔ OVOC / Service Server (cross-region via ukwest firewall)
    #---------------------------------------------------------------------------
    "AudioCodes-SBC-Management" = {
      priority = 701
      rules = [
        {
          name                  = "SBC-to-OVOC-QoE"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["5001"]
          protocols             = ["TCP"]
        },
        {
          name                  = "SBC-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-to-OVOC-NTP"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["123"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-to-ServiceServer-Syslog"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_service_server"]
          destination_ports     = ["514"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-to-ServiceServer-DR"
          source_ip_groups      = ["ac_sbc_mgmt"]
          destination_ip_groups = ["ac_service_server"]
          destination_ports     = ["925"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-SBC-SNMP"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_sbc_mgmt"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-SBC-SNMP-Inform"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_sbc_mgmt"]
          destination_ports     = ["80", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-SBC-SSH"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_sbc_mgmt"]
          destination_ports     = ["22"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # OVOC ↔ UMP / Service Server (server-to-server management)
    #---------------------------------------------------------------------------
    "AudioCodes-Server-Management" = {
      priority = 702
      rules = [
        {
          name                  = "OVOC-to-UMP-SS-SNMP"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_ump", "ac_service_server"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "UMP-SS-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_ump", "ac_service_server"]
          destination_ip_groups = ["ac_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "OVOC-to-UMP-HTTP"
          source_ip_groups      = ["ac_ovoc"]
          destination_ip_groups = ["ac_ump"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
        {
          name                  = "UMP-to-OVOC-SBC-HTTP"
          source_ip_groups      = ["ac_ump"]
          destination_ip_groups = ["ac_ovoc", "ac_sbc_mgmt"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # SBC → Internet (Teams & Gamma VoIP)
    #---------------------------------------------------------------------------
    "AudioCodes-SBC-Internet" = {
      priority = 703
      rules = [
        {
          name                  = "SBC-Media-to-Internet-RTP"
          source_ip_groups      = ["ac_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["3478-3481", "49152-59999"]
          protocols             = ["UDP"]
        },
        {
          name                  = "SBC-Trust-to-Internet-SIP-TLS"
          source_ip_groups      = ["ac_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["5061"]
          protocols             = ["TCP"]
        },
        {
          name                  = "SBC-Untrust-to-Internet-SIP"
          source_ip_groups      = ["ac_sbc_untrust"]
          destination_addresses = ["*"]
          destination_ports     = ["5060"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "SBC-Untrust-to-Gamma-Media"
          source_ip_groups      = ["ac_sbc_untrust"]
          destination_addresses = ["151.2.135.15", "151.2.135.16", "151.2.139.11", "151.2.139.12"]
          destination_ports     = ["6000-40000"]
          protocols             = ["UDP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # TEMP: Mark Jefford SIP trunk test (remove after testing complete)
    #---------------------------------------------------------------------------
    "Temp-Mark-SIP-Trunk-Test" = {
      priority = 710
      rules = [
        {
          name                  = "SBC-to-Mark-All"
          source_ip_groups      = ["ac_sbc_trust", "ac_sbc_untrust"]
          destination_addresses = ["82.71.60.157"]
          destination_ports     = ["*"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "Mark-to-SBC-All"
          source_addresses      = ["82.71.60.157"]
          destination_ip_groups = ["ac_sbc_trust", "ac_sbc_untrust"]
          destination_ports     = ["*"]
          protocols             = ["TCP", "UDP"]
        }
      ]
    }

    #---------------------------------------------------------------------------
    # NLE: OVOC ↔ UMP / Service Server (server-to-server management, ASR failover)
    #---------------------------------------------------------------------------
    "AudioCodes-NLE-Server-Management" = {
      priority = 705
      rules = [
        {
          name                  = "NLE-OVOC-to-UMP-SS-SNMP"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_ump", "ac_nle_service_server"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-UMP-SS-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_nle_ump", "ac_nle_service_server"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-UMP-HTTP"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_ump"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
        {
          name                  = "NLE-UMP-to-OVOC-SBC-HTTP"
          source_ip_groups      = ["ac_nle_ump"]
          destination_ip_groups = ["ac_nle_ovoc", "ac_nle_sbc_mgmt"]
          destination_ports     = ["80"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # NLE: SBC management ↔ OVOC / Service Server (ASR failover)
    #---------------------------------------------------------------------------
    "AudioCodes-NLE-SBC-Management" = {
      priority = 706
      rules = [
        {
          name                  = "NLE-SBC-to-OVOC-QoE"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["5001"]
          protocols             = ["TCP"]
        },
        {
          name                  = "NLE-SBC-to-OVOC-SNMP-Traps"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["162", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-to-OVOC-NTP"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_ovoc"]
          destination_ports     = ["123"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-to-ServiceServer-Syslog"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_service_server"]
          destination_ports     = ["514"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-to-ServiceServer-DR"
          source_ip_groups      = ["ac_nle_sbc_mgmt"]
          destination_ip_groups = ["ac_nle_service_server"]
          destination_ports     = ["925"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-SBC-SNMP"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_ports     = ["161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-SBC-SNMP-Inform"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_ports     = ["80", "1161"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-OVOC-to-SBC-SSH"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_ports     = ["22"]
          protocols             = ["TCP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # NLE: SBC → Internet (Teams & Gamma VoIP, ASR failover)
    #---------------------------------------------------------------------------
    "AudioCodes-NLE-SBC-Internet" = {
      priority = 707
      rules = [
        {
          name                  = "NLE-SBC-Media-to-Internet-RTP"
          source_ip_groups      = ["ac_nle_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["3478-3481", "49152-59999"]
          protocols             = ["UDP"]
        },
        {
          name                  = "NLE-SBC-Trust-to-Internet-SIP-TLS"
          source_ip_groups      = ["ac_nle_sbc_trust"]
          destination_addresses = ["*"]
          destination_ports     = ["5061"]
          protocols             = ["TCP"]
        },
        {
          name                  = "NLE-SBC-Untrust-to-Internet-SIP"
          source_ip_groups      = ["ac_nle_sbc_untrust"]
          destination_addresses = ["*"]
          destination_ports     = ["5060"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "NLE-SBC-Untrust-to-Gamma-Media"
          source_ip_groups      = ["ac_nle_sbc_untrust"]
          destination_addresses = ["151.2.135.15", "151.2.135.16", "151.2.139.11", "151.2.139.12"]
          destination_ports     = ["6000-40000"]
          protocols             = ["UDP"]
        },
      ]
    }

    #---------------------------------------------------------------------------
    # OVOC & UMP → Microsoft Services (Office365 service tag, TCP 443)
    #---------------------------------------------------------------------------
    "AudioCodes-Microsoft-Services" = {
      priority = 708
      rules = [
        {
          name                  = "OVOC-Prod-to-Office365"
          source_ip_groups      = ["ac_ovoc"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
        {
          name                  = "UMP-Prod-to-Office365"
          source_ip_groups      = ["ac_ump"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
        {
          name                  = "OVOC-NLE-to-Office365"
          source_ip_groups      = ["ac_nle_ovoc"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
        {
          name                  = "UMP-NLE-to-Office365"
          source_ip_groups      = ["ac_nle_ump"]
          destination_addresses = ["Office365"]
          destination_ports     = ["443"]
          protocols             = ["TCP"]
        },
      ]
    }
  }
}

###############################################################################
# Custom Application Rules - AudioCodes outbound to vendor services
###############################################################################

custom_application_collections = {
  primary = {
    "AudioCodes-Production" = {
      priority = 700
      rules = [
        {
          name             = "Allow-OVOC-Outbound"
          source_ip_groups = ["ac_ovoc"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-UMP-Outbound"
          source_ip_groups = ["ac_ump"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com",
            "*.service.signalr.net"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-ServiceServer-Outbound"
          source_ip_groups = ["ac_service_server"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        }
      ]
    }
    "Debian-Updates" = {
      priority = 701
      rules = [
        {
          name             = "Debian-Updates"
          source_ip_groups = ["ac_sbc_mgmt"]
          destination_fqdns = [
            "azure.deb.debian.cloud"
          ]
          protocols = [{ type = "Http", port = 80 }]
        }
      ]
    }
    "AudioCodes-NLE" = {
      priority = 702
      rules = [
        {
          name             = "Allow-NLE-OVOC-Outbound"
          source_ip_groups = ["ac_nle_ovoc"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-NLE-UMP-Outbound"
          source_ip_groups = ["ac_nle_ump"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com",
            "*.service.signalr.net"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-NLE-ServiceServer-Outbound"
          source_ip_groups = ["ac_nle_service_server"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        }
      ]
    }
    "NLE-Debian-Updates" = {
      priority = 703
      rules = [
        {
          name             = "NLE-Debian-Updates"
          source_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_fqdns = [
            "azure.deb.debian.cloud"
          ]
          protocols = [{ type = "Http", port = 80 }]
        }
      ]
    }
  }
  secondary = {
    "AudioCodes-Production" = {
      priority = 700
      rules = [
        {
          name             = "Allow-OVOC-Outbound-DR"
          source_addresses = ["10.178.0.4"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-UMP-Outbound-DR"
          source_addresses = ["10.178.0.5"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com",
            "*.service.signalr.net"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-ServiceServer-Outbound-DR"
          source_addresses = ["10.178.0.6"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        }
      ]
    }
    "Debian-Updates" = {
      priority = 701
      rules = [
        {
          name             = "Debian-Updates"
          source_ip_groups = ["ac_sbc_mgmt"]
          destination_fqdns = [
            "azure.deb.debian.cloud"
          ]
          protocols = [{ type = "Http", port = 80 }]
        }
      ]
    }
    "AudioCodes-NLE" = {
      priority = 702
      rules = [
        {
          name             = "Allow-NLE-OVOC-Outbound-DR"
          source_ip_groups = ["ac_nle_ovoc"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-NLE-UMP-Outbound-DR"
          source_ip_groups = ["ac_nle_ump"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com",
            "*.service.signalr.net"
          ]
          protocols = [{ type = "Https", port = 443 }]
        },
        {
          name             = "Allow-NLE-ServiceServer-Outbound-DR"
          source_ip_groups = ["ac_nle_service_server"]
          destination_fqdns = [
            "box.audiocodes.com",
            "download-audiocodes-ireland.s3.amazonaws.com"
          ]
          protocols = [{ type = "Https", port = 443 }]
        }
      ]
    }
    "NLE-Debian-Updates" = {
      priority = 703
      rules = [
        {
          name             = "NLE-Debian-Updates"
          source_ip_groups = ["ac_nle_sbc_mgmt"]
          destination_fqdns = [
            "azure.deb.debian.cloud"
          ]
          protocols = [{ type = "Http", port = 80 }]
        }
      ]
    }
  }
}

# Mandatory tags (from Azure Policy: Audit-Tags-Mandatory)
tags = {
  deployed_by = "terraform"
  source      = "platform_firewall_rules"
  Environment = "production"
  Owner       = "platform-team"
  CostCenter  = "IT-Infrastructure"
}
