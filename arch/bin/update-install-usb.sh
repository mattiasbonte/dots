#!/usr/bin/env bash
# Refreshes the netboot install USB so it can never go stale:
#   - latest iPXE loader (stale loaders fail Arch's image signature check)
#   - install.sh + per-host archinstall configs synced from DOTS
#   - creds.json validated (must be JSON with encryption_password)
# Usage:
#   update-install-usb.sh <usb-mountpoint>       # netboot mode: refresh loader+configs
#   update-install-usb.sh --iso /dev/sdX         # ISO mode: flash latest official ISO (WIPES stick)
set -euo pipefail

if [ "${1:-}" = "--iso" ]; then
    DEV="${2:?usage: update-install-usb.sh --iso /dev/sdX}"
    MIRROR="https://geo.mirror.pkgbuild.com/iso/latest"
    echo "→ downloading latest ISO + checksum"
    curl -fSL --retry 3 -C - -o /tmp/arch.iso "$MIRROR/archlinux-x86_64.iso"
    curl -fsSL "$MIRROR/sha256sums.txt" | grep 'archlinux-x86_64.iso$' | sed 's|archlinux-x86_64.iso|/tmp/arch.iso|' | sha256sum -c -
    echo "⚠ flashing WIPES $DEV completely."
    read -rp "type the device path to confirm: " C; [ "$C" = "$DEV" ] || { echo mismatch; exit 1; }
    sudo dd if=/tmp/arch.iso of="$DEV" bs=4M status=progress oflag=sync
    sync; echo "✔ ISO flashed — in the live env run:"
    echo "  curl -sLO https://raw.githubusercontent.com/mattiasbonte/dots/main/arch/archinstall/install.sh && bash install.sh"
    exit 0
fi

USB="${1:?usage: update-install-usb.sh <usb-mountpoint>}"
DOTS="$(cd "$(dirname "$0")/../.." && pwd)"
[ -d "$USB/EFI/BOOT" ] || { echo "$USB doesn't look like the install USB (no EFI/BOOT)"; exit 1; }

echo "→ refreshing iPXE loader"
curl -sSL -o /tmp/ipxe-arch.efi https://archlinux.org/static/netboot/ipxe-arch.efi
sudo cp "$USB/EFI/BOOT/BOOTX64.EFI" "$USB/EFI/BOOT/BOOTX64.EFI.old" 2>/dev/null || true
sudo cp /tmp/ipxe-arch.efi "$USB/EFI/BOOT/BOOTX64.EFI"

echo "→ syncing install.sh + configs from DOTS"
sudo cp "$DOTS/arch/archinstall/install.sh" "$USB/install.sh"
for conf in "$DOTS"/arch/archinstall/conf_*.json; do
    name=$(basename "$conf" .json); name=${name#conf_}          # desktop / laptop
    dest="$USB/configs/wise-$name"
    sudo mkdir -p "$dest"
    sudo cp "$conf" "$dest/conf.json"
    if ! python3 -c "import json;d=json.load(open('$dest/creds.json'));assert d.get('encryption_password')" 2>/dev/null; then
        echo "  ⚠ $dest/creds.json missing or invalid — create it:"
        echo '    {"root_enc_password": null, "encryption_password": "<temp>",'
        echo '     "users": [{"username": "wise", "enc_password": "<openssl passwd -6 output>", "groups": [], "sudo": true}]}'
    fi
done
sync
echo "✔ USB updated — safe to unmount"
