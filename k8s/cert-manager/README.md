# cert-manager

cert-manager automates TLS certificate management in Kubernetes, including automatic certificate renewal from Let's Encrypt.

## Installation

cert-manager is installed via MicroK8s addon:

```bash
microk8s enable cert-manager
```

## ClusterIssuer

The ClusterIssuer is a cluster-wide resource that defines how certificates are obtained. This homelab uses Let's Encrypt for free, automated TLS certificates.

### Deploy ClusterIssuer

```bash
kubectl apply -f cluster-issuer-letsencrypt.yaml
```

### Verify

```bash
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

## Usage in Applications

Applications can request certificates by adding annotations to their Ingress resources:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-tls
  rules:
  - host: example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: example-service
            port:
              number: 80
```

cert-manager will automatically create a Certificate resource and handle the ACME challenge to obtain a valid TLS certificate.

## References

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
