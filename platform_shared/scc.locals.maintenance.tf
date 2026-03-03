###############################################################################
# SCC Custom: Maintenance Configuration Dynamic Scope Subscriptions
###############################################################################
# Automatically includes all platform subscriptions in maintenance dynamic scopes
# based on the subscription_ids variable.
###############################################################################

locals {
  # Build list of subscription IDs from the subscription_ids map
  scc_maintenance_platform_subscriptions = [
    for key, sub_id in var.subscription_ids : sub_id
  ]
}
