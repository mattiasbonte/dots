# --
# FIRST BOOT
# @note installs all required packages to be able to quickly get the system up and running
# --

cd "$HOME" # unattended service starts in / — clones/builds need a writable CWD

# UPDATE DBS
sudo pacman -Syu && paru -Syu

# NONINTERACTIVE=1 → every gum prompt takes its default (used by the
# wise-firstboot service that runs this unattended after install)
confirm() { if [ "${NONINTERACTIVE:-0}" = 1 ]; then [ "$1" = "--default=true" ]; else gum confirm "$@"; fi; }

# FN — failures are collected, not fatal; summary prints at the end
FAILED=()
paci() { [ -z "$1" ] && return 0; sudo pacman -S --needed --noconfirm "$@" || FAILED+=("pacman: $*"); }
pari() { [ -z "$1" ] && return 0; command -v paru >/dev/null 2>&1 && { paru -S --needed --noconfirm "$@" || FAILED+=("paru: $*"); } || FAILED+=("paru missing: $*"); }

# HW detection (drives laptop/Tuxedo sections below)
IS_LAPTOP=false; ls /sys/class/power_supply/BAT* >/dev/null 2>&1 && IS_LAPTOP=true
IS_TUXEDO=false; grep -qi tuxedo /sys/class/dmi/id/sys_vendor 2>/dev/null && IS_TUXEDO=true

# BASE
paci base-devel git rust go
paci jq xsel xclip bottom wget atool aria2 cmake keychain xdotool bat tree age mpv gum glow dialog bitwarden bitwarden-cli xprintidle dex alsa-utils

# CONFIG
git -C "$HOME/DOTS" pull
find "$HOME/DOTS/arch/config" -mindepth 1 -maxdepth 1 -exec cp -rn {} "$HOME/.config/" \; # files AND dirs; -n = bootstrap only, never clobber
git -C "$HOME/DOTS" remote set-url origin "git@github.com:mattiasbonte/dots.git"

# ZSH
paci zsh zsh-completions starship alacritty kitty tmux
[ "$(basename "$SHELL")" = "zsh" ] || sudo chsh -s "$(which zsh)" "$USER"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
    cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc"
else
    echo "Oh My Zsh already installed, skipping installation"
fi

# AUR
if ! command -v paru &>/dev/null; then
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick trash-cli mpv rsync imv satty

pari resvg

# GIT
paci git git-crypt lazygit github-cli git-delta difftastic
git config --global user.email "info@mattiasbonte.dev"
git config --global user.name "Mattias B."

# DEV
pari pnpm-bin pyenv luarocks postgresql-libs opencode-bin claude-code sqlit
command -v nvm >/dev/null 2>&1 || curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash # NVM

# EDIT
paci bob zed
bob list 2>/dev/null | grep -q nightly || bob use nightly
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
pari whosthere-bin yaak-bin gnu-netcat

# Tailscale (mesh vpn — login happens in post-init: `sudo tailscale up`)
paci tailscale
sudo systemctl enable --now tailscaled

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
        "$KW" --file kscreenlockerrc --group Daemon --key Autolock true
        "$KW" --file kscreenlockerrc --group Daemon --key Timeout 15
        "$KW" --file kscreenlockerrc --group Daemon --key LockOnResume true
        break
    fi
done
chmod +x "$HOME/DOTS/arch/bin/device-evidence.sh"
echo "→ after setup, run ~/DOTS/arch/bin/device-evidence.sh and upload the file to Vanta"

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
sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
sudo pacman -Sy

# Intel - https://github.com/lutris/docs/blob/master/InstallingDrivers.md#intel
paci lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader

# Nvidia - https://github.com/lutris/docs/blob/master/InstallingDrivers.md#nvidia-1
paci linux-zen-headers nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader


# Wine - https://github.com/lutris/docs/blob/master/WineDependencies.md
paci wine-staging
paci --asdeps \
    giflib lib32-giflib gnutls lib32-gnutls v4l-utils lib32-v4l-utils libpulse \
    lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib sqlite lib32-sqlite libxcomposite \
    lib32-libxcomposite ocl-icd lib32-ocl-icd libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs \
    lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader sdl2-compat lib32-sdl2-compat

# Packs
paci steam lutris teamspeak3 discord obsidian
pari protonplus

# DICTATION
if [ ! -d "$HOME/whisper.cpp" ]; then
    cd ~
    git clone https://github.com/ggerganov/whisper.cpp
    cd whisper.cpp
    cmake -B build && cmake --build build -j --config Release # binary: build/bin/whisper-cli
    bash models/download-ggml-model.sh small
else
    echo "Whisper.cpp already installed, skipping installation"
fi

# TTS (Piper)
pari piper-tts-bin

# Install Piper voices
mkdir -p "$HOME/.local/share/piper/voices"
cd "$HOME/.local/share/piper/voices"

[ -f en_GB-cori-high.onnx ] && echo "Piper voices already installed" || confirm --default=true "Install Piper TTS voices (Cori - female British, Ryan - male American) (high quality)?" && {
    echo "Downloading Cori voice (female, British, high quality)..."
    wget -q --show-progress -O en_GB-cori-high.onnx \
        "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_GB/cori/high/en_GB-cori-high.onnx"
    wget -q --show-progress -O en_GB-cori-high.onnx.json \
        "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_GB/cori/high/en_GB-cori-high.onnx.json"

    echo "Downloading Ryan voice (male, American, high quality)..."
    wget -q --show-progress -O en_US-ryan-high.onnx \
        "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/ryan/high/en_US-ryan-high.onnx"
    wget -q --show-progress -O en_US-ryan-high.onnx.json \
        "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/ryan/high/en_US-ryan-high.onnx.json"

    echo "✅ Piper high-quality voices installed"
} || echo "Skipping Piper voice installation"

if $IS_LAPTOP; then
    printf 'ListenAddress 127.0.0.1\n' | sudo tee /etc/ssh/sshd_config.d/10-localhost-only.conf >/dev/null
fi

if $IS_TUXEDO; then
    pari tuxedo-control-center-bin tuxedo-drivers-dkms
fi


# SUMMARY
if [ ${#FAILED[@]} -gt 0 ]; then
    echo; echo "⚠ ${#FAILED[@]} install step(s) failed:"; printf ' - %s\n' "${FAILED[@]}"
else
    echo "✅ all install steps succeeded"
fi

# REBOOT AT THE END
confirm --default=false "Reboot now?" && reboot || echo "Skipping reboot"
