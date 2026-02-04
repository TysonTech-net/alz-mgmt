# Platform Shared Policy Library

This library contains custom Azure Policy definitions, assignments, and archetype overrides for the Azure Landing Zone (ALZ) deployment. The policies enforce governance, security, compliance, and monitoring standards across the management group hierarchy.

## Overview

This policy library is designed to be **reusable and generic**, using archetype-based policy assignments that can be applied to any Azure Landing Zone deployment regardless of specific management group names.

### Policy Strategy

- **AMBA (Azure Monitor Baseline Alerts)**: Deployed separately in `platform_amba` - handles reactive monitoring with metric and activity log alerts
- **ALZ Library Policies**: Deployed via this library - handles proactive controls including diagnostics, security, compliance, and encryption
- **Custom Policies**: Organization-specific policies for tagging, resource locks, and activity log routing

**Key Insight**: AMBA and ALZ policies are complementary, not overlapping:
- AMBA = Reactive alerts when thresholds are breached
- ALZ = Proactive log collection and security controls

## Architecture

### Management Group Hierarchy & Archetypes

Policies are assigned to **archetypes** that map to management groups in the ALZ hierarchy:

```
root_custom (Root MG)
├── platform_custom (Platform MG)
│   ├── connectivity_custom (Connectivity/Network MG)
│   ├── management_custom (Management MG)
│   ├── identity_custom (Identity MG)
│   └── security_custom (Security MG)
└── landing_zones_custom (Landing Zones MG)
    ├── corp_custom (Corp Landing Zones)
    ├── online_custom (Online Landing Zones)
    └── sandbox_custom (Sandbox Landing Zones)
```

### Archetype Inheritance

Policies assigned to parent archetypes automatically apply to child management groups unless explicitly removed.

## Current Policy Assignments

### Root Archetype (root_custom)

Applied to: Root management group and inherited by all child MGs

| Policy Assignment | Effect | Description |
|---|---|---|
| **UK-Official-and-UK-NHS** | Audit | UK OFFICIAL and UK NHS compliance standards |
| **CIS-Msft-Benchmark-v2** | Audit | CIS Microsoft Azure Foundations Benchmark v2.0 |
| **Deploy-Diag-LogsCat** | DeployIfNotExists | Deploys diagnostic settings to send allLogs category group to Log Analytics |
| **Enable-Azure-Monitor-VM** | DeployIfNotExists | Deploys Azure Monitor Agent (AMA) to VMs and VMSSs for monitoring |
| **Append-Tag-From-RG** | Append | Inherits tags from resource group to child resources |
| **Audit-Tags-Mandatory** | Audit | Audits resources for required tags (configurable via `mandatory_tags` variable) |

**Custom Policy Definitions** (referenced by root_custom):
- `Enforce-Resource-Tag` - Enforces required tags on resources
- `Enforce-VM-Tag-and-Values` - Enforces specific tag values on VMs
- `ActivityLog-To-EH` - Routes activity logs to Event Hub for retention/SIEM

### Platform Archetype (platform_custom)

Applied to: Platform management group (parent of connectivity, management, identity, security)

**Current Status**: No additional policies assigned (inherits from root_custom)

**Note**: The platform archetype has removed several Azure Monitor Agent (AMA) policies from the base ALZ library to avoid conflicts with custom monitoring configurations.

### Connectivity Archetype (connectivity_custom)

Applied to: Connectivity/Network management group

**Current Status**: No additional policies assigned (inherits from root_custom and platform_custom)

**Note**: DDoS Protection VNET policy (`Enable-DDoS-VNET`) has been removed from this archetype.

### Management Archetype (management_custom)

Applied to: Management management group (typically contains Log Analytics workspace, Automation Accounts)

**Current Status**: No additional policies assigned (inherits from root_custom and platform_custom)

### Identity Archetype (identity_custom)

Applied to: Identity management group (typically contains domain controllers, identity resources)

**Current Status**: No additional policies assigned (inherits from root_custom and platform_custom)

### Security Archetype (security_custom)

Applied to: Security management group (typically contains security tooling like Defender, Sentinel)

**Current Status**: No additional policies assigned (inherits from root_custom and platform_custom)

### Landing Zones Archetype (landing_zones_custom)

Applied to: Landing Zones management group (parent of corp, online, sandbox)

**Current Status**: No additional policies assigned (inherits from root_custom)

**Note**: DDoS Protection and AMA policies have been removed from this archetype.

### Corp Archetype (corp_custom)

Applied to: Corporate landing zones (typically for internal workloads with hybrid connectivity)

