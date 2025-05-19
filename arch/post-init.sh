
# --
# POST INIT
# @note only after the init and github ssh key have been setup
# --

# CHEZMOI
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git
