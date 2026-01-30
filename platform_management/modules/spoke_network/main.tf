terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.connectivity]
    }
  }
}

##############################################
# Locals
##############################################
locals {
  merged_nsg_tags  = { for k, nsg in var.network_security_groups : k => merge(var.tags, try(nsg.tags, {})) }
  merged_rt_tags   = { for k, rt in var.route_tables : k => merge(var.tags, try(rt.tags, {})) }
  merged_vnet_tags = merge(var.tags, try(var.virtual_network_settings.tags, {}))

  processed_route_tables = {
    for rt_key, rt_config in var.route_tables : rt_key => merge(rt_config, {
      routes = concat(var.common_routes, rt_config.routes)
    })
  }

  subnets_map   = var.subnets
  hub_vnet_name = var.hub_mode == "hubvnet" && var.hub_vnet_id != null ? basename(var.hub_vnet_id) : null

  # Transform input subnet map into AVM subnet objects
  avm_subnets = {
    for key, subnet in local.subnets_map : key => {
      name                                  = subnet.name
      address_prefixes                      = subnet.address_prefixes
      private_endpoint_network_policies     = subnet.private_endpoint_network_policies
      private_link_service_network_policies = subnet.private_link_service_network_policies_enabled
      default_outbound_access_enabled       = subnet.default_outbound_access_enabled

      # Associations
      network_security_group = subnet.network_security_group_key != null ? {
        id = module.nsg[subnet.network_security_group_key].resource_id
      } : null
      route_table = subnet.route_table_key != null ? {
        id = module.rt[subnet.route_table_key].resource_id
      } : null

      # Delegations
      delegations = [
        for del in coalesce(subnet.delegation, []) : {
          name = del.name
          service_delegation = {
            name = del.service_delegation.name
          }
        }
      ]

      # Service endpoints
      service_endpoints_with_location = length(subnet.service_endpoints) > 0 ? [
        for se in subnet.service_endpoints : {
          service   = se
          locations = ["*"]
        }
      ] : []
    }
  }
  # Transform security rules to map keyed by rule name for AVM NSG module
  nsg_rules = {
    for k, nsg in var.network_security_groups :
    k => {
      for rule in try(nsg.security_rules, []) :
      rule.name => {
        access                                     = rule.access
        description                                = try(rule.description, null)
        destination_address_prefix                 = try(rule.destination_address_prefix, null)
        destination_address_prefixes               = try(rule.destination_address_prefixes, null) != null ? toset(rule.destination_address_prefixes) : null
        destination_application_security_group_ids = try(rule.destination_application_security_group_ids, null) != null ? toset(rule.destination_application_security_group_ids) : null
        destination_port_range                     = try(rule.destination_port_range, null)
        destination_port_ranges                    = try(rule.destination_port_ranges, null) != null ? toset(rule.destination_port_ranges) : null
        direction                                  = rule.direction
        name                                       = rule.name
        priority                                   = rule.priority
        protocol                                   = rule.protocol
        source_address_prefix                      = try(rule.source_address_prefix, null)
        source_address_prefixes                    = try(rule.source_address_prefixes, null) != null ? toset(rule.source_address_prefixes) : null
        source_application_security_group_ids      = try(rule.source_application_security_group_ids, null) != null ? toset(rule.source_application_security_group_ids) : null
        source_port_range                          = try(rule.source_port_range, null)
        source_port_ranges                         = try(rule.source_port_ranges, null) != null ? toset(rule.source_port_ranges) : null
      }
    }
  }
}

##############################################
# Route table routes mapped for AVM
##############################################
locals {
  rt_route_maps = {
    for rt_key, rt in local.processed_route_tables :
    rt_key => {
      for route in rt.routes :
      route.name => {
        name                   = route.name
        address_prefix         = route.address_prefix
        next_hop_type          = route.next_hop_type
        next_hop_in_ip_address = try(route.next_hop_in_ip_address, null)
      }
    }
  }
}

