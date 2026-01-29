locals {
  hub_mode = "hubvnet" # this stack peers to existing hub VNets (non-vWAN)
}

resource "azurerm_resource_group" "network" {
  for_each = local.hubs

  name     = each.value.resource_group_name
  location = each.value.location
  tags     = each.value.tags
}

module "spoke_network" {
  source = "./modules/spoke_network"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  for_each = local.hubs

  location       = each.value.location
  location_short = each.value.location_short

  resource_group_name      = azurerm_resource_group.network[each.key].name
  virtual_network_settings = each.value.virtual_network_settings
  subnets                  = each.value.subnets
  network_security_groups  = each.value.network_security_groups
  route_tables             = each.value.route_tables
  common_routes            = each.value.common_routes

  hub_mode                = local.hub_mode
  hub_vnet_id             = each.value.hub_vnet_id
  hub_resource_group_name = each.value.hub_resource_group_name

  tags = each.value.tags
}
