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

# ── TODO(M7): KDE screen lock, still here until M7 ──
# The awesome lock (xss-lock autostart) is chezmoi's now:
# ~/.config/autostart/screen-lock.desktop, checked by 99-verify.
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
