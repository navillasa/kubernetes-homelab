# Proxmox VE Installation

This guide covers installing Proxmox VE 9.0 on the Dell Wyse 5070 thin client.

## Prerequisites

- Dell Wyse 5070 with BIOS updated
- USB flash drive (8GB+) for bootable installer
- Network cable (wired connection)
- Access to BIOS (F2 during boot)

## Download Proxmox VE

Download the latest Proxmox VE ISO from the official website:
- https://www.proxmox.com/en/downloads

Current version: Proxmox VE 9.0

## Create Bootable USB

### macOS
```bash
# Insert USB drive and find its identifier
diskutil list

# Unmount the USB (replace diskN with your disk number)
diskutil unmountDisk /dev/diskN

# Write ISO to USB (replace diskN and path to ISO)
sudo dd if=/path/to/proxmox-ve_9.0-1.iso of=/dev/rdiskN bs=1m

# Eject when complete
diskutil eject /dev/diskN
```

### Linux
```bash
# Find USB device (usually /dev/sdb or /dev/sdc)
lsblk

# Write ISO to USB
sudo dd if=/path/to/proxmox-ve_9.0-1.iso of=/dev/sdX bs=4M status=progress
sync
```

### Windows
Use [Rufus](https://rufus.ie/) or [balenaEtcher](https://www.balena.io/etcher/)

## BIOS Configuration

1. Boot Wyse 5070 and press **F2** to enter BIOS
2. Configure boot settings:
   - Enable UEFI boot
   - Disable Secure Boot (Proxmox requires this)
   - Set USB as first boot device (or use F12 boot menu)
3. Save and exit

## Install Proxmox VE

1. Boot from USB installer
2. Select "Install Proxmox VE (Graphical)"
3. Accept license agreement
4. **Target Disk**: Select your M.2 SSD (this will erase all data)
5. **Location/Time Zone**: Set your region and timezone
6. **Administration Password**: Set root password (save this!)
7. **Network Configuration**:
   - Hostname: `proxmox-node1.local` (or your preference)
   - IP Address: `192.168.1.233` (or use DHCP, then change later)
   - Gateway: Your router IP (usually `192.168.1.1`)
   - DNS: Your router or `8.8.8.8`
8. Review summary and click **Install**
9. Wait for installation (5-10 minutes)
10. Reboot when prompted, remove USB drive

## First Boot & Access

After installation:

1. System will boot to Proxmox login console
2. Note the web interface URL displayed: `https://192.168.1.233:8006`
3. From your computer, navigate to the web UI
   - Accept the self-signed certificate warning
   - Login as `root` with your password
4. You should see the Proxmox web interface

## Post-Installation

### Disable Enterprise Repository (optional for home use)

Proxmox shows warnings about the enterprise repository without a subscription. To disable:

```bash
# SSH into Proxmox
ssh root@192.168.1.233

# Comment out enterprise repo
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update
apt update && apt upgrade -y
```

### Set up SSH Key Authentication

```bash
# From your local machine, copy SSH key
ssh-copy-id root@192.168.1.233

# Test key-based login
ssh root@192.168.1.233
```

## Next Steps

1. [Create Ubuntu VM](ubuntu-vm-install.md) for MicroK8s
2. [Install MicroK8s](microk8s-install.md) in the VM
3. [Configure Tailscale](tailscale-install.md) for remote access

## Troubleshooting

### Can't access web interface
- Check firewall isn't blocking port 8006
- Verify IP address with `ip addr` on console
- Ensure you're using `https://` not `http://`

### Installation fails
- Verify BIOS settings (disable Secure Boot)
- Check USB drive was created correctly
- Try a different USB port

## References

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE Installation Guide](https://pve.proxmox.com/pve-docs/pve-admin-guide.html#chapter_installation)
