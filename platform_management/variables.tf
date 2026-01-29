variable "subscription_ids" {
  description = "Subscription IDs used by this stack."
  type        = map(string)
  nullable    = false
}

variable "starter_locations" {
  description = "Regions to deploy hubs into (order defines primary/secondary, etc.)."
  type        = list(string)
  nullable    = false
}

variable "starter_locations_short" {
  description = "Optional map of region to short code (overrides auto-derived)."
  type        = map(string)
  default     = {}
}

variable "naming" {
  description = "Base naming tokens."
  type = object({
    env      = string
    workload = string
    instance = string
  })
}

variable "hubs" {
  description = "Per-region hub/spoke settings (hubvnet mode only). Key is logical hub name."
  type = map(object({
    location                = string
    location_short          = optional(string)
    resource_group_name     = string
    hub_vnet_id             = string
    hub_resource_group_name = string
    virtual_network_settings = object({
      name                    = string
      address_space           = list(string)
      dns_servers             = optional(list(string), [])
      flow_timeout_in_minutes = optional(number)
      ddos_protection_plan_id = optional(string)
      enable_ddos_protection  = optional(bool, false)
      peer_to_hub             = optional(bool, true)
      peer_to_hub_settings    = optional(any, {})
    })
    subnets                 = map(any)
    network_security_groups = map(any)
    route_tables            = map(any)
    common_routes           = list(any)
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "vms" {
  description = "Virtual machines to deploy (keyed by name)."
  type = map(object({
    name                = string
    hub_key             = string
    resource_group_name = string
    subnet_key          = string
    private_ip_address  = string
    sku_size            = string
    zone                = optional(number, 1)
    license_type        = optional(string, "Windows_Server")
    image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = optional(string, "latest")
    })
    os_disk = object({
      disk_size_gb         = number
      storage_account_type = optional(string, "Premium_LRS")
      caching              = optional(string, "ReadWrite")
    })
    admin_username = optional(string, "azureadmin")
    extensions     = optional(map(any), {})
    tags           = optional(map(string), {})
  }))
  default = {}
}

variable "vm_admin_password" {
  description = "Admin password for VMs."
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Base tags applied to all resources."
  type        = map(string)
  default     = {}
}
