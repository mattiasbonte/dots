# FN
paci() { [ -z "$1" ] && return 0 || sudo pacman -S --needed "$@"; }
pari() { [ -z "$1" ] && return 0 || paru -S --needed "$@"; }

# AUR
if ! command -v paru &> /dev/null; then
    paci base-devel git
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

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
