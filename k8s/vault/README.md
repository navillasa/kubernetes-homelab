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
- Vault deployment (persistent storage mode)
- Service (internal only, no public ingress)
- ServiceAccount and RBAC
- PersistentVolumeClaim for storage

## Accessing Vault

Vault is **internal-only** (no public ingress) for security. Access via port-forward:

```bash
kubectl port-forward -n vault svc/vault 8200:8200
# Access at http://localhost:8200
```

## Initial Setup

After deploying, initialize and unseal Vault:

```bash
export VAULT_ADDR='http://127.0.0.1:8200'

# Initialize Vault (first time only)
vault operator init -key-shares=1 -key-threshold=1

# Save the unseal key and root token securely!

# Unseal Vault
vault operator unseal <YOUR_UNSEAL_KEY>

# Login with root token
vault login <YOUR_ROOT_TOKEN>
```

## Configuration

Vault is configured using **Terraform** (Infrastructure as Code). See `../../terraform/vault.tf` for:
- Kubernetes authentication backend
- KV v2 secrets engine
- Policies for External Secrets Operator
- Kubernetes auth roles
- Application secrets (prod and dev)

To apply Vault configuration:

```bash
cd ../../terraform
terraform init
terraform apply
```

This automatically configures Vault and creates all necessary secrets from `terraform.tfvars`.

## Maintenance

### Check Vault Status
```bash
kubectl get pods -n vault
kubectl logs -n vault deployment/vault
```

### Unseal After Restart
Vault needs to be unsealed after pod restarts:
```bash
kubectl port-forward -n vault svc/vault 8200:8200
export VAULT_ADDR='http://127.0.0.1:8200'
vault operator unseal <YOUR_UNSEAL_KEY>
```

### Backup
Important files to back up securely:
- Unseal key(s)
- Root token
- Vault data (PVC backup recommended)

## Notes

- This is a **homelab Vault setup** with persistent storage
- Single-node deployment (no HA)
- Internal-only access (no public exposure)
- Secrets configured via Terraform (Infrastructure as Code)
- For enterprise production, consider:
  - HA deployment (multiple replicas)
  - Auto-unseal with cloud KMS
  - Comprehensive backup and DR procedures
  - TLS/mTLS for all connections
  - Vault Enterprise features
