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
sudo eject /dev/sdc
```

# Boot
## Tuxedo
- Put usb into right port next to power supply
- Restart laptop
- Spam `del` key to enter the BIOS menu
- In boot menu select boot order to USB first
- Reboot (don't forget to change this again after installation)

## Desktop
- Select `reboot into firmware interface`
- Select `F9` Boot Menu
- Select the iPXE USB Drive

# IPXE Menu

- Select a mirror.
- Select `Boot Arch Linux`

# Archinstall

> creds.json must include `"encryption_password": "<temp-passphrase>"` — the
> desktop config installs with LUKS full-disk encryption. Use a throwaway
> passphrase and rotate after first boot:
> `sudo cryptsetup luksChangeKey /dev/nvme0n1p2`, then wipe creds.json.

```bash
# Single-touch: mount the USB and run its installer — it detects the
# machine (TUXEDO → wise-laptop, else wise-desktop) and uses the local
# config + creds. Keep the stick fresh with:
#   ~/DOTS/arch/bin/update-install-usb.sh <usb-mountpoint>
mkdir -p /mnt/usb && mount /dev/sda1 /mnt/usb
bash /mnt/usb/install.sh

# then: select reboot
```

> After first boot: `passwd` (temp password!) and rotate the LUKS
> passphrase: `sudo cryptsetup luksChangeKey <root-partition>` — then
> delete creds.json from the stick or rerun update-install-usb.sh.

# Post-install

```bash
~/DOTS/arch/first-boot.sh
~/DOTS/arch/post-init.sh

# Device compliance evidence (upload to Vanta > Computers > this device)
~/DOTS/arch/bin/device-evidence.sh
```

# Gaming

## Lutris Runners

- [ ] In steam select `settings` > `compatibility` > `Enable Steam Play for all other titles`
- Go to a game (cs2), right click > `Manage` > `Compatibility` > `Mark force checkmark` and start selecting a version to download it.

```

```

# [Tuxedo Specific](https://www.tuxedocomputers.com/en/Arch-Linux-and-Manjaro-on-TUXEDO-computers.tuxedo)

```bash
paru -S tuxedo-control-center-bin 
paru -S tuxedo-drivers-dkms 
paru -S linux-headers
```
