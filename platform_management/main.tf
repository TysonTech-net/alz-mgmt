module "regions" {
  source           = "Azure/avm-utl-regions/azurerm"
  version          = "~> 0.9"
  enable_telemetry = false
}

locals {
  # Build lookup of short codes, preferring user-provided values, else regions module geo_code/short_name
  location_short_lookup = {
    for loc in var.starter_locations :
    loc => coalesce(
      try(var.starter_locations_short[loc], null),
      try(var.starter_locations_short["starter_${index(var.starter_locations, loc) + 1}_short"], null),
      try(module.regions.regions_by_name_or_display_name[loc].geo_code, null),
      try(module.regions.regions_by_name_or_display_name[loc].short_name, loc)
    )
  }

  base_tags = merge(
    {
      deployed_by = "terraform"
      env         = var.naming.env
      workload    = var.naming.workload
      instance    = var.naming.instance
    },
    coalesce(var.tags, {})
  )

  hubs = {
    for key, hub in var.hubs :
    key => merge(hub, {
      location_short = coalesce(hub.location_short, local.location_short_lookup[hub.location])
      tags = merge(
        local.base_tags,
        {
          region       = hub.location
          region_short = coalesce(hub.location_short, local.location_short_lookup[hub.location])
          hub_key      = key
        },
        coalesce(hub.tags, {})
      )
      name_prefix = "${var.naming.workload}-${var.naming.env}"
    })
  }
}
