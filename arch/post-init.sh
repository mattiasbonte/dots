#!/usr/bin/zsh

# --
# POST INIT
# @note only after the init and github ssh key have been setup
# --

# Pre Chezmoi Setup
if ! command -v gh &>/dev/null; then
    echo "Install github-cli first: 'sudo pacman -S gh'"
    exit 1
fi
if ! command -v bw &>/dev/null; then
    echo "Install bitwarden-cli first: 'sudo pacman -S bitwarden-cli'"
    exit 1
fi
gum confirm --default=false "Have you authorized github-cli (so that your github ssh key is set up)?" || gh auth login
gum confirm --default=false "Have you authorized bitwarden-cli (needed for chezmoi)?" || bw login

# CHEZMOI
gum confirm "Initialize chezmoi?" && {
    bw sync
    echo "Initializing chezmoi..."
    export BW_SESSION=$(bw unlock --raw)
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git
    unset BW_SESSION
}

# Post Chezmoi Setup
source ~/.zshrc
nvm install node

# Shortcuts
z ~/DOTS
z ~/.config
z ~/Downloads
z ~/DEV/GO/breaks
z ~/.local/share/chezmoi
z ~/DEV/PROFESSION/WINTRO/wintro-mono/app

# --
# Sytemd
# --
loginctl enable-linger $USER

# Personal Config
systemctl --user enable wise-config.service
systemctl --user start wise-config.service

# Redis
sudo systemctl start valkey.service
sudo systemctl enable valkey.service


# Reboot
gum confirm --default=false "Reboot now?" && { echo "Rebooting system..."; reboot; } || echo "Reboot skipped. You can reboot manually later."
