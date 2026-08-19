# --
# FIRST BOOT
# @note installs all required packages to be able to quickly get the system up and running
# Every step is tracked: failures collect in FAILED and print in the final
# panel; a VERIFY pass at the end asserts outcomes (binaries/files exist),
# so nothing can silently skip. Idempotent — re-run until the panel is green.
# --

cd "$HOME" # unattended service starts in / — clones/builds need a writable CWD

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
paci() { [ -z "$1" ] && return 0; sudo pacman -S --needed --noconfirm "$@" || fail "pacman: $*"; }
pari() { [ -z "$1" ] && return 0; command -v paru >/dev/null 2>&1 && { paru -S --needed --noconfirm "$@" || fail "paru: $*"; } || fail "paru missing: $*"; }
vcmd() { local c; for c in "$@"; do command -v "$c" >/dev/null 2>&1 || fail "verify: '$c' not on PATH"; done; }
vfile() { [ -e "$1" ] || fail "verify: missing $1"; }

# UPDATE DBS
try "system upgrade (pacman -Syu)" sudo pacman -Syu --noconfirm
command -v paru >/dev/null 2>&1 && try "AUR upgrade (paru -Syu)" paru -Syu --noconfirm

# AUR helper — bootstrapped FIRST (everything pari depends on it), fully
# unattended (--noconfirm), loud on failure.
if ! command -v paru >/dev/null 2>&1; then
    paci base-devel git
    PARU_TMP=$(mktemp -d)
    if git clone https://aur.archlinux.org/paru.git "$PARU_TMP/paru" \
        && ( cd "$PARU_TMP/paru" && makepkg -si --noconfirm ) \
        && command -v paru >/dev/null 2>&1; then
        echo "✔ paru bootstrapped"
    else
        fail "paru bootstrap — ALL AUR installs below will fail"
    fi
    rm -rf "$PARU_TMP"
fi

# HW detection (drives laptop/Tuxedo sections below)
IS_LAPTOP=false; ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && IS_LAPTOP=true
IS_TUXEDO=false; grep -qi tuxedo /sys/class/dmi/id/sys_vendor 2>/dev/null && IS_TUXEDO=true

# BASE
paci base-devel git rust go
paci jq xsel xclip bottom wget atool aria2 cmake keychain xdotool bat tree age mpv gum glow dialog bitwarden bitwarden-cli xprintidle dex alsa-utils

# CONFIG
try "DOTS pull" git -C "$HOME/DOTS" pull
find "$HOME/DOTS/arch/config" -mindepth 1 -maxdepth 1 -exec cp -rn {} "$HOME/.config/" \; # files AND dirs; -n = bootstrap only, never clobber
# fetch stays https (works before any SSH key exists) — only pushes need auth
try "DOTS remote (fetch=https)" git -C "$HOME/DOTS" remote set-url origin "https://github.com/mattiasbonte/dots.git"
try "DOTS remote (push=ssh)"    git -C "$HOME/DOTS" remote set-url --push origin "git@github.com:mattiasbonte/dots.git"

# ZSH
paci zsh zsh-completions starship alacritty kitty tmux
[ "$(basename "$SHELL")" = "zsh" ] || try "chsh to zsh" sudo chsh -s "$(which zsh)" "$USER"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended || fail "oh-my-zsh install"
    cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc" || fail "bootstrap .zshrc copy"
else
    echo "Oh My Zsh already installed, skipping installation"
fi

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick trash-cli mpv rsync imv satty

pari resvg

# GIT
paci git git-crypt lazygit github-cli git-delta difftastic
try "git identity (email)" git config --global user.email "info@mattiasbonte.dev"
try "git identity (name)"  git config --global user.name "Mattias B."

# DEV
pari pnpm-bin pyenv luarocks postgresql-libs opencode-bin claude-code sqlit
[ -s "$HOME/.nvm/nvm.sh" ] || { curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash; } || fail "nvm install" # NVM

