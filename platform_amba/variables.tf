variable "starter_locations" {
  type        = list(string)
  description = "The default for Azure resources. (e.g 'uksouth')"
  validation {
    condition     = length(var.starter_locations) > 0
    error_message = "You must provide at least one starter location region."
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

variable "bring_your_own_user_assigned_managed_identity_resource_id" {
  description = "Resource ID of existing managed identity when bring_your_own is true."
  type        = string
  default     = ""
}

variable "management_subscription_id" {
  description = "Management subscription ID override for AMBA (optional)."
  type        = string
  default     = null
}

variable "action_group_email" {
  description = "Email for AMBA action group notifications."
  type        = list(string)
  default     = []
}

variable "action_group_arm_role_id" {
  description = "ARM role ID for AMBA action group (optional)."
  type        = list(string)
  default     = []
}

variable "alert_severity" {
  description = "Severity levels for alerts notifications to be sent."
  type        = list(string)
  default     = ["Sev0", "Sev1", "Sev2", "Sev3", "Sev4"]
}

variable "root_parent_management_group_name" {
  description = "Root management group name for AMBA policy assignment."
  type        = string
}

variable "amba_disable_tag_name" {
  description = "Tag name to disable AMBA policies."
  type        = string
  default     = "amba_disable"
}

variable "amba_disable_tag_values" {
  description = "Tag values to disable AMBA policies."
  type        = list(string)
  default     = ["true"]
}

variable "webhook_service_uri" {
  description = "Webhook URI for AMBA action group (optional)."
  type        = list(string)
  default     = []
}

variable "event_hub_resource_id" {
  description = "Event Hub resource ID for AMBA (optional)."
  type        = list(string)
  default     = []
}

variable "function_resource_id" {
  description = "Function app resource ID for AMBA (optional)."
  type        = string
  default     = ""
}

variable "function_trigger_uri" {
  description = "Function trigger URL for AMBA (optional)."
  type        = string
  default     = ""
}

variable "logic_app_resource_id" {
  description = "Logic App resource ID for AMBA (optional)."
  type        = string
  default     = ""
}

variable "logic_app_callback_url" {
  description = "Logic App callback URL for AMBA (optional)."
  type        = string
  default     = ""
}

variable "bring_your_own_alert_processing_rule_resource_id" {
  description = "BYO alert processing rule resource ID (optional)."
  type        = string
  default     = ""
}

variable "bring_your_own_action_group_resource_id" {
  description = "BYO action group resource ID (optional)."
  type        = list(string)
  default     = []
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}