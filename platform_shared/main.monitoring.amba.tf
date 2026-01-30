data "azapi_client_config" "current" {}

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
  type        = string
  default     = ""
}

variable "event_hub_resource_id" {
  description = "Event Hub resource ID for AMBA (optional)."
  type        = string
  default     = ""
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
  type        = string
  default     = ""
}

locals {
  amba_location = var.starter_locations[0]
  amba_rg_name  = var.amba_monitoring_resource_group_name
}

module "amba_alz" {
  source = "Azure/avm-ptn-monitoring-amba-alz/azurerm"

  providers = {
    azurerm = azurerm.management
  }
  count = var.bring_your_own_user_assigned_managed_identity ? 0 : 1

  location                            = local.amba_location
  root_management_group_name          = var.root_parent_management_group_name
  resource_group_name                 = local.amba_rg_name
  tags                                = var.tags
  user_assigned_managed_identity_name = var.user_assigned_managed_identity_name
}

module "amba_policy" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "0.12.0"

  architecture_name  = "amba"
  location           = local.amba_location
  parent_resource_id = data.azapi_client_config.current.tenant_id
  policy_default_values = {
    amba_alz_management_subscription_id            = jsonencode({ value = coalesce(var.management_subscription_id, data.azapi_client_config.current.subscription_id) })
    amba_alz_resource_group_location               = jsonencode({ value = local.amba_location })
    amba_alz_resource_group_name                   = jsonencode({ value = var.amba_monitoring_resource_group_name })
    amba_alz_resource_group_tags                   = jsonencode({ value = var.tags })
    amba_alz_user_assigned_managed_identity_name   = jsonencode({ value = var.user_assigned_managed_identity_name })
    amba_alz_byo_user_assigned_managed_identity_id = jsonencode({ value = var.bring_your_own_user_assigned_managed_identity ? var.user_assigned_managed_identity_name : module.amba_alz[0].user_assigned_managed_identity_id })
    amba_alz_disable_tag_name                      = jsonencode({ value = var.amba_disable_tag_name })
    amba_alz_disable_tag_values                    = jsonencode({ value = var.amba_disable_tag_values })
    amba_alz_action_group_email                    = jsonencode({ value = var.action_group_email })
    amba_alz_arm_role_id                           = jsonencode({ value = var.action_group_arm_role_id })
    amba_alz_webhook_service_uri                   = jsonencode({ value = var.webhook_service_uri })
    amba_alz_event_hub_resource_id                 = jsonencode({ value = var.event_hub_resource_id })
    amba_alz_function_resource_id                  = jsonencode({ value = var.function_resource_id })
    amba_alz_function_trigger_url                  = jsonencode({ value = var.function_trigger_uri })
    amba_alz_logicapp_resource_id                  = jsonencode({ value = var.logic_app_resource_id })
    amba_alz_logicapp_callback_url                 = jsonencode({ value = var.logic_app_callback_url })
    amba_alz_byo_alert_processing_rule             = jsonencode({ value = var.bring_your_own_alert_processing_rule_resource_id })
    amba_alz_byo_action_group                      = jsonencode({ value = var.bring_your_own_action_group_resource_id })
  }
}
