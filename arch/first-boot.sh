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
paci jq xsel xclip btop wget atool aria2 cmake keychain xdotool bat tree age mpv

# CONFIG
find "$HOME/DOTS/arch/config" -mindepth 1 -maxdepth 1 -type d -exec cp -r {} "$HOME/.config" \;
cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc"
git -C "$HOME/DOTS" remote set-url origin "git@github.com:mattiasbonte/dots.git"

# ZSH
paci zsh zsh-completions starship alacritty tmux
sudo chsh -s $(which zsh) $USER
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# AUR
if ! command -v paru &>/dev/null; then
    paci base-devel git
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick trash-cli mpv unrar unzip
pari resvg

# GIT
paci git lazygit github-cli git-delta difftastic
git config --global user.email "info@mattiasbonte.dev"
git config --global user.name "Mattias B."

# DEV
pari nvm pnpm-bin pyenv
paci gum glow

# EDIT
paci bob zed
bob use nightly
paci ttf-jetbrains-mono-nerd

# DOTS
paru bitwarden-cli chezmoi

# WEB
pari zen-browser-bin

# AI
paci aichat
curl -LsSf https://aider.chat/install.sh | sh

# --
# GAME
# --

# Multilib
paci pacman-contrib
sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
sudo pacman -Sy

# Nvidia - https://github.com/lutris/docs/blob/master/InstallingDrivers.md#arch--manjaro--other-arch-linux-derivatives
paci nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader

# Intel
paci intel-ucode lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader

# Wine - https://github.com/lutris/docs/blob/master/WineDependencies.md
paci wine-staging
paci --asdeps \
giflib lib32-giflib gnutls lib32-gnutls v4l-utils lib32-v4l-utils libpulse \
lib32-libpulse alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib sqlite lib32-sqlite libxcomposite \
lib32-libxcomposite ocl-icd lib32-ocl-icd libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs \
lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader sdl2-compat lib32-sdl2-compat

# Packs
paci steam lutris teamspeak3
paci gamemode mangohud



# REBOOT AT THE END
reboot
