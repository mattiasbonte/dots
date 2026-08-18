#!/usr/bin/env bash
# Single-touch installer — run from the Arch live environment:
#   mkdir -p /mnt/usb && mount /dev/disk/by-label/WISEUSB /mnt/usb && bash /mnt/usb/install.sh
# Auto-detects the machine (TUXEDO → wise-laptop, else wise-desktop),
# uses the config + creds stored next to this script. Network only needed
# for packages, not for config.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo unknown)
case "$VENDOR" in
    *[Tt][Uu][Xx][Ee][Dd][Oo]*) HOST=wise-laptop ;;
    *)                          HOST=wise-desktop ;;
esac
CFG="$HERE/configs/$HOST"
echo "→ detected vendor '$VENDOR' → installing profile: $HOST"
[ -f "$CFG/conf.json" ]  || { echo "missing $CFG/conf.json";  exit 1; }
[ -f "$CFG/creds.json" ] || { echo "missing $CFG/creds.json"; exit 1; }
grep -q encryption_password "$CFG/creds.json" || { echo "creds.json lacks encryption_password — refusing unencrypted install"; exit 1; }

pacman -Sy --noconfirm archinstall

if ! archinstall --config "$CFG/conf.json" --creds "$CFG/creds.json"; then
    cat <<'MSG'

✘ archinstall rejected the stored config (schema drift with a newer
  archinstall). Fallback: run `archinstall` guided, mirror the choices
  (systemd-boot, linux-zen, ext4 + LUKS encryption, KDE+Awesome, zram),
  then SAVE the generated config back to DOTS/arch/archinstall/.
MSG
    exit 1
fi
echo "✔ install done — reboot, then run ~/DOTS/arch/first-boot.sh"