**Current Status**: No additional policies assigned (inherits from landing_zones_custom and root_custom)

### Online Archetype (online_custom)

Applied to: Online landing zones (typically for internet-facing workloads)

**Current Status**: No additional policies assigned (inherits from landing_zones_custom and root_custom)

### Sandbox Archetype (sandbox_custom)

Applied to: Sandbox landing zones (typically for experimentation with relaxed policies)

**Current Status**: No additional policies assigned (inherits from landing_zones_custom and root_custom)

## Custom Policy Definitions

### 1. Enforce-Resource-Tag
**File**: `policy_definitions/enforce_resource_tag.alz_policy_definition.json`
**Effect**: Deny
**Description**: Enforces mandatory tags on Azure resources. Resources without required tags will be denied deployment.

### 2. Enforce-VM-Tag-and-Values
**File**: `policy_definitions/enforce_vm_tag_and_values.alz_policy_definition.json`
**Effect**: Deny
**Description**: Enforces specific tag values on virtual machines. VMs with incorrect or missing tag values will be denied deployment.

### 3. ActivityLog-To-EH
**File**: `policy_definitions/activity_logs_to_event_hub.alz_policy_definition.json`
**Effect**: DeployIfNotExists
**Description**: Deploys diagnostic settings to route Azure Activity Logs to an Event Hub for long-term retention or SIEM integration.

### 4. Deploy-Lock-Resource-Groups
**File**: `policy_definitions/deploy_lock_resource_groups.alz_policy_definition.json`
**Effect**: DeployIfNotExists
**Description**: Deploys resource locks on resource groups to prevent accidental deletion. (Currently commented out in archetype)

## Policy Assignment Files

Policy assignment JSON files define **HOW** to assign a policy, including:
- Policy definition reference (from ALZ library or custom definitions)
- Parameter values (Log Analytics workspace ID, tag names, etc.)
- Enforcement mode (`Default` or `DoNotEnforce`)
- Managed identity requirements (for DeployIfNotExists/Modify policies)
- Scope variables (`${current_scope_resource_id}`, `${default_location}`)

### Current Assignment Files

| File | Policy Name | Effect | Parameters |
|---|---|---|---|
| `append_tag_from_rg.alz_policy_assignment.json` | Append-Tag-From-RG | Append | Tag names to inherit from RG |
| `associate_dcr_win_eventlogs.alz_policy_assignment.json` | Win-VM-Eventlogs-DCR | DeployIfNotExists | Data Collection Rule ID for Windows event logs (currently disabled) |
| `cis.alz_policy_assignment.json` | CIS-Msft-Benchmark-v2 | Audit | CIS benchmark policy set assignment |
| `deploy_diag_logscat.alz_policy_assignment.json` | Deploy-Diag-LogsCat | DeployIfNotExists | Log Analytics workspace ID, logs/metrics enabled |
| `enable_azure_monitor_vm.alz_policy_assignment.json` | Enable-Azure-Monitor-VM | DeployIfNotExists | Data Collection Rule ID, user-assigned managed identity |
| `uk_official_and_uk_nhs.alz_policy_assignment.json` | UK-Official-and-UK-NHS | Audit | UK government compliance policy set |

## Roadmap: ALZ Library Policy Expansion

The following ALZ library policies are planned to be added to this library for enhanced governance, security, and monitoring.

### Phase 1: Essential Deploy-Diagnostics Policies (AUTO-REMEDIATION)

**Priority**: HIGH - These DeployIfNotExists policies will automatically configure diagnostic settings on resources when created or updated.

#### Connectivity Archetype
- `Deploy-Diagnostics-VNetGW` - VPN Gateway diagnostics
- `Deploy-Diagnostics-ExpressRoute` - ExpressRoute circuit diagnostics
- `Deploy-Diagnostics-Firewall` - Azure Firewall logs
- `Deploy-Diagnostics-VirtualNetwork` - VNet diagnostic logs
- `Deploy-Diagnostics-LoadBalancer` - Load balancer health and performance
- `Deploy-Diagnostics-ApplicationGateway` - App Gateway WAF and access logs
- `Deploy-Diagnostics-Bastion` - Bastion connection logs
- `Deploy-Diagnostics-NetworkSecurityGroups` - NSG flow logs
- `Deploy-Nsg-FlowLogs` (or `Deploy-Nsg-FlowLogs-to-LA`) - NSG flow logging to Log Analytics

#### Management Archetype
- `Deploy-Diagnostics-LogAnalytics` - Log Analytics workspace diagnostics
- `Deploy-Diagnostics-AA` - Automation Account logs
- `Deploy-Diagnostics-RecoveryVault` - Backup vault diagnostics (if available in ALZ)

