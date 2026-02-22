#!/bin/bash
# Startup script for homelab - run from laptop
# Works after both graceful shutdowns and unexpected power loss (e.g. power outage)

NODE=node1

echo "========================================="
echo "Homelab Startup"
echo "========================================="
echo ""

# 1. Wait for node1 to be reachable
echo "Step 1/5: Waiting for node1 to be reachable..."
until ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $NODE "exit" 2>/dev/null; do
  echo "  node1 not reachable yet, retrying in 5s..."
  sleep 5
done
echo "✓ node1 is reachable"
echo ""

# 2. Start MicroK8s if not running
echo "Step 2/5: Checking MicroK8s..."
MICROK8S_STATUS=$(ssh $NODE "microk8s status 2>/dev/null | head -1")
if echo "$MICROK8S_STATUS" | grep -q "microk8s is not running"; then
  echo "  Starting MicroK8s..."
  ssh $NODE "microk8s start"
  ssh $NODE "microk8s status --wait-ready"
  echo "✓ MicroK8s started"
else
  echo "✓ MicroK8s already running"
fi
echo ""

# 3. Uncordon node if cordoned
echo "Step 3/5: Checking node cordon status..."
NODE_NAME=$(ssh $NODE "microk8s kubectl get nodes -o jsonpath='{.items[0].metadata.name}'")
CORDONED=$(ssh $NODE "microk8s kubectl get node $NODE_NAME -o jsonpath='{.spec.unschedulable}'")
if [ "$CORDONED" = "true" ]; then
  ssh $NODE "microk8s kubectl uncordon $NODE_NAME"
  echo "✓ Node uncordoned"
else
  echo "✓ Node already schedulable"
fi
echo ""

# 4. Unseal Vault if sealed
echo "Step 4/5: Checking Vault..."
ssh $NODE "nohup microk8s kubectl port-forward -n vault svc/vault 8200:8200 > /tmp/vault-pf.log 2>&1 & sleep 3"
SEALED=$(ssh $NODE "VAULT_ADDR=http://127.0.0.1:8200 vault status 2>/dev/null | grep '^Sealed' | awk '{print \$2}'")
if [ "$SEALED" = "true" ]; then
  echo "  Vault is sealed. Enter your unseal key:"
  read -s -p "  Unseal Key: " UNSEAL_KEY
  echo ""
  ssh $NODE "VAULT_ADDR=http://127.0.0.1:8200 vault operator unseal $UNSEAL_KEY" > /dev/null
  echo "✓ Vault unsealed"
elif [ "$SEALED" = "false" ]; then
  echo "✓ Vault already unsealed"
else
  echo "⚠ Could not reach Vault — check 'microk8s kubectl get pods -n vault'"
fi
echo ""

# 5. Start Cloudflare Tunnel if not running
echo "Step 5/5: Checking Cloudflare Tunnel..."
if ssh $NODE "systemctl is-active --quiet cloudflared"; then
  echo "✓ Cloudflare Tunnel already running"
else
  ssh $NODE "sudo systemctl start cloudflared"
  echo "✓ Cloudflare Tunnel started"
fi
echo ""

# Summary
echo "========================================="
echo "Status Summary"
echo "========================================="
ssh $NODE "microk8s kubectl get pods -A --no-headers | awk '{print \$4}' | sort | uniq -c | sort -rn"
echo ""
UNHEALTHY=$(ssh $NODE "microk8s kubectl get pods -A --no-headers | grep -v 'Running\|Completed' | wc -l")
if [ "$UNHEALTHY" -eq 0 ]; then
  echo "✓ All pods healthy"
else
  echo "⚠ $UNHEALTHY pod(s) not running:"
  ssh $NODE "microk8s kubectl get pods -A | grep -v 'Running\|Completed\|NAMESPACE'"
fi
echo ""
echo "Homelab is up!"
