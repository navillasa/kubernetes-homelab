#!/bin/bash
# Pull backups from homelab node1 to local machine via rsync over Tailscale

set -e

LOCAL_BACKUP_DIR=~/homelab-backups
REMOTE_HOST=node1-ts
REMOTE_BACKUP_DIR=backups

echo "Pulling backups from $REMOTE_HOST..."

# Create local backup directory
mkdir -p $LOCAL_BACKUP_DIR

# Rsync backups from node1 over Tailscale
rsync -avz --progress \
  $REMOTE_HOST:$REMOTE_BACKUP_DIR/ \
  $LOCAL_BACKUP_DIR/

echo ""
echo "✓ Backups synced to $LOCAL_BACKUP_DIR"
echo "  Latest backup: $LOCAL_BACKUP_DIR/latest"
echo "  Total size: $(du -sh $LOCAL_BACKUP_DIR | cut -f1)"
