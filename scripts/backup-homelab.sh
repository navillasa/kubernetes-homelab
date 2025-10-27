#!/bin/bash
# Homelab backup script - exports Vault data and PostgreSQL databases
# Usage: VAULT_TOKEN=<token> ./backup-homelab.sh

set -e

BACKUP_DIR=~/backups
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_PATH=$BACKUP_DIR/$DATE

# Check for required environment variable
if [ -z "$VAULT_TOKEN" ]; then
  echo "Error: VAULT_TOKEN environment variable not set"
  echo "Usage: VAULT_TOKEN=<your-vault-token> $0"
  exit 1
fi

mkdir -p $BACKUP_PATH/{vault,databases,configs}

echo "Starting backup to $BACKUP_PATH..."

# Backup Vault data (requires unseal)
echo "Backing up Vault secrets..."

# Kill any existing port-forward to Vault
pkill -f 'port-forward.*vault' 2>/dev/null || true
sleep 1

microk8s kubectl port-forward -n vault svc/vault 8200:8200 >/dev/null 2>&1 &
PF_PID=$!
sleep 3

export VAULT_ADDR='http://localhost:8200'

# Export all Vault KV secrets
vault kv get -format=json secret/prod/database > $BACKUP_PATH/vault/prod-database.json 2>/dev/null || echo "  Warning: prod/database not found"
vault kv get -format=json secret/prod/api > $BACKUP_PATH/vault/prod-api.json 2>/dev/null || echo "  Warning: prod/api not found"
vault kv get -format=json secret/dev/database > $BACKUP_PATH/vault/dev-database.json 2>/dev/null || echo "  Warning: dev/database not found"
vault kv get -format=json secret/dev/api > $BACKUP_PATH/vault/dev-api.json 2>/dev/null || echo "  Warning: dev/api not found"

kill $PF_PID 2>/dev/null || true

# Backup PostgreSQL databases
echo "Backing up databases..."
for ns in tv-dashboard-prod tv-dashboard-dev; do
  POD=$(microk8s kubectl get pod -n $ns -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$POD" ]; then
    echo "  Backing up $ns database..."
    microk8s kubectl exec -n $ns $POD -- pg_dump -U tvuser tvshows > $BACKUP_PATH/databases/$ns.sql
  else
    echo "  Warning: No postgres pod found in $ns"
  fi
done

# Backup config files
echo "Backing up config files..."
cp ~/kube-prometheus-stack-values.yaml $BACKUP_PATH/configs/ 2>/dev/null || echo "  Warning: kube-prometheus-stack-values.yaml not found"
cp /etc/cloudflared/config.yml $BACKUP_PATH/configs/cloudflared-config.yml 2>/dev/null || echo "  Warning: cloudflared config not found"

# Create latest symlink
rm -f $BACKUP_DIR/latest
ln -s $BACKUP_PATH $BACKUP_DIR/latest

# Keep only last 7 backups
cd $BACKUP_DIR && ls -t | grep -E '^[0-9]{8}-[0-9]{6}$' | tail -n +8 | xargs rm -rf 2>/dev/null || true

echo ""
echo "✓ Backup complete: $BACKUP_PATH"
echo "  Total size: $(du -sh $BACKUP_PATH | cut -f1)"
echo "  Latest: $BACKUP_DIR/latest"
