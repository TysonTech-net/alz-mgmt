# Identity stack

Purpose: placeholder for identity subscription–specific deployments (none in current code). Keeps its own state file for future additions.

## How to run (no-op today)
```bash
terraform -chdir=stacks/identity init \\
  -backend-config=backend.tfvars

terraform -chdir=stacks/identity plan \\
  -var-file=../platform-landing-zone.auto.tfvars \\
  -var-file=override.tfvars
```

## Notes
- Sets `connectivity_type = "none"` and turns off management resources/groups, so this stack is effectively a no-op until identity resources are added.
- Backend config placeholders—set RG/account/container/key before init.
