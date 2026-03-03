###############################################################################
# Module - Workload Resources Stack
###############################################################################

module "workload_resources" {
  source = "../../alz-modules/stacks/scc-workload-resources"

  # Subscription
  subscription = var.subscription

  # Naming Convention (for auto-generated resource names)
  naming = var.naming

  # Connectivity
  connectivity_type     = var.connectivity_type
  platform_shared_state = var.platform_shared_state
  hub_region_mapping    = var.hub_region_mapping

  # Tags and Telemetry
  tags             = var.tags
  enable_telemetry = var.enable_telemetry

  # Default Resource Toggles
  enable_default_umi             = var.enable_default_umi
  enable_default_nsg             = var.enable_default_nsg
  enable_default_route_table     = var.enable_default_route_table
  enable_default_role_assignment = var.enable_default_role_assignment
  default_contributor_principal_id = var.default_contributor_principal_id

  # Vending Configuration (Resource Groups, VNets, etc.)
  vending = var.vending

  # Management Configuration (RSV, Key Vault, etc.)
  management = var.management

  # Compute Configuration (Virtual Machines)
  compute_enabled = var.compute_enabled
  compute         = var.compute
}
