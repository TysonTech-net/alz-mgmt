variable "subscription_ids" {
  description = "The list of subscription IDs to deploy the Platform Landing Zones into"
  type        = map(string)
  default     = {}
  nullable    = false
  validation {
    condition     = length(var.subscription_ids) == 0 || alltrue([for id in values(var.subscription_ids) : can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", id))])
    error_message = "All subscription IDs must be valid GUIDs"
  }
  validation {
    condition     = length(var.subscription_ids) == 0 || alltrue([for id in keys(var.subscription_ids) : contains(["management", "connectivity", "identity", "security"], id)])
    error_message = "The keys of the subscription_ids map must be one of 'management', 'connectivity', 'identity' or 'security'"
  }
}

variable "starter_locations" {
  type        = list(string)
  description = "The default for Azure resources. (e.g 'uksouth')"
  validation {
    condition     = length(var.starter_locations) > 0
    error_message = "You must provide at least one starter location region."
  }
}

variable "customer" {
  description = "The organization name used in resource names."
  type        = string
}

variable "connectivity_mode" {
  description = "How to connect the spoke: 'vwan' (Virtual WAN hub) or 'hubvnet' (classic hub-and-spoke VNet)."
  type        = string
  default     = "vwan"
  validation {
    condition     = contains(["vwan", "hubvnet"], var.connectivity_mode)
    error_message = "connectivity_mode must be 'vwan' or 'hubvnet'."
  }
}

variable "spoke_network_config_primary" {
  description = "Inputs for the management spoke networking module."
  type = object({
    resource_group = object({
      name = string
      tags = map(string)
    })
    virtual_network_settings = object({
      name          = string
      address_space = list(string)
      dns_servers   = optional(list(string), [])
    })
    subnets                 = map(any)
    network_security_groups = map(any)
    route_tables            = map(any)
    common_routes           = list(any)
    tags                    = map(string)
  })
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}

# vWAN option: look up by name + RG in the CONNECTIVITY subscription
variable "connectivity_vhub_primary" {
  description = "Existing Virtual Hub (used when connectivity_mode == 'vwan')."
  type = object({
    name                = string
    resource_group_name = string
  })
  default = null
}

# Hub VNet option: look up by name + RG in the CONNECTIVITY subscription
variable "connectivity_hub_vnet" {
  description = "Existing Hub VNet (used when connectivity_mode == 'hubvnet')."
  type = object({
    name                = string
    resource_group_name = string
  })
  default = null
}

variable "windows_virtual_machines" {
  description = "Configuration for Windows Virtual Machines to be deployed in the identity spoke."
  type        = map(any)
  default     = {}
}

variable "vm_admin_password" {
  description = "The admin password for the Virtual Machines."
  type        = string
  sensitive   = true
  default     = ""
}