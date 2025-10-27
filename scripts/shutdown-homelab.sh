#!/bin/bash
# Graceful shutdown script for homelab
# Backs up data, drains nodes, and shuts down VMs safely

set -e

echo "========================================="
echo "Homelab Graceful Shutdown"
echo "========================================="
echo ""

# Check if running on node1
if ! command -v microk8s &> /dev/null; then
  echo "Error: This script must run on node1 (MicroK8s not found)"
  exit 1
fi

# 1. Create final backup
echo "Step 1/5: Creating final backup..."
if [ -f ~/backup-homelab.sh ]; then
  source ~/.vault_token 2>/dev/null || true
  if [ -n "$VAULT_TOKEN" ]; then
    ~/backup-homelab.sh
    echo "✓ Backup completed"
  else
    echo "⚠ Skipping backup (VAULT_TOKEN not set)"
  fi
else
  echo "⚠ Skipping backup (backup script not found)"
fi
echo ""

# 2. Drain Kubernetes node (mark unschedulable, evict pods gracefully)
echo "Step 2/5: Draining Kubernetes node..."
NODE_NAME=$(microk8s kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
microk8s kubectl drain "$NODE_NAME" --ignore-daemonsets --delete-emptydir-data --timeout=120s || true
echo "✓ Node drained"
echo ""

# 3. Stop MicroK8s services
echo "Step 3/5: Stopping MicroK8s services..."
microk8s stop
echo "✓ MicroK8s stopped"
echo ""

# 4. Stop Cloudflare Tunnel (if running)
echo "Step 4/5: Stopping Cloudflare Tunnel..."
if systemctl is-active --quiet cloudflared; then
  sudo systemctl stop cloudflared
  echo "✓ Cloudflare Tunnel stopped"
else
  echo "⚠ Cloudflare Tunnel not running"
fi
echo ""

# 5. Shutdown system
echo "Step 5/5: Shutting down system..."
echo ""
echo "System will shutdown in 10 seconds..."
echo "Press Ctrl+C to cancel"
sleep 10

sudo shutdown -h now
