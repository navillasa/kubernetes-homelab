# HashiCorp Vault

This directory contains the Kubernetes manifests for deploying HashiCorp Vault as Layer 0 infrastructure for the homelab.

## Overview

Vault provides secrets management for all applications in the cluster. It's deployed outside of ArgoCD to avoid circular dependencies (ArgoCD needs secrets from Vault, but if Vault was managed by ArgoCD, there would be a bootstrap problem).

## Architecture Decision

See [tv-dashboard-k8s docs](https://github.com/navillasa/tv-dashboard-k8s/blob/main/docs/vault-gitops-decision.md) for the full explanation of why Vault is kept outside of GitOps.

**TL;DR**: Vault is Layer 0 infrastructure that should be stable and simple to manage, deployed manually with `kubectl apply`.

## Deployment

Deploy Vault to the cluster:

```bash
cd /path/to/homelab/k8s/vault
kubectl apply -k .
```

This creates:
- `vault` namespace
- Vault deployment (dev mode for homelab)
- Service and Ingress
- ServiceAccount and RBAC
- PersistentVolumeClaim for storage

## Initial Setup

After deploying, you need to initialize and unseal Vault:

```bash
# Port forward to Vault
kubectl port-forward -n vault svc/vault 8200:8200

# Initialize Vault (first time only)
vault operator init -key-shares=1 -key-threshold=1

# Save the unseal key and root token securely!

# Unseal Vault
vault operator unseal <UNSEAL_KEY>

# Login with root token
vault login <ROOT_TOKEN>
```

## Configuration

After Vault is running, configure it for use with External Secrets Operator:

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

# Enable KV v2 secrets engine (if not already enabled)
vault secrets enable -path=secret kv-v2

# Create policy for External Secrets Operator
vault policy write external-secrets-policy - <<EOF
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOF

# Create Kubernetes auth role
vault write auth/kubernetes/role/external-secrets \
  bound_service_account_names=external-secrets-sa \
  bound_service_account_namespaces=tv-dashboard-prod \
  policies=external-secrets-policy \
  ttl=24h
```

## Adding Secrets

Store secrets for your applications:

```bash
# Database credentials for tv-dashboard
vault kv put secret/prod/database \
  postgres_user=myuser \
  postgres_password=mypassword \
  postgres_db=tvshows

# API keys for tv-dashboard
vault kv put secret/prod/api \
  tmdb_api_key=your_api_key_here
```

## Maintenance

### Check Vault Status
```bash
kubectl get pods -n vault
kubectl logs -n vault deployment/vault
```

### Unseal After Restart
Vault in dev mode auto-unseals, but in production mode you'd need to unseal after pod restarts:
```bash
kubectl port-forward -n vault svc/vault 8200:8200
vault operator unseal <UNSEAL_KEY>
```

### Backup
Important files to back up securely (NOT in git):
- Unseal key(s)
- Root token
- Recovery keys (if using auto-unseal)

## Notes

- This is a **development Vault setup** suitable for homelab
- For production, use:
  - HA deployment (multiple replicas)
  - Auto-unseal with cloud KMS
  - Proper backup and DR procedures
  - TLS/mTLS for all connections
- Dev mode Vault stores data in memory - use persistent storage for production
