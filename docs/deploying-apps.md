# Deploying Applications to Homelab

General guide for deploying applications to the MicroK8s homelab cluster using GitOps.

## Overview

Applications are deployed using:
- **ArgoCD** - GitOps continuous delivery
- **Kustomize** - Kubernetes manifest management
- **HashiCorp Vault** - Secrets management
- **External Secrets Operator** - Syncs secrets from Vault to Kubernetes
- **Cloudflare Tunnel** - Public HTTPS access
- **MicroK8s nginx ingress** - Internal HTTP routing

## Architecture

```
Application Repository
├── k8s-gitops/
│   ├── base/                    # Base Kubernetes manifests
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── overlays/
│       ├── gke/                 # Google Cloud environment
│       └── prod/                # Homelab environment
│           ├── kustomization.yaml
│           ├── external-secret-*.yaml
│           └── *-patch.yaml
```

## Prerequisites

- Application code in Git repository
- Docker images published to container registry (e.g., GitHub Container Registry)
- Access to homelab via SSH
- Vault root token (or appropriate policy)

## Deployment Steps

### 1. Create Kustomize Overlay for Homelab

In your application repository, create an overlay for the homelab prod environment:

```yaml
# k8s-gitops/overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: myapp-prod

resources:
  - ../../base
  - external-secret-database.yaml
  - external-secret-api.yaml

namePrefix: prod-

labels:
  - pairs:
      environment: prod
      cluster: microk8s

patches:
  - path: postgres-homelab-patch.yaml
  - path: ingress-homelab-patch.yaml

images:
  - name: myapp-backend
    newName: ghcr.io/username/myapp/backend
    newTag: v1.0.0
  - name: myapp-frontend
    newName: ghcr.io/username/myapp/frontend
    newTag: v1.0.0
```

### 2. Store Secrets in Vault

SSH into homelab and store application secrets in Vault:

```bash
ssh wyse

# Set Vault environment variables
export VAULT_ADDR='http://vault.vault.svc.cluster.local:8200'
export VAULT_TOKEN='hvs.your-root-token'

# Store database credentials
vault kv put secret/myapp/postgres \
  username=appuser \
  password=securepassword

# Store API keys
vault kv put secret/myapp/api \
  api-key=your-api-key-here

# Verify secrets were stored
vault kv get secret/myapp/postgres
vault kv get secret/myapp/api
```

### 3. Create ExternalSecret Resources

Create ExternalSecret manifests to sync secrets from Vault to Kubernetes:

```yaml
# k8s-gitops/overlays/prod/external-secret-database.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: postgres-secret-from-vault
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: postgres-secret
  data:
    - secretKey: username
      remoteRef:
        key: secret/myapp/postgres
        property: username
    - secretKey: password
      remoteRef:
        key: secret/myapp/postgres
        property: password
```

```yaml
# k8s-gitops/overlays/prod/external-secret-api.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-secrets-from-vault
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: api-secrets
  data:
    - secretKey: api-key
      remoteRef:
        key: secret/myapp/api
        property: api-key
```

### 4. Create Ingress Configuration

Create an ingress patch for homelab deployment:

```yaml
# k8s-gitops/overlays/prod/ingress-homelab-patch.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: public
  rules:
  - host: myapp.navillasa.dev
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 4000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

**Note:** SSL is handled by Cloudflare Tunnel, so we disable ssl-redirect in nginx.

### 5. Configure Cloudflare Tunnel

Add your application's subdomain to the Cloudflare Tunnel configuration:

```bash
ssh wyse
sudo nano /etc/cloudflared/config.yml
```

Add your hostname to the ingress section:

```yaml
tunnel: a94f84ef-4867-4d28-afdf-496afebd6712
credentials-file: /etc/cloudflared/a94f84ef-4867-4d28-afdf-496afebd6712.json

ingress:
  - hostname: myapp.navillasa.dev
    service: http://localhost:80
  - hostname: existing-app.navillasa.dev
    service: http://localhost:80
  - service: http_status:404
```

Create DNS record in Cloudflare:

```bash
cloudflared tunnel route dns tv-dashboard myapp.navillasa.dev
```

Restart cloudflared service:

```bash
sudo systemctl restart cloudflared
sudo systemctl status cloudflared
```

### 6. Deploy with ArgoCD

Create an ArgoCD Application to deploy your app:

```bash
ssh wyse

argocd app create myapp-prod \
  --repo https://github.com/username/myapp.git \
  --path k8s-gitops/overlays/prod \
  --dest-namespace myapp-prod \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

Alternatively, create via YAML manifest:

```yaml
# myapp-argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/username/myapp.git
    targetRevision: main
    path: k8s-gitops/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply the manifest:

```bash
microk8s kubectl apply -f myapp-argocd-app.yaml
```

### 7. Verify Deployment

Check ArgoCD application status:

```bash
argocd app get myapp-prod
argocd app sync myapp-prod  # Force sync if needed
```

Check Kubernetes resources:

```bash
# Check all resources
microk8s kubectl get all -n myapp-prod

# Check pods
microk8s kubectl get pods -n myapp-prod

# Check ExternalSecrets
microk8s kubectl get externalsecret -n myapp-prod
microk8s kubectl get secret -n myapp-prod

# Check ingress
microk8s kubectl get ingress -n myapp-prod

