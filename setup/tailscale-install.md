# Tailscale Setup

Tailscale provides secure remote access and the ability to expose services to the public internet via Tailscale Funnel, without requiring port forwarding or firewall configuration on the router.

## Benefits

- **Secure remote access** - No firewall ports need to be opened on router
- **Tailscale Funnel** - Expose specific services to public internet
- **Zero-trust networking** - All traffic encrypted and authenticated
- **Easy management** - Web dashboard for access control

## Installation

### Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### Authenticate

```bash
sudo tailscale up
```

Opens a URL in browser for authentication with Tailscale account.

### Enable IP Forwarding

For subnet routing functionality:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Tailscale Funnel

Tailscale Funnel exposes services to the public internet with automatic HTTPS certificates.

### Check Funnel Status

```bash
sudo tailscale funnel status
```

### Expose a Service

```bash
sudo tailscale funnel 443 http://<service-cluster-ip>:<port>
```

Service becomes available at: `https://<hostname>.tail<hex>.ts.net`

Example workflow:
1. Get service ClusterIP: `kubectl get svc -n <namespace> <service-name>`
2. Expose via Funnel: `sudo tailscale funnel 443 http://10.152.183.XX:80`

### Custom Domain

CNAME records can point custom domains to the Tailscale-provided domain:

```
subdomain.example.com CNAME <hostname>.tail<hex>.ts.net
```

## Tailscale Serve

For services that should only be accessible within the Tailscale network (not public):

```bash
sudo tailscale serve 443 http://<service-cluster-ip>:<port>
```

## Status Commands

```bash
# View connection status
sudo tailscale status

# View current funnel configuration
sudo tailscale funnel status

# View assigned IP addresses
tailscale ip
```

## Firewall Configuration

Tailscale works through NAT and typically requires no inbound firewall rules. For strict configurations:

```bash
sudo ufw allow in on tailscale0
```

## References

- [Tailscale Documentation](https://tailscale.com/kb)
- [Tailscale Funnel](https://tailscale.com/kb/1223/tailscale-funnel)
- [Tailscale Serve](https://tailscale.com/kb/1242/tailscale-serve)
