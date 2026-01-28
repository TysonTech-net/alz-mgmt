# Security stack

Purpose: deploy the security subscription resources (security Log Analytics workspace + Microsoft Sentinel onboarding) with isolated state.

## How to run
```bash
terraform -chdir=../.. init  \
  -backend-config=stacks/security/backend.tfvars

terraform -chdir=../.. plan \
  -var-file=platform-landing-zone.auto.tfvars \
  -var-file=stacks/security/override.tfvars
```

## What it deploys
- Security resource group (name from `security_log_analytics_resource_group_name`)
- Log Analytics workspace (name from `security_log_analytics_workspace_name`, retention 90d)
- Sentinel onboarding of that workspace

## Notes
- Disables connectivity and management resources for this stack.
- Backend config placeholders—set RG/account/container/key before init.
