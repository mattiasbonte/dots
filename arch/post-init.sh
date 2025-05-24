# --
# POST INIT
# @note only after the init and github ssh key have been setup
# --

# Conrifm
gum confirm "Have you authorized github-cli (so that your ssh is set up correctly)?" || gh auth login
gum confirm "Have you authorized bitwarden-cli (needed for chezmoi)?" || bw login

export BW_SESSION=$(bw unlock --raw)

# CHEZMOI
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git

unset BW_SESSION

gum confirm "Reboot now?" && reboot || "Reboot later"
