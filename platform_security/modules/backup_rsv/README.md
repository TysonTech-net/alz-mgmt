
# Azure Recovery Services Vault Module (`backup_rsv`)

Enterprise-ready Terraform module to provision **Azure Recovery Services Vaults (RSV)** and opinionated **backup policies** for common workloads protected by RSV.

It supports creating one or more vaults with different backup storage redundancies and generates per‑workload policies with daily/weekly/monthly/yearly retention. The module is designed with **guardrails** to prevent unsafe configuration drift and to make extension safe in large estates.

---

## ✨ What this module does

- Creates an **Azure Resource Group** (optional) or reuses an existing one.
- Creates one or more **Azure Recovery Services Vaults** (`azurerm_recovery_services_vault`) with backup storage redundancy:
  - `lr` → LocallyRedundant
  - `zr` → ZoneRedundant
  - `gr` → GeoRedundant (optional **cross‑region restore**)
- Configures vault posture:
  - **Soft delete** state & retention window.
  - **Immutability** mode: `Disabled`, `Unlocked`, or `Locked` (immutable vault).
  - (Optional) **Cross‑Region Restore** for GRS vaults.
- Generates backup policies for the following workloads (for **each** selected vault type):
  - **Azure Virtual Machines** (`azurerm_backup_policy_vm`)
  - **Azure Files (File Shares)** (`azurerm_backup_policy_file_share`)
- Exposes outputs for resource IDs, names, and (if enabled) the **managed identity** of each vault (principal & tenant IDs).

> **Naming**: Vaults are named `"{name_prefix}-{vault_type}-{name_suffix}"`, e.g. `corp-lr-prd`.

---

## 🧰 Requirements

- Terraform **1.x**
- Provider: `hashicorp/azurerm` 3.x (configure in your root module).
- Azure permissions to create Resource Groups, Recovery Services Vaults and Backup Policies in the target subscription.
- Network access to Azure ARM endpoints from where Terraform runs.

> The module does **not** create backup **associations** (protected items) or configure RBAC on protected resources. Associate resources (VMs, file shares) to policies and assign RBAC separately per your security model.

---

## 🚀 Quick start

```hcl
# Root provider config (example)
provider "azurerm" {
  features {}
}

module "backup_rsv" {
  source = "./backup_rsv"

  name_prefix           = "corp"
  name_suffix           = "prd"
  location              = "westeurope"
  resource_group_name   = "rg-rsv-backup-prd"
  create_resource_group = true

  # Deploy all three vault types
  vaults_to_deploy = ["lr", "zr", "gr"]

  # Governance
  rg_tags = {
    env   = "prod"
    owner = "platform"
  }

  # Vault posture
  soft_delete                    = "On"       # "AlwaysOn" | "On" | "Off" (tenant policy may restrict)
  soft_delete_retention_in_days  = 14         # 14..180
  immutability                   = "Disabled" # or "Unlocked" / "Locked"
  cross_region_restore_enabled   = true       # applies to 'gr' vaults only

  # Optional per‑workload policy extensions (see section below)
  # policy_extensions = { ... }
}
```

Apply with:

```bash
terraform init
terraform plan
terraform apply
```

---

## 🔧 Policies & safe extensions (add‑only)

The module ships with sensible **default policies**, e.g. `VM-14d` and `FileShare-14d` (daily retention 14 days).
You can **add** more policies without modifying module code via `policy_extensions`. The module enforces a **precondition** to **block name collisions** with built‑in policies.

### Schema (per type)
```hcl
policy_extensions = {
  vm = {
    "VM-30d" = {
      schedule  = { type = "Daily", time_utc = "21:00" } # or type = "Weekly", days = ["Sunday"], time_utc = "21:00"
      retention = { daily = 30, weekly = 0, monthly = 0, yearly = 0 }
      instant_restore_retention_days = 5                  # optional, default sensible
      time_zone = "UTC"
    }
    "VM-12w-12m-5y" = {
      schedule  = { type = "Weekly", days = ["Sunday"], time_utc = "21:00" }
      retention = { daily = 0, weekly = 12, monthly = 12, yearly = 5 }
      time_zone = "UTC"
    }
  }

  file_share = {
    "FileShare-30d" = {
      schedule  = { type = "Daily", time_utc = "21:00" }
      retention = { daily = 30, weekly = 0, monthly = 0, yearly = 0 }
      time_zone = "UTC"
    }
  }
}
```

