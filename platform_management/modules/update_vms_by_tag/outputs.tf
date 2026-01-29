output "maintenance_configuration_ids" {
  description = "Map of MC name => id"
  value       = { for k, v in azurerm_maintenance_configuration.mc : k => v.id }
}

output "initiative_id" {
  value = azurerm_policy_set_definition.this.id
}

output "assignment_id" {
  value = azurerm_management_group_policy_assignment.assign.id
}

output "assignment_principal_id" {
  value = azurerm_management_group_policy_assignment.assign.identity[0].principal_id
}
