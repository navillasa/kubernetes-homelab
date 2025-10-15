# External Secrets Infrastructure

This directory contains cluster-wide infrastructure for External Secrets Operator to integrate with HashiCorp Vault.

## Components

### cluster-secret-store.yaml
A `ClusterSecretStore` that defines how to connect to Vault. This is shared across all projects/namespaces in the cluster.

- **Name**: `vault-backend`
- **Vault Server**: `http://vault.vault.svc.cluster.local:8200`
- **KV Mount**: `secret` (v2)
- **Auth Method**: Kubernetes ServiceAccount

### service-account-tv-dashboard-prod.yaml
ServiceAccount and ClusterRoleBinding for the `tv-dashboard-prod` namespace to authenticate with Vault.

- **ServiceAccount**: `external-secrets-sa` in `tv-dashboard-prod` namespace
- **Role**: `system:auth-delegator` (required for Kubernetes auth)

## Deployment

These resources should be applied **once** to the cluster before deploying applications that use External Secrets.

### Quick Deploy

Use the provided deployment script (run on homelab server or with kubectl configured):

```bash
cd /path/to/homelab/k8s/external-secrets
chmod +x deploy.sh update-vault-role.sh
./deploy.sh
```

### Manual Deploy

If you prefer to deploy manually:

```bash
# Deploy ServiceAccount and ClusterSecretStore
kubectl apply -f cluster-secret-store.yaml
kubectl apply -f service-account-tv-dashboard-prod.yaml

# Update Vault role (requires vault CLI and port-forward)
kubectl port-forward -n vault svc/vault 8200:8200 &
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='your-root-token'
./update-vault-role.sh
```

## Adding New Projects

When adding a new project that needs secrets from Vault:

1. **Create a new ServiceAccount file** (e.g., `service-account-other-project-prod.yaml`):
   - Update namespace to your project's namespace
   - Update ClusterRoleBinding name to avoid conflicts
   - Keep ServiceAccount name as `external-secrets-sa` for consistency

2. **Update Vault Kubernetes auth role** to allow the new namespace:
   ```bash
   vault write auth/kubernetes/role/external-secrets \
     bound_service_account_names=external-secrets-sa \
     bound_service_account_namespaces=tv-dashboard-prod,other-project-prod \
     policies=external-secrets-policy \
     ttl=24h
   ```

3. **Apply the new ServiceAccount**:
   ```bash
   kubectl apply -f service-account-other-project-prod.yaml
   ```

4. **In your project's manifests**, reference the shared ClusterSecretStore:
   ```yaml
   spec:
     secretStoreRef:
       name: vault-backend
       kind: ClusterSecretStore
   ```

## Vault Configuration

The Vault Kubernetes auth role must allow the service accounts and namespaces:

```bash
vault write auth/kubernetes/role/external-secrets \
  bound_service_account_names=external-secrets-sa \
  bound_service_account_namespaces=tv-dashboard-prod \
  policies=external-secrets-policy \
  ttl=24h
```

## Notes

- The ClusterSecretStore is cluster-scoped and shared across all projects
- Each project namespace needs its own ServiceAccount
- ServiceAccount name is consistent (`external-secrets-sa`) across namespaces
- Vault secrets are organized by project: `secret/tv-dashboard/*`, `secret/other-project/*`
