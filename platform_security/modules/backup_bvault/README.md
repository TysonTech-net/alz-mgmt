
# Azure Backup Vault Module (`backup_bvault`)

Enterprise-ready Terraform module to provision **Azure Data Protection Backup Vaults** and opinionated **backup policies** for common workloads.

It supports creating one or more vaults with different redundancy options, and generates per‑workload policies with daily/weekly/monthly/yearly retention. The module is designed with **guardrails** to prevent unsafe configuration drift and to make extension safe in large estates.

---

## ✨ What this module does

- Creates an **Azure Resource Group** (optional) or reuses an existing one.
- Creates one or more **Azure Data Protection Backup Vaults** (`azurerm_data_protection_backup_vault`) with redundancy:
  - `lr` → LocallyRedundant
  - `zr` → ZoneRedundant
  - `gr` → GeoRedundant (optional **cross‑region restore**)
- Generates backup policies for the following workloads (for **each** selected vault type):
  - **Blob Storage** (`azurerm_data_protection_backup_policy_blob_storage`)
  - **Managed Disks** (`azurerm_data_protection_backup_policy_disk`)
  - **Azure Database for PostgreSQL (single server)** (`azurerm_data_protection_backup_policy_postgresql`)
  - **Azure Kubernetes Service (AKS)** (`azurerm_data_protection_backup_policy_kubernetes_cluster`)
  - **PostgreSQL Flexible Server** (`azurerm_data_protection_backup_policy_postgresql_flexible_server`)
- Exposes outputs for resource IDs, names, and the **managed identity** of each vault (principal & tenant IDs).

> **Naming**: Vaults are named `"{name_prefix}-{vault_type}-{name_suffix}"`, e.g. `corp-lr-prd`.

---

## 🧰 Requirements

- Terraform **1.x**
- Provider: `hashicorp/azurerm` 3.x (configure in your root module).
- Azure permissions to create Resource Groups, Backup Vaults and Backup Policies in the target subscription.
- Network access to Azure ARM endpoints from where Terraform runs.

> The module does **not** configure RBAC on source resources (e.g., storage accounts, disks, AKS, PostgreSQL servers). Assign those permissions separately per your security model.

---

## 🚀 Quick start

```hcl
# Root provider config (example)
provider "azurerm" {
  features {}
}

module "backup_bvault" {
  source = "./backup_bvault"

  name_prefix         = "corp"
  name_suffix         = "prd"
  location            = "westeurope"
  resource_group_name = "rg-backup-prd"
  create_resource_group = true

  # Deploy all three vault types
  vaults_to_deploy = ["lr", "zr", "gr"]

  # Governance
  rg_tags = {
    env   = "prod"
    owner = "platform"
  }

  # Protection posture
  immutability                 = "Disabled" # or "Unlocked" / "Locked"
  soft_delete                  = "On"       # "AlwaysOn" | "On" | "Off"
  retention_duration_in_days   = 14         # 14..180
  cross_region_restore_enabled = true       # only applies to 'gr' vaults
}
```

Apply with:

```bash
terraform init
terraform plan
terraform apply
```

---

## 🔧 Extending policies safely (add‑only)

The module ships with sensible **default policies**, e.g. `Blob-14d`, `Disk-14d`, `PostgreSQL-14d`, `Kubernetes-14d`, `PostgreSQLFlexible-14d` (daily retention 14 days).
You can **add** more policies without modifying module code via `policy_extensions`. The module enforces a **precondition** to **block name collisions** with built‑in policies.

Schema (per type):
```hcl
policy_extensions = {
  blob = {
    "Blob-30d" = {
      retention = { daily = 30, weekly = 0, monthly = 0, yearly = 0 }
    }
  }

  disk = {
    "Disk-12w" = {
      retention = { daily = 0, weekly = 12, monthly = 0, yearly = 0 }
    }
  }

  postgresql = {
    "PostgreSQL-12m" = {
      retention = { daily = 0, weekly = 0, monthly = 12, yearly = 0 }
    }
  }

  kubernetes = {
    "Kubernetes-1y" = {
      retention = { daily = 0, weekly = 0, monthly = 0, yearly = 1 }
    }
  }

  postgresql_flexible = {
    "PostgreSQLFlexible-30d" = {
      retention = { daily = 30, weekly = 0, monthly = 0, yearly = 0 }
    }
  }
}
```

