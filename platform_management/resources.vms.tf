resource "azurerm_resource_group" "vm" {
  for_each = {
    for k, vm in var.vms : k => vm
  }

  name     = each.value.resource_group_name
  location = local.hubs[each.value.hub_key].location
  tags     = merge(local.hubs[each.value.hub_key].tags, try(each.value.tags, {}))
}

module "windows_vms" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "~> 0.20"

  for_each = { for k, vm in var.vms : k => vm if vm != null }

  name                = each.value.name
  location            = local.hubs[each.value.hub_key].location
  resource_group_name = azurerm_resource_group.vm[each.key].name
  sku_size            = each.value.sku_size
  zone                = tostring(try(each.value.zone, 1))

  source_image_reference = {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = try(each.value.image.version, "latest")
  }

  os_disk = {
    caching              = try(each.value.os_disk.caching, "ReadWrite")
    storage_account_type = try(each.value.os_disk.storage_account_type, "Premium_LRS")
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  network_interfaces = {
    primary = {
      name = "nic-${each.value.name}-001"
      ip_configurations = {
        ipconfig1 = {
          name                          = "ipconfig1"
          is_primary_ipconfiguration    = true
          private_ip_address_allocation = "Static"
          private_ip_address            = each.value.private_ip_address
          private_ip_subnet_resource_id = module.spoke_network[each.value.hub_key].subnet_ids[each.value.subnet_key]
        }
      }
    }
  }

  admin_username                     = try(each.value.admin_username, "azureadmin")
  admin_password                     = var.vm_admin_password
  generate_admin_password_or_ssh_key = false

  license_type = try(each.value.license_type, "Windows_Server")

  patch_mode            = "AutomaticByPlatform"
  patch_assessment_mode = "AutomaticByPlatform"

  tags = merge(local.hubs[each.value.hub_key].tags, try(each.value.tags, {}))

  enable_telemetry = false
}
