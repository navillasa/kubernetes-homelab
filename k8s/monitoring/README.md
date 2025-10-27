# Monitoring Stack - Prometheus + Grafana

Centralized monitoring for the entire homelab cluster using kube-prometheus-stack.

## Overview

**Stack**: kube-prometheus-stack (Helm chart)
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Alertmanager**: Alert routing and management
- **Node Exporter**: Host-level metrics
- **Kube State Metrics**: Kubernetes resource metrics

**Access**: https://grafana.navillasa.dev

## What's Monitored

The monitoring stack automatically collects metrics from:

- **Kubernetes cluster**: CPU, memory, disk, network
- **All pods and containers** across all namespaces
- **Nodes**: Host-level metrics from wyse-node1
- **System components**: kubelet, kube-apiserver, etc.
- **Applications**:
  - TV Dashboard (backend, frontend, postgres)
  - Multi-cloud LLM Router frontend
  - Vault
  - External Secrets Operator
  - ArgoCD
  - All other deployed apps

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Grafana (Port 80)                    │
│              https://grafana.navillasa.dev              │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Prometheus (Port 9090)                     │
│          Scrapes metrics every 30s                      │
│          Retention: 7 days                              │
│          Storage: 10Gi (microk8s-hostpath)              │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
  ┌──────────┐       ┌─────────────┐    ┌─────────────┐
  │   Node   │       │    Kube     │    │ Application │
  │ Exporter │       │    State    │    │   Metrics   │
  │          │       │   Metrics   │    │  (apps/*/)  │
  └──────────┘       └─────────────┘    └─────────────┘
```

## Installation

Installed via Helm in the `monitoring` namespace.

### Helm Values

The following custom values are used (stored on node1 at `~/kube-prometheus-stack-values.yaml`):

```yaml
grafana:
  enabled: true

  ingress:
    enabled: true
    ingressClassName: public
    hosts:
      - grafana.navillasa.dev
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      nginx.ingress.kubernetes.io/ssl-redirect: "false"
    tls:
      - secretName: grafana-tls
        hosts:
          - grafana.navillasa.dev

  # MicroK8s-specific: skip TLS verification for dashboard sidecar
  sidecar:
    dashboards:
      enabled: true
      env:
        SKIP_TLS_VERIFY: "true"
    datasources:
      enabled: true
      env:
        SKIP_TLS_VERIFY: "true"

prometheus:
  prometheusSpec:
    retention: 7d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: microk8s-hostpath
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

alertmanager:
  enabled: true
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: microk8s-hostpath
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 2Gi
```

### Installation Commands

```bash
# Add Helm repo
microk8s helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
microk8s helm repo update

# Create namespace
microk8s kubectl create namespace monitoring

# Install chart
microk8s helm install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ~/kube-prometheus-stack-values.yaml
```

## Public Access

Grafana is exposed via Cloudflare Tunnel:

1. **Ingress**: MicroK8s nginx ingress routes `grafana.navillasa.dev` to Grafana service
2. **Cloudflare Tunnel**: Routes public HTTPS traffic to localhost:80
3. **DNS**: CNAME `grafana.navillasa.dev` → Cloudflare Tunnel

SSL Mode: **Flexible** (Cloudflare terminates SSL, tunnel to homelab is HTTP)

## Using Grafana

### Pre-installed Dashboards

The stack includes 28 pre-built dashboards automatically provisioned from ConfigMaps. Key ones to check:

**Kubernetes Cluster Monitoring**:
- Browse → Dashboards → search "Kubernetes"
- "Kubernetes / Compute Resources / Cluster" - overall cluster health
- "Kubernetes / Compute Resources / Namespace (Pods)" - per-namespace resource usage
- "Kubernetes / Compute Resources / Pod" - individual pod metrics

**Node Monitoring**:
- "Node Exporter / Nodes" - CPU, memory, disk, network for k8s-node1

**Application Metrics** (if apps expose Prometheus metrics):
- Look for ServiceMonitor resources per application
- TV Dashboard backend exposes metrics at `/metrics`

**Note**: Dashboards are automatically loaded by the Grafana sidecar from ConfigMaps on every pod restart. No manual import needed.

### Creating Custom Dashboards

1. Click "+" → "Dashboard" → "Add visualization"
2. Select "Prometheus" as data source
3. Write PromQL queries (e.g., `rate(http_requests_total[5m])`)
4. Customize visualization and save

## Monitoring Your Applications

### Automatic Service Discovery

Prometheus automatically discovers and scrapes:
- All pods with `prometheus.io/scrape: "true"` annotation
- Kubernetes system components
- Node metrics

### Adding Custom Metrics

To expose metrics from your application:

1. **Instrument your app** with Prometheus client library
2. **Expose `/metrics` endpoint** (e.g., TV Dashboard backend at port 4000)
3. **Create ServiceMonitor** (optional, for custom scrape config):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
  - port: metrics
    interval: 30s
```

## Alerting

Alertmanager is installed but not configured with notification channels yet.

**To configure alerts**:
1. Define PrometheusRule resources with alert conditions
2. Configure Alertmanager receivers (email, Slack, etc.)
3. See [Prometheus alerting docs](https://prometheus.io/docs/alerting/latest/overview/)

## Maintenance

### Check Stack Status

```bash
# All monitoring pods
microk8s kubectl get pods -n monitoring

# Prometheus
microk8s kubectl get prometheus -n monitoring

# Grafana
microk8s kubectl get svc -n monitoring | grep grafana
```

### View Logs

```bash
# Grafana logs
microk8s kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -f

# Prometheus logs
microk8s kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0 -c prometheus -f
```

### Upgrade Stack

```bash
# Update Helm repo
microk8s helm repo update

# Upgrade release
microk8s helm upgrade kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f ~/kube-prometheus-stack-values.yaml
```

### Increase Storage

If you need more storage for metrics:

```bash
# Edit PVC (only works if storage class supports volume expansion)
microk8s kubectl edit pvc -n monitoring prometheus-kube-prometheus-stack-prometheus-db-prometheus-kube-prometheus-stack-prometheus-0

# Or delete PVC and recreate with larger size (will lose historical data)
```

## Storage

### Prometheus Data

- **Location**: `/var/snap/microk8s/common/default-storage/monitoring-prometheus-*`
- **Size**: 10Gi PVC
- **Retention**: 7 days of metrics

### Alertmanager Data

- **Location**: `/var/snap/microk8s/common/default-storage/monitoring-alertmanager-*`
- **Size**: 2Gi PVC

### Grafana Data

- **Dashboards**: Stored in Kubernetes ConfigMaps
- **Settings**: Stored in SQLite database in pod (ephemeral)
- **Note**: Custom dashboards will be lost on pod restart unless exported/backed up

## Troubleshooting

### Grafana Shows "No Data"

**Check Prometheus is running:**
```bash
microk8s kubectl get pods -n monitoring | grep prometheus
```

**Check Prometheus targets:**
- Access Prometheus UI via port-forward:
  ```bash
  microk8s kubectl port-forward -n monitoring prometheus-kube-prometheus-stack-prometheus-0 9090:9090
  ```
- Open http://localhost:9090/targets
- Verify targets are "UP"

### High Memory Usage

Prometheus can use significant memory with many targets.

**Reduce retention period:**
Edit `~/kube-prometheus-stack-values.yaml` and change `retention: 7d` to `retention: 3d`, then upgrade Helm release.

**Reduce scrape frequency:**
Increase `scrapeInterval` from default 30s to 60s in values file.

### Cannot Access Grafana

**Check ingress:**
```bash
microk8s kubectl get ingress -n monitoring
```

**Check Cloudflare Tunnel:**
```bash
sudo systemctl status cloudflared
```

**Test locally:**
```bash
curl -H "Host: grafana.navillasa.dev" http://localhost/
```

## References

- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
