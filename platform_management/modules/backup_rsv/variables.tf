variable "name_prefix" {
  description = "Prefix for the Recovery Services Vault names"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for the Recovery Services Vault names"
  type        = string
}

variable "location" {
  description = "Azure location for the Recovery Services Vault"
  type        = string
}

variable "location_short" {
  description = "Short Azure location for policy naming"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create the resource group (true) or use an existing one (false)"
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_ids" {
  description = "List of subnet IDs for the private endpoints"
  type        = list(string)
}

variable "private_dns_zone_group_ids" {
  description = "List of private DNS zones to associate with the private endpoint"
  type        = list(string)
}

variable "rg_tags" {
  description = "Tags to apply to the RSV resource group"
  type        = map(string)
  default     = {}
}

variable "immutability" {
  type    = string
  default = "Disabled"
  validation {
    condition     = contains(["Disabled", "Unlocked", "Locked"], var.immutability)
    error_message = "immutability must be one of: Disabled, Unlocked, Locked."
  }
}

variable "vaults_to_deploy" {
  type    = list(string)
  default = ["lr", "zr", "gr"]
  validation {
    condition     = alltrue([for v in var.vaults_to_deploy : contains(["lr", "zr", "gr"], v)])
    error_message = "vaults_to_deploy must only contain: lr, zr, gr."
  }
}
variable "root_id" {
  description = "Root ID for the policy definition"
  type        = string
  default     = ""
}

variable "enable_azure_policy" {
  description = "When true, deploy the Policy Set/Assignment and RBAC for backup tagging."
  type        = bool
  default     = true # keep existing behavior; set to false if you want it off by default
}

# variables.tf
variable "policy_extensions" {
  description = <<EOT
Optional ADD-ONLY extensions to the default policy configs.
Keys are policy types: vms, azfiles, sql_server_in_azure_vm, sap_hana_in_azure_vm.
Each value is a map(policy_name => full policy object). If a name collides with a default,
it will be rejected (or dropped), depending on how you configure the locals/preconditions.
EOT
  type = object({
    vms = optional(map(object({
      policy_type = string
      backup = object({
        frequency     = string
        time          = optional(string)
        hour_interval = optional(number)
        hour_duration = optional(number)
      })
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    azfiles = optional(map(object({
      backup = object({
        frequency = string
        hourly = object({
          interval        = number
          start_time      = string
          window_duration = number
        })
      })
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    sql_server_in_azure_vm = optional(map(object({
      full_backup = object({
        frequency = string
        time      = string
        weekdays  = optional(list(string))
      })
      log_backup = object({
        frequency_in_minutes = number
        retention_days       = number
      })
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    sap_hana_in_azure_vm = optional(map(object({
      full_backup = object({
        frequency = string
        time      = string
        weekdays  = optional(list(string))
      })
      log_backup = object({
        frequency_in_minutes = number
        retention_days       = number
      })
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})
  })
  default = {}
}

variable "cross_region_restore_enabled" {
  description = "Enable Cross-Region Restore. Only applied to 'gr' vaults."
  type        = bool
  default     = true
}