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
[ -d "$HOME/.local/share/chezmoi/.git" ] && echo "chezmoi already initialized" || gum confirm "Initialize chezmoi?" && {
    bw sync
    echo "Initializing chezmoi..."
    export BW_SESSION=$(bw unlock --raw)
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git
    unset BW_SESSION
}

# Post Chezmoi Setup
source ~/.zshrc
command -v node >/dev/null 2>&1 || nvm install node

# Shortcuts
z ~/DOTS
z ~/MIND
z ~/NOTES
z ~/.config
z ~/Downloads
z ~/DEV/GO/breaks
z ~/.local/share/chezmoi
z ~/DEV/PROFESSION/WINTRO/wintro-mono/app

# --
# Default Applications
# --
# Set Zed as default editor for markdown and text files
xdg-mime default dev.zed.Zed.desktop text/markdown
xdg-mime default dev.zed.Zed.desktop text/x-markdown
xdg-mime default dev.zed.Zed.desktop text/plain

# --
# Sytemd
# --
loginctl enable-linger $USER

# Personal Config
systemctl --user enable wise-config.service # starts with the next graphical session
# laptop-specific user units (files come from chezmoi)
case "$(cat /etc/hostname)" in wise-laptop*)
    for u in aether-break.service aether-secrets-unlock.service aether-tunnel.service \
             wintro-notes-sync.service aether-backup-daily.timer aether-laptop-sync.timer \
             chezmoi-re-add.timer laptop-heartbeat.timer; do
        [ -f "$HOME/.config/systemd/user/$u" ] && systemctl --user enable "$u"
    done ;;
esac
if command -v tailscale >/dev/null && ! tailscale status >/dev/null 2>&1; then # installed = chosen in first-boot
    gum confirm "Connect Tailscale now? (prints an auth URL to open in a browser)" && sudo tailscale up || echo "later: sudo tailscale up"
fi
sudo systemctl enable --now bluetooth.service # system service, not user
case "$(cat /etc/hostname)" in wise-laptop*) systemctl --user enable autorandr.service ;; esac # multi-display is a laptop concern


# Redis
sudo systemctl start valkey.service
sudo systemctl enable valkey.service

# Spotify
[ -x "$HOME/go/bin/go-spotify-cli" ] || go install github.com/envoy49/go-spotify-cli@latest


# Reboot
gum confirm --default=false "Reboot now?" && { echo "Rebooting system..."; reboot; } || echo "Reboot skipped. You can reboot manually later."
