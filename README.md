# ✨😶‍🌫️ Kubernetes Homelab — Wyse 5070 + Proxmox + MicroK8s

![Proxmox VE](https://img.shields.io/badge/Proxmox-VE%209.0-orange?logo=proxmox)
![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-orange?logo=ubuntu)
![MicroK8s](https://img.shields.io/badge/MicroK8s-1.32%2B-blue?logo=kubernetes)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)

<p align="center">
  <img src="docs/photos/dell_wyse.jpg" height="200">
  <img src="docs/photos/inside_case.jpg" height="200">
  <img src="docs/photos/ram_upgrade.jpg" height="200">
</p>

Self-hosted Kubernetes homelab built on a Dell Wyse 5070 thin client running Proxmox VE with virtualized infrastructure managed by Terraform.

## Architecture
- **Hypervisor**: Proxmox VE 9.0 (bare metal)
- **k8s-node1 VM**: Ubuntu 24.04 LTS (200GB disk, 12GB RAM, 3 cores)
  - MicroK8s 1.32+
  - All Kubernetes workloads

## Software
- Terraform (VM and Vault infrastructure as code)
- MicroK8s 1.32+
- HashiCorp Vault (secrets management)
- External Secrets Operator
- ArgoCD (GitOps)
- Cloudflare Tunnel (public access & SSL)
- Tailscale (private network access)
- Prometheus + Grafana (monitoring)

## Hardware
- Dell Wyse 5070 (Intel Pentium Silver J5005, quad-core)
- RAM: 16 GB DDR4 RAM
- Storage: 512 GB M.2 SATA SSD (TeamGroup MS30)
- Networking: 1x GbE (wired)
- Power: 65W Dell adapter, small UPS (battery backup)

## 📚 Documentation

### Setup
- 🧠 [hardware/wyse5070.md](hardware/wyse5070.md) — hardware specs
- 🖥️ [setup/proxmox-install.md](setup/proxmox-install.md) — Proxmox VE installation
- 💽 [setup/ubuntu-vm-install.md](setup/ubuntu-vm-install.md) — Ubuntu VM creation
- ☸️ [setup/microk8s-install.md](setup/microk8s-install.md) — Kubernetes setup
- 🔑 [setup/network-ssh.md](setup/network-ssh.md) — SSH & firewall
- ☁️ [setup/cloudflare-tunnel.md](setup/cloudflare-tunnel.md) — Cloudflare Tunnel
- 🌐 [setup/tailscale-install.md](setup/tailscale-install.md) — Tailscale

### Infrastructure
- 🏗️ [terraform/](terraform/) — Terraform IaC for Proxmox VMs and Vault config
- 🔐 [k8s/vault/](k8s/vault/) — Vault deployment
- 🔑 [k8s/external-secrets/](k8s/external-secrets/) — External Secrets setup
- 🔒 [k8s/cert-manager/](k8s/cert-manager/) — TLS certificate management
- 📊 [k8s/monitoring/](k8s/monitoring/) — Prometheus + Grafana monitoring stack

### Guides
- 🚀 [docs/deploying-apps.md](docs/deploying-apps.md) — Deploying applications to homelab

## Applications
- [TV Dashboard](https://github.com/navillasa/tv-dashboard-k8s) — TV show tracker (https://tv-hub.navillasa.dev)
- [Multi-cloud LLM Router](https://github.com/navillasa/multi-cloud-llm-router) — Demo frontend (https://demo-multicloud.navillasa.dev)

## Services
- **Grafana**: https://grafana.navillasa.dev (monitoring dashboards)

<p align="center">
  <img src="docs/photos/dashboard-k8s-compute-resources-cluster.png" alt="Grafana Kubernetes Dashboard" width="800">
</p>

## Status / Changelog
- 2025-10-23: Migrated from bare metal to Proxmox VE virtualization
- 2025-10-23: Added Terraform for infrastructure as code (VMs + Vault)
- 2025-10-16: Added cluster monitoring with kube-prometheus-stack (Prometheus + Grafana)
- 2025-10-16: Deployed multi-cloud-llm-router demo frontend
- 2025-10-16: Installed Docker for building images locally
- 2025-10-15: Infrastructure refactor - moved Vault/External Secrets to homelab repo
- 2025-10-14: Base install complete, MicroK8s running

## Next
- Setup backups
- Add Tailscale for remote access
- Self-host GitLab (git hosting + CI/CD + container registry)
