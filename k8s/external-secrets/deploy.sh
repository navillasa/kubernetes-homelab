#!/bin/bash
# Deploy External Secrets infrastructure to homelab cluster
# This should be run ON the homelab server (or with kubectl configured to access it)

set -e

echo "========================================="
echo "Deploying External Secrets Infrastructure"
echo "========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Step 1: Deploying ServiceAccount and ClusterRoleBinding..."
kubectl apply -f "$SCRIPT_DIR/service-account-tv-dashboard-prod.yaml"
echo "✓ ServiceAccount deployed"
echo ""

echo "Step 2: Deploying ClusterSecretStore..."
kubectl apply -f "$SCRIPT_DIR/cluster-secret-store.yaml"
echo "✓ ClusterSecretStore deployed"
echo ""

echo "Step 3: Updating Vault Kubernetes auth role..."
echo "NOTE: This requires vault CLI and VAULT_ADDR/VAULT_TOKEN to be set"
echo ""

if command -v vault &> /dev/null; then
    if [ -z "$VAULT_TOKEN" ]; then
        echo "⚠  VAULT_TOKEN not set. Please set it and run:"
        echo "   export VAULT_ADDR='http://127.0.0.1:8200'"
        echo "   export VAULT_TOKEN='your-root-token'"
        echo "   $SCRIPT_DIR/update-vault-role.sh"
    else
        echo "Updating Vault role..."
        vault write auth/kubernetes/role/external-secrets \
          bound_service_account_names=external-secrets-sa \
          bound_service_account_namespaces=tv-dashboard-prod \
          policies=external-secrets-policy \
          ttl=24h
        echo "✓ Vault role updated"
    fi
else
    echo "⚠  vault CLI not found. Please install it and run:"
    echo "   $SCRIPT_DIR/update-vault-role.sh"
fi

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "To verify:"
echo "  kubectl get clustersecretsecrets vault-backend"
echo "  kubectl get sa -n tv-dashboard-prod external-secrets-sa"
echo "  kubectl describe clustersecretsecrets vault-backend"
echo ""
