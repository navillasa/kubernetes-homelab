# ✨😶‍🌫️ Kubernetes Homelab — Wyse 5070 + Ubuntu + MicroK8s

![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-orange?logo=ubuntu)
![MicroK8s](https://img.shields.io/badge/MicroK8s-1.32%2B-blue?logo=kubernetes)

<p align="center">
  <img src="photos/dell_wyse.jpg" height="200">
  <img src="photos/inside_case.jpg" height="200">
  <img src="photos/ram_upgrade.jpg" height="200">
</p>

Self-hosted single-node Kubernetes lab built on a Dell Wyse 5070 thin client for infra and automation experiments.

## Hardware
- Dell Wyse 5070 (Intel Pentium Silver J5005, quad-core)
- RAM: 16 GB DDR4 RAM
- Storage: 512 GB M.2 SATA SSD (TeamGroup MS30)
- Networking: 1x GbE (wired)
- Power: 65W Dell adapter, small UPS (battery backup)

## Software
- Ubuntu 24.04 LTS (Server)
- MicroK8s 1.32+
- HashiCorp Vault (secrets management)
- External Secrets Operator
- ArgoCD (GitOps)
- Cloudflare Tunnel (public access & SSL)
- Tailscale (private network access)

## 📚 Documentation

### Setup
- 🧠 [hardware/wyse5070.md](hardware/wyse5070.md) — hardware specs
- 💽 [setup/ubuntu-install.md](setup/ubuntu-install.md) — OS installation
- ☸️ [setup/microk8s-install.md](setup/microk8s-install.md) — Kubernetes setup
- 🔑 [setup/network-ssh.md](setup/network-ssh.md) — SSH & firewall
- ☁️ [setup/cloudflare-tunnel.md](setup/cloudflare-tunnel.md) — Cloudflare Tunnel
- 🌐 [setup/tailscale-install.md](setup/tailscale-install.md) — Tailscale (optional)

### Infrastructure
- 🔐 [k8s/vault/](k8s/vault/) — Vault deployment
- 🔑 [k8s/external-secrets/](k8s/external-secrets/) — External Secrets setup
- 🔒 [k8s/cert-manager/](k8s/cert-manager/) — TLS certificate management

### Guides
- 🚀 [docs/deploying-apps.md](docs/deploying-apps.md) — Deploying applications to homelab

## Applications
- [TV Dashboard](https://github.com/navillasa/tv-dashboard-k8s) — TV show tracker

## Status / Changelog
- 2025-10-15: Infrastructure refactor - moved Vault/External Secrets to homelab repo
- 2025-10-14: Base install complete, MicroK8s running

## Next
- Setup backups
- Add Tailscale for remote access
- Self-host GitLab (git hosting + CI/CD + container registry)
