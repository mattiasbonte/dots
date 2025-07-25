# --
# FIRST BOOT
# @note installs all required packages to be able to quickly get the system up and running
# --

# FN
paci() { [ -z "$1" ] && return 0 || command -v pacman >/dev/null 2>&1 && sudo pacman -S --needed --noconfirm "$@" || echo "pacman not found, skipping: $@"; }
pari() { [ -z "$1" ] && return 0 || command -v paru >/dev/null 2>&1 && paru -S --needed --noconfirm "$@" || echo "paru not found, skipping: $@"; }
cari() { [ -z "$1" ] && return 0 || command -v cargo >/dev/null 2>&1 && cargo install --if-not-installed "$@" || echo "cargo not found, skipping: $@"; }

# BASE
paci base-devel git rust go
paci jq xsel xclip btop wget atool aria2 cmake keychain xdotool bat tree age mpv gum glow bitwarden bitwarden-cli xprintidle dex

# CONFIG
git -C "$HOME/DOTS" pull
find "$HOME/DOTS/arch/config" -mindepth 1 -maxdepth 1 -type d -exec cp -r {} "$HOME/.config" \;
git -C "$HOME/DOTS" remote set-url origin "git@github.com:mattiasbonte/dots.git"

# ZSH
paci zsh zsh-completions starship alacritty tmux
sudo chsh -s $(which zsh) $USER
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" "" --unattended
cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc"

# AUR
if ! command -v paru &>/dev/null; then
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick trash-cli mpv

pari resvg

# GIT
paci git lazygit github-cli git-delta difftastic
git config --global user.email "info@mattiasbonte.dev"
git config --global user.name "Mattias B."

# DEV
pari pnpm-bin pyenv luarocks postgresql-libs
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash # NVM

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

# DICTATION
pari nerd-dictation

if gum confirm "Download nerd-dictation voice model?"; then
    MODEL_FILE="vosk-model-en-us-0.42-gigaspeech.zip"
    wget "https://alphacephei.com/vosk/models/$MODEL_FILE"
    [ ! -d "$HOME/.config/nerd-dictation/model" ] && mkdir -p "$HOME/.config/nerd-dictation/model"
    unzip -q "$MODEL_FILE" -d "$HOME/.config/nerd-dictation/model"
    rm "$MODEL_FILE"
fi

# MISC
paci redis thunderbird slack-desktop flameshot copyq easyeffects xournalpp yt-dlp

# WM
paci arandr pavucontrol redshift
    # arandr: screen management
    # pavucontrol: audio/video control
    # redshift: night light -> redshift -0 3000
pari lain-git
    # lain-git: Awesome WM complements - provides additional layouts, widgets, and utilities for Awesome window manager

# LAPTOP
paci xorg-xinput # touchpad


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
paci steam lutris teamspeak3 discord
pari protonplus

# REBOOT AT THE END
gum confirm --default=false "Reboot now?" && reboot || echo "Skipping reboot"
