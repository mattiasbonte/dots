# FN
paci() { [ -z "$1" ] && return 0 || sudo pacman -S --needed "$@"; }
pari() { [ -z "$1" ] && return 0 || paru -S --needed "$@"; }

# AUR
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

# ZSH
paci zsh
paci zsh-completions
sudo chsh -s $(which zsh)

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick
pari resvg

# GIT
paci lazygit github-cli

# PLAY
paci pacman-contrib

# WEB
pari zen-browser-bin
