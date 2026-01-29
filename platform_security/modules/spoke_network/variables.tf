##############################################
# Variables for single-spoke network module  #
##############################################

variable "location" {
  description = "Azure region where resources will be created."
  type        = string
}

variable "location_short" {
  description = "Short location code (e.g., 'uks') used in resource names."
  type        = string
}

variable "tags" {
  description = "Default tags inherited from the root module."
  type        = map(string)
  default     = {}
}

# New: all resources in this RG (created outside)
variable "resource_group_name" {
  description = "The resource group name in which to create all resources."
  type        = string
}

##############################################
# VNet settings (single spoke)
##############################################
variable "virtual_network_settings" {
  description = "Configuration for the single virtual network this module deploys."
  type = object({
    name                    = string
    address_space           = list(string)
    dns_servers             = optional(list(string), [])
    flow_timeout_in_minutes = optional(number, null)
    tags                    = optional(map(string), {})

    # Optional DDoS plan
    ddos_protection_plan_id = optional(string, null)
    enable_ddos_protection  = optional(bool, false)

    # Hub connectivity toggles (applies to both hub-vnet or vwan modes below)
    peer_to_hub = optional(bool, true)

    # Classic hub-vnet peering knobs
    peer_to_hub_settings = optional(object({
      allow_forwarded_traffic              = optional(bool, true)
      allow_gateway_transit                = optional(bool, false)
      use_remote_gateways                  = optional(bool, true)
      create_reverse_peering               = optional(bool, true)
      reverse_allow_forwarded_traffic      = optional(bool, false)
      reverse_allow_gateway_transit        = optional(bool, true)
      reverse_allow_virtual_network_access = optional(bool, true)
      reverse_use_remote_gateways          = optional(bool, false)
    }), {})

    # vWAN connection overrides (used only when hub_mode='vwan')
    vwan_connection_settings = optional(object({
      enable                     = optional(bool, true)
      internet_security_enabled  = optional(bool)
      associated_route_table_id  = optional(string)
      propagated_route_table_ids = optional(list(string))
      propagated_route_labels    = optional(list(string))
    }), {})
  })
}

##############################################
# Subnets (top-level, keyed by logical name)
##############################################
variable "subnets" {
  description = "Map of subnets to create inside this VNet, keyed by logical name."
  type = map(object({
    name             = string
    address_prefixes = list(string)

    # Look up by key in the maps passed to network_security_groups / route_tables
    network_security_group_key = optional(string, null)
    route_table_key            = optional(string, null)

    # Optional subnet features
    delegation = optional(list(object({
      name = string
      service_delegation = object({
        name    = string
        actions = optional(list(string))
      })
    })), [])

    service_endpoints                             = optional(list(string), [])
    private_endpoint_network_policies             = optional(string, "Enabled")
    private_link_service_network_policies_enabled = optional(string, "Enabled")
    default_outbound_access_enabled               = optional(bool, false)
  }))
  default = {}
}

##############################################
# Shared, still-multi maps for NSGs & RTs
##############################################
variable "network_security_groups" {
  description = "Map of NSGs to create. All are placed in the provided resource group."
  type = map(object({
    name = string
    security_rules = optional(list(object({
      name      = string
      priority  = number
      direction = string
      access    = string
      protocol  = string

      source_port_range       = optional(string)
      source_port_ranges      = optional(list(string))
      destination_port_range  = optional(string)
      destination_port_ranges = optional(list(string))

      source_address_prefix        = optional(string)
      source_address_prefixes      = optional(list(string))
      destination_address_prefix   = optional(string)
      destination_address_prefixes = optional(list(string))

      description                                = optional(string)
      source_application_security_group_ids      = optional(list(string))
      destination_application_security_group_ids = optional(list(string))
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "route_tables" {
  description = "Map of route tables to create. All are placed in the provided resource group."
  type = map(object({
    name                          = string
    bgp_route_propagation_enabled = optional(bool, false) # provider arg is disable_bgp_route_propagation
    routes = optional(list(object({
      name                   = string
      address_prefix         = string
      next_hop_type          = string
      next_hop_in_ip_address = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "common_routes" {
  description = "Routes automatically added to ALL route tables in this module instance."
  type        = list(any)
  default     = []
}

##############################################
# Private DNS auto-registration (optional)
##############################################
variable "autoregistration_private_dns_zone_name" {
  description = "Private DNS zone name for auto-registration. Set null to skip linking."
  type        = string
  default     = null
}

variable "autoregistration_private_dns_zone_resource_group_name" {
  description = "Resource group for the private DNS zone. Set null to skip linking."
  type        = string
  default     = null
}

##############################################
# Hub connectivity toggles & inputs
##############################################
variable "hub_mode" {
  description = "Connectivity mode for the spoke: 'hubvnet' (peering) or 'vwan' (Virtual WAN vHub connection)."
  type        = string
  default     = "hubvnet"
  validation {
    condition     = contains(["hubvnet", "vwan"], var.hub_mode)
    error_message = "hub_mode must be 'hubvnet' or 'vwan'."
  }
}

# vWAN / vHub inputs (required when hub_mode = 'vwan')
variable "virtual_hub_id" {
  description = "Resource ID of the Virtual Hub (Microsoft.Network/virtualHubs) used when hub_mode='vwan'."
  type        = string
  default     = null
}

# Defaults used for all vWAN connections (can be overridden by virtual_network_settings.vwan_connection_settings)
variable "vwan_connection_defaults" {
  description = "Defaults for vWAN connections."
  type = object({
    internet_security_enabled  = optional(bool, true)
    associated_route_table_id  = optional(string)
    propagated_route_table_ids = optional(list(string), [])
    propagated_route_labels    = optional(list(string), [])
  })
  default = {}
}

# hub-vnet inputs (required when hub_mode = 'hubvnet')
variable "hub_vnet_id" {
  description = "Resource ID of the hub Virtual Network for peering when hub_mode='hubvnet'."
  type        = string
  default     = null
}

variable "hub_resource_group_name" {
  description = "Resource group name containing the hub VNet when hub_mode='hubvnet'."
  type        = string
  default     = null
}
