# --
# FIRST BOOT
# @note installs all required packages to be able to quickly get the system up and running
# --

# FN
paci() { [ -z "$1" ] && return 0 || sudo pacman -S --needed --noconfirm "$@"; }
pari() { [ -z "$1" ] && return 0 || paru -S --needed --noconfirm "$@"; }
cari() { [ -z "$1" ] && return 0 || cargo install "$@"; }

# ZSH
sudo chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


# RUST
rustup default stable

# AUR
if ! command -v paru &>/dev/null; then
    paci base-devel git
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ..
    rm -rf paru
fi

# FM
pari resvg

# DEV
pari nvm pnpm-bin
paci gum glow

# NVIM
paci bob
bob use nightly

# WEB
pari zen-browser-bin

# AI
cari aichat

# GAME
paci giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
paci nvidia-dkms nvidia-utils lib32-nvidia-utils
paci steam wine wine-stagin winetricks lutris mangohud gamemode
paru proton-ge-custom-bin teamspeak3

paci irqbalance
sudo systemctl enable --now irqbalance
