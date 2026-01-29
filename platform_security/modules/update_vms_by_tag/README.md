
# Azure VM Update by Tag Module (`update_vms_by_tag`)

Enterprise-ready Terraform module that orchestrates **OS patching of Azure Virtual Machines** selected **dynamically by tag**.
It supports both the modern **Azure Update Manager** path (preferred) and the legacy **Automation/Log Analytics Update Management** path for backwards compatibility. The module focuses on **safe defaults**, **predictable schedules**, and **guardrails** suitable for large estates.

> **TL;DR**: Define a tag selector (e.g., `patch=true`), choose classifications and a maintenance window, and the module will schedule patching for all matching VMs — with sane reboot and concurrency controls.

---

## ✨ What this module does

- Creates/reuses an **Azure Resource Group**.
- Builds an update schedule targeting VMs by **tag** (include/exclude) using one of two engines:
  1. **Update Manager (In-guest patching)** via **Maintenance Configurations** (preferred).
  2. **Automation Update Management** via **Automation Account + LA Workspace** (legacy).
- Supports **Windows** and **Linux** classifications, **reboot** behavior, **pre/post scripts**, **maintenance window**, and **concurrency** limits.
- Optionally restricts scope to a set of **subscriptions** and/or **resource groups**.
- Applies **consistent tags** and provides **rich outputs** for downstream automation/observability.

> The module **does not** install agents on VMs. For the legacy engine, ensure the LA agent/onboarding is handled upstream. For Update Manager, platform-based in-guest patching is used where supported.

---

## 🧰 Requirements

- Terraform **1.x**
- Provider: `hashicorp/azurerm` **3.x**
- Azure permissions depending on engine:
  - **Update Manager**: `Owner` or `Contributor` on the scope where maintenance configurations are created; read access to target VMs.
  - **Automation**: Permissions to create **Automation Account**, link **Log Analytics Workspace**, create **schedules** and **software update configurations**.
- Time synchronization for schedule times (module uses UTC by default).

---

## 🚀 Quick start (Update Manager — preferred)

```hcl
provider "azurerm" {
  features {}
}

module "update_vms_by_tag" {
  source = "./update_vms_by_tag"

  # Naming & scope
  name_prefix           = "corp"
  name_suffix           = "prd-weu"
  location              = "westeurope"
  resource_group_name   = "rg-update-prd"
  create_resource_group = true

  engine = "update_manager" # or "automation"

  # Target selection
  target_tag_name   = "patch"
  target_tag_values = ["true"]                  # include when tag patch=true
  exclude_tag_name   = "patch_exempt"          # optional
  exclude_tag_values = ["true", "temp"]

  # Optional scoping
  scope_subscription_ids = []                  # [] means current subscription
  include_resource_groups = ["rg-apps-prd", "rg-data-prd"]
  exclude_resource_groups = ["rg-legacy-prd"]

  # Patching policy
  os_types = ["Windows", "Linux"]

  windows_classifications = ["Critical", "Security", "UpdateRollup", "Updates"]
  linux_classifications   = ["Critical", "Security", "Other"]

  reboot_behavior = "IfRequired"               # IfRequired | Always | Never | RebootOnly
  maintenance_window_minutes = 120

  # Recurrence
  schedule = {
    type          = "Weekly"                   # OneTime | Daily | Weekly | Monthly
    start_time_utc= "2025-11-10T21:00:00Z"
    weekly_days   = ["Sunday"]
    time_zone     = "UTC"
  }

  # Optional throttling
  batch_percentage = 20                        # patch up to N% at a time
  max_concurrent   = 50                        # absolute concurrency cap
  max_failures     = 5                         # stop after N failures

  # Optional pre/post scripts (SAS URIs or script refs)
  pre_scripts  = []
  post_scripts = []

  rg_tags = {
    env   = "prod"
    owner = "platform"
  }
}
```

Apply with:

```bash
terraform init
terraform plan
terraform apply
```

