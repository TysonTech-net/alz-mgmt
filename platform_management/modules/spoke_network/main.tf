terraform {
  required_providers {
    azurerm = {
      source                = "hashicorp/azurerm"
      configuration_aliases = [azurerm.connectivity]
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 1.12.0"
    }
  }
}

##############################################
# Locals
##############################################
locals {
  # Merge common tags with specific resource tags
  merged_nsg_tags  = { for k, nsg in var.network_security_groups : k => merge(var.tags, try(nsg.tags, {})) }
  merged_rt_tags   = { for k, rt in var.route_tables : k => merge(var.tags, try(rt.tags, {})) }
  merged_vnet_tags = merge(var.tags, try(var.virtual_network_settings.tags, {}))

  # Add common routes to each route table definition
  processed_route_tables = {
    for rt_key, rt_config in var.route_tables : rt_key => merge(rt_config, {
      routes = concat(var.common_routes, rt_config.routes)
    })
  }

  # Subnets map (top-level input)
  subnets_map = var.subnets

  # Derive hub VNet name from ID only when in hub-vnet mode
  hub_vnet_name = var.hub_mode == "hubvnet" && var.hub_vnet_id != null ? basename(var.hub_vnet_id) : null

  # Effective vWAN connection settings for the single VNet (allow nulls; coalesce later)
  vwan_conn_effective = {
    enable = try(var.virtual_network_settings.vwan_connection_settings.enable, true)
    internet_security_enabled = try(var.virtual_network_settings.vwan_connection_settings.internet_security_enabled,
    try(var.vwan_connection_defaults.internet_security_enabled, false))
    associated_route_table_id = try(var.virtual_network_settings.vwan_connection_settings.associated_route_table_id,
    try(var.vwan_connection_defaults.associated_route_table_id, null))
    propagated_route_table_ids = try(var.virtual_network_settings.vwan_connection_settings.propagated_route_table_ids,
    try(var.vwan_connection_defaults.propagated_route_table_ids, null))
    propagated_route_labels = try(var.virtual_network_settings.vwan_connection_settings.propagated_route_labels,
    try(var.vwan_connection_defaults.propagated_route_labels, null))
  }

  enable_dns_autoreg = var.autoregistration_private_dns_zone_name != null && var.autoregistration_private_dns_zone_resource_group_name != null
}

##############################################
# Network Security Groups (in supplied RG)
##############################################
resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_groups

  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.merged_nsg_tags[each.key]

  dynamic "security_rule" {
    for_each = try(each.value.security_rules, [])
    iterator = rule
    content {
      name                                       = rule.value.name
      description                                = try(rule.value.description, null)
      priority                                   = rule.value.priority
      direction                                  = rule.value.direction
      access                                     = rule.value.access
      protocol                                   = rule.value.protocol
      source_port_range                          = try(rule.value.source_port_range, null)
      source_port_ranges                         = try(rule.value.source_port_ranges, [])
      destination_port_range                     = try(rule.value.destination_port_range, null)
      destination_port_ranges                    = try(rule.value.destination_port_ranges, [])
      source_address_prefix                      = try(rule.value.source_address_prefix, null)
      source_address_prefixes                    = try(rule.value.source_address_prefixes, [])
      source_application_security_group_ids      = try(rule.value.source_application_security_group_ids, [])
      destination_address_prefix                 = try(rule.value.destination_address_prefix, null)
      destination_address_prefixes               = try(rule.value.destination_address_prefixes, [])
      destination_application_security_group_ids = try(rule.value.destination_application_security_group_ids, [])
    }
  }
}

##############################################
# Route Tables (in supplied RG)
##############################################
resource "azurerm_route_table" "this" {
  for_each = local.processed_route_tables

  name                          = each.value.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = each.value.bgp_route_propagation_enabled
  tags                          = local.merged_rt_tags[each.key]

  dynamic "route" {
    for_each = each.value.routes
    iterator = rt_route
    content {
      name                   = rt_route.value.name
      address_prefix         = rt_route.value.address_prefix
      next_hop_type          = rt_route.value.next_hop_type
      next_hop_in_ip_address = lookup(rt_route.value, "next_hop_in_ip_address", null)
    }
  }
}

##############################################
# Single Virtual Network
##############################################
resource "azurerm_virtual_network" "this" {
  name                    = var.virtual_network_settings.name
  location                = var.location
  resource_group_name     = var.resource_group_name
  address_space           = var.virtual_network_settings.address_space
  dns_servers             = try(var.virtual_network_settings.dns_servers, null)
  tags                    = local.merged_vnet_tags
  flow_timeout_in_minutes = try(var.virtual_network_settings.flow_timeout_in_minutes, null)

  dynamic "ddos_protection_plan" {
    for_each = var.virtual_network_settings.ddos_protection_plan_id != null ? [1] : []
    content {
      id     = var.virtual_network_settings.ddos_protection_plan_id
      enable = try(var.virtual_network_settings.enable_ddos_protection, false)
    }
  }
}

