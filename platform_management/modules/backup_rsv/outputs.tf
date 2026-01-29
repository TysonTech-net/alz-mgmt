output "resource_group_id" {
  description = "The ID of the resource group"
  value       = local.resource_group_id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = local.resource_group_name
}

output "vault_ids" {
  description = "Map of vault types to their IDs"
  value       = { for k, v in azurerm_recovery_services_vault.vaults : k => v.id }
}

output "vault_names" {
  description = "Map of vault types to their names"
  value       = { for k, v in azurerm_recovery_services_vault.vaults : k => v.name }
}

output "vm_policy_ids" {
  description = "Map of VM backup policy names to their IDs"
  value       = { for k, v in azurerm_backup_policy_vm.this : k => v.id }
}

output "file_share_policy_ids" {
  description = "Map of Azure Files backup policy names to their IDs"
  value       = { for k, v in azurerm_backup_policy_file_share.this : k => v.id }
}

output "sql_server_policy_ids" {
  description = "Map of SQL Server in Azure VM backup policy names to their IDs"
  value       = { for k, v in azurerm_backup_policy_vm_workload.sql_server_in_azure_vm : k => v.id }
}

output "sap_hana_policy_ids" {
  description = "Map of SAP HANA in Azure VM backup policy names to their IDs"
  value       = { for k, v in azurerm_backup_policy_vm_workload.sap_hana_in_azure_vm : k => v.id }
}

output "policy_assignment_id" {
  description = "The ID of the policy assignment (null when enable_azure_policy=false)"
  value       = var.enable_azure_policy ? azurerm_subscription_policy_assignment.backup[0].id : null
}

output "policy_set_definition_id" {
  description = "The ID of the policy set definition (null when enable_azure_policy=false)"
  value       = var.enable_azure_policy ? azurerm_policy_set_definition.backup[0].id : null
}

