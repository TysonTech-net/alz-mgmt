# Single VNet outputs
output "virtual_network_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "virtual_network_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

# Subnet outputs (keyed by subnet logical key)
output "subnet_ids" {
  description = "Map of subnet IDs, keyed by subnet logical key."
  value       = { for k, s in azapi_resource.subnet : k => s.id }
}

output "subnet_names" {
  description = "Map of subnet names, keyed by subnet logical key."
  value       = { for k, s in azapi_resource.subnet : k => s.name }
}

# NSG & RT outputs (still maps)
output "network_security_group_ids" {
  description = "Map of NSG IDs, keyed by logical name."
  value       = { for k, n in azurerm_network_security_group.this : k => n.id }
}

output "route_table_ids" {
  description = "Map of route table IDs, keyed by logical name."
  value       = { for k, r in azurerm_route_table.this : k => r.id }
}

# Hub connectivity outputs
output "peering_spoke_to_hub_id" {
  description = "ID of the spoke-to-hub peering (hubvnet mode). Null if not created."
  value       = try(azurerm_virtual_network_peering.spoke_to_hub[0].id, null)
}

output "peering_hub_to_spoke_id" {
  description = "ID of the hub-to-spoke peering (hubvnet mode). Null if not created."
  value       = try(azurerm_virtual_network_peering.hub_to_spoke[0].id, null)
}

output "vwan_connection_id" {
  description = "ID of the vWAN hub connection (vwan mode). Null if not created."
  value       = try(azurerm_virtual_hub_connection.this[0].id, null)
}