##############################################
# Subnets via AzAPI (latest API)
##############################################
resource "azapi_resource" "subnet" {
  for_each = local.subnets_map

  type      = "Microsoft.Network/virtualNetworks/subnets@2023-11-01"
  name      = each.value.name
  parent_id = azurerm_virtual_network.this.id

  body = {
    properties = {
      addressPrefixes = each.value.address_prefixes

      # NSG association
      networkSecurityGroup = each.value.network_security_group_key != null ? {
        id = azurerm_network_security_group.this[each.value.network_security_group_key].id
      } : null

      # Route table association
      routeTable = each.value.route_table_key != null ? {
        id = azurerm_route_table.this[each.value.route_table_key].id
      } : null

      # Service endpoints
      serviceEndpoints = try(each.value.service_endpoints, null) != null ? [
        for se in each.value.service_endpoints : { service = se }
      ] : null

      # Delegations
      delegations = try(each.value.delegation, null) != null ? [
        for del in each.value.delegation : {
          name = del.name
          properties = {
            serviceName = del.service_delegation.name
          }
        }
      ] : null

      # Network policies
      privateEndpointNetworkPolicies    = try(each.value.private_endpoint_network_policies, "Enabled")
      privateLinkServiceNetworkPolicies = try(each.value.private_link_service_network_policies_enabled, "Enabled")

      defaultOutboundAccess = each.value.default_outbound_access_enabled
    }
  }

  # Ensure parent VNet exists first
  locks = [azurerm_virtual_network.this.id]

  lifecycle {
    ignore_changes = [
      body.properties.ipConfigurations,
      body.properties.privateEndpoints
    ]
  }
}

##############################################
# Spoke-to-Hub VNet Peering (hubvnet mode)
##############################################
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count = var.hub_mode == "hubvnet" && try(var.virtual_network_settings.peer_to_hub, true) ? 1 : 0

  name                         = format("peer-%s-to-hub-%s", trimsuffix(lower(var.virtual_network_settings.name), "-01"), var.location_short)
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = var.hub_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = try(var.virtual_network_settings.peer_to_hub_settings.allow_forwarded_traffic, true)
  allow_gateway_transit        = try(var.virtual_network_settings.peer_to_hub_settings.allow_gateway_transit, false)
  use_remote_gateways          = try(var.virtual_network_settings.peer_to_hub_settings.use_remote_gateways, true)
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider = azurerm.connectivity
  count    = var.hub_mode == "hubvnet" && try(var.virtual_network_settings.peer_to_hub, true) && try(var.virtual_network_settings.peer_to_hub_settings.create_reverse_peering, true) ? 1 : 0

  name                         = format("peer-hub-%s-to-%s", var.location_short, trimsuffix(lower(var.virtual_network_settings.name), "-01"))
  resource_group_name          = var.hub_resource_group_name
  virtual_network_name         = local.hub_vnet_name
  remote_virtual_network_id    = azurerm_virtual_network.this.id
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
  count    = local.enable_dns_autoreg ? 1 : 0

  name                  = substr(format("link-%s-to-%s", azurerm_virtual_network.this.name, replace(var.autoregistration_private_dns_zone_name, ".", "-")), 0, 80)
  resource_group_name   = var.autoregistration_private_dns_zone_resource_group_name
  private_dns_zone_name = var.autoregistration_private_dns_zone_name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = true
}

##############################################
# vWAN (vHub) Connection (vwan mode)
##############################################
resource "azurerm_virtual_hub_connection" "this" {
  count = var.hub_mode == "vwan" && try(var.virtual_network_settings.peer_to_hub, true) && try(local.vwan_conn_effective.enable, true) ? 1 : 0

  name                      = format("peering-%s", var.virtual_network_settings.name)
  virtual_hub_id            = var.virtual_hub_id
  remote_virtual_network_id = azurerm_virtual_network.this.id

  internet_security_enabled = try(local.vwan_conn_effective.internet_security_enabled, false)

  # Only render 'routing' when something is specified
  dynamic "routing" {
    for_each = (
      try(local.vwan_conn_effective.associated_route_table_id, null) != null
      || length(coalesce(local.vwan_conn_effective.propagated_route_table_ids, [])) > 0
      || length(coalesce(local.vwan_conn_effective.propagated_route_labels, [])) > 0
    ) ? [1] : []

    content {
      associated_route_table_id = try(local.vwan_conn_effective.associated_route_table_id, null)

      # Only render 'propagated_route_table' when at least one of ids/labels is set
      dynamic "propagated_route_table" {
        for_each = (
          length(coalesce(local.vwan_conn_effective.propagated_route_table_ids, [])) > 0
          || length(coalesce(local.vwan_conn_effective.propagated_route_labels, [])) > 0
        ) ? [1] : []

        content {
          route_table_ids = coalesce(local.vwan_conn_effective.propagated_route_table_ids, [])
          labels          = coalesce(local.vwan_conn_effective.propagated_route_labels, [])
        }
      }
    }
  }

  lifecycle {
    # Safety: clear error if vWAN inputs are missing
    precondition {
      condition     = var.hub_mode != "vwan" || length(coalesce(var.virtual_hub_id, "")) > 0
      error_message = "hub_mode is 'vwan' but virtual_hub_id was not provided."
    }
  }
}