# View logs
microk8s kubectl logs -n myapp-prod deployment/prod-backend -f
```

Test the application:

```bash
# From wyse
curl -H "Host: myapp.navillasa.dev" http://localhost/

# From anywhere
curl https://myapp.navillasa.dev/
```

## Key Differences: Homelab vs. Cloud

### Secrets Management

| Aspect | GCP | Homelab |
|--------|-----|---------|
| Provider | Google Secret Manager | HashiCorp Vault |
| Access | Workload Identity | External Secrets Operator |
| Storage | Managed service | Self-hosted in cluster |

### Ingress & SSL

| Aspect | GCP | Homelab |
|--------|-----|---------|
| Ingress Class | `gce` | `public` (MicroK8s nginx) |
| SSL/TLS | Google-managed certificates | Cloudflare Tunnel (automatic) |
| Load Balancer | Google Cloud Load Balancer | Cloudflare edge network |
| Public Access | Direct via GCP IPs | Via Cloudflare Tunnel |

### Storage

| Aspect | GCP | Homelab |
|--------|-----|---------|
| Type | Google Persistent Disk | Local host storage |
| Provisioning | Dynamic | Manual PVCs |
| Configuration | Default storage class | Custom patches per app |

## Common Patterns & Patches

### Storage Patch for PostgreSQL

```yaml
# postgres-homelab-patch.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: microk8s-hostpath
```

### Backend Deployment Environment Variables

For Node.js backends that make external API calls:

```yaml
# backend-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  template:
    spec:
      containers:
      - name: backend
        env:
        - name: NODE_OPTIONS
          value: "--dns-result-order=ipv4first"
```

This fixes IPv6 timeout issues when pods try to reach external APIs.

## Updating Applications

### Update Application Code

1. Push code changes to repository
2. CI/CD builds and pushes new Docker image with tag
3. Update `kustomization.yaml` image tag:

```yaml
images:
  - name: myapp-backend
    newName: ghcr.io/username/myapp/backend
    newTag: v20251016-abc123  # New tag
```

4. Commit and push
5. ArgoCD auto-syncs (or manually sync: `argocd app sync myapp-prod`)

### Update Secrets

```bash
ssh wyse
export VAULT_ADDR='http://vault.vault.svc.cluster.local:8200'
export VAULT_TOKEN='hvs.your-root-token'

# Update secret
vault kv put secret/myapp/api api-key=new-value

# External Secrets Operator syncs automatically (default: every 1 hour)
# Or delete the Kubernetes secret to force immediate sync:
microk8s kubectl delete secret api-secrets -n myapp-prod
```

## Troubleshooting

### ExternalSecret Shows "SecretSyncedError"

**Symptoms:** ExternalSecret status shows error but secret exists and pods are running.

**Cause:** Timing issue during secret sync.

**Solution:** If the secret exists and pods work, the error can be ignored. Otherwise:

```bash
# Check ExternalSecret details
microk8s kubectl describe externalsecret -n myapp-prod

# Verify secret exists
microk8s kubectl get secret -n myapp-prod

# Check Vault path and values
vault kv get secret/myapp/postgres
```

### Ingress Returns 404

**Symptoms:** Frontend loads but API endpoints return 404.

**Cause:** Ingress path routing or host header mismatch.

**Solution:**

```bash
# Test with correct host header
curl -H "Host: myapp.navillasa.dev" http://localhost/api/endpoint

# Check ingress configuration
microk8s kubectl get ingress -n myapp-prod -o yaml

# Verify backend service exists
microk8s kubectl get svc -n myapp-prod
```

### Backend Can't Connect to External APIs

**Symptoms:** `ETIMEDOUT` errors in backend logs when fetching from external APIs.

**Cause:** IPv6 connectivity issues - pods try IPv6 first but don't have working IPv6 routes.

**Solution:** Add `NODE_OPTIONS` to deployment (see "Backend Deployment Environment Variables" above).

### Site Not Accessible Publicly

**Symptoms:** Site works from wyse localhost but not from internet.

**Solution:**

```bash
# Check Cloudflare Tunnel status
sudo systemctl status cloudflared

# View tunnel logs
sudo journalctl -u cloudflared -f

# Verify DNS
dig myapp.navillasa.dev

# Check tunnel config includes your hostname
cat /etc/cloudflared/config.yml

# Verify ingress uses correct hostname
microk8s kubectl get ingress -n myapp-prod -o yaml | grep host
```

### Pods Stuck in ImagePullBackOff

**Symptoms:** Pods can't pull Docker images.

**Cause:** Image doesn't exist or is private without credentials.

**Solution:**

```bash
# Check pod events
microk8s kubectl describe pod -n myapp-prod <pod-name>

# Verify image exists and tag is correct
# For GitHub Container Registry:
docker pull ghcr.io/username/myapp/backend:v1.0.0

# For private registries, create image pull secret:
microk8s kubectl create secret docker-registry regcred \
  --docker-server=ghcr.io \
  --docker-username=username \
  --docker-password=token \
  -n myapp-prod
```

## References

- [Vault Setup](../k8s/vault/)
- [External Secrets Operator](../k8s/external-secrets/)
- [Cloudflare Tunnel Setup](../setup/cloudflare-tunnel.md)
- [MicroK8s Install](../setup/microk8s-install.md)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize](https://kustomize.io/)
