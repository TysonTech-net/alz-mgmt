###############################################################################
# Required Variables
###############################################################################

variable "connectivity_subscription_id" {
  type        = string
  description = "Subscription ID for the connectivity subscription"
}

variable "platform_shared_state" {
  type = object({
    resource_group_name  = string
    storage_account_name = string
    container_name       = string
    key                  = string
    subscription_id      = string
  })
  description = "Remote state configuration for platform_shared"
}

variable "hub_region_mapping" {
  description = "Map hub keys to region names (e.g., primary = uksouth)"
  type        = map(string)
  default = {
    primary   = "uksouth"
    secondary = "ukwest"
  }
}

variable "naming" {
  type = object({
    env      = string
    workload = string
    instance = string
  })
  description = "Naming tokens for resource naming"
}

variable "regions" {
  description = "Per-region basic configuration"
  type = map(object({
    location              = string
    resource_group_name   = string
    bastion_subnet_prefix = string
  }))
}

###############################################################################
# IP Groups - CIDRs per region
# Update these to change what's allowed through the firewall
###############################################################################

variable "ip_groups" {
  description = "IP group CIDRs per region - update these to change firewall rules"
  type = map(object({
    # Required - Domain controller subnets
    identity_dcs = set(string)

    # All Azure spoke networks (get ADDS access + spoke ↔ on_prem traffic)
    spokes = optional(set(string), [])

    # On-premises networks via VPN/ExpressRoute
    on_prem = optional(set(string), [])

    # External DCs for AD replication/enrollment
    replication_dcs = optional(set(string), [])

    # Spoke networks in other regions (for cross-region connectivity)
    remote_spokes = optional(set(string), [])

    # Jumpbox/management subnets (SSH + RDP access to all spokes)
    jumpboxes = optional(set(string), [])

    # LogicMonitor monitoring
    logicmonitor = optional(object({
      collectors = optional(set(string), [])
      targets    = optional(set(string), [])
    }), {})

    # Tenable vulnerability scanning
    tenable = optional(object({
      scanners = optional(set(string), [])
    }), {})
  }))
}

###############################################################################
# Custom IP Groups - Per region
# Additional IP groups for use in custom rules (key = group name, value = CIDRs)
# Referenced in custom rules via source_ip_groups/destination_ip_groups by key
###############################################################################

variable "custom_ip_groups" {
  description = "Custom IP groups per region for use in custom firewall rules"
  type        = map(map(set(string)))
  default     = {}
}

###############################################################################
# Rule Settings - Override module defaults
###############################################################################

variable "rule_settings" {
  description = "Rule enablement and priority settings"
  type = object({
    # Azure management rules
    enable_az_mgmt_rules            = optional(bool)
    enable_az_mgmt_app_rules        = optional(bool)
    enable_ntp                      = optional(bool)

    # LogicMonitor rules
    enable_logicmonitor_rules       = optional(bool)
    enable_monitoring_windows       = optional(bool)
    enable_monitoring_linux         = optional(bool)

    # Security monitoring (Sentinel, Tenable, syslog, CEF, WEF)
    enable_security_monitoring      = optional(bool)

    # Internet outbound
    enable_internet_outbound        = optional(bool)

    # Troubleshooting
    enable_troubleshooting          = optional(bool)
    enable_troubleshooting_internet = optional(bool)

    # Spoke traffic
    enable_spoke_to_spoke           = optional(bool)
    enable_cross_region_spokes      = optional(bool)  # Cross-region spoke ↔ remote spoke traffic
    enable_jumpbox_access           = optional(bool)  # Jumpboxes → Spokes (SSH, RDP)
    enable_icmp                     = optional(bool)

    # On-prem traffic
    enable_spokes_to_on_prem        = optional(bool)
    enable_on_prem_adds             = optional(bool)
    enable_on_prem_kerberos         = optional(bool)

    # OS updates and security tooling
    enable_edge_updates             = optional(bool)
    enable_linux_updates            = optional(bool)
    enable_tenable                  = optional(bool)

    # Rule collection group priorities
    # Order: DNAT(100) → Troubleshoot(200) → Identity(300) → Internet Net(400) / App(410) → Platform Net(500) / App(510) → Monitoring(600) → Custom(700-800)
    rcg_troubleshooting_priority        = optional(number)
    rcg_identity_priority               = optional(number)
    rcg_internet_network_priority       = optional(number)
    rcg_internet_application_priority   = optional(number)
    rcg_platform_network_priority       = optional(number)
    rcg_platform_application_priority   = optional(number)
    rcg_monitoring_priority             = optional(number)
    rcg_custom_network_priority         = optional(number)
    rcg_custom_application_priority     = optional(number)
  })
  default = {}
}

###############################################################################
# Traffic Rules - Override default ports/protocols
###############################################################################

variable "traffic_rules" {
  description = "Optional: Override default ports/protocols for directional rules"
  type = object({
    spokes_to_on_prem = optional(object({ ports = list(string), protocols = list(string) }))
    on_prem_to_spokes = optional(object({ ports = list(string), protocols = list(string) }))
    spoke_to_spoke    = optional(object({ ports = list(string), protocols = list(string) }))
  })
  default = {}
}

###############################################################################
# Custom DNAT Rules - Per region
# Define customer-specific inbound NAT rules (e.g., vendor access, applications)
###############################################################################

variable "custom_dnat_collections" {
  description = "Custom DNAT rule collections per region with configurable names and priorities"
  type = map(map(object({
    priority = number
    rules = list(object({
      name                = string
      source_addresses    = optional(list(string), ["*"])
      destination_address = string # Firewall public IP
      destination_port    = string
      translated_address  = string # Internal target IP
      translated_port     = string
      protocols           = optional(list(string), ["TCP"])
    }))
  })))
  default = {}
}

###############################################################################
# Custom Network Rules - Per region
# Define customer-specific network rules (e.g., security services, management)
###############################################################################

variable "custom_network_collections" {
  description = "Custom network rule collections per region with configurable names and priorities"
  type = map(map(object({
    priority = number
    rules = list(object({
      name                  = string
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
      destination_addresses = optional(list(string))
      destination_ip_groups = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_ports     = list(string)
      protocols             = list(string) # TCP, UDP, ICMP, Any
    }))
  })))
  default = {}
}

###############################################################################
# Custom Application Rules - Per region
# Define customer-specific application rules (e.g., vendor services, SaaS)
###############################################################################

variable "custom_application_collections" {
  description = "Custom application rule collections per region with configurable names and priorities"
  type = map(map(object({
    priority = number
    rules = list(object({
      name                  = string
      source_addresses      = optional(list(string))
      source_ip_groups      = optional(list(string))
      destination_fqdns     = optional(list(string))
      destination_fqdn_tags = optional(list(string))
      protocols = list(object({
        type = string # Http, Https, Mssql
        port = number
      }))
    }))
  })))
  default = {}
}

###############################################################################
# Tags
###############################################################################

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
  default     = {}
}
