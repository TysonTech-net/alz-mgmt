terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.40.0"
    }
  }
}

# ----------------------------
# Maintenance Configurations
# ----------------------------
resource "azurerm_maintenance_configuration" "mc" {
  for_each                 = var.maintenance_configurations
  name                     = each.key
  resource_group_name      = var.resource_group_name
  location                 = var.location
  scope                    = "InGuestPatch"
  in_guest_user_patch_mode = "User"

  window {
    start_date_time = each.value.start_date_time
    duration        = each.value.duration
    time_zone       = each.value.time_zone
    recur_every     = each.value.recur_every
  }

  install_patches {
    windows {
      classifications_to_include = each.value.windows_classifications
    }
    linux {
      classifications_to_include = each.value.linux_classifications
    }
    reboot = each.value.reboot
  }

  # The tag key used on the MC itself still comes from var.tag_key.
  # Portal users can change the POLICY tag key separately via initiative parameter.
  tags = merge(
    var.tags,
    {
      (var.tag_key) = each.value.tag
    }
  )

  lifecycle {
    ignore_changes = [
      install_patches[0].reboot
    ]
  }
}

# ----------------------------
# Custom Initiative (MG only)
# One entry of the built-in policy per MC
# ----------------------------

locals {
  builtin_update_policy_id = "/providers/Microsoft.Authorization/policyDefinitions/ba0df93e-e4ac-479a-aac2-134bbae39a1a"

  ref_ids = {
    for name, _ in azurerm_maintenance_configuration.mc :
    name => "upd-${replace(lower(name), "/[^a-z0-9]/", "-")}"
  }

  # Single initiative parameter for the shared tag key (e.g. "PatchGroup")
  initiative_parameter_tag_key = {
    patchGroupTagKey = {
      type = "String"
      metadata = {
        displayName = "Patch group tag key"
        description = "Tag key used to select VMs for all maintenance configurations."
      }
      defaultValue = var.tag_key
    }
  }

  # One initiative parameter per maintenance configuration for the tag value
  initiative_parameters_tag_values = {
    for name, mc in var.maintenance_configurations :
    "tagValue_${replace(name, "/[^A-Za-z0-9]/", "_")}" => {
      type = "String"
      metadata = {
        displayName = "PatchGroup tag for ${name}"
        description = "Tag value used to select VMs for maintenance configuration '${name}'."
      }
      defaultValue = mc.tag
    }
  }

  # One initiative parameter per maintenance configuration for the MC resource ID
  initiative_parameters_mc_ids = {
    for name, mc in azurerm_maintenance_configuration.mc :
    "mcId_${replace(name, "/[^A-Za-z0-9]/", "_")}" => {
      type = "String"
      metadata = {
        displayName = "Maintenance Configuration resource ID for ${name}"
        description = "Resource ID of the Maintenance Configuration used by '${name}'."
      }
      defaultValue = mc.id
    }
  }

  # All initiative parameters merged together
  initiative_parameters = merge(
    local.initiative_parameter_tag_key,
    local.initiative_parameters_tag_values,
    local.initiative_parameters_mc_ids
  )

  # Keep track of policy refs + which initiative parameters they should use
  policy_refs = {
    for name, mc in azurerm_maintenance_configuration.mc :
    name => {
      reference_id         = local.ref_ids[name]
      policy_definition_id = local.builtin_update_policy_id
      tag_param_name       = "tagValue_${replace(name, "/[^A-Za-z0-9]/", "_")}"
      mc_param_name        = "mcId_${replace(name, "/[^A-Za-z0-9]/", "_")}"
    }
  }
}

resource "azurerm_policy_set_definition" "this" {
  name                = var.policy_initiative_name
  display_name        = var.policy_initiative_display_name
  policy_type         = "Custom"
  management_group_id = var.management_group_id
  description         = var.policy_initiative_description
  metadata            = jsonencode({ version = "2.0.0", category = "General" })

  # Expose all initiative parameters (tag key, tag values, MC IDs)
  parameters = jsonencode(local.initiative_parameters)

  dynamic "policy_definition_reference" {
    for_each = local.policy_refs
    content {
      policy_definition_id = policy_definition_reference.value.policy_definition_id
      reference_id         = policy_definition_reference.value.reference_id

      # values here are *strings* that the policy engine interprets as [parameters('...')]
      parameter_values = jsonencode({
        maintenanceConfigurationResourceId = {
          value = "[parameters('${policy_definition_reference.value.mc_param_name}')]"
        }
        tagValues = {
          value = [
            {
              # Shared tag key parameter for all policies
              key = "[parameters('patchGroupTagKey')]"
              # Per-MC tag value parameter
              value = "[parameters('${policy_definition_reference.value.tag_param_name}')]"
            }
          ]
        }
        tagOperator = { value = "Any" }
      })
    }
  }
}

# ----------------------------
# Initiative Assignment @ MG
# With System-Assigned MI + location (required for DeployIfNotExists)
# ----------------------------
resource "azurerm_management_group_policy_assignment" "assign" {
  name                 = var.policy_initiative_name
  display_name         = var.policy_assignment_display_name
  management_group_id  = var.management_group_id
  policy_definition_id = azurerm_policy_set_definition.this.id
  location             = var.policy_assignment_location

  identity {
    type = "SystemAssigned"
  }
}

# optional: grant Contributor to the assignment MI at the MG scope
resource "azurerm_role_assignment" "assignment_mi_contributor" {
  count                = var.grant_contributor_to_assignment_mi ? 1 : 0
  scope                = var.management_group_id
  role_definition_name = "Contributor"
  principal_id         = azurerm_management_group_policy_assignment.assign.identity[0].principal_id
}
