# -------------------------- #
# ARCH https://archlinux.org #
# -------------------------- #

# sudo
se() { sudoedit $* }
su() { sudo su $* }

# pacman
paci() { sudo pacman -Si $* }
pacs() { sudo pacman -S $* }
pacr() { sudo pacman -R $* }

# yay
yayi() { yay -Si $* }
yays() { yay -S $* }
yayr() { yay -R $* }

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
