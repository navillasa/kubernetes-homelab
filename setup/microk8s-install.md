# MicroK8s — Single Node Setup

## Install
```
sudo apt update && sudo apt upgrade -y
sudo snap install microk8s --classic
sudo usermod -aG microk8s $USER
newgrp microk8s
microk8s status --wait-ready

## enable core add-ons
```
microk8s enable dns storage ingress dashboard

## kubectl convenience alias
```
sudo snap alias microk8s.kubectl kubectl

## verify
```
kubectl get nodes
kubectl get pods -A
