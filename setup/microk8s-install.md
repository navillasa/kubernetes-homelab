# MicroK8s — Single Node Setup

## Install
```
sudo apt update && sudo apt upgrade -y
sudo snap install microk8s --classic
sudo usermod -aG microk8s $USER
newgrp microk8s
microk8s status --wait-ready
```

## enable core add-ons
```
microk8s enable dns storage ingress dashboard
```

## kubectl convenience alias
```
sudo snap alias microk8s.kubectl kubectl
```

## verify
```
kubectl get nodes
kubectl get pods -A
```

# Set Up Remote Access

Get the microk8s config. If you have SSH set up, you can do this:
```
ssh <user>@<homelab-ip> "microk8s config" > ~/.kube/config-homelab
```
Add it to your kubectl config:
```
export KUBECONFIG=~/.kube/config:~/.kube/config-homelab
kubectl config use-context microk8s
```