**Notes on retention semantics**
- **Daily**: keep N daily points, rule `FirstOfDay`.
- **Weekly**: keep N weekly points, rule `FirstOfWeek`.
- **Monthly**: keep N monthly points, rule `FirstOfMonth`.
- **Yearly**: keep N yearly points, rule `FirstOfYear`.
- Azure imposes limits for **AKS** (OperationalStore, max ~360 days) and for **Disks** (yearly/monthly rules use *compatible* durations capped at 360 days). The module encodes these caps.

**Schedules** (opinionated defaults)
- Blob / Disk / PostgreSQL / PostgreSQL Flexible: **daily at 21:00 UTC**.
- AKS: **weekly at 21:00 UTC (Sunday)** with OperationalStore defaults.

---

## 📦 Inputs

> Types and defaults are shown for convenience. Configure provider versioning in your root module.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name_prefix` | `string` | n/a | Prefix for backup vault names. |
| `name_suffix` | `string` | n/a | Suffix for backup vault names. |
| `location` | `string` | n/a | Azure region, e.g., `westeurope`. |
| `location_short` | `string` | n/a | Short region code for naming (if you standardize on this). |
| `resource_group_name` | `string` | n/a | Resource Group to create or reuse. |
| `create_resource_group` | `bool` | `false` | Create the RG (`true`) or use an existing one (`false`). |
| `rg_tags` | `map(string)` | `{}` | Tags applied to the RG and all vaults. |
| `vaults_to_deploy` | `list(string)` | `["lr","zr","gr"]` | Which vaults to deploy: `lr`, `zr`, `gr`. |
| `immutability` | `string` | `"Disabled"` | Immutability policy: `"Disabled"`, `"Unlocked"`, `"Locked"`. |
| `soft_delete` | `string` | `"On"` | Soft delete state: `"AlwaysOn"`, `"On"`, `"Off"`. |
| `retention_duration_in_days` | `number` | `14` | Soft delete retention in days (14–180). |
| `cross_region_restore_enabled` | `bool` | `false` | Enables Cross‑Region Restore (applies to `gr` vaults only). |
| `policy_extensions` | *object* | `{}` | Add‑only policy definitions by workload (see schema above). |

---

## 🧾 Outputs

| Name | Description |
| --- | --- |
| `resource_group_id` | The ID of the resource group. |
| `resource_group_name` | The name of the resource group. |
| `vault_ids` | Map of `lr`/`zr`/`gr` to vault IDs. |
| `vault_names` | Map of `lr`/`zr`/`gr` to vault names. |
| `blob_policy_ids` | Map of Blob policy names to IDs. |
| `disk_policy_ids` | Map of Disk policy names to IDs. |
| `postgresql_policy_ids` | Map of PostgreSQL (single server) policy names to IDs. |
| `kubernetes_cluster_policy_ids` | Map of AKS policy names to IDs. |
| `postgresql_flexible_server_policy_ids` | Map of PostgreSQL Flexible Server policy names to IDs. |
| `vault_identities` | Map of vault type to `{ principal_id, tenant_id }` for the System‑Assigned identity. |

---

## 🔐 Security, governance & operations

- **Identity**: Each vault has a **system‑assigned managed identity**. Use the output `vault_identities` for downstream RBAC.
- **RBAC**: Assign appropriate backup‑related roles to source resources (e.g., disks, storage accounts, AKS, PostgreSQL servers) so the vaults can back them up.
- **Tags**: All tags in `rg_tags` are applied to the RG and vaults for cost/ownership tracking.
- **Guardrails**: The module fails fast if a `policy_extensions` entry collides with a built‑in name.
- **Immutability / Soft Delete**: Configure at the vault level; be aware of organizational retention requirements.
- **Cross‑Region Restore**: Only meaningful for `gr` vaults; set `cross_region_restore_enabled = true` if required by policy.

---

## 🧪 Testing & validation

- Run `terraform validate` and `terraform plan` in CI.
- Consider a **non‑prod** subscription/management group for dry‑runs.
- Use `terraform destroy` only in sandboxes—backup assets are sensitive resources.

---

## ⚠️ Known limitations

- Azure imposes retention caps for **AKS** OperationalStore and **Disk** policies; the module enforces compatible durations.
- The module does not manage backup **instances** (associating a specific resource to a policy) nor any **RBAC** on source resources.
- Provider features and API behavior can change—pin `hashicorp/azurerm` to a tested version in your root.

---

## 📁 Repository layout

```
backup_bvault/
├─ main.tf                      # Core resources and policies
├─ variables.tf                 # Inputs (with validation)
├─ outputs.tf                   # Outputs
└─ default_backup_policy.tf     # Built‑in policy definitions
```

---

## 🙋 Support

File issues and requests with your platform team. For production changes, follow your change management process and ensure you have a tested rollback plan.

