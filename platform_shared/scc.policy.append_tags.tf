###############################################################################
# SCC Custom: Dynamic Tag Inheritance Policies
###############################################################################
# Creates policy assignments for each tag in var.tags to inherit from RG to resources.
# Uses built-in Azure Policy: ea3f2387-9b95-492a-a190-fcdc54f7b070
# "Append a tag and its value from the resource group"
#
# This replaces the static Append-Tag-From-RG assignment with dynamic assignments
# for ALL tags defined in var.tags, ensuring complete tag inheritance.
###############################################################################

locals {
  # Root management group ID (VISPlatform is defined in alz_custom.alz_architecture_definition.yaml)
  scc_root_management_group_id = "/providers/Microsoft.Management/managementGroups/${var.root_parent_management_group_id}"
}

resource "azurerm_management_group_policy_assignment" "append_tag_from_rg" {
  for_each = var.management_groups_enabled ? toset(keys(var.tags)) : []

  name                 = "Append-Tag-${replace(each.key, "_", "-")}"
  display_name         = "Append ${each.key} tag from resource group"
  description          = "Appends the ${each.key} tag to resources using the value from their parent resource group when missing."
  management_group_id  = local.scc_root_management_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"

  parameters = jsonencode({
    tagName = { value = each.key }
  })

  identity {
    type = "SystemAssigned"
  }
  location = var.starter_locations[0]

  depends_on = [module.management_groups]
}

# Role assignment for remediation (Contributor needed for Modify effect)
resource "azurerm_role_assignment" "append_tag_contributor" {
  for_each = azurerm_management_group_policy_assignment.append_tag_from_rg

  scope                = each.value.management_group_id
  role_definition_name = "Contributor"
  principal_id         = each.value.identity[0].principal_id
}
