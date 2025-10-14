# Networking, SSH & Firewall

## IP & SSH (server side)
Find IP:
```
ip a

## SSH status
```
sudo systemctl status ssh

## From laptop
```
ssh-copy-id -i ~/.ssh/[pubkey] <user>@<server-ip>

## Config shortcut
Add to `~/.ssh/config`:
```
Host wyse
    HostName [IP]
    User [user]
    IdentityFile ~/.ssh/[key]

Then `ssh wyse`.

## Firewall (ufw)
```
sudo apt install ufw -y
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status

## Secure SSH
```
sudo vi /etc/ssh/ssd_config

Uncommented and edited:
```
PasswordAuthentication no
PermitRootLogin no

Then ran:
```
sudo systemctl restart ssh

## Set up unattended upgrades
Automate security patches.
```
sudo apt update && sudo apt install unattended-upgrades -y
sudo dpkg-reconfigure --priority=low unattended-upgrades

Check config later at:
`/etc/apt/apt.conf.d/50unattended-upgrades`

## Set up fail2ban
Protect SSH by rate-limiting.
```
sudo apt update && sudo apt install fail2ban -y
sudo systemctl enable --now fail2ban
sudo systemctl status fail2ban

View logs:
```
sudo fail2ban-client status sshd
