# Helpers
i() {
    local pm="$1"
    shift

    if [ -z "$1" ]; then
        echo "POST INSTALL ERROR: No package specified."
        return 1
    fi

    if [ "$pm" = "pacman" ]; then
        for pkg in "$@"; do
            echo "Checking package: $pkg"
            if ! pacman -Qi "$pkg" &>/dev/null; then
                echo "Installing $pkg with pacman..."
                sudo pacman -S --needed "$pkg" || {
                    echo "Failed to install $pkg"
                    return 1
                }
                echo "$pkg installed successfully"
            else
                echo "$pkg is already installed"
            fi
        done
    elif [ "$pm" = "paru" ]; then
        for pkg in "$@"; do
            echo "Checking package: $pkg"
            if ! paru -Qi "$pkg" &>/dev/null; then
                echo "Installing $pkg with paru..."
                paru -S "$pkg" || {
                    echo "Failed to install $pkg"
                    return 1
                }
                echo "$pkg installed successfully"
            else
                echo "$pkg is already installed"
            fi
        done
    else
        echo "POST INSTALL ERROR: Invalid package manager specified. Use 'pacman' or 'paru'."
        return 1
    fi
}

# Paru
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

# Shell
i pacman zsh
i pacman zsh-completions
sudo chsh -s $(which zsh)

# Yazi
i pacman yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick
paru resvg

# Git
i pacman lazygit github-cli

# Game
i pacman pacman-contrib
