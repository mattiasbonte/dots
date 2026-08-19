#!/usr/bin/env bash
# The one command to bring a machine up to date. Both phases are idempotent,
# so this is equally the install path and the "sync my machine" path:
#   phase 1  first-boot  packages, drivers, device compliance   (no auth needed)
#   phase 2  post-init   GitHub/Bitwarden, dotfiles, services   (needs your vault)
# Run it as often as you like.
set -uo pipefail

SETUP_CHAIN=1 bash "$HOME/DOTS/arch/first-boot.sh" || FIRSTBOOT_FAILED=1
echo
exec zsh "$HOME/DOTS/arch/post-init.sh"
