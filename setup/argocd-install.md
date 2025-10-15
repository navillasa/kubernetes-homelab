# ArgoCD Installation

ArgoCD is installed via kubectl for GitOps continuous deployment.

## Installation

```bash
# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd
```

## Access ArgoCD UI

### Get admin password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo  # Add newline
```

### Port forward (temporary access)
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access at: https://localhost:8080
- Username: `admin`
- Password: (from secret above)

## Create Application

Example: Deploy tv-dashboard-prod

```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tv-dashboard-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/navillasa/tv-dashboard-k8s.git
    targetRevision: main
    path: k8s-gitops/overlays/prod
  destination:
    server: https://kubernetes.default.svc
    namespace: tv-dashboard-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF
```

## Notes

- ArgoCD is Layer 1 infrastructure (depends on Layer 0 being deployed first)
- ArgoCD manages applications, but Layer 0 (Vault, External Secrets) is managed manually with kubectl
- See [TV Dashboard docs](https://github.com/navillasa/tv-dashboard-k8s/blob/main/docs/vault-gitops-decision.md) for architectural reasoning
