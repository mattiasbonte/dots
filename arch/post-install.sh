# --
# POST INSTALL
# @note will run directly after the `archinstall` script as a `custom_command`
# @warn should not contain commands that can't be executed as root or that require user input
# --

# FN
paci() { [ -z "$1" ] && return 0 || sudo pacman -S --needed --noconfirm "$@"; }

# COPY CONF
cp -r "$HOME/DOTS/arch/config/zshrc" "$HOME/.zshrc"
cp -r "$HOME/DOTS/arch/config/i3" "$HOME/.config/i3"
cp -r "$HOME/DOTS/arch/config/zsh" "$HOME/.config/zsh"
cp -r "$HOME/DOTS/arch/config/tmux" "$HOME/.config/tmux"
cp -r "$HOME/DOTS/arch/config/yazi" "$HOME/.config/yazi"
cp -r "$HOME/DOTS/arch/config/polybar" "$HOME/.config/polybar"

# BASE
paci pacman-contrib base-devel git

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
