# alz-mgmt

Azure Landing Zone management repository containing Terraform root modules for a hub-spoke architecture across two UK regions (uksouth primary, ukwest secondary).

Each `platform_*` directory is an independently deployable Terraform root module with its own state file. A companion repo [`alz-modules`](../../alz-modules/) contains reusable modules and stacks referenced by several platforms here.

## Architecture

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

## Platforms

| Platform | Description | Origin |
|----------|-------------|--------|
| `platform_shared` | Management groups, hub VNets, Azure Firewall policies, Azure Policy, maintenance configs | ALZ Terraform Accelerator + SCC extensions (`scc.*.tf`) |
| `platform_connectivity` | Public DNS zones and DNS records | Template + customer DNS records (`resources.dns.tf`) |
| `platform_firewall_rules` | Azure Firewall IP groups and rule collection groups | `scc-azure-platform-firewall` module from alz-modules |
| `platform_amba` | Azure Monitor Baseline Alerts | AVM AMBA pattern module |
| `platform_identity` | Identity domain spoke VNets, VMs, vaults | `scc-workload-resources` stack from alz-modules |
| `platform_security` | Security domain spoke VNets, VMs, vaults | `scc-workload-resources` stack from alz-modules |
| `platform_management` | Management domain spoke VNets, VMs, vaults | `scc-workload-resources` stack from alz-modules |

## Template vs Customer-Specific Code

This repo contains a mix of accelerator-generated template code and customer-specific (SCC) additions.

- **Template code** (`main.*.tf`, `variables.*.tf`, `modules/`) defines infrastructure patterns and should remain largely untouched.
- **Customer config** (`.auto.tfvars` files) contains environment-specific values: subscriptions, CIDRs, VM specs, rule sets.
- **SCC extensions** (`scc.*.tf` in platform_shared, `resources.*.tf` elsewhere) add customer-specific resources beyond what the accelerator provides.
- **`lib/`** (in platform_shared) contains archetype override YAMLs that customise policy assignments without modifying accelerator code.

See each platform's README for a detailed file layout table.

## Module Inventory

| Module | Source | Version | Used By |
|--------|--------|---------|---------|
| ALZ management groups | `Azure/avm-ptn-alz/azurerm` | 0.12.0 (AMBA), internal (shared) | platform_shared, platform_amba |
| Hub and spoke connectivity | `Azure/avm-ptn-alz-connectivity-hub-and-spoke-vnet/azurerm` | 0.16.8 | platform_shared |
| Virtual WAN connectivity | `Azure/avm-ptn-alz-connectivity-virtual-wan/azurerm` | 0.13.5 | platform_shared |
| DNS zones | `Azure/avm-res-network-dnszone/azurerm` | 0.2.1 | platform_connectivity |
| Resource groups | `Azure/avm-res-resources-resourcegroup/azurerm` | 0.2.1 | platform_shared |
| Maintenance configuration | `Azure/avm-res-maintenance-maintenanceconfiguration/azurerm` | 0.1.0 | platform_shared |
| AMBA monitoring | `Azure/avm-ptn-monitoring-amba-alz/azurerm` | latest | platform_amba |
| Regions utility | `Azure/avm-utl-regions/azurerm` | ~> 0.9 | platform_shared, platform_connectivity |
| Workload resources stack | `../../alz-modules/stacks/scc-workload-resources` | local | platform_identity, platform_security, platform_management |
| Platform firewall | `../../alz-modules/modules/scc-azure-platform-firewall` | local | platform_firewall_rules |

## Getting Started

### Prerequisites

- Terraform `~> 1.12`
- Azure CLI with OIDC authentication configured
- Access to the target Azure subscriptions and state storage account

### Common Commands

All commands run from within a `platform_*` directory:

```bash
terraform init -backend-config=backend.conf
terraform plan -input=false -out=tfplan
terraform apply tfplan
terraform validate
terraform fmt -check -recursive
```

## CI/CD

- **CI** ([`.github/workflows/ci.yaml`](.github/workflows/ci.yaml)): Runs on PRs to main. Matrix strategy over platform folders. Validates and plans.
- **CD** ([`.github/workflows/cd.yaml`](.github/workflows/cd.yaml)): Runs on push to main or manual dispatch. Calls a reusable template from `TysonTech-net/alz-mgmt-templates`.
- Authentication is OIDC-based (no stored secrets).

## Related Repos

- **alz-modules**: Reusable Terraform modules and stacks (`../../alz-modules/`)
- **Azure-Landing-Zones-Library**: Microsoft's reference policy library (`../../Azure-Landing-Zones-Library/`)