#### Landing Zones Archetype
- `Deploy-Diagnostics-VM` - Virtual machine diagnostics
- `Deploy-Diagnostics-VMSS` - VM Scale Set diagnostics
- `Deploy-Diagnostics-Website` (or `Deploy-Diagnostics-AppService`) - App Service logs
- `Deploy-Diagnostics-Function` - Function App logs
- `Deploy-Diagnostics-SQLElasticPools` - SQL Elastic Pool diagnostics
- `Deploy-Diagnostics-SQLMI` - SQL Managed Instance logs
- `Deploy-Diagnostics-PostgreSQL` - PostgreSQL database logs
- `Deploy-Diagnostics-MySQL` - MySQL database logs
- `Deploy-Diagnostics-CosmosDB` - Cosmos DB query and request logs
- `Deploy-Diagnostics-ACR` - Container Registry operations
- `Deploy-Diagnostics-KeyVault` - Key Vault access auditing (if available)

**Total**: 16+ essential diagnostic policies

### Phase 2: Backup & Disaster Recovery (AUTO-REMEDIATION)

**Priority**: HIGH - Replaces old backup policies with ALZ standard

#### Root Archetype
- `Deploy-VM-Backup` - Auto-configures VM backup to Recovery Services Vault (replaces `Audit-VM-Backups`)
- `Enforce-Backup` (Policy Set) - Comprehensive backup enforcement for VMs, SQL, File Shares, etc. (replaces `Enforce-VM-Backup-RSV`)
- `Enforce-ASR` - Azure Site Recovery configuration for disaster recovery

### Phase 3: Security & Compliance (PREVENTIVE + AUTO-REMEDIATION)

**Priority**: MEDIUM - Hardens security posture

#### Root Archetype (Deny Policies)
- `Deny-IP-forwarding` - Prevents IP forwarding on NICs
- `Deny-MgmtPorts-From-Internet` - Blocks RDP/SSH from internet
- `Deny-Subnet-Without-Nsg` - Requires NSGs on subnets
- `DenyAction-DeleteProtection` (Policy Set) - Prevents accidental deletions

#### Root Archetype (Deploy Policies)
- `Deploy-AzActivity-Log` - Routes activity logs to Log Analytics

#### Platform Archetype
- `Deny-Storage-http` - Forces HTTPS on storage accounts
- `Deploy-Storage-sslEnforcement` - Enables HTTPS on storage (auto-remediation)

#### Landing Zones Archetype
- `Deploy-SQL-TDE` - Enables Transparent Data Encryption on SQL databases
- `Deploy-Private-DNS-Zones` (Policy Set) - Creates private DNS zones for Private Link

#### Corp Archetype
- `Deny-Public-IP-On-NIC` - Prevents public IPs on NICs
- `Deny-Public-Endpoints` - Blocks public endpoints on PaaS services

### Phase 4: Monitoring & Change Tracking (AUTO-REMEDIATION)

**Priority**: MEDIUM

- `Deploy-VM-ChangeTrack` - Change tracking for VMs
- `Deploy-VMSS-ChangeTrack` - Change tracking for VM Scale Sets
- `Deploy-vmArc-ChangeTrack` - Change tracking for Arc-enabled servers
- `Enable-AUM-CheckUpdates` (Policy Set) - Azure Update Manager
- `Deploy-VM-Monitoring` - VM insights and performance monitoring
- `Deploy-VMSS-Monitoring` - VMSS insights

### Phase 5: Defender for Cloud (MDFC)

**Priority**: MEDIUM

- `Deploy-MDFC-Config-H224` (Policy Set) - Microsoft Defender for Cloud configuration
- `Deploy-MDFC-DefenderSQL-AMA` (Policy Set) - Defender for SQL with Azure Monitor Agent
- `Deploy-ASC-SecurityContacts` - Security contact configuration
- `Deploy-MDFC-OssDb` - Defender for open-source databases
- `Deploy-MDFC-SqlAtp` - Advanced Threat Protection for SQL

## Policy Parameters

### Common Template Variables

Policy assignments use template variables that are resolved at deployment time:

| Variable | Description | Example |
|---|---|---|
| `${current_scope_resource_id}` | Resource ID of the management group where policy is assigned | `/providers/Microsoft.Management/managementGroups/mg-platform` |
| `${default_location}` | Primary Azure region for the deployment | `uksouth` |
| `${log_analytics_workspace_id}` | Resource ID of the Log Analytics workspace | `/subscriptions/.../resourceGroups/.../providers/Microsoft.OperationalInsights/workspaces/law-...` |

