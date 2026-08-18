#!/usr/bin/env bash
# Single-touch installer — run from the Arch live environment:
#   mkdir -p /mnt/usb && mount /dev/disk/by-label/WISEUSB /mnt/usb && bash /mnt/usb/install.sh
# Auto-detects the machine (TUXEDO → wise-laptop, else wise-desktop),
# uses the config + creds stored next to this script. Network only needed
# for packages, not for config.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

# Only ever run from the Arch live ISO — never on an installed system.
[ -d /run/archiso ] || { echo "✘ not the Arch live environment — refusing to run an installer here"; exit 1; }

VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo unknown)
case "$VENDOR" in
    *[Tt][Uu][Xx][Ee][Dd][Oo]*) HOST=wise-laptop ;;
    *)                          HOST=wise-desktop ;;
esac
CFG="$HERE/configs/$HOST"
echo "→ detected vendor '$VENDOR' → installing profile: $HOST"

# No local configs (e.g. piped via curl from a plain ISO boot)? Fetch the
# config from the dots repo and build creds interactively — one password
# prompt, used for both LUKS and the user account (rotate after install).
if [ ! -f "$CFG/conf.json" ]; then
    echo "→ no local config — fetching from github:mattiasbonte/dots"
    CFG=$(mktemp -d)
    SHORT=${HOST#wise-}   # desktop / laptop
    curl -fsSL -o "$CFG/conf.json"         "https://raw.githubusercontent.com/mattiasbonte/dots/main/arch/archinstall/conf_${SHORT}.json"         || { echo "✘ no conf_${SHORT}.json in dots repo"; exit 1; }
    read -rsp "choose temp password (LUKS + user 'wise', rotate later): " PW; echo
    read -rsp "repeat: " PW2; echo
    [ "$PW" = "$PW2" ] || { echo "mismatch"; exit 1; }
    HASH=$(openssl passwd -6 "$PW")
    python3 - "$CFG/creds.json" "$PW" "$HASH" <<'PY'
import json,sys
open(sys.argv[1],'w').write(json.dumps({
  "root_enc_password": None,
  "encryption_password": sys.argv[2],
  "users":[{"username":"wise","enc_password":sys.argv[3],"groups":[],"sudo":True}]},indent=2))
PY
fi
[ -f "$CFG/creds.json" ] || { echo "missing $CFG/creds.json"; exit 1; }
grep -q encryption_password "$CFG/creds.json" || { echo "creds.json lacks encryption_password — refusing unencrypted install"; exit 1; }

DISK=$(python3 -c "import json;print(json.load(open('$CFG/conf.json'))['disk_config']['device_modifications'][0]['device'])")
echo "⚠ this WIPES $DISK completely."
read -rp "type the disk path to confirm: " CONFIRM
[ "$CONFIRM" = "$DISK" ] || { echo "mismatch — aborting"; exit 1; }

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
