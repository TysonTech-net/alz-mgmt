locals {
  use_vwan    = var.connectivity_mode == "vwan"
  use_hubvnet = var.connectivity_mode == "hubvnet"
}

# vHub lookup
data "azurerm_virtual_hub" "primary" {
  provider            = azurerm.connectivity
  count               = local.use_vwan ? 1 : 0
  name                = var.connectivity_vhub_primary.name
  resource_group_name = var.connectivity_vhub_primary.resource_group_name
}

# Hub VNet lookup
data "azurerm_virtual_network" "primary" {
  provider            = azurerm.connectivity
  count               = local.use_hubvnet ? 1 : 0
  name                = var.connectivity_hub_vnet.name
  resource_group_name = var.connectivity_hub_vnet.resource_group_name
}

locals {
  virtual_hub_id          = local.use_vwan ? data.azurerm_virtual_hub.primary[0].id : null
  hub_vnet_id             = local.use_hubvnet ? data.azurerm_virtual_network.primary[0].id : null
  hub_resource_group_name = local.use_hubvnet ? var.connectivity_hub_vnet.resource_group_name : null
}

resource "azurerm_resource_group" "network_primary" {
  name     = var.spoke_network_config_primary.resource_group.name
  location = local.primary_location
  tags = merge(
    local.final_tags,
    var.spoke_network_config_primary.resource_group.tags
  )
}

module "spoke_network_primary" {
  source = "git@github.com:TysonTech-net/alz-modules.git//spoke_network?ref=main"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  location       = local.primary_location
  location_short = local.primary_location_short

  resource_group_name      = azurerm_resource_group.network_primary.name
  virtual_network_settings = var.spoke_network_config_primary.virtual_network_settings
  subnets                  = var.spoke_network_config_primary.subnets
  network_security_groups  = var.spoke_network_config_primary.network_security_groups
  route_tables             = var.spoke_network_config_primary.route_tables
  common_routes            = var.spoke_network_config_primary.common_routes

  # ---- Connectivity selection ----
  hub_mode                = var.connectivity_mode
  virtual_hub_id          = local.virtual_hub_id
  hub_vnet_id             = local.hub_vnet_id
  hub_resource_group_name = local.hub_resource_group_name

  # Optional DNS auto-registration (unchanged)
  autoregistration_private_dns_zone_name                = null
  autoregistration_private_dns_zone_resource_group_name = null

  tags = merge(
    local.final_tags,
    var.spoke_network_config_primary.tags
  )
}