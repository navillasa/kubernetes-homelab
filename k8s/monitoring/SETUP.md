# Mini LLM Monitoring Setup

This directory contains the configuration for exposing the Mini LLM Grafana dashboard at `mini-llm-monitoring.navillasa.dev`.

## Kubernetes Resources

Apply these resources to set up the monitoring endpoint:

```bash
kubectl apply -f mini-llm-monitoring-certificate.yaml
kubectl apply -f mini-llm-monitoring-ingress.yaml
```

## Additional Node Configuration

### 1. Cloudflare Tunnel Configuration

Add the monitoring subdomain to `/etc/cloudflared/config.yml` on node1:

```yaml
ingress:
  # ... other entries ...
  - hostname: mini-llm-monitoring.navillasa.dev
    service: http://localhost:80
  # ... rest of config ...
```

After updating, restart cloudflared:
```bash
sudo systemctl restart cloudflared
```

### 2. CoreDNS Configuration (Optional but Recommended)

If your local DNS server doesn't resolve external domains properly, update CoreDNS to use public DNS servers.

Edit the CoreDNS ConfigMap:
```bash
kubectl edit configmap coredns -n kube-system
```

Change the `forward` line from:
```
forward . /etc/resolv.conf
```

To:
```
forward . 8.8.8.8 1.1.1.1
```

Then restart CoreDNS:
```bash
kubectl rollout restart deployment/coredns -n kube-system
```

## DNS Configuration

In Cloudflare DNS settings for `navillasa.dev`:

- **Type**: CNAME
- **Name**: `mini-llm-monitoring`
- **Target**: `a94f84ef-4867-4d28-afdf-496afebd6712.cfargotunnel.com`
- **Proxy status**: Proxied (orange cloud)
- **TTL**: Auto

## How It Works

1. User visits `https://mini-llm-monitoring.navillasa.dev/`
2. Cloudflare Tunnel routes traffic to the cluster
3. Nginx ingress redirects `/` to the Mini LLM dashboard
4. Grafana serves the dashboard at `/d/mini-llm-metrics/mini-llm-metrics`

The certificate is automatically issued by cert-manager using Let's Encrypt.
