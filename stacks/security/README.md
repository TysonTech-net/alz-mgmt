# Security stack

Purpose: placeholder for security subscription–specific deployments. Uses isolated state so future security resources (e.g., Sentinel, Defender settings) can be added cleanly.

## How to run (no-op today)
```bash
terraform -chdir=../.. init  \\
  -backend-config=stacks/security/backend.tfvars

terraform -chdir=../.. plan \\
  -var-file=platform-landing-zone.auto.tfvars \\
  -var-file=stacks/security/override.tfvars
```

## Notes
- Disables connectivity and management resources; currently results in no changes.
- Backend config placeholders—set RG/account/container/key before init.
