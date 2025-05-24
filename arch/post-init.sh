# --
# POST INIT
# @note only after the init and github ssh key have been setup
# --

# Checks
gum confirm "Have you authorized github-cli (so that your ssh is set up correctly)?" || gh auth login
gum confirm "Have you authorized bitwarden-cli (needed for chezmoi)?" || bw login

# Shortcuts
z ~/DOTS
z ~/.config
z ~/Downloads
z ~/DEV/GO/breaks
z ~/.local/share/chezmoi
z ~/DEV/PROFESSION/WINTRO/wintro-mono/app

# CHEZMOI
export BW_SESSION=$(bw unlock --raw)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git
unset BW_SESSION

gum confirm "Reboot now?" && reboot || "Reboot later"
