# Homelab Backup Strategy

Simple backup solution for critical homelab data.

## What Gets Backed Up

- **Vault secrets** (JSON exports of all KV secrets)
- **PostgreSQL databases** (TV Dashboard prod/dev)
- **Config files** (Helm values, Cloudflare Tunnel config)

## Setup

### 1. On node1 (create backup script)

Copy the backup script to node1:

```bash
scp scripts/backup-homelab.sh node1-ts:~/
```

### 2. Set Vault token environment variable

Create `~/.vault_token` on node1 (gitignored):

```bash
ssh node1-ts
echo "export VAULT_TOKEN=<your-vault-root-token>" > ~/.vault_token
chmod 600 ~/.vault_token
```

Add to `~/.bashrc` on node1:

```bash
echo "source ~/.vault_token" >> ~/.bashrc
```

### 3. On laptop (pull backups)

The pull script is already in `scripts/pull-backups.sh` and ready to use.

## Usage

### Create backup on node1

```bash
ssh node1-ts
source ~/.vault_token  # Or just login again if you added to .bashrc
~/backup-homelab.sh
```

This creates a timestamped backup in `~/backups/YYYYMMDD-HHMMSS/` and symlinks `~/backups/latest`.

### Pull backups to laptop

From your laptop:

```bash
./scripts/pull-backups.sh
```

This rsyncs all backups from node1 to `~/homelab-backups/` on your laptop over Tailscale.

## Backup Contents

```
~/backups/20251027-153000/
├── vault/
│   ├── prod-database.json
│   ├── prod-api.json
│   ├── dev-database.json
│   └── dev-api.json
├── databases/
│   ├── tv-dashboard-prod.sql
│   └── tv-dashboard-dev.sql
└── configs/
    ├── kube-prometheus-stack-values.yaml
    └── cloudflared-config.yml
```

## Retention

- Backups on node1: **Last 7 backups** (automatic cleanup)
- Backups on laptop: **All** (manual cleanup as needed)

## Restore Procedures

### Restore Vault secrets

```bash
kubectl port-forward -n vault svc/vault 8200:8200 &
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN=<your-vault-token>

# Restore from JSON backups
vault kv put secret/prod/database @vault/prod-database.json
vault kv put secret/prod/api @vault/prod-api.json
```

### Restore PostgreSQL database

```bash
POD=$(microk8s kubectl get pod -n tv-dashboard-prod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
cat databases/tv-dashboard-prod.sql | microk8s kubectl exec -i -n tv-dashboard-prod $POD -- psql -U tvuser tvshows
```

## Automation (Optional)

Add to node1 crontab for automatic daily backups:

```bash
# Daily backup at 2 AM
0 2 * * * source ~/.vault_token && ~/backup-homelab.sh >> ~/backup.log 2>&1
```

On laptop, you can run the pull script manually whenever you want to sync backups locally.

## Security Notes

- Vault token is stored in `~/.vault_token` on node1 (not in Git)
- Backup files contain sensitive data - keep them secure
- Backups transfer over Tailscale (encrypted VPN)
- Laptop backups stored in `~/homelab-backups/` (outside Git repo)
