# Management stack

Purpose: deploy management groups and management resources (Log Analytics, DCRs, policies) to the management subscription with its own state.

## How to run
```bash
terraform -chdir=../.. init  \\
  -backend-config=stacks/management/backend.tfvars

terraform -chdir=../.. plan \\
  -var-file=platform-landing-zone.auto.tfvars \\
  -var-file=stacks/management/override.tfvars
```

## Notes
- Disables connectivity deployment by setting `connectivity_type = "none"`.
- Leaves management resources and management groups enabled.
- Backend config placeholders—set RG/account/container/key before init.
