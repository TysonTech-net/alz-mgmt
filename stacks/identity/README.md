# Identity stack

Purpose: placeholder for identity subscription–specific deployments (none in current code). Keeps its own state file for future additions.

## How to run (no-op today)
```bash
terraform -chdir=../.. init  \\
  -backend-config=stacks/identity/backend.tfvars

terraform -chdir=../.. plan \\
  -var-file=platform-landing-zone.auto.tfvars \\
  -var-file=stacks/identity/override.tfvars
```

## Notes
- Sets `connectivity_type = "none"` and turns off management resources/groups, so this stack is effectively a no-op until identity resources are added.
- Backend config placeholders—set RG/account/container/key before init.
