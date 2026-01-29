#!/usr/bin/env bash
set -euo pipefail

MG="evri"
ASSIGNMENT_ID="/providers/microsoft.management/managementgroups/evri/providers/microsoft.authorization/policyassignments/alllogs-to-rapid7-eh"
INITIATIVE_ID="/providers/microsoft.authorization/policysetdefinitions/85175a36-2f12-419a-96b4-18d5b0096531"
LOCATION="uksouth"

INIT_NAME="${INITIATIVE_ID##*/}"

refs="$(az policy set-definition show \
  --name "$INIT_NAME" \
  --query "policyDefinitions[].policyDefinitionReferenceId" \
  -o tsv)"

if [[ -z "$refs" ]]; then
  echo "No policyDefinitionReferenceId found (refs empty). Check initiative id/name."
  exit 1
fi

for ref in $refs; do
  task="remediate-${ref}"
  task="${task:0:64}"

  echo "Creating remediation: $task"
  az policy remediation create \
    --name "$task" \
    --management-group "$MG" \
    --policy-assignment "$ASSIGNMENT_ID" \
    --definition-reference-id "$ref" \
    --location "$LOCATION" \
    --resource-discovery-mode ExistingNonCompliant \
    -o none
done

echo "Done. List tasks:"
az policy remediation list --management-group "$MG" -o table