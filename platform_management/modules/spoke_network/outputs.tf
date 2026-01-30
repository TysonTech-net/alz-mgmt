# Single VNet outputs
output "virtual_network_id" {
  description = "ID of the virtual network."
  value       = module.vnet.resource_id
}

output "virtual_network_name" {
  description = "Name of the virtual network."
  value       = module.vnet.name
}

# Subnet outputs (keyed by subnet logical key)
output "subnet_ids" {
  description = "Map of subnet IDs, keyed by subnet logical key."
  value       = { for k, s in module.vnet.subnets : k => s.resource_id }
}

output "subnet_names" {
  description = "Map of subnet names, keyed by subnet logical key."
  value       = { for k, s in module.vnet.subnets : k => s.name }
}

# NSG & RT outputs (still maps)
output "network_security_group_ids" {
  description = "Map of NSG IDs, keyed by logical name."
  value       = { for k, n in module.nsg : k => n.resource_id }
}

output "route_table_ids" {
  description = "Map of route table IDs, keyed by logical name."
  value       = { for k, r in module.rt : k => r.resource_id }
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
  value       = null
}
