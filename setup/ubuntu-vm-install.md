# Ubuntu Server VM in Proxmox

Guide for creating an Ubuntu Server 24.04 VM in Proxmox for running MicroK8s.

> **Note**: For production/repeatable setups, consider using Terraform to provision VMs (see `terraform/proxmox-vms.tf` for a template). This guide covers the manual approach for understanding the process.

## Prerequisites

- Proxmox VE installed and accessible via web UI
- Ubuntu Server 24.04 ISO uploaded to Proxmox

## Upload Ubuntu ISO

Via command line:
```bash
ssh root@192.168.1.233
cd /var/lib/vz/template/iso
wget https://releases.ubuntu.com/24.04/ubuntu-24.04-live-server-amd64.iso
```

Or via web UI: **Node** → **local** → **ISO Images** → **Upload**

## Create VM (Web UI)

1. **Create VM** (top right)
2. **General**: Name: `k8s-node1`, VM ID: `100`
3. **OS**: Select Ubuntu ISO, Type: Linux, Version: 6.x kernel
4. **System**: Machine: q35, BIOS: OVMF (UEFI), Add EFI Disk: Yes
5. **Disks**: Bus: VirtIO Block, Size: `100` GB, Storage: local-lvm
6. **CPU**: Sockets: 1, Cores: `3`, Type: host
7. **Memory**: `12288` MB (12 GB)
8. **Network**: Bridge: vmbr0, Model: VirtIO
9. **Confirm** and **Start**

## Install Ubuntu

Click **Console** and follow installer:

1. **Network**: Use DHCP on VirtIO interface
2. **Storage**: Use entire disk
3. **Profile**:
   - Server name: `k8s-node1`
   - Username: `nat` (or your preference)
   - Set password
4. **SSH**: Install OpenSSH server
5. **Snaps**: Skip all
6. Wait for installation and reboot

## Post-Installation

Get VM IP address from console:
```bash
ip addr show
```

### Set up SSH access from your machine

```bash
# Copy SSH key
ssh-copy-id nat@192.168.1.241

# Add to ~/.ssh/config
cat >> ~/.ssh/config <<EOF

Host node1
  HostName 192.168.1.241
  User nat
  IdentityFile ~/.ssh/id_ed25519
EOF

# Test
ssh node1
```

### Update system

```bash
ssh node1
sudo apt update && sudo apt upgrade -y
sudo reboot
```

## Next Steps

1. [Install MicroK8s](microk8s-install.md)
2. [Configure Tailscale](tailscale-install.md) for remote access

## VM Specs (k8s-node1)

- **OS**: Ubuntu Server 24.04 LTS
- **Disk**: 100 GB (VirtIO)
- **RAM**: 12 GB
- **CPU**: 3 cores (host passthrough)
- **Network**: VirtIO on vmbr0

## Terraform Alternative

For repeatable infrastructure, see `terraform/proxmox-vms.tf` for a VM template that can be managed with Terraform. This allows:
- Version-controlled infrastructure
- Consistent VM configuration
- Easy disaster recovery (`terraform apply`)
- Infrastructure as code for portfolio/interviews
