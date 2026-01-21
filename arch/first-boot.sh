# --
# FIRST BOOT
# @note installs all required packages to be able to quickly get the system up and running
# --

# UPDATE DBS
sudo pacman -Syu && paru -Syu

# FN
paci() { [ -z "$1" ] && return 0 || command -v pacman >/dev/null 2>&1 && sudo pacman -S --needed --noconfirm "$@" || echo "pacman not found, skipping: $@"; }
pari() { [ -z "$1" ] && return 0 || command -v paru >/dev/null 2>&1 && paru -S --needed --noconfirm "$@" || echo "paru not found, skipping: $@"; }
cari() { [ -z "$1" ] && return 0 || command -v cargo >/dev/null 2>&1 && cargo install --if-not-installed "$@" || echo "cargo not found, skipping: $@"; }

# BASE
paci base-devel git rust go
paci jq xsel xclip bottom wget atool aria2 cmake keychain xdotool bat tree age mpv gum glow bitwarden bitwarden-cli xprintidle dex alsa-utils

# CONFIG
git -C "$HOME/DOTS" pull
find "$HOME/DOTS/arch/config" -mindepth 1 -maxdepth 1 -type d -exec cp -r {} "$HOME/.config" \;
git -C "$HOME/DOTS" remote set-url origin "git@github.com:mattiasbonte/dots.git"

# ZSH
paci zsh zsh-completions starship alacritty tmux
sudo chsh -s $(which zsh) $USER

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
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick trash-cli mpv rsync

pari resvg

# GIT
paci git lazygit github-cli git-delta difftastic
git config --global user.email "info@mattiasbonte.dev"
git config --global user.name "Mattias B."

# DEV
pari pnpm-bin pyenv luarocks postgresql-libs opencode-bin claude-code
command -v nvm >/dev/null 2>&1 || curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash # NVM

# EDIT
paci bob zed
bob use nightly
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

# WM
paci arandr autorandr pavucontrol redshift
    # arandr: screen management
    # pavucontrol: audio/video control
    # redshift: night light -> redshift -0 3000
pari lain-git
    # lain-git: Awesome WM complements - provides additional layouts, widgets, and utilities for Awesome window manager

# LAPTOP
paci xorg-xinput # touchpad
paci blueman # bluetooth
paci brightnessctl # screen brightness
pari unified-remote-server # remote control


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
paci nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader


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
    make  # Simple make, no cmake needed
    bash models/download-ggml-model.sh small
else
    echo "Whisper.cpp already installed, skipping installation"
fi

# TTS (Piper)
pari piper-tts

# Install Piper voices
mkdir -p "$HOME/.local/share/piper/voices"
cd "$HOME/.local/share/piper/voices"

gum confirm --default=true "Install Piper TTS voices (Cori - female British, Ryan - male American) (high quality)?" && {
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

gum confirm --default=false "Are you on a Tuxedo laptop?" && {
    pari tuxedo-control-center-bin tuxedo-drivers-dkms 
} || echo "Skipping Tuxedo-specific packages"


# REBOOT AT THE END
gum confirm --default=false "Reboot now?" && reboot || echo "Skipping reboot"
