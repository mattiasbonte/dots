# Netboot USB

> Netboot allows us to always have the latest iso file when installing arch linux.

```bash
# Find the USB drive identifier
sudo fdisk -l

# Prepare USB (using /dev/sdc in our example)
sudo wipefs -a /dev/sdc
sudo parted /dev/sdc mklabel gpt
sudo parted /dev/sdc mkpart ESP fat32 1MiB 100%
sudo parted /dev/sdc set 1 boot on
sudo mkfs.fat -F32 /dev/sdc1
sudo mount /dev/sdc1 /mnt

# Download the arch linux iso (https://archlinux.org/releng/netboot/)
wget https://archlinux.org/static/netboot/ipxe-arch.efi

# Copy the file to the partition
sudo cp ~/Downloads/ipxe-arch.efi /mnt/EFI/BOOT/BOOTX64.EFI

# Eject
sudo umount /mnt
sudo Reject /dev/sdc
```

# Boot

- Select `reboot into firmware interface`
- Select `F9` Boot Menu
- Select the iPXE USB Drive

# IPXE Menu

- Select a mirror.
- Select `Boot Arch Linux`

# Archinstall

```bash
# Mount the installation USB
mkdir /mnt/usb
mount /dev/sda /mnt/usb

# Update installer
pacman -Sy && pacman -S --noconfirm archinstall

# Install config
archinstall \
--creds /mnt/usb/configs/wise-desktop/creds.json \
--config-url https://raw.githubusercontent.com/mattiasbonte/dots/main/arch/archinstall/conf_desktop.json
# --config https://tinyurl.com/12345678 \ # Use [tinyurl](https://tinyurl.com) to shorten config url if preferred

select reboot
```

# Post-install

```bash
~/DOTS/arch/first-boot.sh
~/DOTS/arch/post-init.sh
```

# Gaming

## Lutris Runners

- [ ] In steam select `settings` > `compatibility` > `Enable Steam Play for all other titles`
- Go to a game (cs2), right click > `Manage` > `Compatibility` > `Mark force checkmark` and start selecting a version to download it.

```

```