# EDIT
paci bob zed
# bob prompts "add to PATH?" on /dev/tty (unpipeable) unless nvim-bin is already in PATH
export PATH="$PATH:$HOME/.local/share/bob/nvim-bin"
bob list 2>/dev/null | grep -q nightly || bob use nightly || fail "bob use nightly (neovim)"
paci ttf-jetbrains-mono-nerd

# DOTS
pari chezmoi

# WEB
pari zen-browser-bin
paci chromium

# AI
paci aichat

# MISC
paci valkey thunderbird flameshot copyq easyeffects xournalpp yt-dlp
pari slack-desktop

# ESSENTIALS (from installed-state audit — daily-driver basics)
paci htop btop vim nano xdg-utils xorg-xrandr xorg-xev xterm \
    network-manager-applet terminus-font ttf-liberation gnu-free-fonts \
    sof-firmware smartmontools efibootmgr net-tools inotify-tools time \
    git-filter-repo sox darkman python-pipx tree-sitter-cli \
    feh nsxiv zathura zathura-pdf-mupdf clamav
pari whosthere-bin yaak-bin # nc comes from openbsd-netcat (dep); gnu-netcat conflicts with it

# Tailscale (mesh vpn) — your choice per machine; default yes on laptops
TS_DEFAULT="--default=false"; $IS_LAPTOP && TS_DEFAULT="--default=true"
if confirm "$TS_DEFAULT" "Install Tailscale? (mesh VPN / remote access)"; then
    paci tailscale
    try "tailscaled enable" sudo systemctl enable --now tailscaled
fi

# --
# DEVICE COMPLIANCE (Vanta device trust: encryption is handled at
# install time by archinstall; this covers screen lock + evidence)
# --
paci xss-lock i3lock
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/screen-lock.desktop" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Screen autolock (xss-lock)
Exec=sh -c 'xset s 900 && exec xss-lock -- i3lock -c 000000'
OnlyShowIn=awesome;
DESKTOP
# KDE session: enforce kscreenlocker regardless of defaults
for KW in kwriteconfig6 kwriteconfig5; do
    if command -v "$KW" >/dev/null 2>&1; then
        try "kscreenlocker config" "$KW" --file kscreenlockerrc --group Daemon --key Autolock true
        "$KW" --file kscreenlockerrc --group Daemon --key Timeout 15
        "$KW" --file kscreenlockerrc --group Daemon --key LockOnResume true
        break
    fi
done
chmod +x "$HOME/DOTS/arch/bin/device-evidence.sh"
echo "→ after setup, run ~/DOTS/arch/bin/device-evidence.sh and upload the file to Vanta"

# caps:escape at the X-server level — applies in every session and at the
# SDDM greeter, independent of WM autostarts
try "x11 keymap (caps:escape)" sudo localectl set-x11-keymap us pc105+inet "" caps:escape,terminate:ctrl_alt_bksp

# WM
paci arandr autorandr pavucontrol redshift
    # arandr: screen management
    # pavucontrol: audio/video control
    # redshift: night light -> redshift -0 3000
pari lain-git
    # lain-git: Awesome WM complements - provides additional layouts, widgets, and utilities for Awesome window manager

# LAPTOP (auto-detected)
if $IS_LAPTOP; then
    paci xorg-xinput # touchpad
    paci blueman # bluetooth
    paci brightnessctl # screen brightness
    pari unified-remote-server # remote control
fi


# --
# GAME
# --

# Multilib
paci pacman-contrib
try "enable multilib repo" sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
try "pacman -Sy (multilib)" sudo pacman -Sy

# Intel - https://github.com/lutris/docs/blob/master/InstallingDrivers.md#intel
paci lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader

# Nvidia - https://github.com/lutris/docs/blob/master/InstallingDrivers.md#nvidia-1
paci linux-zen-headers nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader


# Wine - https://github.com/lutris/docs/blob/master/WineDependencies.md
paci wine-staging
sudo pacman -S --needed --noconfirm --asdeps \
    giflib gnutls lib32-gnutls v4l-utils libpulse \
    lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib sqlite lib32-sqlite libxcomposite \
    lib32-libxcomposite ocl-icd lib32-ocl-icd libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs \
    vulkan-icd-loader lib32-vulkan-icd-loader sdl2-compat lib32-sdl2-compat \
    || fail "wine dependencies (--asdeps)"

