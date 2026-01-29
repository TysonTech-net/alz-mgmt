# Get current subscription information
data "azurerm_subscription" "current" {}

# Create policy maps for different vault types and policy types
locals {
  # ------------------------- Original (non-enhanced) policies -------------------------
  # Maps for standard VM policies (V1) for each vault type
  gr_policies = local.has_gr ? {
    for policy_name, policy_config in local.policy_configs.vms :
    "${policy_name}-GR" => azurerm_backup_policy_vm.this["gr_${policy_name}"].id
    if policy_config.policy_type == "V1"
  } : {}

  zr_policies = local.has_zr ? {
    for policy_name, policy_config in local.policy_configs.vms :
    "${policy_name}-ZR" => azurerm_backup_policy_vm.this["zr_${policy_name}"].id
    if policy_config.policy_type == "V1"
  } : {}

  lr_policies = local.has_lr ? {
    for policy_name, policy_config in local.policy_configs.vms :
    "${policy_name}-LR" => azurerm_backup_policy_vm.this["lr_${policy_name}"].id
    if policy_config.policy_type == "V1"
  } : {}

  # ------------------------------ Enhanced policies ------------------------------
  # Maps for enhanced VM policies (V2) for each vault type
  gr_enhanced_policies = local.has_gr ? {
    for policy_name, policy_config in local.policy_configs.vms :
    "${policy_name}-GR" => azurerm_backup_policy_vm.this["gr_${policy_name}"].id
    if policy_config.policy_type == "V2"
  } : {}

  zr_enhanced_policies = local.has_zr ? {
    for policy_name, policy_config in local.policy_configs.vms :
    "${policy_name}-ZR" => azurerm_backup_policy_vm.this["zr_${policy_name}"].id
    if policy_config.policy_type == "V2"
  } : {}

  lr_enhanced_policies = local.has_lr ? {
    for policy_name, policy_config in local.policy_configs.vms :
    "${policy_name}-LR" => azurerm_backup_policy_vm.this["lr_${policy_name}"].id
    if policy_config.policy_type == "V2"
  } : {}

  # Merge everything into one map for policy assignment
  all_policies = merge(
    local.gr_policies,
    local.zr_policies,
    local.lr_policies,
    local.gr_enhanced_policies,
    local.zr_enhanced_policies,
    local.lr_enhanced_policies
  )
}

# Process subscription name for use in policy names
locals {
  raw_subscription_name = trimspace(data.azurerm_subscription.current.display_name)

  # Clean up certain characters to create a valid name
  sub_normalized_dashes = replace(
    replace(local.raw_subscription_name, "–", "-"), # Replace en-dash
    "—", "-"                                        # Replace em-dash
  )
  sub_remove_spaces        = replace(local.sub_normalized_dashes, " ", "-")
  sub_remove_triple_dashes = replace(local.sub_remove_spaces, "---", "-")
  sub_final_name           = replace(local.sub_remove_triple_dashes, "--", "-")
}

# Create a policy set definition that includes all backup policies
resource "azurerm_policy_set_definition" "backup" {
  count               = var.enable_azure_policy ? 1 : 0
  name                = "${local.sub_final_name}-VM-Backup-${upper(var.location_short)}"
  policy_type         = "Custom"
  display_name        = "CD Custom Policy | Configure VM Backup for subscription ${trimspace(data.azurerm_subscription.current.display_name)} based on tag in ${var.location}"
  management_group_id = "/providers/Microsoft.Management/managementGroups/${var.root_id}"

  dynamic "policy_definition_reference" {
    for_each = local.all_policies
    content {
      policy_definition_id = "/providers/Microsoft.Management/managementGroups/${var.root_id}/providers/Microsoft.Authorization/policyDefinitions/Enforce-VM-Backup-Custom"
      parameter_values     = <<EOT
{
  "vaultLocation": {"value": "${var.location}"},
  "inclusionTagName": {"value": "Backup"},
  "inclusionTagValue": {"value": ["${policy_definition_reference.key}"]},
  "backupPolicyId": {"value": "${policy_definition_reference.value}"},
  "effect": {"value": "DeployIfNotExists"}
}
EOT
      reference_id         = "Enforce-VM-Backup-${policy_definition_reference.key}-${upper(var.location_short)}"
    }
  }
}

# Assign the policy set to the subscription
resource "azurerm_subscription_policy_assignment" "backup" {
  count                = var.enable_azure_policy ? 1 : 0
  name                 = "${local.sub_final_name}-VM-Backup-${upper(var.location_short)}"
  display_name         = "Configure VM Backup for subscription ${trimspace(data.azurerm_subscription.current.display_name)} based on tag in ${var.location}"
  policy_definition_id = azurerm_policy_set_definition.backup[0].id
  subscription_id      = data.azurerm_subscription.current.id
  location             = var.location

  identity { type = "SystemAssigned" }

  resource_selectors {
    selectors {
      kind = "resourceLocation"
      in   = [lower(replace(var.location, " ", ""))]
    }
  }
}

# Assign necessary RBAC roles to the policy assignment's managed identity
resource "azurerm_role_assignment" "backup_contributor" {
  count                = var.enable_azure_policy ? 1 : 0
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Backup Contributor"
  principal_id         = azurerm_subscription_policy_assignment.backup[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "virtual_machine_contributor" {
  count                = var.enable_azure_policy ? 1 : 0
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_subscription_policy_assignment.backup[0].identity[0].principal_id
}

resource "azurerm_role_assignment" "reader" {
  count                = var.enable_azure_policy ? 1 : 0
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_subscription_policy_assignment.backup[0].identity[0].principal_id
}