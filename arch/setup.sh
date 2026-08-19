#!/usr/bin/env bash
# The one command to bring a machine up to date. Both phases are idempotent,
# so this is equally the install path and the "sync my machine" path:
#   phase 1  first-boot  packages, drivers, device compliance   (no auth needed)
#   phase 2  post-init   GitHub/Bitwarden, dotfiles, services   (needs your vault)
# Run it as often as you like.
#
# Debugging a second machine is far faster over SSH from the primary one than
# at its keyboard: desktops enable sshd on the LAN (see first-boot), so
#   ssh-copy-id wise@<host>     # once
#   ssh wise@<host> 'bash ~/DOTS/arch/setup.sh'
# gives full output where you can read and act on it.
set -uo pipefail

SETUP_CHAIN=1 bash "$HOME/DOTS/arch/first-boot.sh" || FIRSTBOOT_FAILED=1
echo
exec zsh "$HOME/DOTS/arch/post-init.sh"
