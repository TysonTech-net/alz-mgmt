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
  value       = { for k, v in azurerm_data_protection_backup_vault.vaults : k => v.id }
}

output "vault_names" {
  description = "Map of vault types to their names"
  value       = { for k, v in azurerm_data_protection_backup_vault.vaults : k => v.name }
}

output "blob_policy_ids" {
  description = "Map of blob backup policy names to their IDs"
  value       = { for k, v in azurerm_data_protection_backup_policy_blob_storage.this : k => v.id }
}

output "disk_policy_ids" {
  description = "Map of disk backup policy names to their IDs"
  value       = { for k, v in azurerm_data_protection_backup_policy_disk.this : k => v.id }
}

output "postgresql_policy_ids" {
  description = "Map of PostgreSQL backup policy names to their IDs"
  value       = { for k, v in azurerm_data_protection_backup_policy_postgresql.this : k => v.id }
}

output "kubernetes_cluster_policy_ids" {
  description = "Map of Kubernetes cluster backup policy names to their IDs"
  value       = { for k, v in azurerm_data_protection_backup_policy_kubernetes_cluster.this : k => v.id }
}

output "postgresql_flexible_server_policy_ids" {
  description = "Map of PostgreSQL flexible server backup policy names to their IDs"
  value       = { for k, v in azurerm_data_protection_backup_policy_postgresql_flexible_server.this : k => v.id }
}

output "vault_identities" {
  description = "Map of vault types to their managed identities"
  value = { for k, v in azurerm_data_protection_backup_vault.vaults : k => {
    principal_id = v.identity[0].principal_id
    tenant_id    = v.identity[0].tenant_id
  } }
}