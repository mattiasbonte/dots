#!/usr/bin/env bash
# Fully scripted Arch installer — no archinstall, no schema drift. Every
# step is an explicit, stable primitive: partition → LUKS2 → pacstrap →
# configure → systemd-boot. Run from the live ISO:
#   curl -fL https://raw.githubusercontent.com/mattiasbonte/dots/main/arch/archinstall/install.sh -o i.sh && bash i.sh
set -euo pipefail

main() {
[ -t 0 ] || exec </dev/tty
trap 'echo "✘ failed at line $LINENO — machine is mid-wipe anyway: fix + re-run is safe."' ERR
[ -d /run/archiso ] || { echo "✘ not the Arch live environment — refusing"; exit 1; }

# ── profile ─────────────────────────────────────────────────────────
VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo unknown)
case "$VENDOR" in
    *[Tt][Uu][Xx][Ee][Dd][Oo]*) HOST=wise-laptop ;;
    *)                          HOST=wise-desktop ;;
esac
DISK=/dev/nvme0n1
ESP=${DISK}p1
ROOT=${DISK}p2
TZ=Europe/Brussels
KEYMAP=us
LOCALE=en_US.UTF-8

# GPU: Turing+ → open modules; none → skip (first-boot handles extras)
GPU_PKGS=""
if lspci | grep -qi nvidia; then GPU_PKGS="nvidia-open-dkms nvidia-utils"; fi

PKGS="base linux-zen linux-zen-headers linux-firmware e2fsprogs cryptsetup
networkmanager sudo zsh git openssh zram-generator
plasma-meta sddm awesome xorg-server xorg-xinit konsole
pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
$GPU_PKGS"
grep -q GenuineIntel /proc/cpuinfo && PKGS="$PKGS intel-ucode" || PKGS="$PKGS amd-ucode"

# ── preflight ───────────────────────────────────────────────────────
timedatectl set-ntp true 2>/dev/null || true
curl -fsm 10 https://archlinux.org >/dev/null 2>&1 \
    || { echo "✘ no internet — plug ethernet (or iwctl) and re-run"; exit 1; }
echo "→ profile: $HOST  disk: $DISK  gpu: ${GPU_PKGS:-none}"
echo "⚠ this WIPES $DISK completely."
read -rp "type the disk path to confirm: " C
[ "$C" = "$DISK" ] || { echo "mismatch — aborting"; exit 1; }
while :; do
    read -rsp "LUKS + login passphrase (min 8 chars): " PW; echo
    [ ${#PW} -ge 8 ] || { echo "too short"; continue; }
    read -rsp "repeat: " PW2; echo
    [ "$PW" = "$PW2" ] && break || echo "mismatch, again"
done

# ── partition + encrypt + filesystems ───────────────────────────────
umount -R /mnt 2>/dev/null || true
cryptsetup close root 2>/dev/null || true
sgdisk -Z "$DISK"
sgdisk -n1:0:+1G -t1:ef00 -c1:ESP "$DISK"
sgdisk -n2:0:0   -t2:8309 -c2:cryptroot "$DISK"
partprobe "$DISK"; sleep 2
printf '%s' "$PW" | cryptsetup luksFormat --type luks2 --batch-mode "$ROOT" -d -
printf '%s' "$PW" | cryptsetup open "$ROOT" root -d -
mkfs.fat -F32 "$ESP"
mkfs.ext4 -q /dev/mapper/root
mount /dev/mapper/root /mnt
mkdir -p /mnt/boot
mount "$ESP" /mnt/boot

# ── base system ─────────────────────────────────────────────────────
# shellcheck disable=SC2086
pacstrap -K /mnt $PKGS
genfstab -U /mnt >> /mnt/etc/fstab
LUKS_UUID=$(blkid -s UUID -o value "$ROOT")

# ── configure (chroot) ──────────────────────────────────────────────
arch-chroot /mnt /bin/bash -e <<CHROOT
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
hwclock --systohc
sed -i 's/^#$LOCALE/$LOCALE/' /etc/locale.gen && locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOST" > /etc/hostname
printf '127.0.0.1 localhost\n::1 localhost\n127.0.1.1 $HOST\n' > /etc/hosts

useradd -m -G wheel -s /bin/zsh wise
echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

bootctl install
printf 'default arch.conf\ntimeout 3\n' > /boot/loader/loader.conf
printf 'title Arch Linux (zen)\nlinux /vmlinuz-linux-zen\ninitrd /initramfs-linux-zen.img\noptions cryptdevice=UUID=$LUKS_UUID:root root=/dev/mapper/root rw rootfstype=ext4 zswap.enabled=0\n' > /boot/loader/entries/arch.conf
printf 'title Arch Linux (zen fallback)\nlinux /vmlinuz-linux-zen\ninitrd /initramfs-linux-zen-fallback.img\noptions cryptdevice=UUID=$LUKS_UUID:root root=/dev/mapper/root rw rootfstype=ext4 zswap.enabled=0\n' > /boot/loader/entries/arch-fallback.conf

printf '[zram0]\nzram-size = ram / 2\n' > /etc/systemd/zram-generator.conf

git clone https://github.com/mattiasbonte/dots.git /home/wise/DOTS
chown -R wise:wise /home/wise/DOTS

printf '[Unit]\nDescription=wise first-boot provisioning\nWants=network-online.target\nAfter=network-online.target\nConditionPathExists=!/var/lib/wise-firstboot.done\n[Service]\nType=oneshot\nTimeoutStartSec=0\nExecStart=/usr/bin/runuser -u wise -- env NONINTERACTIVE=1 HOME=/home/wise bash /home/wise/DOTS/arch/first-boot.sh\nExecStartPost=/usr/bin/touch /var/lib/wise-firstboot.done\nStandardOutput=append:/var/log/wise-firstboot.log\nStandardError=append:/var/log/wise-firstboot.log\n[Install]\nWantedBy=multi-user.target\n' > /etc/systemd/system/wise-firstboot.service

systemctl enable NetworkManager sddm systemd-timesyncd wise-firstboot.service
CHROOT

printf '%s:%s\n' wise "$PW" | arch-chroot /mnt chpasswd

# ── self-verify ─────────────────────────────────────────────────────
echo; lsblk -o NAME,TYPE,FSTYPE,MOUNTPOINT "$DISK"
lsblk -no FSTYPE "$DISK" | grep -q crypto_LUKS || { echo "✘ NO crypto_LUKS — unencrypted result, do not use"; exit 1; }
[ -f /mnt/boot/loader/entries/arch.conf ] || { echo "✘ boot entry missing"; exit 1; }
echo "✔ encryption verified · boot entry present · user configured"
umount -R /mnt
cryptsetup close root
echo "✔ done — reboot, remove the USB, enter your passphrase, log in as wise."
echo "  The machine provisions itself: tail -f /var/log/wise-firstboot.log"
}
main "$@"
exit $?