**Notes on retention semantics**
- **Daily**: keep N daily recovery points.
- **Weekly**: keep N weekly points (based on scheduled day).
- **Monthly**: keep N monthly points (first scheduled point in the month).
- **Yearly**: keep N yearly points (first scheduled point in the year).
- Instant restore for VMs controls how long snapshots are kept locally for fast restores.

**Opinionated defaults**
- VM / File Share: **daily at 21:00 UTC**.
- Time zone default: **UTC**.

---

## 📦 Inputs

> Types and defaults are shown for convenience. Pin provider versions in your root module.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name_prefix` | `string` | n/a | Prefix for vault names. |
| `name_suffix` | `string` | n/a | Suffix for vault names. |
| `location` | `string` | n/a | Azure region, e.g., `westeurope`. |
| `location_short` | `string` | `null` | Optional short region code for naming. |
| `resource_group_name` | `string` | n/a | Resource Group to create or reuse. |
| `create_resource_group` | `bool` | `false` | Create the RG (`true`) or use an existing one (`false`). |
| `rg_tags` | `map(string)` | `{}` | Tags applied to the RG and all vaults. |
| `vaults_to_deploy` | `list(string)` | `["lr","zr","gr"]` | Which vaults to deploy: `lr`, `zr`, `gr`. |
| `soft_delete` | `string` | `"On"` | `"AlwaysOn"`, `"On"`, `"Off"` (subject to tenant policy). |
| `soft_delete_retention_in_days` | `number` | `14` | Soft delete retention in days (14–180). |
| `immutability` | `string` | `"Disabled"` | Immutability policy: `"Disabled"`, `"Unlocked"`, `"Locked"`. |
| `cross_region_restore_enabled` | `bool` | `false` | Enables Cross‑Region Restore (applies to `gr` vaults only). |
| `policy_extensions` | *object* | `{}` | Add‑only policy definitions by workload (see schema). |

---

## 🧾 Outputs

| Name | Description |
| --- | --- |
| `resource_group_id` | The ID of the resource group. |
| `resource_group_name` | The name of the resource group. |
| `vault_ids` | Map of `lr`/`zr`/`gr` to vault IDs. |
| `vault_names` | Map of `lr`/`zr`/`gr` to vault names. |
| `vm_policy_ids` | Map of VM policy names to IDs. |
| `file_share_policy_ids` | Map of File Share policy names to IDs. |
| `vault_identities` | Map of vault type to `{ principal_id, tenant_id }` when the vault identity is enabled. |

---

## 🔐 Security, governance & operations

- **Soft delete & immutability**: Configure at the vault level; align with organizational retention and legal hold requirements.
- **Cross‑Region Restore (CRR)**: Only meaningful for **GRS** vaults; set `cross_region_restore_enabled = true` if mandated by policy.
- **RBAC**: Assign appropriate backup roles to protected resources (VMs, storage accounts) so the vault can discover and protect them.
- **Tags & naming**: All tags in `rg_tags` are applied to the RG and vaults for cost/ownership tracking; naming is deterministic.
- **Guardrails**: The module fails early if a `policy_extensions` entry collides with a built‑in policy.

---

## 🧪 Testing & validation

- Run `terraform fmt -check`, `terraform validate`, and `terraform plan` in CI.
- Test in a **non‑prod** subscription/management group before rollout.
- Avoid `terraform destroy` in shared environments—backup assets are sensitive resources.

---

## ⚠️ Known limitations

- Azure Backup policy capabilities differ between **VM** and **File Share**; the module applies compatible retention semantics across both but defers to provider constraints when needed.
- The module does not manage backup **associations** (protected VMs or file shares) nor any **RBAC** on those resources.
- Provider features and API behavior can change—pin `hashicorp/azurerm` to a tested version in your root.

---

## 📁 Repository layout

```
backup_rsv/
├─ main.tf                      # Core vault(s) and policies
├─ variables.tf                 # Inputs (with validation)
├─ outputs.tf                   # Outputs
└─ default_backup_policy.tf     # Built‑in policy definitions
```

---

## 🙋 Support

File issues and requests with your platform team. For production changes, follow your change management process and ensure you have a tested rollback plan.
