## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.71.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_firewall_rules"></a> [firewall\_rules](#module\_firewall\_rules) | ../../alz-modules/modules/scc-azure-platform-firewall | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_remote_state.platform_shared](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/data-sources/remote_state) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connectivity_subscription_id"></a> [connectivity\_subscription\_id](#input\_connectivity\_subscription\_id) | Subscription ID for the connectivity subscription | `string` | n/a | yes |
| <a name="input_custom_application_collections"></a> [custom\_application\_collections](#input\_custom\_application\_collections) | Custom application rule collections per region with configurable names and priorities | <pre>map(map(object({<br/>    priority = number<br/>    rules = list(object({<br/>      name                  = string<br/>      source_addresses      = optional(list(string))<br/>      source_ip_groups      = optional(list(string))<br/>      destination_fqdns     = optional(list(string))<br/>      destination_fqdn_tags = optional(list(string))<br/>      protocols = list(object({<br/>        type = string # Http, Https, Mssql<br/>        port = number<br/>      }))<br/>    }))<br/>  })))</pre> | `{}` | no |
| <a name="input_custom_dnat_collections"></a> [custom\_dnat\_collections](#input\_custom\_dnat\_collections) | Custom DNAT rule collections per region with configurable names and priorities | <pre>map(map(object({<br/>    priority = number<br/>    rules = list(object({<br/>      name                = string<br/>      source_addresses    = optional(list(string), ["*"])<br/>      destination_address = string # Firewall public IP<br/>      destination_port    = string<br/>      translated_address  = string # Internal target IP<br/>      translated_port     = string<br/>      protocols           = optional(list(string), ["TCP"])<br/>    }))<br/>  })))</pre> | `{}` | no |
| <a name="input_custom_ip_groups"></a> [custom\_ip\_groups](#input\_custom\_ip\_groups) | Custom IP groups per region for use in custom firewall rules | `map(map(set(string)))` | `{}` | no |
| <a name="input_custom_network_collections"></a> [custom\_network\_collections](#input\_custom\_network\_collections) | Custom network rule collections per region with configurable names and priorities | <pre>map(map(object({<br/>    priority = number<br/>    rules = list(object({<br/>      name                  = string<br/>      source_addresses      = optional(list(string))<br/>      source_ip_groups      = optional(list(string))<br/>      destination_addresses = optional(list(string))<br/>      destination_ip_groups = optional(list(string))<br/>      destination_fqdns     = optional(list(string))<br/>      destination_ports     = list(string)<br/>      protocols             = list(string) # TCP, UDP, ICMP, Any<br/>    }))<br/>  })))</pre> | `{}` | no |
| <a name="input_hub_region_mapping"></a> [hub\_region\_mapping](#input\_hub\_region\_mapping) | Map hub keys to region names (e.g., primary = uksouth) | `map(string)` | <pre>{<br/>  "primary": "uksouth",<br/>  "secondary": "ukwest"<br/>}</pre> | no |
| <a name="input_ip_groups"></a> [ip\_groups](#input\_ip\_groups) | IP group CIDRs per region - update these to change firewall rules | <pre>map(object({<br/>    # Required - Domain controller subnets<br/>    identity_dcs = set(string)<br/><br/>    # All Azure spoke networks (get ADDS access + spoke ↔ on_prem traffic)<br/>    spokes = optional(set(string), [])<br/><br/>    # On-premises networks via VPN/ExpressRoute<br/>    on_prem = optional(set(string), [])<br/><br/>    # External DCs for AD replication/enrollment<br/>    replication_dcs = optional(set(string), [])<br/><br/>    # Spoke networks in other regions (for cross-region connectivity)<br/>    remote_spokes = optional(set(string), [])<br/><br/>    # LogicMonitor monitoring<br/>    logicmonitor = optional(object({<br/>      collectors = optional(set(string), [])<br/>      targets    = optional(set(string), [])<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_naming"></a> [naming](#input\_naming) | Naming tokens for resource naming | <pre>object({<br/>    env      = string<br/>    workload = string<br/>    instance = string<br/>  })</pre> | n/a | yes |
| <a name="input_platform_shared_state"></a> [platform\_shared\_state](#input\_platform\_shared\_state) | Remote state configuration for platform\_shared | <pre>object({<br/>    resource_group_name  = string<br/>    storage_account_name = string<br/>    container_name       = string<br/>    key                  = string<br/>    subscription_id      = string<br/>  })</pre> | n/a | yes |
| <a name="input_regions"></a> [regions](#input\_regions) | Per-region basic configuration | <pre>map(object({<br/>    location              = string<br/>    resource_group_name   = string<br/>    bastion_subnet_prefix = string<br/>  }))</pre> | n/a | yes |
| <a name="input_rule_settings"></a> [rule\_settings](#input\_rule\_settings) | Rule enablement and priority settings | <pre>object({<br/>    # Azure management rules<br/>    enable_az_mgmt_rules            = optional(bool)<br/>    enable_az_mgmt_app_rules        = optional(bool)<br/>    enable_ntp                      = optional(bool)<br/><br/>    # LogicMonitor rules<br/>    enable_logicmonitor_rules       = optional(bool)<br/>    enable_monitoring_windows       = optional(bool)<br/>    enable_monitoring_linux         = optional(bool)<br/><br/>    # Security monitoring (Sentinel, Tenable, syslog, CEF, WEF)<br/>    enable_security_monitoring      = optional(bool)<br/><br/>    # Internet outbound<br/>    enable_internet_outbound        = optional(bool)<br/><br/>    # Troubleshooting<br/>    enable_troubleshooting          = optional(bool)<br/>    enable_troubleshooting_internet = optional(bool)<br/><br/>    # Spoke traffic<br/>    enable_spoke_to_spoke           = optional(bool)<br/>    enable_cross_region_spokes      = optional(bool)  # Cross-region spoke ↔ remote spoke traffic<br/>    enable_icmp                     = optional(bool)<br/><br/>    # On-prem traffic<br/>    enable_spokes_to_on_prem        = optional(bool)<br/>    enable_on_prem_adds             = optional(bool)<br/>    enable_on_prem_kerberos         = optional(bool)<br/><br/>    # Rule collection group priorities<br/>    # Order: DNAT(100) → Troubleshoot(200) → Identity(300) → Internet Net(400) / App(410) → Platform Net(500) / App(510) → Monitoring(600) → Custom(700-800)<br/>    rcg_troubleshooting_priority        = optional(number)<br/>    rcg_identity_priority               = optional(number)<br/>    rcg_internet_network_priority       = optional(number)<br/>    rcg_internet_application_priority   = optional(number)<br/>    rcg_platform_network_priority       = optional(number)<br/>    rcg_platform_application_priority   = optional(number)<br/>    rcg_monitoring_priority             = optional(number)<br/>    rcg_custom_network_priority         = optional(number)<br/>    rcg_custom_application_priority     = optional(number)<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

No outputs.
