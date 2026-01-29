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

variable "maintenance_configurations" {
  description = "Per-group patching configs"
  type = map(object({
    tag                     = string
    recur_every             = string # e.g. "Month Second Tuesday Offset3" or "Month Third Tuesday"
    start_date_time         = string # "YYYY-MM-DD HH:MM" (anchor date – first run is next matching recurrence)
    duration                = string # "HH:MM"
    time_zone               = string # e.g. "UTC"
    reboot                  = string # "Always" | "IfRequired" | "Never"
    windows_classifications = list(string)
    linux_classifications   = list(string)
  }))
}

variable "service_health_email_addresses" {
  description = "Email recipients for central Service Health alerts."
  type        = list(string)
}