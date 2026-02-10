starter_locations = ["uksouth", "ukwest"]

# CAF region short codes override
starter_locations_short = {
  starter_location_01_short = "uks"
  starter_location_02_short = "ukw"
}

root_parent_management_group_name   = "VISPlatform"
amba_monitoring_resource_group_name = "rg-amba-prod-uks-001"
user_assigned_managed_identity_name = "id-amba-prod-uks-001"
action_group_email                  = ["liam.tysons@scc.com"]
#action_group_arm_role_id                         = []
#alert_severity                                   = ["Sev0", "Sev1", "Sev2", "Sev3", "Sev4"]
amba_disable_tag_name   = "amba_disable"
amba_disable_tag_values = ["true"]
#webhook_service_uri                              = ""
#event_hub_resource_id                            = ""
#function_resource_id                             = ""
#function_trigger_uri                             = ""
#logic_app_resource_id                            = ""
#logic_app_callback_url                           = ""
#bring_your_own_alert_processing_rule_resource_id = ""
#bring_your_own_action_group_resource_id          = ""
bring_your_own_user_assigned_managed_identity = false

tags = {
  "deployed_by" = "amba"
}