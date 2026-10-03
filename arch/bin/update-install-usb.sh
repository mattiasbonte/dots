#!/usr/bin/env bash
# Refreshes the netboot install USB so it can never go stale:
#   - latest iPXE loader (stale loaders fail Arch's image signature check)
#   - install.sh synced from DOTS (it needs no config files or credentials)
# Usage:
#   update-install-usb.sh <usb-mountpoint>       # netboot mode: refresh loader + install.sh
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
    echo "  curl -sL https://raw.githubusercontent.com/mattiasbonte/dots/main/arch/archinstall/install.sh | bash"
    exit 0
fi

USB="${1:?usage: update-install-usb.sh <usb-mountpoint>}"
DOTS="$(cd "$(dirname "$0")/../.." && pwd)"
[ -d "$USB/EFI/BOOT" ] || { echo "$USB doesn't look like the install USB (no EFI/BOOT)"; exit 1; }

echo "→ refreshing iPXE loader"
curl -sSL -o /tmp/ipxe-arch.efi https://archlinux.org/static/netboot/ipxe-arch.efi
sudo cp "$USB/EFI/BOOT/BOOTX64.EFI" "$USB/EFI/BOOT/BOOTX64.EFI.old" 2>/dev/null || true
sudo cp /tmp/ipxe-arch.efi "$USB/EFI/BOOT/BOOTX64.EFI"

echo "→ syncing install.sh from DOTS"
sudo cp "$DOTS/arch/archinstall/install.sh" "$USB/install.sh"
sync
echo "✔ USB updated — safe to unmount"
