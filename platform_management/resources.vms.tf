resource "azurerm_resource_group" "adds" {
  name     = "rg-${local.base_name_primary}-activedirectory-001"
  location = local.primary_location
  tags     = local.final_tags
}

module "windows_vms" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "~> 0.20"

  for_each = var.windows_virtual_machines

  name                = each.value.name
  location            = local.primary_location
  resource_group_name = azurerm_resource_group.adds.name
  sku_size            = each.value.sku_size
  zone                = tostring(try(each.value.zone, 1))

  source_image_reference = {
    publisher = each.value.image.publisher
    offer     = each.value.image.offer
    sku       = each.value.image.sku
    version   = try(each.value.image.version, "latest")
  }

  os_disk = {
    caching                   = try(each.value.os_disk.caching, "ReadWrite")
    storage_account_type      = try(each.value.os_disk.storage_account_type, "Premium_LRS")
    disk_size_gb              = each.value.os_disk.disk_size_gb
    write_accelerator_enabled = false
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
          private_ip_subnet_resource_id = module.spoke_network_primary.subnet_ids[try(each.value.subnet_key, "mgmt")]
        }
      }
    }
  }

  admin_username                     = try(each.value.admin_username, "EUKSAdmin")
  admin_password                     = var.vm_admin_password
  generate_admin_password_or_ssh_key = false

  license_type = try(each.value.license_type, "Windows_Server")

  encryption_at_host_enabled = try(each.value.encryption_at_host_enabled, true)

  patch_mode            = "AutomaticByPlatform"
  patch_assessment_mode = "AutomaticByPlatform"

  extensions = {
    for ext_key, ext in try(each.value.extensions, {}) : ext_key => {
      name                       = ext.name
      publisher                  = ext.publisher
      type                       = ext.type
      type_handler_version       = ext.type_handler_version
      auto_upgrade_minor_version = try(ext.auto_upgrade_minor_version, true)
      settings                   = jsonencode(try(ext.settings, {}))
    }
  }

  tags = merge(local.final_tags, try(each.value.tags, {}))

  enable_telemetry = false
}