# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Azure Landing Zone management repository (`alz-mgmt`) containing Terraform root modules for a hub-spoke architecture across two UK regions (uksouth primary, ukwest secondary). Each `platform_*` directory is an independently deployable Terraform root module with its own state file.

A companion repo `alz-modules` (at `../../alz-modules/`) contains reusable modules and stacks referenced by several platforms here.

## Template vs Customer-Specific Code

This repo contains a mix of accelerator-generated template code and customer-specific (SCC) additions. Understanding the boundary matters for upgrades, code review, and knowing what is safe to modify.

### platform_shared (Accelerator Output + SCC Extensions)

`platform_shared` is generated from the [Azure Landing Zones Terraform Accelerator](https://github.com/Azure/ALZ-Terraform-Accelerator). The following are accelerator output and should remain largely untouched:

- `main.*.tf`, `variables.*.tf`, `locals.tf`, `outputs.tf`, `outputs.moved.tf` — core resource declarations
- `modules/` — accelerator-provided internal modules:
  - `config-templating/` — data-transformation module that resolves template placeholders in tfvars (e.g. `${starter_location_01}`) to concrete values at plan time
  - `management_groups/` — creates ALZ management group hierarchy
  - `management_resources/` — creates management-plane resources (Log Analytics, Automation Account)
- `lib/` — local ALZ library containing archetype override YAMLs (`lib/archetype_definitions/`) and a custom architecture definition (`lib/architecture_definitions/`). These layer policy assignment and definition customisations on top of the upstream Azure Landing Zones Library (downloaded automatically into `.alzlib/` at plan time by the ALZ provider). Modifying `lib/` is the primary way to customise policies without touching accelerator code.

Customer-specific SCC additions use the `scc.` prefix to keep the boundary clear:

- `scc.main.maintenance.tf` — Azure Update Manager maintenance configurations
- `scc.policy.append_tags.tf` — dynamic tag inheritance policy assignments
- `scc.outputs.tf`, `scc.outputs.maintenance.tf` — custom outputs (hub address spaces, bastion subnets, maintenance status)
- `scc.locals.maintenance.tf`, `scc.variables.maintenance.tf` — supporting locals and variables
- `scc.imports.tf` — one-time resource imports
- `.scc-maintenance.auto.tfvars` — maintenance configuration values

### Other Platforms

| Platform | Code Origin | Customer-Specific Files |
|----------|------------|------------------------|
| `platform_connectivity` | Template (`main.tf` calls AVM regions utility) | `resources.dns.tf` (DNS records), `.auto.tfvars` |
| `platform_firewall_rules` | Template (`main.tf` + `variables.tf` call `scc-azure-platform-firewall` from alz-modules) | `.auto.tfvars` (IP groups, rule sets, custom collections) |
| `platform_amba` | Template (`main.monitoring.amba.tf` calls AVM AMBA module) | `amba.auto.tfvars` (action groups, alert settings) |
| `platform_identity` | Template (all `.tf` files call `scc-workload-resources` stack from alz-modules) | `.auto.tfvars`, `-compute.auto.tfvars` |
| `platform_security` | Template (identical structure to identity) | `.auto.tfvars`, `-compute.auto.tfvars` |
| `platform_management` | Template (identical structure to identity) | `.auto.tfvars`, `-compute.auto.tfvars` |

The pattern: template `.tf` files define infrastructure patterns and are shared/reusable. `.auto.tfvars` files and `scc.*.tf` files are the customer-specific layer.

## Common Commands

All commands run from within a `platform_*` directory:

```bash
# Initialise (every platform uses backend.conf for state config)
terraform init -backend-config=backend.conf

# Plan
terraform plan -input=false -out=tfplan

# Apply
terraform apply tfplan

# Validate only (used in CI)
terraform validate

# Format check
terraform fmt -check -recursive
```

There are no test suites in this repo. Validation happens via `terraform validate` and `terraform plan` in CI.

## Architecture

### Platform Dependency Graph

```
platform_shared (foundation: management groups, hub VNets, policies, firewall policies)
    |
    ├── platform_connectivity (extends hubs with DNS zones and records)
    ├── platform_firewall_rules (IP groups and rule collection groups for hub firewalls)
    ├── platform_amba (Azure Monitor Baseline Alerts and policy assignments)
    |
    ├── platform_identity (workload vending: identity domain resources)
    ├── platform_security (workload vending: security domain resources)
    └── platform_management (workload vending: management domain resources)
```

`platform_shared` must be deployed first. All other platforms read its outputs via `data.terraform_remote_state`.

### Module Sourcing

Two sourcing patterns are used:

1. **Azure Verified Modules (AVM)** from the Terraform registry, e.g. `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm`
2. **Local modules** from the companion `alz-modules` repo via relative paths:
   - `../../alz-modules/stacks/scc-workload-resources` (used by identity, security, management)
   - `../../alz-modules/modules/scc-azure-platform-firewall` (used by firewall_rules)

`platform_shared` also has accelerator-provided modules under `./modules/` (config-templating, management_groups, management_resources). These came from the ALZ Terraform Accelerator and should not be modified directly.

### Workload Vending Pattern

`platform_identity`, `platform_security`, and `platform_management` all use the same stack module (`scc-workload-resources`). They share identical variable structures for subscription targeting, naming, connectivity, vending, management, and compute configuration. The only differences are in their `.auto.tfvars` values.

### Region Mapping

Hub infrastructure uses abstract keys (`primary`/`secondary`) mapped to actual regions via `hub_region_mapping` in tfvars:

```hcl
hub_region_mapping = {
  primary   = "uksouth"
  secondary = "ukwest"
}
```

Firewall rules, IP groups, and custom rules are all keyed by these abstract hub keys, not region names directly.

## Key Conventions

### File Naming

- `terraform.tf` — provider config, required versions, backend block
- `main.tf` or `main.*.tf` — resource/module declarations (platform_shared splits across multiple `main.*.tf`)
- `variables.tf` or `variables.*.tf` — variable definitions
- `resources.*.tf` — customer-specific resource declarations outside platform_shared (e.g. `resources.dns.tf` in platform_connectivity)
- `scc.*.tf` — customer-specific SCC extensions in platform_shared (maintenance, policies, custom outputs, imports). This prefix keeps a clear boundary between accelerator-generated code and custom additions, making future accelerator upgrades safer.
- `.platform-<name>.auto.tfvars` — committed configuration values (dot-prefixed)
- `.platform-<name>-compute.auto.tfvars` — optional compute-specific values
- `backend.conf` — backend storage config (committed, not sensitive)
- `scc.imports.tf-sample` — template for one-time import blocks (not auto-executed)

### State Management

All platforms share one Azure Storage account. State files are differentiated by key:

- `platform_shared` → `terraform.tfstate`
- Others → `platform_<name>/terraform.tfstate` (e.g. `platform_firewall_rules/terraform.tfstate`, `platform_identity/terraform.tfstate`)

All platforms except `platform_shared` and `platform_amba` include `use_azuread_auth = true` in their backend.conf.

### Provider Patterns

- `platform_shared` uses multiple provider aliases: default `azurerm`, `azurerm.management`, `azurerm.connectivity`, `azapi.connectivity`
- The ALZ provider loads the upstream Azure Landing Zones Library into `.alzlib/` at plan time, then layers the local `lib/` directory on top as a custom library. `lib/archetype_definitions/` contains archetype overrides (add/remove policy assignments per management group) and `lib/architecture_definitions/` defines the management group hierarchy.
- Workload platforms target a single subscription via `var.subscription`

### What Gets Committed

All `.auto.tfvars` files are committed (CI/CD needs them). State files, plans, `.terraform/`, `.alzlib/`, and `backend.tfvars` are gitignored.

## CI/CD

- **CI** (`.github/workflows/ci.yaml`): Runs on PRs to main. Matrix strategy over all 7 platform folders. Does init, validate, plan, and uploads plan artifact. Checks out `alz-modules` alongside `alz-mgmt` so relative module paths resolve.
- **CD** (`.github/workflows/cd.yaml`): Runs on push to main or manual dispatch. Calls a reusable template from `TysonTech-net/alz-mgmt-templates`. Supports apply/destroy actions. All 7 platforms are available for manual dispatch.
- Authentication is OIDC-based (no stored secrets for Azure credentials).
- The CD reusable template (`alz-mgmt-templates`) must also checkout `alz-modules` for platforms that use relative module paths (firewall_rules, identity, security, management).

## Terraform Version

All platforms require `~> 1.12`. Provider constraints are also aligned: `azurerm ~> 4.0` and `azapi ~> 2.0` where applicable.
