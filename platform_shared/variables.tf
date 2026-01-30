variable "starter_locations" {
  type        = list(string)
  description = "The default for Azure resources. (e.g 'uksouth')"
  validation {
    condition     = length(var.starter_locations) > 0
    error_message = "You must provide at least one starter location region."
  }
  validation {
    condition     = var.connectivity_type == "none" || ((length(var.virtual_hubs) <= length(var.starter_locations)) || (length(var.hub_virtual_networks) <= length(var.starter_locations)))
    error_message = "The number of regions supplied in `starter_locations` must match the number of regions specified for connectivity."
  }
}

variable "starter_locations_short" {
  type        = map(string)
  default     = {}
  description = <<DESCRIPTION
Optional overrides for the starter location short codes.

Keys should match the built-in replacement names used in the examples, for example:
- starter_location_01_short
- starter_location_02_short

If not provided, short codes are derived from the regions module using geo_code when available, falling back to short_name when no geo_code is published.
DESCRIPTION
}

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

variable "subscription_id_connectivity" {
  description = "DEPRECATED (use subscription_ids instead): The identifier of the Connectivity Subscription"
  type        = string
  default     = null
  validation {
    condition     = var.subscription_id_connectivity == null || can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.subscription_id_connectivity))
    error_message = "The subscription ID must be a valid GUID"
  }
}

variable "subscription_id_identity" {
  description = "DEPRECATED (use subscription_ids instead): The identifier of the Identity Subscription"
  type        = string
  default     = null
  validation {
    condition     = var.subscription_id_identity == null || can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.subscription_id_identity))
    error_message = "The subscription ID must be a valid GUID"
  }
}

variable "subscription_id_management" {
  description = "DEPRECATED (use subscription_ids instead): The identifier of the Management Subscription"
  type        = string
  default     = null
  validation {
    condition     = var.subscription_id_management == null || can(regex("^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})$", var.subscription_id_management))
    error_message = "The subscription ID must be a valid GUID"
  }
}

variable "root_parent_management_group_id" {
  type        = string
  default     = ""
  description = "This is the id of the management group that the ALZ hierarchy will be nested under, will default to the Tenant Root Group"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Flag to enable/disable telemetry"
}

# AMBA monitoring variables
variable "amba_monitoring_resource_group_name" {
  description = "Resource group name for AMBA monitoring resources."
  type        = string
}

variable "user_assigned_managed_identity_name" {
  description = "Name of the AMBA user-assigned managed identity."
  type        = string
}

variable "bring_your_own_user_assigned_managed_identity" {
  description = "Set true to use an existing AMBA managed identity instead of deploying one."
  type        = bool
  default     = false
}

variable "management_subscription_id" {
  description = "Management subscription ID override for AMBA (optional)."
  type        = string
  default     = null
}

variable "action_group_email" {
  description = "Email for AMBA action group notifications."
  type        = string
}

variable "action_group_arm_role_id" {
  description = "ARM role ID for AMBA action group (optional)."
  type        = string
  default     = ""
}

variable "alert_severity" {
  description = "Default alert severity for AMBA Deploy-AMBA-Notification assignment (e.g., Sev3)."
  type        = string
  default     = "Sev3"
}

variable "custom_replacements" {
  type = object({
    names                      = optional(map(string), {})
    resource_group_identifiers = optional(map(string), {})
    resource_identifiers       = optional(map(string), {})
  })
  default = {
    names                      = {}
    resource_group_identifiers = {}
    resource_identifiers       = {}
  }
  description = "Custom replacements"
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}
