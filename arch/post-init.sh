# --
# POST INIT
# @note only after the init and github ssh key have been setup
# --

# Checks
if ! command -v gh &> /dev/null; then
  echo "Install github-cli first: 'sudo pacman -S gh'"
  exit 1
fi
if ! command -v bw &> /dev/null; then
  echo "Install bitwarden-cli first: 'sudo pacman -S bitwarden-cli'"
  exit 1
fi
gum confirm --default=false "Have you authorized github-cli (so that your github ssh key is set up)?" || gh auth login
gum confirm --default=false "Have you authorized bitwarden-cli (needed for chezmoi)?" || bw login

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

gum confirm --default=false "Reboot now?" && reboot || "Reboot later"
