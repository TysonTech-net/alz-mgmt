#!/usr/bin/env bash
set -euo pipefail

echo "Collecting enabled subscriptions for current account..."

SUBS=$(az account list \
  --query "[?state=='Enabled'].id" -o tsv)

if [ -z "$SUBS" ]; then
  echo "No enabled subscriptions visible to this account."
  exit 0
fi

for SUB in $SUBS; do
  echo "Triggering policy scan in subscription: $SUB"
  az account set --subscription "$SUB"
  az policy state trigger-scan
done

echo "Done."