### Log Analytics Workspace

Many diagnostic policies require the Log Analytics workspace resource ID as a parameter. This workspace is deployed as part of the `platform_shared` module using the ESLZ (Enterprise-Scale Landing Zone) accelerator.

**Common Parameters**:
- `logAnalytics` or `logAnalyticsWorkspaceId` - The workspace resource ID
- `profileName` - Diagnostic setting name (typically `"setByPolicy"`)
- `logsEnabled` - Boolean to enable logs (typically `true`)
- `metricsEnabled` - Boolean to enable metrics (typically `true`)

## Managed Identities

**DeployIfNotExists** and **Modify** policies require a managed identity to perform automatic remediation actions.

### System-Assigned Managed Identity

Most auto-remediation policies use a **system-assigned managed identity** created automatically at policy assignment:

```json
"identity": {
  "type": "SystemAssigned"
}
```

**Required Permissions**:
- `Contributor` role at the policy assignment scope, OR
- Specific resource permissions (e.g., `Network Contributor` for NSG policies, `Log Analytics Contributor` for diagnostic policies)

### User-Assigned Managed Identity

Some policies (like `Enable-Azure-Monitor-VM`) may use a **user-assigned managed identity** for more granular control:

```json
"identity": {
  "type": "UserAssigned",
  "userAssignedIdentities": {
    "${user_assigned_identity_id}": {}
  }
}
```

## Enforcement Modes

Policies can be deployed in two enforcement modes:

| Mode | Behavior | Use Case |
|---|---|---|
| **Default** | Policy is actively enforced (blocks non-compliant resources or auto-remediates) | Production enforcement after testing |
| **DoNotEnforce** | Policy evaluates compliance but does not block or remediate | Testing and compliance reporting |

**Recommended Approach**:
1. Deploy new policies in `DoNotEnforce` mode first
2. Review compliance results in Azure Policy dashboard
3. Switch to `Default` enforcement after validating no negative impacts

## Remediation Tasks

For **existing resources**, DeployIfNotExists policies do not automatically remediate until a **remediation task** is created.

**Steps**:
1. Assign the policy with enforcement mode set to `Default`
2. Create a remediation task in the Azure Portal (Policy > Remediation)
3. The policy will deploy configurations (diagnostic settings, agents, etc.) to all existing non-compliant resources

**New resources** are automatically remediated when they are created or updated.

### Troubleshooting: Remediation Tasks Not Working

**Symptom**: Creating a remediation task in Azure Portal appears to work but nothing happens, or remediation tasks fail immediately.

**Cause**: The policy assignment's managed identity doesn't have the necessary role assignments to perform remediation.

**Solution**: Manually assign roles to the managed identity.

#### For Deploy-Diag-LogsCat (Comprehensive Diagnostic Settings)

This policy covers multiple resource types, so it needs broad permissions:

```bash
# Get the policy assignment's managed identity principal ID
PRINCIPAL_ID=$(az policy assignment show \
  --name "Deploy-Diag-LogsCat" \
  --scope "/providers/Microsoft.Management/managementGroups/<your-mg-id>" \
  --query identity.principalId -o tsv)

# Assign Contributor role at the management group scope
az role assignment create \
  --assignee "$PRINCIPAL_ID" \
  --role "Contributor" \
  --scope "/providers/Microsoft.Management/managementGroups/<your-mg-id>"
```

**Alternative**: Use the provided script at [`assign_policy_roles.sh`](../assign_policy_roles.sh) which automates this process.

**Why this is needed**: Some built-in policies (especially for resources like Public IP addresses) don't include `roleDefinitionIds` in their policy definitions, so Azure doesn't automatically grant permissions to the managed identity.

**After assigning roles**:
1. Wait 5-10 minutes for role assignment propagation
2. Try creating the remediation task again
3. Monitor remediation progress in Azure Portal > Policy > Remediation

## Testing Approach

1. **Phase 1 - Audit Mode**: Deploy policies in `DoNotEnforce` mode to assess compliance
2. **Phase 2 - Review**: Check Azure Policy compliance dashboard for non-compliant resources
3. **Phase 3 - Validate**: Ensure policies don't block legitimate workloads
4. **Phase 4 - Enforce**: Switch to `Default` enforcement mode
5. **Phase 5 - Remediate**: Create remediation tasks for existing resources
6. **Phase 6 - Monitor**: Watch Log Analytics workspace costs as diagnostic settings increase log ingestion

## ALZ Library Reference

