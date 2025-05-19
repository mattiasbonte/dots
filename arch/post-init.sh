
# --
# POST INIT
# @note only after the init and github ssh key have been setup
# --

export BW_SESSION=$(bw unlock --raw)

# CHEZMOI
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git

unset BW_SESSION
