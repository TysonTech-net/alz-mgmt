###############################################################################
# Firewall Rules Module
# Creates IP Groups and Rule Collection Groups for each region
###############################################################################

module "firewall_rules" {
  source   = "../../alz-modules/modules/scc-azure-platform-firewall"
  for_each = var.regions

  # Reference existing firewall policy from remote state
  firewall_policy_id = local.firewall_policy_ids[each.value.location]

  # Basic config
  environment         = var.naming.env
  workload            = var.naming.workload
  location            = each.value.location
  resource_group_name = each.value.resource_group_name

  azure_bastion_subnet_prefix = each.value.bastion_subnet_prefix

  # IP groups from tfvars (keyed by region: primary/secondary)
  # Update ip_groups in .auto.tfvars to change CIDRs
  ip_groups        = var.ip_groups[each.key]
  custom_ip_groups = try(var.custom_ip_groups[each.key], {})

  # Rule settings from tfvars (override module defaults as needed)
  rule_settings = var.rule_settings

  # Custom rules from tfvars (keyed by region: primary/secondary)
  custom_dnat_collections        = try(var.custom_dnat_collections[each.key], {})
  custom_network_collections     = try(var.custom_network_collections[each.key], {})
  custom_application_collections = try(var.custom_application_collections[each.key], {})

  tags = var.tags
}
