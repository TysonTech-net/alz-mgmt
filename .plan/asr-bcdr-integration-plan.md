# ASR BCDR Integration Plan

## Overview

Integrate `Azure/avm-ptn-bcdr-vm-replication/azurerm` (v0.1.0) into the `scc-azure-workload-vm` module to enable Azure Site Recovery replication for VMs with an `asr` configuration block.

## Current State

### Existing ASR Support in VM Module
- **Location:** `modules/scc-azure-workload-vm/main.tf` (lines 327-402)
- **Features:**
  - Collects VM disk metadata (OS disk, data disks) for ASR
  - Extracts network interface information
  - Supports `asr_enabled` (bool) and `asr` (object) per VM
  - Outputs `asr_replication_candidates` for downstream orchestration
  - Does NOT actually perform replication - just prepares metadata

### Stack-Level ASR Variables (variables.compute.tf)
```hcl
asr_enabled = optional(bool, false)
asr = optional(object({
  enabled = optional(bool, false)
  target_resource_group_key = optional(string)
  target_resource_group_id = optional(string)
}))
```

## Proposed Changes

### 1. Expand VM-Level `asr` Variable Structure

**File:** `stacks/scc-workload-resources/variables.compute.tf`

Add comprehensive ASR configuration per VM:

```hcl
asr = optional(object({
  enabled = optional(bool, false)

  # Target Configuration
  target_resource_group_key = optional(string)  # Reference to vm_resource_groups key
  target_resource_group_id  = optional(string)  # Direct RG ID (alternative)
  target_zone               = optional(string)  # Target availability zone
  target_availability_set_id = optional(string)
  target_proximity_placement_group_id = optional(string)

  # Network Configuration
  target_network_id = optional(string)          # Target VNet resource ID
  target_subnet_name = optional(string)         # Subnet name in target VNet
  target_static_ip   = optional(string)         # Static private IP in target

  # Disk Configuration
  target_disk_type = optional(string)           # e.g., "Premium_LRS", "StandardSSD_LRS"
  target_disk_encryption_set_id = optional(string)

  # Recovery Configuration
  multi_vm_group_name = optional(string)        # For multi-VM consistent recovery
}))
```

### 2. Add Region-Level ASR Configuration

**File:** `stacks/scc-workload-resources/variables.compute.tf`

Add ASR defaults at the compute region level:

```hcl
variable "compute" {
  # ... existing fields ...
  # Add per-region ASR configuration:
  asr_config = optional(object({
    enabled = optional(bool, false)

    # Target Region
    target_location = string                     # e.g., "ukwest"

    # Recovery Vault Configuration
    use_existing_vault         = optional(bool, false)
    vault_name                 = optional(string)  # RSV name (create or existing)
    vault_resource_group_name  = optional(string)  # RG for vault
    vault_resource_group_key   = optional(string)  # Reference to vm_resource_groups

    # Replication Policy
    recovery_point_retention_in_minutes = optional(number, 1440)  # 24 hours
    app_consistent_snapshot_frequency_in_minutes = optional(number, 240)  # 4 hours

    # Target Network (default for all VMs in this region)
    target_network_id   = optional(string)
    target_subnet_name  = optional(string)

    # Target Resource Group (default for all VMs in this region)
    target_resource_group_id  = optional(string)
    target_resource_group_key = optional(string)

    # Capacity Reservation (optional)
    enable_capacity_reservation = optional(bool, false)
    capacity_reservation_sku    = optional(string)
  }))
}
```

### 3. Add BCDR Module to VM Module

**File:** `modules/scc-azure-workload-vm/main.tf`

Add new section after VM creation:

