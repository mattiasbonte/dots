#!/usr/bin/env bash
# Generates the device-trust evidence bundle Vanta asks for on
# agent-unsupported (Linux) machines: identity, disk encryption,
# screen lock, login auth. Output: ~/Downloads/device-evidence-<host>-<date>.txt
set -u
OUT="$HOME/Downloads/device-evidence-$(cat /etc/hostname)-$(date +%F).txt"
{
    echo "== DEVICE EVIDENCE — generated $(date -Is)"
    echo "Host:    $(cat /etc/hostname)"
    echo "Model:   $(cat /sys/class/dmi/id/sys_vendor 2>/dev/null) $(cat /sys/class/dmi/id/product_name 2>/dev/null)"
    echo "Serial:  $(sudo cat /sys/class/dmi/id/product_serial 2>/dev/null || echo 'run with sudo for serial')"
    echo "OS:      $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2), kernel $(uname -r)"
    echo
    echo "== DISK ENCRYPTION"
    lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINT
    ROOTDEV=$(findmnt -no SOURCE /)
    case "$ROOTDEV" in
        /dev/mapper/*)
            echo
            sudo cryptsetup status "${ROOTDEV##*/}" 2>/dev/null | head -5
            echo "RESULT: root filesystem is LUKS-encrypted ✔" ;;
        *)  echo "RESULT: root filesystem is NOT encrypted ✘" ;;
    esac
    echo
    echo "== SCREEN LOCK"
    if [ -f "$HOME/.config/kscreenlockerrc" ]; then
        echo "KDE kscreenlocker:"; grep -A5 '\[Daemon\]' "$HOME/.config/kscreenlockerrc"
    fi
    if [ -f "$HOME/.config/autostart/screen-lock.desktop" ]; then
        echo "X11 (awesome) xss-lock autostart:"; grep Exec "$HOME/.config/autostart/screen-lock.desktop"
    fi
    pgrep -a xss-lock 2>/dev/null | sed 's/^/running: /'
    echo
    echo "== LOGIN AUTHENTICATION"
    echo "Password status: $(passwd -S "$USER" | awk '{print $2}') (P = password set)"
    echo
    echo "== UPDATE RECENCY"
    echo "Last pacman upgrade: $(grep -h 'starting full system upgrade' /var/log/pacman.log 2>/dev/null | tail -1)"
} > "$OUT"
echo "written: $OUT"
