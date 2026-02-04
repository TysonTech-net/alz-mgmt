###############################################
# Workload Stack (Network + Management)
###############################################

module "workload_stack" {
  source = "git@github.com:TysonTech-net/alz-modules.git//stacks/scc-workload-stack?ref=main"

  providers = {
    azurerm              = azurerm
    azurerm.connectivity = azurerm.connectivity
  }

  # Subscription (required by stack)
  subscription_id = var.subscription_ids["identity"]

  # Naming
  workload        = var.naming.workload
  environment     = var.naming.env
  customer_prefix = var.customer_prefix
  location        = var.primary_location

  # Tags
  tags = local.base_tags

  # Network Configuration
  create_network_rg = true
  create_vnet       = true
  virtual_network   = var.virtual_network
  subnets           = var.subnets
  network_security_groups = var.network_security_groups
  route_tables      = var.route_tables
  common_routes     = var.common_routes

  # Hub Connectivity (vWAN mode)
  hub_mode = "vwan"
  connectivity = {
    virtual_hub_id = var.virtual_hub_id
    vwan_routing = {
      internet_security_enabled = true
    }
  }

  # Private DNS
  private_dns = {
    zone_ids                     = var.private_dns_zone_ids
    forwarding_ruleset_id        = var.dns_forwarding_ruleset_id
    connectivity_subscription_id = var.subscription_ids["connectivity"]
  }

  # Management Toggles
  enable_resources_iaas_mgmt     = true
  create_management_rg           = var.create_management_rg
  create_log_analytics_workspace = var.create_log_analytics_workspace
  create_management_kv           = var.create_management_kv
  create_backup_rsv              = var.create_backup_rsv
}
