# Ubuntu Server 24.04 LTS — Clean Install

## Boot
1. Flash ISO to USB (Balena Etcher/Rufus).
2. F12 → Boot Menu → select USB (UEFI).

## Network Screen
- Select wired interface: `enp1s0` (DHCPv4 should show an IP).
- Use tab to focus list → Enter on `enp1s0` → `Edit IPv4` = Automatic (DHCP) → Save → Close → Done.
- Proxy: leave blank. Mirror: default.

## Storage
- Use an entire disk → pick the new M.2 SATA 2280 SSD (~512 GB).
- Confirm layout:
  - `/boot/efi` ~1 GB (FAT32)
  - `/` rest of disk (ext4)

## Profile
- Name: your name (display only)
- Server name: `wyse-node1` (hostname)
- Username: set
- Password: set

## SSH & Snaps
- Install OpenSSH: Yes
- Import SSH keys: No (add later)
- Featured snaps: Skip (install manually later)

## Weird Messages I Saw (normal)
- `GPT PMBR size mismatch... will be corrected by write`
- `Backup GPT table is not at the end of the device`
- `usbc000:00 deferred probe pending`
These resolved after install/reboot.

## Finish
- At “remove installation medium” (even if it says failed unmounting `/cdrom` -- apparently this just means it worked): remove USB, press Enter.
