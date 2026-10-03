# --
# FIRST BOOT
# @note system steps before chezmoi (packages are chezmoi's: .chezmoidata/packages.yaml)
# Every step is tracked: failures collect in FAILED and print in the final
# panel; a VERIFY pass at the end asserts outcomes (binaries/files exist),
# so nothing can silently skip. Idempotent — re-run until the panel is green.
# --

cd "$HOME" # unattended service starts in / — clones/builds need a writable CWD
# Always run the newest version of this script: pull, and if that changed
# anything, re-exec so fixes land on the very run that needs them.
if [ "${DOTS_SELFUPDATE:-1}" = 1 ] && [ -d "$HOME/DOTS/.git" ]; then
    BEFORE=$(git -C "$HOME/DOTS" rev-parse HEAD 2>/dev/null)
    git -C "$HOME/DOTS" pull --ff-only 2>/dev/null
    if [ "$BEFORE" != "$(git -C "$HOME/DOTS" rev-parse HEAD 2>/dev/null)" ]; then
        echo "→ DOTS updated — re-running the latest first-boot"
        DOTS_SELFUPDATE=0 exec bash "$HOME/DOTS/arch/first-boot.sh" "$@"
    fi
fi


# full transcript — failures in the panel reference it for the actual error text
LOG="$HOME/.local/state/first-boot.log"; mkdir -p "$HOME/.local/state"
exec > >(tee "$LOG") 2>&1
# stdout is a pipe now — gum renders its TUI to stdout, so point it at the
# real terminal or it degrades to colorless ASCII
GUMTTY=/dev/stdout; [ -w /dev/tty ] && GUMTTY=/dev/tty
gum() { command gum "$@" >$GUMTTY; }

# NONINTERACTIVE=1 → every gum prompt takes its default (used by the
# wise-firstboot service that runs this unattended after install)
confirm() { if [ "${NONINTERACTIVE:-0}" = 1 ]; then [ "$1" = "--default=true" ]; else gum confirm "$@"; fi; }

# FN — failures are collected, not fatal; summary prints at the end
FAILED=()
fail() { FAILED+=("$1"); echo "✘ FAILED: $1"; }
try()  { local l=$1; shift; "$@" || fail "$l"; }
vfile() { [ -e "$1" ] || fail "verify: missing $1"; }

# UPDATE DBS
try "system upgrade (pacman -Syu)" sudo pacman -Syu --noconfirm
command -v paru >/dev/null 2>&1 && try "AUR upgrade (paru -Syu)" paru -Syu --noconfirm

# PACKAGES: chezmoi owns them now. The lists live in the dotfiles repo
# (.chezmoidata/packages.yaml) and run_onchange_before_10-packages.sh installs
# them (pacman, paru bootstrap, AUR, multilib, nvidia by detected GPU) on every
# chezmoi apply where the list changed. This script only keeps system steps.

# pre-chezmoi tools: prompts + panel (gum), oh-my-zsh download (wget), post-init auth (gh, bw), chezmoi
command -v gum >/dev/null && command -v wget >/dev/null && command -v gh >/dev/null && command -v bw >/dev/null && command -v chezmoi >/dev/null \
    || try "pre-chezmoi tools" sudo pacman -S --needed --noconfirm gum wget github-cli bitwarden-cli chezmoi

# HW detection (drives the laptop sections below)
IS_LAPTOP=false; ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && IS_LAPTOP=true

# CONFIG
try "DOTS pull" git -C "$HOME/DOTS" pull
# chezmoi owns every config file; DOTS only carries the minimal .zshrc that
# keeps a pre-chezmoi shell usable (copied in the oh-my-zsh block below)
# fetch stays https (works before any SSH key exists) — only pushes need auth
try "DOTS remote (fetch=https)" git -C "$HOME/DOTS" remote set-url origin "https://github.com/mattiasbonte/dots.git"
try "DOTS remote (push=ssh)"    git -C "$HOME/DOTS" remote set-url --push origin "git@github.com:mattiasbonte/dots.git"

# ZSH (zsh itself comes from install.sh pacstrap)
[ "$(basename "$SHELL")" = "zsh" ] || try "chsh to zsh" sudo chsh -s "$(which zsh)" "$USER"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended || fail "oh-my-zsh install"
    cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc" || fail "bootstrap .zshrc copy"
else
    echo "Oh My Zsh already installed, skipping installation"
fi

# --
# DEVICE COMPLIANCE (Vanta device trust: encryption is handled at
# install time by archinstall; this covers screen lock + evidence)
# --
# Laptops run awesome only, so the lock has to come from the WM session.
# Desktops run KDE as their primary session and lock via kscreenlocker below;
# an xss-lock autostart there would also lock the awesome session, which is
# not wanted on a machine that never leaves the house.
mkdir -p "$HOME/.config/autostart"
if $IS_LAPTOP; then
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
        try "kscreenlocker config" "$KW" --file kscreenlockerrc --group Daemon --key Autolock true
        "$KW" --file kscreenlockerrc --group Daemon --key Timeout 15
        "$KW" --file kscreenlockerrc --group Daemon --key LockOnResume true
        break
    fi
