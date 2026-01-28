# Connectivity stack

Purpose: deploy only the connectivity landing‑zone resources (hub/spoke VNets, firewalls, bastion, gateways, DNS) to the connectivity subscription, isolated state.

## How to run
```bash
terraform -chdir=stacks/connectivity init \\
  -backend-config=backend.tfvars

terraform -chdir=stacks/connectivity plan \\
  -var-file=../platform-landing-zone.auto.tfvars \\
  -var-file=override.tfvars
```

## Notes
- Uses the shared `platform-landing-zone.auto.tfvars` for naming and IPs.
- Disables management resources and management groups; deploys connectivity only.
- Backend config is placeholder—set your storage account / container / key before init.
