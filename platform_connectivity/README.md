## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_avm-res-network-dnszone"></a> [avm-res-network-dnszone](#module\_avm-res-network-dnszone) | Azure/avm-res-network-dnszone/azurerm | 0.2.1 |
| <a name="module_regions"></a> [regions](#module\_regions) | Azure/avm-utl-regions/azurerm | ~> 0.9 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_hubs"></a> [hubs](#input\_hubs) | Per-region hub/spoke settings (hubvnet mode only). Key is logical hub name. | <pre>map(object({<br/>    location                = string<br/>    location_short          = optional(string)<br/>    resource_group_name     = string<br/>    hub_vnet_id             = string<br/>    hub_resource_group_name = string<br/>    virtual_network_settings = object({<br/>      name                    = string<br/>      address_space           = list(string)<br/>      dns_servers             = optional(list(string), [])<br/>      flow_timeout_in_minutes = optional(number)<br/>      ddos_protection_plan_id = optional(string)<br/>      enable_ddos_protection  = optional(bool, false)<br/>      peer_to_hub             = optional(bool, true)<br/>      peer_to_hub_settings    = optional(any, {})<br/>    })<br/>    subnets                 = map(any)<br/>    network_security_groups = map(any)<br/>    route_tables            = map(any)<br/>    common_routes           = list(any)<br/>    tags                    = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_naming"></a> [naming](#input\_naming) | Base naming tokens. | <pre>object({<br/>    env      = string<br/>    workload = string<br/>    instance = string<br/>  })</pre> | n/a | yes |
| <a name="input_network_dns_zone"></a> [network\_dns\_zone](#input\_network\_dns\_zone) | Map of DNS Zones and their associated records to deploy. | <pre>map(object({<br/>    name                = string<br/>    resource_group_name = string<br/>    tags                = optional(map(string))<br/>    enable_telemetry    = optional(bool, true)<br/><br/>    # Sub-variables (Record Sets)<br/>    a_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records             = optional(list(string))<br/>      target_resource_id  = optional(string)<br/>      tags                = optional(map(string), null)<br/>    })), {})<br/><br/>    aaaa_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records             = optional(list(string))<br/>      target_resource_id  = optional(string)<br/>      tags                = optional(map(string), null)<br/>    })), {})<br/><br/>    caa_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      record = map(object({<br/>        flags = string<br/>        tag   = string<br/>        value = string<br/>      }))<br/>      tags = optional(map(string), null)<br/>    })), {})<br/><br/>    cname_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      record              = string<br/>      tags                = optional(map(string), null)<br/>      target_resource_id  = optional(string)<br/>    })), {})<br/><br/>    mx_records = optional(map(object({<br/>      name                = optional(string, "@")<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records = map(object({<br/>        preference = number<br/>        exchange   = string<br/>      }))<br/>      tags = optional(map(string), null)<br/>    })), {})<br/><br/>    ns_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records             = list(string)<br/>      tags                = optional(map(string), null)<br/>    })), {})<br/><br/>    ptr_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records             = list(string)<br/>      tags                = optional(map(string), null)<br/>    })), {})<br/><br/>    srv_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records = map(object({<br/>        priority = number<br/>        weight   = number<br/>        port     = number<br/>        target   = string<br/>      }))<br/>      tags = optional(map(string), null)<br/>    })), {})<br/><br/>    txt_records = optional(map(object({<br/>      name                = string<br/>      resource_group_name = string<br/>      zone_name           = string<br/>      ttl                 = number<br/>      records = map(object({<br/>        value = string<br/>      }))<br/>      tags = optional(map(string), null)<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_starter_locations"></a> [starter\_locations](#input\_starter\_locations) | Regions to deploy hubs into (order defines primary/secondary, etc.). | `list(string)` | n/a | yes |
| <a name="input_starter_locations_short"></a> [starter\_locations\_short](#input\_starter\_locations\_short) | Optional map of region to short code (overrides auto-derived). | `map(string)` | `{}` | no |
| <a name="input_subscription_ids"></a> [subscription\_ids](#input\_subscription\_ids) | Subscription IDs used by this stack. | `map(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Base tags applied to all resources. | `map(string)` | `{}` | no |
| <a name="input_vm_admin_password"></a> [vm\_admin\_password](#input\_vm\_admin\_password) | Admin password for VMs. | `string` | `""` | no |
| <a name="input_vms"></a> [vms](#input\_vms) | Virtual machines to deploy (keyed by name). | <pre>map(object({<br/>    name                = string<br/>    hub_key             = string<br/>    resource_group_name = string<br/>    subnet_key          = string<br/>    private_ip_address  = string<br/>    sku_size            = string<br/>    zone                = optional(number, 1)<br/>    license_type        = optional(string, "Windows_Server")<br/>    image = object({<br/>      publisher = string<br/>      offer     = string<br/>      sku       = string<br/>      version   = optional(string, "latest")<br/>    })<br/>    os_disk = object({<br/>      disk_size_gb         = number<br/>      storage_account_type = optional(string, "Premium_LRS")<br/>      caching              = optional(string, "ReadWrite")<br/>    })<br/>    admin_username = optional(string, "azureadmin")<br/>    extensions     = optional(map(any), {})<br/>    tags           = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

No outputs.
