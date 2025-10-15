#!/bin/bash
# Update Vault Kubernetes auth role for External Secrets Operator
# Run this after deploying the external-secrets infrastructure

set -e

echo "Updating Vault Kubernetes auth role..."

vault write auth/kubernetes/role/external-secrets \
  bound_service_account_names=external-secrets-sa \
  bound_service_account_namespaces=tv-dashboard-prod \
  policies=external-secrets-policy \
  ttl=24h

echo ""
echo "✓ Vault role updated successfully!"
echo ""
echo "To verify:"
echo "  vault read auth/kubernetes/role/external-secrets"
