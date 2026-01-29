module "regions" {
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "~> 0.9"
  enable_telemetry = false
}

locals {
  primary_location       = var.starter_locations[0]
  primary_location_short = module.regions.regions_by_name_or_display_name[local.primary_location].geo_code

  base_name_primary = "shared-security-prod-${local.primary_location_short}"

  baseline_tags = {
    deployed_by = "terraform"
  }

  final_tags = merge(
    local.baseline_tags,
    coalesce(var.tags, {})
  )
}