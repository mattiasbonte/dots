# --
# POST INSTALL
# @note will run directly after the `archinstall` script as a `custom_command`
# @warn should not contain commands that can't be executed as root or that require user input
# --

# FN
paci() { [ -z "$1" ] && return 0 || sudo pacman -S --needed --noconfirm "$@"; }

# BASE
paci pacman-contrib paci base-devel git

# ZSH
paci zsh zsh-completions starship alacritty
sudo chsh -s $(which zsh)

# FM
paci yazi ffmpeg 7zip jq poppler fd ripgrep fzf zoxide imagemagick trash-cli mpv unrar unzip

# GIT
paci git lazygit github-cli git-delta

# OTHER
paci jq xsel xclip btop wget atool aria2 cmake keychain xdotool bat tree

# I3
paci polybar rofi clipmenu xdotool nitrogen
