variable "name_prefix" {
  description = "Prefix for the Backup Vault names"
  type        = string
}

variable "name_suffix" {
  description = "Suffix for the Backup Vault names"
  type        = string
}

variable "location" {
  description = "Azure location for the Backup Vault"
  type        = string
}

variable "location_short" {
  description = "Short Azure location for naming"
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

variable "rg_tags" {
  description = "Tags to apply to the Backup resource group and vaults"
  type        = map(string)
  default     = {}
}

variable "vaults_to_deploy" {
  description = "List of vault types to deploy: options are lr, zr, gr."
  type        = list(string)
  default     = ["lr", "zr", "gr"]
  validation {
    condition     = alltrue([for v in var.vaults_to_deploy : contains(["lr", "zr", "gr"], v)])
    error_message = "vaults_to_deploy must only contain: lr, zr, gr."
  }
}

variable "immutability" {
  description = "Enable immutability policy. Possible values are Disabled, Locked, and Unlocked."
  type        = string
  default     = "Disabled"
  validation {
    condition     = contains(["Disabled", "Unlocked", "Locked"], var.immutability)
    error_message = "immutability must be one of: Disabled, Unlocked, Locked."
  }
}

variable "soft_delete" {
  description = "The state of soft delete for the Backup Vault. Possible values are AlwaysOn, Off, and On."
  type        = string
  default     = "On"
  validation {
    condition     = contains(["AlwaysOn", "Off", "On"], var.soft_delete)
    error_message = "soft_delete must be one of: AlwaysOn, Off, On."
  }
}

variable "retention_duration_in_days" {
  description = "The soft delete retention duration in days for the Backup Vault. Range: 14-180."
  type        = number
  default     = 14
  validation {
    condition     = var.retention_duration_in_days >= 14 && var.retention_duration_in_days <= 180
    error_message = "retention_duration_in_days must be between 14 and 180."
  }
}

variable "retention_duration_in_days" {
  description = "The soft delete retention duration in days for the Backup Vault. Range: 14-180."
  type        = number
  default     = 14
}

variable "cross_region_restore_enabled" {
  description = "Whether to enable cross-region restore for geo-redundant vaults."
  type        = bool
  default     = false
}

variable "policy_extensions" {
  description = <<EOT
Optional ADD-ONLY extensions to the default policy configs.
Keys are policy types: blob, disk, postgresql, kubernetes, postgresql_flexible.
Each value is a map(policy_name => full policy object). If a name collides with a default,
the module will fail fast.
EOT
  type = object({
    blob = optional(map(object({
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    disk = optional(map(object({
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    postgresql = optional(map(object({
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    kubernetes = optional(map(object({
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})

    postgresql_flexible = optional(map(object({
      retention = object({ daily = number, weekly = number, monthly = number, yearly = number })
    })), {})
  })
  default = {}
}