---

## 🔧 Legacy engine (Automation Update Management)

> Prefer **Update Manager**. Use this only if you still operate the legacy stack and have agents onboarded to Log Analytics.

```hcl
module "update_vms_by_tag" {
  source = "./update_vms_by_tag"

  engine                = "automation"
  location              = "westeurope"
  resource_group_name   = "rg-update-prd"
  create_resource_group = true

  # Onboarding (workspace must exist)
  log_analytics_workspace_id = "/subscriptions/000.../resourceGroups/rg-ops/providers/Microsoft.OperationalInsights/workspaces/la-ops"

  target_tag_name   = "patch"
  target_tag_values = ["true"]

  os_types = ["Windows", "Linux"]

  # Scheduling (daily at 21:00 UTC)
  schedule = {
    type           = "Daily"
    start_time_utc = "2025-11-10T21:00:00Z"
    time_zone      = "UTC"
  }

  windows_classifications = ["Critical", "Security"]
  linux_classifications   = ["Critical", "Security"]

  reboot_behavior            = "IfRequired"
  maintenance_window_minutes = 90

  # Legacy-only knobs
  instant_start_if_missed = true
  create_automation_account = true
}
```

---

## 🎯 Targeting model

- **Include by tag**: `target_tag_name` + `target_tag_values` (logical **OR** across values).
- **Exclude by tag** (optional): `exclude_tag_name` + `exclude_tag_values`.
- **Scope** (optional):
  - `scope_subscription_ids` — restrict to specific subscriptions.
  - `include_resource_groups` / `exclude_resource_groups` — RG allow/deny lists.
- **OS filter**: `os_types = ["Windows","Linux"]`.

> Tag evaluation is **dynamic**: VMs added/removed or tag-changes join/leave at the next evaluation cycle for the configured engine.

---

## 🧩 Variables

> Types and defaults are shown for convenience. Pin provider versions in your root module.

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `name_prefix` | `string` | n/a | Prefix used in resource naming. |
| `name_suffix` | `string` | n/a | Suffix used in resource naming (env/region). |
| `location` | `string` | n/a | Azure region, e.g., `westeurope`. |
| `resource_group_name` | `string` | n/a | RG to create or reuse. |
| `create_resource_group` | `bool` | `false` | Create the RG if true. |
| `rg_tags` | `map(string)` | `{}` | Tags applied to RG and resources. |
| `engine` | `string` | `"update_manager"` | `"update_manager"` or `"automation"`. |
| `target_tag_name` | `string` | n/a | Tag key to include. |
| `target_tag_values` | `list(string)` | `[]` | Tag values to include. |
| `exclude_tag_name` | `string` | `null` | Tag key to exclude. |
| `exclude_tag_values` | `list(string)` | `[]` | Tag values to exclude. |
| `scope_subscription_ids` | `list(string)` | `[]` | Limit search to these subscriptions (empty = current). |
| `include_resource_groups` | `list(string)` | `[]` | Allow-list of RGs. |
| `exclude_resource_groups` | `list(string)` | `[]` | Deny-list of RGs. |
| `os_types` | `list(string)` | `["Windows","Linux"]` | OS families to patch. |
| `windows_classifications` | `list(string)` | `["Critical","Security","Updates"]` | Windows update classifications. |
| `linux_classifications` | `list(string)` | `["Critical","Security","Other"]` | Linux update classifications. |
| `exclude_kb_numbers` | `list(string)` | `[]` | KBs/packages to exclude. |
| `reboot_behavior` | `string` | `"IfRequired"` | `IfRequired` \| `Always` \| `Never` \| `RebootOnly`. |
| `maintenance_window_minutes` | `number` | `120` | Max duration for the patch run. |
| `batch_percentage` | `number` | `20` | Patch up to N% of targets at a time. |
| `max_concurrent` | `number` | `0` | Absolute concurrency cap (0 = derive from percentage). |
| `max_failures` | `number` | `0` | Stop after N failures (0 = unlimited/engine default). |
| `schedule` | `object` | see below | Recurrence config `{ type, start_time_utc, time_zone, weekly_days, monthly_day, monthly_occurrence }`. |
| `pre_scripts` | `list(string)` | `[]` | URIs/refs to pre-scripts. |
| `post_scripts` | `list(string)` | `[]` | URIs/refs to post-scripts. |
| `log_analytics_workspace_id` | `string` | `null` | Required for `engine="automation"`. |
| `create_automation_account` | `bool` | `false` | Create Automation Account if using legacy engine. |
| `instant_start_if_missed` | `bool` | `true` | Run immediately if a scheduled run was missed (legacy). |