```hcl
###############################################
# Azure Site Recovery Replication (BCDR)
###############################################

locals {
  # Filter VMs that have ASR enabled
  asr_enabled_vms = {
    for vm_key, vm in var.vms :
    vm_key => vm
    if try(vm.asr_enabled, false) || try(vm.asr.enabled, false)
  }

  # Only enable BCDR module if there are VMs to replicate and asr_config is provided
  enable_bcdr = length(local.asr_enabled_vms) > 0 && var.asr_config != null

  # Build replicated_vms map for BCDR module
  bcdr_replicated_vms = local.enable_bcdr ? {
    for vm_key, vm in local.asr_enabled_vms :
    vm_key => {
      vm_id = module.avm_res_compute_virtualmachine[vm_key].resource_id

      # Target resource group (VM-level override or region default)
      target_resource_group_id = coalesce(
        try(vm.asr.target_resource_group_id, null),
        try(local.rg_name_by_key[vm.asr.target_resource_group_key], null),
        try(var.asr_config.target_resource_group_id, null),
        try(local.rg_name_by_key[var.asr_config.target_resource_group_key], null)
      )

      # Network configuration
      source_network_id = try(
        module.avm_res_compute_virtualmachine[vm_key].network_interfaces["primary"].ip_configurations["ipconfig1"].subnet_id,
        null
      )
      target_network_id = coalesce(
        try(vm.asr.target_network_id, null),
        try(var.asr_config.target_network_id, null)
      )

      # Target zone/availability
      target_zone = try(vm.asr.target_zone, null)
      target_availability_set_id = try(vm.asr.target_availability_set_id, null)
      target_proximity_placement_group_id = try(vm.asr.target_proximity_placement_group_id, null)

      # Disk configuration
      managed_disks = concat(
        # OS Disk
        [{
          disk_id = local.vm_primary_disk[vm_key].managed_disk_id
          staging_storage_account_id = null  # Module creates staging account
          target_resource_group_id = coalesce(
            try(vm.asr.target_resource_group_id, null),
            try(var.asr_config.target_resource_group_id, null)
          )
          target_disk_type = coalesce(
            try(vm.asr.target_disk_type, null),
            local.vm_primary_disk[vm_key].storage_account_type
          )
          target_disk_encryption_set_id = try(vm.asr.target_disk_encryption_set_id, null)
        }],
        # Data Disks
        [for disk_key, disk in local.vm_data_disks[vm_key] : {
          disk_id = disk.disk_id
          staging_storage_account_id = null
          target_resource_group_id = coalesce(
            try(vm.asr.target_resource_group_id, null),
            try(var.asr_config.target_resource_group_id, null)
          )
          target_disk_type = coalesce(
            try(vm.asr.target_disk_type, null),
            disk.storage_account_type
          )
          target_disk_encryption_set_id = try(vm.asr.target_disk_encryption_set_id, null)
        }]
      )

      # Network interfaces for failover
      network_interfaces = [for nic_key, nic in module.avm_res_compute_virtualmachine[vm_key].network_interfaces : {
        source_network_interface_id = nic.id
        target_static_ip = try(vm.asr.target_static_ip, null)
        target_subnet_name = coalesce(
          try(vm.asr.target_subnet_name, null),
          try(var.asr_config.target_subnet_name, null)
        )
      }]

      # Multi-VM group for consistent recovery
      multi_vm_group_name = try(vm.asr.multi_vm_group_name, null)
    }
  } : {}
}

module "bcdr_replication" {
  count  = local.enable_bcdr ? 1 : 0
  source = "Azure/avm-ptn-bcdr-vm-replication/azurerm"
  version = "0.1.0"

  depends_on = [module.avm_res_compute_virtualmachine]

  # Source and Target Locations
  source_location = var.location
  target_location = var.asr_config.target_location

  # Recovery Services Vault
  use_existing_vault        = var.asr_config.use_existing_vault
  vault_name                = var.asr_config.vault_name
  vault_resource_group_name = coalesce(
    var.asr_config.vault_resource_group_name,
    try(local.rg_name_by_key[var.asr_config.vault_resource_group_key], null)
  )

  # Replication Policy
  recovery_point_retention_in_minutes = var.asr_config.recovery_point_retention_in_minutes
  application_consistent_snapshot_frequency_in_minutes = var.asr_config.app_consistent_snapshot_frequency_in_minutes

  # Replicated VMs
  replicated_vms = local.bcdr_replicated_vms

  # Capacity Reservation (optional)
  enable_capacity_reservation = try(var.asr_config.enable_capacity_reservation, false)
  capacity_reservation_target_sku = try(var.asr_config.capacity_reservation_sku, "")

  # Telemetry
  enable_telemetry = true

  # Tags
  tags = local.module_tags
}
```

### 4. Add New Variables to VM Module

**File:** `modules/scc-azure-workload-vm/variables.tf`

```hcl
variable "asr_config" {
  type = object({
    target_location = string

    use_existing_vault         = optional(bool, false)
    vault_name                 = optional(string)
    vault_resource_group_name  = optional(string)
    vault_resource_group_key   = optional(string)

    recovery_point_retention_in_minutes = optional(number, 1440)
    app_consistent_snapshot_frequency_in_minutes = optional(number, 240)

    target_network_id         = optional(string)
    target_subnet_name        = optional(string)
    target_resource_group_id  = optional(string)
    target_resource_group_key = optional(string)

    enable_capacity_reservation = optional(bool, false)
    capacity_reservation_sku    = optional(string)
  })
  default     = null
  description = "Region-level ASR configuration for VM replication"
}
```

