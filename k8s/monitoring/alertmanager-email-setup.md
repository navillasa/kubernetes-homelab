# Alertmanager Email Notifications Setup

Email notifications are configured for Mini LLM alerts to send to my email.

## Mini LLM Alerts Configured

The following alerts will trigger email notifications:

1. **MiniLLMHighCPU** - CPU usage > 80% for 5 minutes
2. **MiniLLMMany503Errors** - More than 5 req/min with 503 errors
3. **MiniLLMModelNotLoaded** - LLM model fails to load (critical)
4. **MiniLLMHighMemory** - Memory usage > 2.5GB for 5 minutes

## Testing

Send a test alert:

```bash
ssh node1-ts "microk8s kubectl run curl-test --image=curlimages/curl --rm -i --restart=Never -- \
  curl -X POST -H 'Content-Type: application/json' \
  http://kube-prometheus-stack-alertmanager.monitoring:9093/api/v2/alerts -d '[{
    \"labels\": {
      \"alertname\": \"TestAlert\",
      \"severity\": \"warning\",
      \"component\": \"mini-llm\"
    },
    \"annotations\": {
      \"summary\": \"Test alert\",
      \"description\": \"Testing email notifications\"
    },
    \"startsAt\": \"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'\"
  }]'"
```

## Updating the Configuration

The Alertmanager configuration is stored in:
```bash
kubectl get secret -n monitoring alertmanager-kube-prometheus-stack-alertmanager -o yaml
```
