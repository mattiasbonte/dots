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

# ZSH
paci zsh zsh-completions starship alacritty tmux
sudo chsh -s $(which zsh) $USER
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"

# CONFIG
find "$HOME/DOTS/arch/config" -mindepth 1 -maxdepth 1 -type d -exec cp -r {} "$HOME/.config" \;
cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc"
git -C "$HOME/DOTS" remote set-url origin "git@github.com:mattiasbonte/dots.git"

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

# DOTS
paru bitwarden-cli chezmoi

# WEB
pari zen-browser-bin

# AI
cari aichat
curl -LsSf https://aider.chat/install.sh | sh

# --
# GAME
# --

# Uncomments multilib to be able to install packages for gaming
paci pacman-contrib
sudo sed -i '/^#\[multilib\]/,/^#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
sudo pacman -Sy

# Deps
paci steam wine wine-staging winetricks lutris mangohud gamemode teamspeak3
paru proton-ge-custom-bin

# REBOOT AT THE END
sudo reboot
