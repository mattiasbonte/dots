# -------------------------- #
# ARCH https://archlinux.org #
# -------------------------- #

# sudo
se() { sudoedit $* }
su() { sudo su $* }

# pacman
paci() { sudo pacman -S --needed --noconfirm $* }
pacr() { sudo pacman -R $* }

# paru
pari() { paru -S --needed --noconfirm $* }
parr() { paru -R $* }

# i3
update() {
    sudo pacman -Syu
    # Disable system beep
    xset b off
    # Set keyboard repeat speed (arch)
    xset r rate 145 40
    # remap caps -> escape
    setxkbmap -option caps:escape
}
