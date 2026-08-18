#!/usr/bin/env bash
# Refreshes the netboot install USB so it can never go stale:
#   - latest iPXE loader (stale loaders fail Arch's image signature check)
#   - install.sh + per-host archinstall configs synced from DOTS
#   - creds.json validated (must be JSON with encryption_password)
# Usage: update-install-usb.sh /path/to/mounted/usb
set -euo pipefail
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
