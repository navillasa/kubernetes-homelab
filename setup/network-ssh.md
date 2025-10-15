# Networking, SSH & Firewall

## IP & SSH (server side)
Find IP:
```
ip a
```

## SSH status
```
sudo systemctl status ssh
```

## From laptop
```
ssh-copy-id -i ~/.ssh/[pubkey] <user>@<server-ip>
```

## Config shortcut
Add to `~/.ssh/config`:
```
Host wyse
    HostName [IP]
    User [user]
    IdentityFile ~/.ssh/[key]
```

Then `ssh wyse`.

## Firewall (ufw)
```
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status
```
## MicroK8s Specific Config
Make sure to add a UFW rule to allow the pod network to reach only the API port on the node (16443 is the typical microk8s API port):
```
sudo ufw allow from [k8s service CIDR] to any port 16443 proto tcp
```
Make sure UFW doesn't break CNI traffic. These are typical allows on a Calico/MicroK8s node (harmless no-op if any of these interfaces aren't present):
```
# Allow traffic on CNI/Calico interfaces
sudo ufw allow in on cni0
sudo ufw allow in on cali+
sudo ufw allow in on vxlan.calico

# Forwarding usually needs to be ACCEPT for k8s
sudo sed -i
's/^DEFAULT_FORWARD_POLICY=.*/DEFAULT_FORWARD_POLICY="ACCEPT"/'
/etc/default/ufw
sudo ufw reload
```

## Secure SSH
```
sudo vi /etc/ssh/ssd_config
```

Uncommented and edited:
```
PasswordAuthentication no
PermitRootLogin no
```

Then ran:
```
sudo systemctl restart ssh
```

## Set up unattended upgrades
Automate security patches.
```
sudo apt update && sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

Check config later at:
`/etc/apt/apt.conf.d/50unattended-upgrades`

## Set up fail2ban
Protect SSH by rate-limiting.
```
sudo apt update && sudo apt install fail2ban -y
sudo systemctl enable --now fail2ban
sudo systemctl status fail2ban
```

View logs:
```
sudo fail2ban-client status sshd
```
