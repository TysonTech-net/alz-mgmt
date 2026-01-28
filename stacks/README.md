# Stacks (per-subscription entrypoints)

This folder organizes per-subscription Terraform entrypoints so you can plan/apply connectivity, management, identity, or security independently with their own state files.

Structure:
- `connectivity/` – hub/spoke networking only.
- `management/` – management groups and management resources.
- `identity/` – placeholder for future identity resources.
- `security/` – security Log Analytics workspace + Sentinel onboarding.

Each stack contains:
- `backend.tfvars` – backend settings (fill in storage account/container/key).
- `override.tfvars` – small overlay that toggles modules on/off for that stack.
- `README.md` – how to run init/plan using the shared `platform-landing-zone.auto.tfvars`.

Example (connectivity):
```bash
terraform -chdir=../.. init  -backend-config=stacks/connectivity/backend.tfvars
terraform -chdir=../.. plan  -var-file=platform-landing-zone.auto.tfvars -var-file=stacks/connectivity/override.tfvars
```

Why this helps:
- Separate state per subscription reduces blast radius and clarifies ownership.
- Small overlay files keep the shared naming/address-space config in one place.
