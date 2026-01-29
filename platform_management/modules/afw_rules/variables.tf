variable "firewall_policy_id" {
  type        = string
  description = "ID of the Azure Firewall Policy to attach rule collection groups to."
}

variable "group_name_prefix" {
  type        = string
  description = "Prefix for rule collection group names, e.g. 'Evri'. Final names: <prefix>_Default_Internet_Rules, etc."
}

variable "ip_groups" {
  type        = map(string)
  description = <<EOT
Map of logical IP group roles to IP Group IDs. Expected (optional) keys:
  - hub                     : hub VNet IP Group
  - identity_spokes         : identity / ADDS subnet IP Group
  - spokes                  : other spoke VNets IP Group
  - onprem                  : on-premises ranges IP Group
  - domaincontrollers       : domain controllers IP Group
  - logicmonitor_collectors : LogicMonitor collectors IP Group
  - logicmonitor_targets    : LogicMonitor monitored targets IP Group
EOT
  default     = {}
}

# NOTE: object() + optional() so {} is allowed and you override only what you care about

variable "internet_settings" {
  type = object({
    enabled                          = optional(bool)
    priority                         = optional(number)
    enable_azure_services_network    = optional(bool)
    enable_azure_services_app        = optional(bool)
    enable_datadog_network_rules     = optional(bool)
    enable_logicmonitor_egress_rules = optional(bool)
  })
  description = "Optional overrides for Internet rule collection behaviour."
  default     = {}
}

variable "identity_settings" {
  type = object({
    enabled                     = optional(bool)
    priority                    = optional(number)
    azure_bastion_subnet_prefix = optional(string)
  })
  description = "Optional overrides for Identity rule collection behaviour."
  default     = {}
}

variable "monitoring_settings" {
  type = object({
    enabled  = optional(bool)
    priority = optional(number)
  })
  description = "Optional overrides for Monitoring rule collection behaviour."
  default     = {}
}