This deployment uses the **Azure Landing Zones (ALZ) library** version `2025.09.3` via the Terraform `alz` provider:

```terraform
provider "alz" {
  library_references = [
    {
      path = "platform/alz"
      ref  = "2025.09.3"
    }
  ]
}
```

**Key Point**: You do NOT need to copy policy definitions from the ALZ library into `lib/policy_definitions/` - the provider automatically pulls them. Only create:
1. **Policy assignment JSON files** in `lib/policy_assignments/` (defines HOW to assign)
2. **Archetype override YAML files** in `lib/archetype_definitions/` (defines WHICH assignments go WHERE)

## Policy vs Policy Set Definitions

- **Policy Definition**: A single policy rule (e.g., "Deploy diagnostic settings for Key Vault")
- **Policy Set Definition** (Initiative): A collection of related policies grouped together (e.g., "Enforce-Backup" contains policies for VM backup, SQL backup, File Share backup)

Policy sets simplify management by allowing you to assign multiple related policies in a single assignment.

## File Structure

```
platform_shared/lib/
├── README.md (this file)
├── archetype_definitions/
│   ├── root_custom.alz_archetype_override.yaml
│   ├── platform_custom.alz_archetype_override.yaml
│   ├── connectivity_custom.alz_archetype_override.yaml
│   ├── management_custom.alz_archetype_override.yaml
│   ├── identity_custom.alz_archetype_override.yaml
│   ├── security_custom.alz_archetype_override.yaml
│   ├── landing_zones_custom.alz_archetype_override.yaml
│   ├── corp_custom.alz_archetype_override.yaml
│   ├── online_custom.alz_archetype_override.yaml
│   ├── sandbox_custom.alz_archetype_override.yaml
│   └── decommissioned_custom.alz_archetype_override.yaml
├── policy_assignments/
│   ├── append_tag_from_rg.alz_policy_assignment.json
│   ├── associate_dcr_win_eventlogs.alz_policy_assignment.json
│   ├── cis.alz_policy_assignment.json
│   ├── deploy_diag_logscat.alz_policy_assignment.json
│   ├── enable_azure_monitor_vm.alz_policy_assignment.json
│   └── uk_official_and_uk_nhs.alz_policy_assignment.json
├── policy_definitions/
│   ├── activity_logs_to_event_hub.alz_policy_definition.json
│   ├── deploy_lock_resource_groups.alz_policy_definition.json
│   ├── enforce_resource_tag.alz_policy_definition.json
│   └── enforce_vm_tag_and_values.alz_policy_definition.json
└── policy_set_definitions/
    └── (empty - using ALZ library policy sets)
```

## Relationship to AMBA

This library is complementary to the **Azure Monitor Baseline Alerts (AMBA)** deployment in `platform_amba`:

| Aspect | Platform_Shared (This Library) | Platform_AMBA |
|---|---|---|
| **Purpose** | Proactive governance, diagnostics, security | Reactive alerting and notifications |
| **Policy Count** | 6 current + 18+ planned | 132 alert policies |
| **Policy Types** | DeployIfNotExists (diagnostics), Deny (security), Audit (compliance) | DeployIfNotExists (alerts), Modify (action groups) |
| **Focus** | Log collection, security hardening, compliance | Metric alerts, activity log alerts |
| **Log Analytics** | Sends diagnostic logs TO Log Analytics | Queries metrics/logs FROM Log Analytics to trigger alerts |
| **Example Policies** | `Deploy-Diagnostics-VM` (collects VM logs) | `Deploy_VM_CPU_Alert` (alerts on high CPU) |

**Both are required** for comprehensive Azure monitoring and governance.

## Additional Resources

- [Azure Landing Zones Library Documentation](https://github.com/Azure/Azure-Landing-Zones-Library)
- [Azure Policy Documentation](https://learn.microsoft.com/en-us/azure/governance/policy/)
- [AMBA Documentation](https://azure.github.io/azure-monitor-baseline-alerts/)
- [ALZ Terraform Provider](https://registry.terraform.io/providers/Azure/alz/latest/docs)

## Change Log

### 2026-02-02
- **Removed**: `Audit-VM-Backups` and `Enforce-VM-Backup-RSV` policy assignments (redundant with planned ALZ alternatives)
- **Updated**: `root_custom` archetype to remove old backup policies
- **Added**: This comprehensive README documentation

---

**Note**: This library uses generic archetype names (root_custom, platform_custom, etc.) to ensure reusability across different Azure Landing Zone deployments. Specific management group names are configured in the Terraform deployment variables, not hardcoded in the policy library.
