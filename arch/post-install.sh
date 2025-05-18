# Helpers
install() {
    if [ "$1" = "pacman" ]; then
        if ! pacman -Qi "$2" &>/dev/null; then
            sudo pacman -S --needed "$2"
        fi
    elif [ "$1" = "paru" ]; then
        if ! paru -Qi "$2" &>/dev/null; then
            paru -S "$2"
        fi
    fi
}

# Paru
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

# Shell
install pacman zsh
install pacman zsh-completions
sudo chsh -s $(which zsh)

# Yazi
install yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick
paru resvg

# Git
install pacman lazygit github-cli

# Game
install pacman pacman-contrib
