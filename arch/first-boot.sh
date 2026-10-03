#!/usr/bin/env bash
# --
# FIRST BOOT (deprecated): ~/DOTS/bootstrap.sh is the one command now.
# Packages, system settings, units, desktop defaults and the verify panel are
# chezmoi scripts in the dotfiles repo (.chezmoiscripts). This shim runs
# bootstrap, then the screen-lock steps that still wait for M7 (X session and
# screen lock move into chezmoi there; delete this file afterwards).
# --
echo "⚠ first-boot.sh is deprecated: running ~/DOTS/bootstrap.sh"
bash "$HOME/DOTS/bootstrap.sh" "$@"; rc=$?

# ── TODO(M7): device compliance screen lock, still here until M7 ──
# Laptops run awesome only, so the lock has to come from the WM session.
# Desktops run KDE as their primary session and lock via kscreenlocker;
# an xss-lock autostart there would also lock the awesome session.
mkdir -p "$HOME/.config/autostart"
if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    # xss-lock + i3lock come from packages.yaml (laptop)
    cat > "$HOME/.config/autostart/screen-lock.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Screen autolock (xss-lock)
Exec=sh -c 'xset s 900 && exec xss-lock -- i3lock -c 000000'
OnlyShowIn=awesome;
DESKTOP
else
    rm -f "$HOME/.config/autostart/screen-lock.desktop"
fi
# KDE session: enforce kscreenlocker regardless of defaults
for KW in kwriteconfig6 kwriteconfig5; do
    if command -v "$KW" >/dev/null 2>&1; then
        "$KW" --file kscreenlockerrc --group Daemon --key Autolock true
        "$KW" --file kscreenlockerrc --group Daemon --key Timeout 15
        "$KW" --file kscreenlockerrc --group Daemon --key LockOnResume true
        break
    fi
done
exit $rc
