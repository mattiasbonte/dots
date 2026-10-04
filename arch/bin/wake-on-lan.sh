#!/usr/bin/env bash
# Wake-on-LAN, idempotent: safe to re-run, changes only what differs.
#   bash ~/DOTS/arch/bin/wake-on-lan.sh
# - USB hubs may wake the machine (a laptop's LAN sits behind its dock's hubs)
# - every wired NetworkManager connection arms wake on magic packet
# - suspend uses deep sleep (S3) when the firmware offers it; s2idle did not wake from a dock
# Wake it from another machine: wakeonlan <mac>, or the FRITZ!Box: Heimnetz → Netzwerk → device → Computer starten
set -euo pipefail

say() { echo "→ $*"; }
ok()  { echo "✔ $*"; }

# write_if_changed <path> <content>: returns 0 when it wrote
write_if_changed() {
    [ "$(sudo cat "$1" 2>/dev/null)" = "$2" ] && return 1
    sudo install -Dm644 /dev/stdin "$1" <<<"$2"
}

rule=/etc/udev/rules.d/90-usb-hub-wakeup.rules
if write_if_changed "$rule" 'ACTION=="add", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="09", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"'; then
    say "USB hubs may wake the machine ($rule)"
    sudo udevadm control --reload && sudo udevadm trigger -s usb -c add
fi

if command -v nmcli >/dev/null; then
    while IFS=: read -r name type; do
        [ "$type" = 802-3-ethernet ] || continue
        [ "$(nmcli -g 802-3-ethernet.wake-on-lan con show "$name")" = magic ] && continue
        say "wake on magic packet: $name"
        sudo nmcli con modify "$name" 802-3-ethernet.wake-on-lan magic
    done < <(nmcli -t -f NAME,TYPE con show)
fi

if grep -qw deep /sys/power/mem_sleep 2>/dev/null; then
    if write_if_changed /etc/systemd/sleep.conf.d/10-deep.conf $'[Sleep]\nMemorySleepMode=deep'; then
        say "suspend uses deep sleep (S3)"
    fi
    grep -q '\[deep\]' /sys/power/mem_sleep || echo deep | sudo tee /sys/power/mem_sleep >/dev/null
fi

for dev in /sys/class/net/*; do
    [ -e "$dev/device" ] && [ "$(cat "$dev/type")" = 1 ] && [ ! -d "$dev/wireless" ] || continue
    ok "wake-on-lan ready: ${dev##*/} $(cat "$dev/address")"
done
