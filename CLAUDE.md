# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Azure Landing Zone management repository (`alz-mgmt`) containing Terraform root modules for a hub-spoke architecture across two UK regions (uksouth primary, ukwest secondary). Each `platform_*` directory is an independently deployable Terraform root module with its own state file.

A companion repo `alz-modules` (at `../../alz-modules/`) contains reusable modules and stacks referenced by several platforms here.

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

`platform_shared` also has internal modules under `./modules/` (config-templating, management_groups, management_resources).

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
- `resources.*.tf` — additional resource declarations (e.g. `resources.dns.tf`)
- `scc.*.tf` — custom/org-specific additions in platform_shared (maintenance, policies, outputs, imports)
- `.platform-<name>.auto.tfvars` — committed configuration values (dot-prefixed)
- `.platform-<name>-compute.auto.tfvars` — optional compute-specific values
- `backend.conf` — backend storage config (committed, not sensitive)
- `scc.imports.tf-sample` — template for one-time import blocks (not auto-executed)

### State Management

All platforms share one Azure Storage account. State files are differentiated by key:

- `platform_shared` → `terraform.tfstate`
- `platform_firewall_rules` → `platform-firewall-rules.tfstate`
- Others → `platform_<name>/terraform.tfstate` (e.g. `platform_identity/terraform.tfstate`)

All platforms except `platform_shared` and `platform_amba` include `use_azuread_auth = true` in their backend.conf.

### Provider Patterns

- `platform_shared` uses multiple provider aliases: default `azurerm`, `azurerm.management`, `azurerm.connectivity`, `azapi.connectivity`
- The ALZ provider uses a local library override at `${path.root}/lib`
- Workload platforms target a single subscription via `var.subscription`

### What Gets Committed

All `.auto.tfvars` files are committed (CI/CD needs them). State files, plans, `.terraform/`, `.alzlib/`, and `backend.tfvars` are gitignored.

## CI/CD

- **CI** (`.github/workflows/ci.yaml`): Runs on PRs to main. Matrix strategy over platform folders. Does init, validate, plan, and uploads plan artifact.
- **CD** (`.github/workflows/cd.yaml`): Runs on push to main or manual dispatch. Calls a reusable template from `TysonTech-net/alz-mgmt-templates`. Supports apply/destroy actions.
- Authentication is OIDC-based (no stored secrets for Azure credentials).
- CI currently only validates `platform_shared` and `platform_amba` by default.
- CD manual dispatch only covers `platform_shared`, `platform_amba`, `platform_management`, and `platform_security`. Other platforms (`platform_connectivity`, `platform_identity`, `platform_firewall_rules`) are not yet wired into CD.

## Terraform Version

- `platform_shared`, `platform_connectivity`, `platform_amba` require `~> 1.12`
- `platform_firewall_rules`, `platform_identity`, `platform_security`, `platform_management` require `>= 1.5.0` (lower bound set by their upstream modules)
