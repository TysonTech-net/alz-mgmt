###############################################################################
# SCC Custom: Hub VNet Address Spaces Output
###############################################################################
# Provides the resolved hub VNet address spaces for spoke UDR configuration.
# Uses templated_inputs which has the resolved values (not template placeholders).
###############################################################################

output "scc_hub_vnet_address_spaces" {
  description = "Hub VNet address spaces per region key (resolved from config, for spoke UDR configuration)"
  value = local.connectivity_hub_and_spoke_vnet_enabled ? {
    for key, hub in module.config.outputs.hub_virtual_networks : key => hub.hub_virtual_network.address_space
  } : null
}

output "scc_bastion_subnet_address_prefixes" {
  description = "Bastion subnet address prefixes per region key (for spoke UDR bypass routes)"
  value = local.connectivity_hub_and_spoke_vnet_enabled ? {
    for key, hub in module.config.outputs.hub_virtual_networks : key =>
    try(hub.bastion.subnet_address_prefix, null)
  } : null
}

output "scc_firewall_subnet_address_prefixes" {
  description = "Firewall subnet address prefixes per region key (for spoke NSG inbound rules)"
  value = local.connectivity_hub_and_spoke_vnet_enabled ? {
    for key, hub in module.config.outputs.hub_virtual_networks : key =>
    try(hub.firewall.subnet_address_prefix, null)
  } : null
}
