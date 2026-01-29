locals {
  # ---- IP Group IDs from logical roles ----
  ipg_hub               = try(var.ip_groups["hub"], null)
  ipg_identity_spokes   = try(var.ip_groups["identity_spokes"], null)
  ipg_spokes            = try(var.ip_groups["spokes"], null)
  ipg_onprem            = try(var.ip_groups["onprem"], null)
  ipg_domaincontrollers = try(var.ip_groups["domaincontrollers"], null)
  ipg_lm_collectors     = try(var.ip_groups["logicmonitor_collectors"], null)
  ipg_lm_targets        = try(var.ip_groups["logicmonitor_targets"], null)

  # ---- Settings with defaults merged ----
  internet_settings = merge(
    {
      enabled                          = true
      priority                         = 100
      enable_azure_services_network    = true
      enable_azure_services_app        = true
      enable_datadog_network_rules     = false
      enable_logicmonitor_egress_rules = false
    },
    var.internet_settings,
  )

  identity_settings = merge(
    {
      enabled                     = true
      priority                    = 110
      azure_bastion_subnet_prefix = null
    },
    var.identity_settings,
  )

  monitoring_settings = merge(
    {
      enabled  = false
      priority = 120
    },
    var.monitoring_settings,
  )

  # ---- Derived flags / lists ----
  internet_source_ip_groups = compact([
    local.ipg_hub,
    local.ipg_identity_spokes,
    local.ipg_spokes,
    local.ipg_onprem,
  ])

  create_internet_group   = local.internet_settings.enabled && length(local.internet_source_ip_groups) > 0
  create_identity_group   = local.identity_settings.enabled && local.ipg_identity_spokes != null
  create_monitoring_group = local.monitoring_settings.enabled && local.ipg_lm_collectors != null && local.ipg_lm_targets != null
}