### 5. Add BCDR Outputs

**File:** `modules/scc-azure-workload-vm/outputs.tf`

```hcl
output "bcdr_vault_name" {
  description = "Name of the Recovery Services Vault used for BCDR"
  value       = try(module.bcdr_replication[0].vault_name, null)
}

output "bcdr_replicated_vm_ids" {
  description = "Map of replicated VM resource IDs"
  value       = try(module.bcdr_replication[0].replicated_vm_ids, {})
}

output "bcdr_site_recovery_fabric_source" {
  description = "Source site recovery fabric name"
  value       = try(module.bcdr_replication[0].site_recovery_fabric_name_source, null)
}

output "bcdr_site_recovery_fabric_target" {
  description = "Target site recovery fabric name"
  value       = try(module.bcdr_replication[0].site_recovery_fabric_name_target, null)
}
```

### 6. Wire Up in Stack

**File:** `stacks/scc-workload-resources/main.compute.tf`

Update the module call to pass `asr_config`:

```hcl
module "workload_vms" {
  source   = "../../modules/scc-azure-workload-vm"
  for_each = var.compute_enabled ? var.compute : {}

  # ... existing config ...

  # ASR Configuration (per-region)
  asr_config = try(each.value.asr_config, null)
}
```

## Example Usage

### VM Configuration with ASR (platform_management-compute.auto.tfvars)

```hcl
compute = {
  uksouth = {
    location = "uksouth"

    # ASR Configuration for this region
    asr_config = {
      enabled         = true
      target_location = "ukwest"

      # Use existing vault from management config
      use_existing_vault        = true
      vault_name                = "rsv-asr-mgmt-prod-ukw-001"
      vault_resource_group_name = "rg-mgmt-prod-mgmt-ukw-001"

      # Replication policy
      recovery_point_retention_in_minutes = 1440  # 24 hours
      app_consistent_snapshot_frequency_in_minutes = 240  # 4 hours

      # Default target network (can be overridden per-VM)
      target_network_id  = "/subscriptions/.../resourceGroups/rg-mgmt-prod-network-ukw-001/providers/Microsoft.Network/virtualNetworks/vnet-mgmt-prod-ukw-001"
      target_subnet_name = "snet-mgmt-prod-jump-ukw-001"
    }

    vm_resource_groups = {
      jump = { name = "rg-mgmt-prod-jump-uks-001" }
    }

    vms = {
      jump_server_01 = {
        name               = "vmmgmtuksjmp001"
        resource_group_key = "jump"
        sku_size           = "Standard_D2s_v5"
        # ... other config ...

        # Enable ASR for this VM
        asr = {
          enabled = true
          target_static_ip = "10.1.5.4"  # Static IP in target subnet
          # Inherits target_network_id, target_subnet_name from asr_config
        }
      }

      lm_collector_01 = {
        name = "vmmgmtukslm001"
        # ... other config ...

        # This VM does NOT have ASR enabled
        # (no asr block = not replicated)
      }
    }
  }
}
```

## Files to Modify

| File | Changes |
|------|---------|
| `modules/scc-azure-workload-vm/main.tf` | Add BCDR module call and locals for VM mapping |
| `modules/scc-azure-workload-vm/variables.tf` | Add `asr_config` variable |
| `modules/scc-azure-workload-vm/outputs.tf` | Add BCDR-related outputs |
| `modules/scc-azure-workload-vm/terraform.tf` | Ensure azurerm provider constraint |
| `stacks/scc-workload-resources/variables.compute.tf` | Expand `asr` object, add `asr_config` to region |
| `stacks/scc-workload-resources/main.compute.tf` | Pass `asr_config` to VM module |

## Dependencies

1. **Recovery Services Vault** - Must exist in target region (or create via BCDR module)
2. **Target VNet/Subnet** - Must exist before replication
3. **Target Resource Group** - Must exist for replicated disks/NICs

## Known Limitations

1. **High Churn Not Supported** - Azure provider limitation (GitHub issue #23343)
2. **Initial Replication Time** - ~5.5 hour timeout for large VMs
3. **Cross-Subscription** - Requires additional provider configuration

## Testing Plan

1. Deploy VM without ASR (baseline)
2. Enable ASR with `use_existing_vault = false` (creates vault)
3. Enable ASR with `use_existing_vault = true` (uses management RSV)
4. Test multi-VM group consistency
5. Verify replication status in Azure Portal

## Rollback Strategy

1. Set `asr_config.enabled = false` or remove `asr_config` block
2. Run `terraform apply` - BCDR module count becomes 0
3. Manual cleanup of replicated items may be needed in RSV