**`schedule` object**

```hcl
schedule = {
  type           = "Weekly"             # OneTime | Daily | Weekly | Monthly
  start_time_utc = "2025-11-10T21:00:00Z"
  time_zone      = "UTC"                # For engines that use TZ
  weekly_days    = ["Sunday"]           # When type = Weekly
  monthly_day    = 1                    # When type = Monthly (day-of-month)
  monthly_occurrence = null             # Alt monthly style, e.g., "FirstSunday"
}
```

---

## 🧾 Outputs

| Name | Description |
| --- | --- |
| `resource_group_id` | Resource Group ID. |
| `maintenance_configuration_id` | Maintenance Configuration ID (when `engine="update_manager"`). |
| `update_schedule_id` | Software Update Configuration / schedule ID (when `engine="automation"`). |
| `target_selector_overview` | Object summarizing include/exclude tags and scope. |
| `effective_recurrence` | Normalized view of the recurrence and window. |

---

## 🔐 Security & governance

- **Least privilege**: Limit write permissions to the RG hosting maintenance/scheduling resources. Only **read** access is needed to enumerate targets.
- **Change windows**: Align `start_time_utc` and `maintenance_window_minutes` with your CAB/change policy. Use **UTC** and document local conversions.
- **Exemptions**: Use `exclude_tag_*` for break-glass; keep the list small and time-bound.
- **Canary & throttling**: Use `batch_percentage` and `max_concurrent` to canary before full rollout.
- **Auditing**: Route engine diagnostics to your SIEM (e.g., Maintenance Runs / Automation Job logs).

---

## 🧪 Testing & validation

- `terraform fmt -check`, `terraform validate`, `terraform plan` in CI.
- **Dry-run**: Start with a small tag value (e.g., `patch=canary`) and confirm only canary VMs are targeted.
- Validate reboot policy on representative Windows/Linux VMs in non‑prod first.

---

## ⚠️ Known limitations

- Tag-based targeting is **eventually consistent**; recent tag changes may take time to reflect.
- Legacy engine requires **Log Analytics/MMA agent**; consider migrating to Update Manager where possible.
- Some update classifications may not map 1:1 across distros; the module applies the broadest compatible set.
- Pre/post scripts must be **idempotent** and reachable (e.g., SAS URIs) from target VMs.

---

## 📁 Repository layout

```
update_vms_by_tag/
├─ main.tf
├─ variables.tf
├─ outputs.tf
├─ engine_update_manager.tf    # Maintenance Configuration & dynamic scope
├─ engine_automation.tf        # Automation Account, schedule & SUC
├─ targeting.tf                # Tag/RG/subscription selection logic
└─ scripts.tf                  # Optional pre/post script hooks
```

---

## 🔄 Upgrade & breaking changes

- Switching `engine` may require **resource replacement** and a one-time schedule migration.
- Changing `target_*` or scope settings can significantly alter the target set; treat as a **change-controlled** update.
- Moving schedules between time zones or changing recurrence type may recreate engine resources.

---

## 🙋 Support

Contact your platform team. Include the module version, Terraform version, engine, a redacted plan, and any error messages. For production, follow your change process and maintain a rollback plan.
