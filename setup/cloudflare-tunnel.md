# Cloudflare Tunnel Setup

Cloudflare Tunnel provides secure remote access with automatic HTTPS certificates, DDoS protection, and caching.

## Installation

### Install cloudflared

```bash
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

### Authenticate

```bash
cloudflared tunnel login
```

Opens browser for Cloudflare authentication. Credentials saved to `~/.cloudflared/cert.pem`.

### Create Tunnel

```bash
cloudflared tunnel create <tunnel-name>
```

Creates tunnel and saves credentials to `~/.cloudflared/<tunnel-id>.json`.

## Configuration

### Create Config File

`/etc/cloudflared/config.yml`:

```yaml
tunnel: <tunnel-id>
credentials-file: /etc/cloudflared/<tunnel-id>.json

ingress:
  - hostname: subdomain.example.com
    service: http://localhost:80
  - service: http_status:404
```

### Configure DNS

```bash
cloudflared tunnel route dns <tunnel-name> subdomain.example.com
```

Creates CNAME record in Cloudflare pointing to the tunnel.

### Install as System Service

```bash
sudo mkdir -p /etc/cloudflared
sudo cp ~/.cloudflared/config.yml /etc/cloudflared/
sudo cp ~/.cloudflared/*.json /etc/cloudflared/
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

## Status and Logs

```bash
# Check service status
sudo systemctl status cloudflared

# View logs
sudo journalctl -u cloudflared -f

# List tunnels
cloudflared tunnel list
```

## Security Notes

- Credentials in `/etc/cloudflared/*.json` and `~/.cloudflared/cert.pem` are secrets
- Do not commit these files to version control
- Cloudflare automatically provides valid SSL certificates
- All traffic is encrypted through Cloudflare's edge network

## References

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [cloudflared GitHub](https://github.com/cloudflare/cloudflared)
