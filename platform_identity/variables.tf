###############################################
# Subscription IDs
###############################################

variable "subscription_ids" {
  description = "Subscription IDs used by this stack."
  type        = map(string)
  nullable    = false
}

###############################################
# Location
###############################################

variable "primary_location" {
  description = "Primary Azure region for deployment."
  type        = string
}

variable "primary_location_short" {
  description = "Short code for primary location (e.g., uks)."
  type        = string
  default     = ""
}

###############################################
# Naming
###############################################

variable "customer_prefix" {
  description = "Optional customer prefix for resource naming."
  type        = string
  default     = ""
}

variable "naming" {
  description = "Base naming tokens."
  type = object({
    env      = string
    workload = string
    instance = string
  })
}

###############################################
# Tags
###############################################

variable "tags" {
  description = "Base tags applied to all resources."
  type        = map(string)
  default     = {}
}

###############################################
# Network Configuration
###############################################

variable "virtual_network" {
  description = "Virtual network configuration."
  type = object({
    name                    = optional(string)
    address_space           = list(string)
    dns_servers             = optional(list(string), [])
    ddos_protection_plan_id = optional(string)
  })
}

variable "subnets" {
  description = "Map of subnets to create."
  type        = map(any)
  default     = {}
}

variable "network_security_groups" {
  description = "Map of NSGs to create."
  type        = map(any)
  default     = {}
}

variable "route_tables" {
  description = "Map of route tables to create."
  type        = map(any)
  default     = {}
}

variable "common_routes" {
  description = "Routes added to all route tables."
  type        = list(any)
  default     = []
}

###############################################
# Hub Connectivity (vWAN)
###############################################

variable "virtual_hub_id" {
  description = "Virtual Hub ID for vWAN connectivity."
  type        = string
  default     = null
}

###############################################
# Private DNS
###############################################

variable "private_dns_zone_ids" {
  description = "Map of Private DNS zone IDs to link."
  type        = map(string)
  default     = {}
}

variable "dns_forwarding_ruleset_id" {
  description = "DNS forwarding ruleset ID."
  type        = string
  default     = null
}

###############################################
# Management Toggles
###############################################

variable "create_management_rg" {
  description = "Whether to create the management resource group."
  type        = bool
  default     = true
}

variable "create_log_analytics_workspace" {
  description = "Whether to create a Log Analytics Workspace."
  type        = bool
  default     = true
}

variable "create_management_kv" {
  description = "Whether to create a management Key Vault."
  type        = bool
  default     = true
}

variable "create_backup_rsv" {
  description = "Whether to create a backup Recovery Services Vault."
  type        = bool
  default     = true
}
