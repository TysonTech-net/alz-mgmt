data "azapi_client_config" "current" {}

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
  version = "0.11.0"

  architecture_name  = "custom"
  location           = local.amba_location
  parent_resource_id = data.azapi_client_config.current.tenant_id

  policy_assignments_to_modify = {
    (var.root_parent_management_group_name) = {
      policy_assignments = {
        Deploy-AMBA-Notification = {
          parameters = {
            ALZAlertSeverity = jsonencode({ value = var.alert_severity })
          }
        }
      }
    }
  }

  policy_default_values = {
    amba_alz_management_subscription_id          = jsonencode({ value = coalesce(var.management_subscription_id, data.azapi_client_config.current.subscription_id) })
    amba_alz_resource_group_location             = jsonencode({ value = local.amba_location })
    amba_alz_resource_group_name                 = jsonencode({ value = local.amba_rg_name })
    amba_alz_resource_group_tags                 = jsonencode({ value = var.tags })
    amba_alz_user_assigned_managed_identity_name = jsonencode({ value = var.user_assigned_managed_identity_name })
    amba_alz_action_group_email                  = jsonencode({ value = var.action_group_email })
    amba_alz_arm_role_id                         = jsonencode({ value = var.action_group_arm_role_id })
  }
}
