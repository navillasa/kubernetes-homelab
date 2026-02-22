# Power Outage Recovery

## Normal Startup

After any unplanned power loss (or any time the homelab is offline):

1. Make sure the **physical Wyse is powered on** — press the power button if needed
2. Log into **Proxmox** at `https://192.168.1.233:8006` and confirm `VM 100` is running
   - If stopped, start it manually (it should auto-start on boot — see below)
3. From your laptop, run the startup script:

```bash
./scripts/startup-homelab.sh
```

The script will:
- Wait for node1 to become reachable
- Start MicroK8s if it isn't running
- Uncordon the node if it was drained
- Check Vault seal status and prompt for your unseal key if needed
- Start Cloudflare Tunnel if it isn't running
- Print a pod health summary

> **Note:** Vault always seals itself on restart. You'll need your unseal key every time. Keep it in a password manager.

## Proxmox: Auto-start VM on Boot

To avoid having to manually start the VM after a power outage:

1. In the Proxmox UI, click **VM 100** in the left sidebar
2. Go to the **Options** tab
3. Double-click **Start at boot** and enable it

## If Vault Data is Corrupted

An unclean shutdown (e.g. power cut with no UPS) can corrupt Vault's storage. Symptoms:
- `vault operator unseal` returns `error decrypting seal wrapped value; invalid key`
- The error persists even with the correct unseal key

**Recovery steps:**

### 1. Wipe Vault and re-initialize

```bash
# Scale down Vault
ssh node1 "microk8s kubectl scale deployment vault -n vault --replicas=0"
ssh node1 "microk8s kubectl wait --for=delete pod -l app=vault -n vault --timeout=60s"

# Wipe corrupted data
ssh node1 "sudo rm -rf /var/snap/microk8s/common/default-storage/vault-vault-storage-pvc-*/*"

# Bring Vault back up
ssh node1 "microk8s kubectl scale deployment vault -n vault --replicas=1"
ssh node1 "microk8s kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=60s"
```

### 2. Initialize Vault and save credentials

```bash
ssh node1 "nohup microk8s kubectl port-forward -n vault svc/vault 8200:8200 > /tmp/vault-pf.log 2>&1 & sleep 5 && \
  VAULT_ADDR=http://127.0.0.1:8200 vault operator init -key-shares=1 -key-threshold=1"
```

> **IMPORTANT:** Save the new unseal key and root token immediately — in a password manager.

### 3. Unseal Vault

```bash
ssh node1 "VAULT_ADDR=http://127.0.0.1:8200 vault operator unseal <NEW_UNSEAL_KEY>"
```

### 4. Restore Vault config via Terraform

Update `terraform/terraform.tfvars` with the new root token, then run:

```bash
# Open SSH tunnel to Vault
ssh -f -N -L 8200:127.0.0.1:8200 node1

# Apply Vault resources only (don't touch Proxmox VMs)
cd terraform
terraform apply \
  -target=vault_auth_backend.kubernetes \
  -target=vault_kubernetes_auth_backend_config.k8s \
  -target=vault_policy.external_secrets \
  -target=vault_kubernetes_auth_backend_role.external_secrets \
  -target=vault_mount.secret \
  -target=vault_kv_secret_v2.postgres \
  -target=vault_kv_secret_v2.prod_database \
  -target=vault_kv_secret_v2.prod_api \
  -target=vault_kv_secret_v2.dev_database \
  -target=vault_kv_secret_v2.dev_api \
  -auto-approve
```

### 5. Restart External Secrets and update vault token file

```bash
# Restart External Secrets so it picks up the new Vault config
ssh node1 "microk8s kubectl rollout restart deployment -n external-secrets"

# Update the vault token used by the backup script
ssh node1 "echo 'export VAULT_TOKEN=<NEW_ROOT_TOKEN>' > ~/.vault_token && chmod 600 ~/.vault_token"
```