# Packs
paci steam lutris teamspeak3 discord obsidian
pari protonplus

# DICTATION
if [ ! -f "$HOME/whisper.cpp/build/bin/whisper-cli" ]; then
    ( set -e
      cd "$HOME"
      [ -d whisper.cpp ] || git clone https://github.com/ggerganov/whisper.cpp
      cd whisper.cpp
      cmake -B build && cmake --build build -j --config Release # binary: build/bin/whisper-cli
      bash models/download-ggml-model.sh small
    ) || fail "whisper.cpp build"
else
    echo "Whisper.cpp already built, skipping"
fi

# TTS (Piper)
pari piper-tts-bin

# Piper voices
mkdir -p "$HOME/.local/share/piper/voices"
if [ -f "$HOME/.local/share/piper/voices/en_GB-cori-high.onnx" ]; then
    echo "Piper voices already installed"
elif confirm --default=true "Install Piper TTS voices (Cori - female British, Ryan - male American) (high quality)?"; then
    ( set -e
      cd "$HOME/.local/share/piper/voices"
      wget -q --show-progress -O en_GB-cori-high.onnx \
          "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_GB/cori/high/en_GB-cori-high.onnx"
      wget -q --show-progress -O en_GB-cori-high.onnx.json \
          "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_GB/cori/high/en_GB-cori-high.onnx.json"
      wget -q --show-progress -O en_US-ryan-high.onnx \
          "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/ryan/high/en_US-ryan-high.onnx"
      wget -q --show-progress -O en_US-ryan-high.onnx.json \
          "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/ryan/high/en_US-ryan-high.onnx.json"
    ) || fail "piper voice downloads"
else
    echo "Skipping Piper voice installation"
fi

if $IS_LAPTOP; then
    printf 'ListenAddress 127.0.0.1\n' | sudo tee /etc/ssh/sshd_config.d/10-localhost-only.conf >/dev/null || fail "sshd localhost-only config"
fi

if $IS_TUXEDO; then
    pari tuxedo-control-center-bin tuxedo-drivers-dkms
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
vcmd paru zsh starship alacritty kitty tmux yazi lazygit gh delta difft bob zeditor \
     chromium aichat flameshot copyq easyeffects steam lutris discord obsidian \
     pnpm pyenv chezmoi claude opencode xss-lock i3lock piper-tts valkey-server \
     zen-browser slack resvg zoxide fzf rg fd bat gum glow bw age
vfile "$HOME/.oh-my-zsh"
vfile "$HOME/.nvm/nvm.sh"
vfile "$HOME/.config/autostart/screen-lock.desktop"
vfile "$HOME/whisper.cpp/build/bin/whisper-cli"
vfile "$HOME/.local/share/piper/voices/en_GB-cori-high.onnx"
[ "$(basename "$(getent passwd "$USER" | cut -d: -f7)")" = zsh ] || fail "verify: login shell is not zsh"
pacman -Slq multilib >/dev/null 2>&1 || fail "verify: multilib repo not enabled"
case "$(git -C "$HOME/DOTS" remote get-url origin)" in https://*) ;; *) fail "verify: DOTS fetch URL is not https";; esac
git config --global user.email >/dev/null 2>&1 || fail "verify: git identity not set"
$IS_LAPTOP && { [ -f /etc/ssh/sshd_config.d/10-localhost-only.conf ] || fail "verify: sshd localhost-only config missing"; }

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
            "Next:" \
            "  1. bash ~/DOTS/arch/post-init.sh          chezmoi + gh/bw auth" \
            "  2. log out → pick session at the greeter" \
            "  3. ~/DOTS/arch/bin/device-evidence.sh     Vanta evidence"
    else
        echo "✅ first-boot complete — next: bash ~/DOTS/arch/post-init.sh"
    fi
fi

# REBOOT AT THE END
confirm --default=false "Reboot now?" && reboot || echo "Skipping reboot"
