###############################################
# Regions Module
###############################################

module "regions" {
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "~> 0.9"
  enable_telemetry = false
}

###############################################
# Locals
###############################################

locals {
  location_short = coalesce(
    var.primary_location_short,
    try(module.regions.regions_by_name_or_display_name[var.primary_location].geo_code, null),
    try(module.regions.regions_by_name_or_display_name[var.primary_location].short_name, var.primary_location)
  )

  base_tags = merge(
    {
      deployed_by = "terraform"
      env         = var.naming.env
      workload    = var.naming.workload
      instance    = var.naming.instance
      region      = var.primary_location
    },
    coalesce(var.tags, {})
  )
}