done
echo "→ after setup, run ~/.local/bin/device-evidence.sh (from chezmoi) and upload the file to Vanta"

# caps:escape at the X-server level — applies in every session and at the
# SDDM greeter, independent of WM autostarts
try "x11 keymap (caps:escape)" sudo localectl set-x11-keymap us pc105+inet "" caps:escape,terminate:ctrl_alt_bksp

if $IS_LAPTOP; then
    # laptop travels: never listen on an untrusted network
    printf 'ListenAddress 127.0.0.1\n' | sudo tee /etc/ssh/sshd_config.d/10-localhost-only.conf >/dev/null || fail "sshd localhost-only config"
elif confirm --default=true "Enable SSH on the LAN? (lets your other machine push keys and drive the rest of the setup remotely)"; then
    # desktop stays home: reachable on the LAN so the laptop can drive setup
    # and debugging remotely — far faster than working at this keyboard
    sudo rm -f /etc/ssh/sshd_config.d/10-localhost-only.conf
    printf 'PasswordAuthentication yes\nPermitRootLogin no\n' | sudo tee /etc/ssh/sshd_config.d/10-lan.conf >/dev/null || fail "sshd lan config"
    try "sshd enable" sudo systemctl enable --now sshd
    LAN_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
fi

# ── MACHINE QUIRKS (optional, see arch/machines/README.md) ──
MACHINE_FILE="$HOME/DOTS/arch/machines/$(cat /etc/hostname).sh"
if [ -f "$MACHINE_FILE" ]; then
    echo "→ machine quirks: $MACHINE_FILE"
    source "$MACHINE_FILE" || fail "machine quirks: $MACHINE_FILE"
fi

# ── VERIFY — assert outcomes, not attempts. A step that "ran" but left
# nothing behind fails HERE with the exact missing thing named. ──
echo; echo "── verifying outcomes"
# package binaries: verified by chezmoi (packages.yaml), not here
vfile "$HOME/.oh-my-zsh"
[ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" = zsh ] || fail "verify: login shell is not zsh"
case "$(git -C "$HOME/DOTS" remote get-url origin)" in https://*) ;; *) fail "verify: DOTS fetch URL is not https";; esac
$IS_LAPTOP && { [ -f /etc/ssh/sshd_config.d/10-localhost-only.conf ] || fail "verify: sshd localhost-only config missing"; }
$IS_LAPTOP && { [ -f "$HOME/.config/autostart/screen-lock.desktop" ] || fail "verify: xss-lock autostart missing"; }

# SUMMARY — always the last thing printed; failures also land as a file
# in $HOME so a login can't miss them, and a nonzero exit makes the
# wise-firstboot service show FAILED and retry on next boot.
echo; echo
if [ ${#FAILED[@]} -gt 0 ]; then
    { echo "first-boot: ${#FAILED[@]} step(s) failed ($(date -Is))"
      printf '  • %s\n' "${FAILED[@]}"
    } > "$HOME/FIRSTBOOT-FAILURES.txt"
    if command -v gum >/dev/null 2>&1; then
        gum style --border rounded --border-foreground 1 --padding "1 3" --margin "1 2" \
            "⚠  FIRST-BOOT — ${#FAILED[@]} step(s) failed" "" \
            "$(printf '• %s\n' "${FAILED[@]}")" "" \
            "Details:  ~/FIRSTBOOT-FAILURES.txt" \
            "Full log: ~/.local/state/first-boot.log" \
            "Re-run:  bash ~/DOTS/arch/first-boot.sh" \
            "(idempotent — only redoes what failed)"
    else
        cat "$HOME/FIRSTBOOT-FAILURES.txt"
    fi
    exit 1
else
    rm -f "$HOME/FIRSTBOOT-FAILURES.txt"
    if command -v gum >/dev/null 2>&1; then
        gum style --border rounded --border-foreground 2 --padding "1 3" --margin "1 2" \
            "✅  FIRST-BOOT COMPLETE — all steps verified" "" \
            "Shells stay bare until post-init: plugins, keybinds, tmux," \
            "alacritty and zen all arrive with chezmoi." "" \
            ${LAN_IP:+"From your other machine (paste there):"} \
            ${LAN_IP:+"  ssh-copy-id wise@$LAN_IP"} \
            ${LAN_IP:+"  rsync -av --chmod=D700,F600 ~/.config/git-crypt/ wise@$LAN_IP:.config/git-crypt/"} \
            ${LAN_IP:+""} \
            "Next:" \
            "  1. bash ~/DOTS/arch/post-init.sh          chezmoi + gh/bw auth" \
            "  2. log out → pick session at the greeter" \
            "  3. device-evidence.sh                     Vanta evidence (~/.local/bin, from chezmoi)"
    else
        echo "✅ first-boot complete — next: bash ~/DOTS/arch/post-init.sh"
    fi
fi

# REBOOT AT THE END (setup.sh chains straight into post-init instead)
if [ "${SETUP_CHAIN:-0}" != 1 ]; then
    confirm --default=false "Reboot now?" && reboot || echo "Skipping reboot"
fi
