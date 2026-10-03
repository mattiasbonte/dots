# DOTS

The public half of my machine setup: an Arch Linux installer and the one
command that runs after it. Everything after the first login (packages, system
settings, services, dotfiles, dev checkouts) lives in a private chezmoi repo
that `bootstrap.sh` clones and applies.

| File | What it does |
|------|--------------|
| `arch/archinstall/install.sh` | Live-ISO installer: wipes the NVMe disk, LUKS2, pacstrap, user, systemd-boot |
| `bootstrap.sh` | The one command after first login, on any machine, as often as you like |
| `arch/bin/update-install-usb.sh` | Refreshes a netboot USB (iPXE loader + install.sh), or flashes the latest ISO |
| `arch/first-boot.sh`, `post-init.sh`, `setup.sh` | Deprecated shims that run `bootstrap.sh` |

## Fresh machine

1. Boot the Arch ISO (or the netboot USB: firmware boot menu, pick the USB, a
   mirror, then "Boot Arch Linux").
2. In the live environment:
   ```bash
   curl -fL https://raw.githubusercontent.com/mattiasbonte/dots/main/arch/archinstall/install.sh -o i.sh && bash i.sh
   ```
   It asks you to confirm the disk and for one passphrase, and checks the result is encrypted.
3. Reboot, remove the USB, enter the LUKS passphrase, log in.
4. Run:
   ```bash
   bash ~/DOTS/bootstrap.sh
   ```
   Bitwarden login and unlock is the only password step. It fetches the SSH
   (and age) keys, clones the dotfiles and applies them. Read the verify panel at the end.
5. Run `sudo tailscale up`, then `passwd` and `sudo cryptsetup luksChangeKey <root partition>`
   if you used temporary secrets. Reboot.

## Existing machine

```bash
bash ~/DOTS/bootstrap.sh            # --dry-run to preview, --no-upgrade to skip pacman -Syu
```

Every step checks before it acts, so re-running is safe. It also repairs a
clean chezmoi clone whose remote history was rewritten (it stops if the clone has local commits).

## Things no script restores

- SSH keys that are not in Bitwarden. Copy `~/.ssh/` somewhere safe before you wipe a disk.
- Keys that live only on the machine (git-crypt keys, app passphrases). Escrow them first.
- Wi-Fi profiles (`/etc/NetworkManager/system-connections/`). Re-join instead.
- Anything installed by hand and never added to the package list.
- Browser tabs and app logins. Sign in again.
- Device-compliance evidence: run `~/.local/bin/device-evidence.sh` and upload the file.

## Gaming notes

- Steam: Settings > Compatibility > Enable Steam Play for all other titles.
  Per game: Manage > Compatibility > force a Proton version.
