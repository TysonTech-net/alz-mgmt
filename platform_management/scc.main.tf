module "regions" {
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "~> 0.9"
  enable_telemetry = false
}

locals {
  primary_location       = var.starter_locations[0]
  primary_location_short = module.regions.regions_by_name_or_display_name[local.primary_location].geo_code

  base_name_primary = "shared-management-prod-${local.primary_location_short}"

  log_analytics_workspace_id         = module.config.custom_replacements.log_analytics_workspace_id
  log_analytics_workspace_name       = module.config.custom_replacements.log_analytics_workspace_name
  management_log_resource_group_name = module.config.custom_replacements.management_resource_group_name

  baseline_tags = {
    deployed_by = "terraform"
  }

  final_tags = merge(
    local.baseline_tags,
    coalesce(var.tags, {})
  )
}