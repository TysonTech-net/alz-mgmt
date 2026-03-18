## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12 |
| <a name="requirement_alz"></a> [alz](#requirement\_alz) | 0.20.0 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 2.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | 2.8.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amba_alz"></a> [amba\_alz](#module\_amba\_alz) | Azure/avm-ptn-monitoring-amba-alz/azurerm | n/a |
| <a name="module_amba_policy"></a> [amba\_policy](#module\_amba\_policy) | Azure/avm-ptn-alz/azurerm | 0.12.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_client_config.current](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_action_group_arm_role_id"></a> [action\_group\_arm\_role\_id](#input\_action\_group\_arm\_role\_id) | ARM role ID for AMBA action group (optional). | `list(string)` | `[]` | no |
| <a name="input_action_group_email"></a> [action\_group\_email](#input\_action\_group\_email) | Email for AMBA action group notifications. | `list(string)` | `[]` | no |
| <a name="input_alert_severity"></a> [alert\_severity](#input\_alert\_severity) | Severity levels for alerts notifications to be sent. | `list(string)` | <pre>[<br/>  "Sev0",<br/>  "Sev1",<br/>  "Sev2",<br/>  "Sev3",<br/>  "Sev4"<br/>]</pre> | no |
| <a name="input_amba_disable_tag_name"></a> [amba\_disable\_tag\_name](#input\_amba\_disable\_tag\_name) | Tag name to disable AMBA policies. | `string` | `"amba_disable"` | no |
| <a name="input_amba_disable_tag_values"></a> [amba\_disable\_tag\_values](#input\_amba\_disable\_tag\_values) | Tag values to disable AMBA policies. | `list(string)` | <pre>[<br/>  "true"<br/>]</pre> | no |
| <a name="input_amba_monitoring_resource_group_name"></a> [amba\_monitoring\_resource\_group\_name](#input\_amba\_monitoring\_resource\_group\_name) | Resource group name for AMBA monitoring resources. | `string` | n/a | yes |
| <a name="input_bring_your_own_action_group_resource_id"></a> [bring\_your\_own\_action\_group\_resource\_id](#input\_bring\_your\_own\_action\_group\_resource\_id) | BYO action group resource ID (optional). | `list(string)` | `[]` | no |
| <a name="input_bring_your_own_alert_processing_rule_resource_id"></a> [bring\_your\_own\_alert\_processing\_rule\_resource\_id](#input\_bring\_your\_own\_alert\_processing\_rule\_resource\_id) | BYO alert processing rule resource ID (optional). | `string` | `""` | no |
| <a name="input_bring_your_own_user_assigned_managed_identity"></a> [bring\_your\_own\_user\_assigned\_managed\_identity](#input\_bring\_your\_own\_user\_assigned\_managed\_identity) | Set true to use an existing AMBA managed identity instead of deploying one. | `bool` | `false` | no |
| <a name="input_bring_your_own_user_assigned_managed_identity_resource_id"></a> [bring\_your\_own\_user\_assigned\_managed\_identity\_resource\_id](#input\_bring\_your\_own\_user\_assigned\_managed\_identity\_resource\_id) | Resource ID of existing managed identity when bring\_your\_own is true. | `string` | `""` | no |
| <a name="input_event_hub_resource_id"></a> [event\_hub\_resource\_id](#input\_event\_hub\_resource\_id) | Event Hub resource ID for AMBA (optional). | `list(string)` | `[]` | no |
| <a name="input_function_resource_id"></a> [function\_resource\_id](#input\_function\_resource\_id) | Function app resource ID for AMBA (optional). | `string` | `""` | no |
| <a name="input_function_trigger_uri"></a> [function\_trigger\_uri](#input\_function\_trigger\_uri) | Function trigger URL for AMBA (optional). | `string` | `""` | no |
| <a name="input_logic_app_callback_url"></a> [logic\_app\_callback\_url](#input\_logic\_app\_callback\_url) | Logic App callback URL for AMBA (optional). | `string` | `""` | no |
| <a name="input_logic_app_resource_id"></a> [logic\_app\_resource\_id](#input\_logic\_app\_resource\_id) | Logic App resource ID for AMBA (optional). | `string` | `""` | no |
| <a name="input_management_subscription_id"></a> [management\_subscription\_id](#input\_management\_subscription\_id) | Management subscription ID override for AMBA (optional). | `string` | `null` | no |
| <a name="input_root_parent_management_group_name"></a> [root\_parent\_management\_group\_name](#input\_root\_parent\_management\_group\_name) | Root management group name for AMBA policy assignment. | `string` | n/a | yes |
| <a name="input_starter_locations"></a> [starter\_locations](#input\_starter\_locations) | The default for Azure resources. (e.g 'uksouth') | `list(string)` | n/a | yes |
| <a name="input_starter_locations_short"></a> [starter\_locations\_short](#input\_starter\_locations\_short) | Optional overrides for the starter location short codes.<br/><br/>Keys should match the built-in replacement names used in the examples, for example:<br/>- starter\_location\_01\_short<br/>- starter\_location\_02\_short<br/><br/>If not provided, short codes are derived from the regions module using geo\_code when available, falling back to short\_name when no geo\_code is published. | `map(string)` | `{}` | no |
| <a name="input_subscription_ids"></a> [subscription\_ids](#input\_subscription\_ids) | The list of subscription IDs to deploy the Platform Landing Zones into | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Tags of the resource. | `map(string)` | `null` | no |
| <a name="input_user_assigned_managed_identity_name"></a> [user\_assigned\_managed\_identity\_name](#input\_user\_assigned\_managed\_identity\_name) | Name of the AMBA user-assigned managed identity. | `string` | n/a | yes |
| <a name="input_webhook_service_uri"></a> [webhook\_service\_uri](#input\_webhook\_service\_uri) | Webhook URI for AMBA action group (optional). | `list(string)` | `[]` | no |

## Outputs

No outputs.
