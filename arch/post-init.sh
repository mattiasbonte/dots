#!/usr/bin/env bash
# Deprecated: ~/DOTS/bootstrap.sh is the one command for fresh and existing machines.
echo "⚠ arch/post-init.sh is deprecated: running ~/DOTS/bootstrap.sh"
exec bash "$HOME/DOTS/bootstrap.sh" "$@"
