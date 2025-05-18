# FN
paci() { [ -z "$1" ] && return 0 || sudo pacman -S --needed --noconfirm "$@"; }

# BASE
paci pacman-contrib paci base-devel git

# ZSH
paci zsh zsh-completions
sudo chsh -s $(which zsh)

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick
pari resvg

# GIT
paci git lazygit github-cli
