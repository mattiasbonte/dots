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
# Every machine runs awesome (desktops log in through sddm, laptops through
# tty1 autologin), so the lock comes from the WM session everywhere; xss-lock +
# i3lock are in packages.yaml base. awesome's rc.lua starts autostart entries
# with `dex --environment Awesome`, and dex matches OnlyShowIn case-sensitively:
# a lone `awesome` was skipped, so list both spellings. KDE (XDG name KDE) skips
# this entry and locks through kscreenlocker below.
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/screen-lock.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Screen autolock (xss-lock)
Exec=sh -c 'xset s 900 && exec xss-lock -- i3lock -c 000000'
OnlyShowIn=Awesome;awesome;
DESKTOP
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