##############################################
# Network Security Groups (AVM)
##############################################
module "nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  for_each = var.network_security_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.merged_nsg_tags[each.key]
  security_rules      = local.nsg_rules[each.key]
  enable_telemetry    = false
}

##############################################
# Route Tables (AVM)
##############################################
module "rt" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  for_each = local.processed_route_tables

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = try(each.value.bgp_route_propagation_enabled, true)
  routes                        = local.rt_route_maps[each.key]
  tags                          = local.merged_rt_tags[each.key]
  enable_telemetry              = false
}

##############################################
# Virtual Network via AVM
##############################################
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  location  = var.location
  parent_id = var.resource_group_id
  name      = var.virtual_network_settings.name

  address_space           = var.virtual_network_settings.address_space
  dns_servers             = var.virtual_network_settings.dns_servers != null ? { dns_servers = var.virtual_network_settings.dns_servers } : null
  flow_timeout_in_minutes = try(var.virtual_network_settings.flow_timeout_in_minutes, null)
  tags                    = local.merged_vnet_tags

  ddos_protection_plan = var.virtual_network_settings.ddos_protection_plan_id != null ? {
    id     = var.virtual_network_settings.ddos_protection_plan_id
    enable = try(var.virtual_network_settings.enable_ddos_protection, false)
  } : null

  subnets = local.avm_subnets
}

##############################################
# Spoke-to-Hub Peering (hub-vnet mode only)
##############################################
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.hub_mode == "hubvnet" && try(var.virtual_network_settings.peer_to_hub, true) ? 1 : 0

  name                         = format("peer-%s-to-hub-%s", trimsuffix(lower(module.vnet.name), "-01"), var.location_short)
  resource_group_name          = var.resource_group_name
  virtual_network_name         = module.vnet.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = try(var.virtual_network_settings.peer_to_hub_settings.allow_forwarded_traffic, true)
  allow_gateway_transit        = try(var.virtual_network_settings.peer_to_hub_settings.allow_gateway_transit, false)
  use_remote_gateways          = try(var.virtual_network_settings.peer_to_hub_settings.use_remote_gateways, true)
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.connectivity
  count    = var.hub_mode == "hubvnet" && try(var.virtual_network_settings.peer_to_hub, true) && try(var.virtual_network_settings.peer_to_hub_settings.create_reverse_peering, true) ? 1 : 0

  name                         = format("peer-hub-%s-to-%s", var.location_short, trimsuffix(lower(module.vnet.name), "-01"))
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = local.hub_vnet_name
  remote_virtual_network_id    = module.vnet.resource_id
  allow_virtual_network_access = try(var.virtual_network_settings.peer_to_hub_settings.reverse_allow_virtual_network_access, true)
  allow_forwarded_traffic      = try(var.virtual_network_settings.peer_to_hub_settings.reverse_allow_forwarded_traffic, false)
  allow_gateway_transit        = try(var.virtual_network_settings.peer_to_hub_settings.reverse_allow_gateway_transit, true)
  use_remote_gateways          = try(var.virtual_network_settings.peer_to_hub_settings.reverse_use_remote_gateways, false)

  depends_on = [azurerm_virtual_network_peering.spoke_to_hub]
}

##############################################
# Private DNS auto-registration (optional)
##############################################
resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  provider = azurerm.connectivity
  count    = (var.autoregistration_private_dns_zone_name != null && var.autoregistration_private_dns_zone_resource_group_name != null) ? 1 : 0

  name                  = substr(format("link-%s-to-%s", module.vnet.name, replace(var.autoregistration_private_dns_zone_name, ".", "-")), 0, 80)
  resource_group_name   = var.autoregistration_private_dns_zone_resource_group_name
  private_dns_zone_name = var.autoregistration_private_dns_zone_name
  virtual_network_id    = module.vnet.resource_id
  registration_enabled  = true
}
