# 😶‍🌫️ Homelab

![Ubuntu 24.04](https://img.shields.io/badge/Ubuntu-24.04-orange?logo=ubuntu)
![MicroK8s](https://img.shields.io/badge/MicroK8s-1.30%2B-blue?logo=kubernetes)

<p align="center">
  <img src="photos/dell_wyse.jpg" width="30%">
  <img src="photos/inside_case.jpg" width="30%">
  <img src="photos/ram_upgrade.png" width="30%">
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
- MicroK8s 1.32 +
- SSH hardened with UFW

## Current Projects
- [TV Dashboard K8s](https://github.com/navillasa/tv-dashboard-k8s)

## Next Steps
- Add Prometheus + Grafana
- Deploy Tailscale for remote access

