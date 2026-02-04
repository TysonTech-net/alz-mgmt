module "avm-res-network-dnszone" {
  source  = "Azure/avm-res-network-dnszone/azurerm"
  version = "0.2.1"

  for_each = var.network_dns_zone

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  tags                = var.tags
  enable_telemetry    = each.value.enable_telemetry

  a_records     = each.value.a_records
  aaaa_records  = each.value.aaaa_records
  caa_records   = each.value.caa_records
  cname_records = each.value.cname_records
  mx_records    = each.value.mx_records
  ns_records    = each.value.ns_records
  ptr_records   = each.value.ptr_records
  srv_records   = each.value.srv_records
  txt_records   = each.value.txt_records
}