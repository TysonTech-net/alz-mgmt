###############################################################################
# SCC Custom: Maintenance Configuration Outputs
###############################################################################
# These outputs expose maintenance configuration resource IDs for use by
# workload subscriptions when assigning VMs to patch groups.
###############################################################################

output "scc_maintenance_configuration_resource_ids" {
  value       = { for k, v in module.scc_maintenance_configuration : k => v.resource_id }
  description = "A map of maintenance configuration keys to their resource IDs. Use these IDs in workload VM configurations."
}

output "scc_maintenance_configuration_names" {
  value       = { for k, v in module.scc_maintenance_configuration : k => v.name }
  description = "A map of maintenance configuration keys to their names."
}
