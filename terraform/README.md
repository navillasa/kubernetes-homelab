# Homelab Terraform Configuration

Infrastructure as Code for managing Proxmox VMs and Vault configuration.

## What This Manages

- **Proxmox VMs**: k8s-node1 (main Kubernetes cluster)
- **Vault Configuration**: Auth backends, policies, roles, and secrets

## Prerequisites

- Terraform >= 1.0
- Access to Proxmox web UI (192.168.1.233:8006)
- Vault running and accessible
- SSH access to Proxmox host

## Setup

1. Copy the example tfvars file:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your actual values:
   - Proxmox root password
   - Vault root token (from vault init output)
   - Your SSH public key

3. Initialize Terraform:
```bash
terraform init
```

## Usage

### Plan Changes

```bash
terraform plan
```

### Apply Changes

```bash
terraform apply
```

## Vault Setup

To use Vault terraform provider, you need port-forward access:

```bash
ssh -L 8200:localhost:8200 node1 'sudo microk8s kubectl port-forward -n vault svc/vault 8200:8200'
```

Then in another terminal:
```bash
export VAULT_ADDR='http://localhost:8200'
export VAULT_TOKEN='your-root-token'
terraform apply
```

## Adding New VMs

Add new resources to `proxmox-vms.tf` following the k8s_node1 pattern.
