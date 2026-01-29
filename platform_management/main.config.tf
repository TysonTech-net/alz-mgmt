module "config" {
  source = "../_modules-accelerator/config-templating"

  starter_locations               = var.starter_locations
  starter_locations_short         = var.starter_locations_short
  subscription_id_connectivity    = try(var.subscription_ids["connectivity"], var.subscription_id_connectivity)
  subscription_id_identity        = try(var.subscription_ids["identity"], var.subscription_id_identity)
  subscription_id_management      = try(var.subscription_ids["management"], var.subscription_id_management)
  subscription_id_security        = try(var.subscription_ids["security"], "")
  root_parent_management_group_id = var.root_parent_management_group_id

  custom_replacements = var.custom_replacements

  inputs = {
    management_resource_settings = var.management_resource_settings
    management_group_settings    = var.management_group_settings
    tags                         = local.final_tags # SCC mod
  }

  enable_telemetry = var.enable_telemetry
}