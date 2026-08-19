#!/usr/bin/zsh

# --
# POST INIT
# @note only after the init and github ssh key have been setup
# Gates verify for themselves and hard-exit when auth is broken; every
# other step is tracked and a VERIFY pass asserts outcomes at the end.
# --

FAILED=()
fail() { FAILED+=("$1"); echo "✘ FAILED: $1"; }
try()  { local l=$1; shift; "$@" || fail "$l"; }
vfile() { [ -e "$1" ] || fail "verify: missing $1"; }

# Pre Chezmoi Setup
if ! command -v gh &>/dev/null; then
    echo "Install github-cli first: 'sudo pacman -S gh'"
    exit 1
fi
if ! command -v bw &>/dev/null; then
    echo "Install bitwarden-cli first: 'sudo pacman -S bitwarden-cli'"
    exit 1
fi

# gh's device flow blocks on the browser and stores nothing if interrupted.
# What chezmoi actually needs is an SSH key on GitHub — so that's the gate;
# gh login is a nice-to-have handled afterwards.
export BROWSER="${XDG_RUNTIME_DIR:-/tmp}/quiet-browser"
printf '#!/bin/sh\nexec setsid xdg-open "$@" >/dev/null 2>&1 &\n' > "$BROWSER"
chmod +x "$BROWSER"
export GH_BROWSER="$BROWSER"

HOST=$(cat /etc/hostname)
github_ssh_ok() { ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; }

if ! github_ssh_ok; then
    [ -f "$HOME/.ssh/id_ed25519" ] || ssh-keygen -t ed25519 -C "$HOST" -f "$HOME/.ssh/id_ed25519" -N ""
    gh auth status &>/dev/null && gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "$HOST" 2>/dev/null
    if ! github_ssh_ok; then
        echo
        echo "→ Add this key at https://github.com/settings/ssh/new  (title: $HOST)"
        echo
        cat "$HOME/.ssh/id_ed25519.pub"
        echo
        gum confirm "Added it to GitHub?" || { echo "✘ chezmoi can't clone without it — re-run when added"; exit 1; }
        github_ssh_ok || { echo "✘ GitHub still rejects the key — check you pasted the whole line"; exit 1; }
    fi
fi
echo "✔ GitHub SSH authenticated"
gh auth status &>/dev/null || echo "⚠ gh CLI not logged in (optional) — run 'gh auth login' whenever you like"

bw login --check &>/dev/null || bw login
bw login --check &>/dev/null || { echo "✘ bitwarden-cli still not logged in"; exit 1; }

# One unlock per boot, shared with the chbw/chup shell helpers via the same
# cache (user-only tmpfs, gone at logout)
BW_SESSION_CACHE="${XDG_RUNTIME_DIR:-/tmp}/bw-session"
bw_session_ensure(){
    [[ -z $BW_SESSION && -r $BW_SESSION_CACHE ]] && export BW_SESSION="$(<$BW_SESSION_CACHE)"
    [[ -n $BW_SESSION ]] && bw status 2>/dev/null | grep -q '"status":"unlocked"' && return 0
    export BW_SESSION="$(bw unlock --raw)"
    [[ -n $BW_SESSION ]] || return 1
    (umask 077; print -r -- "$BW_SESSION" > "$BW_SESSION_CACHE")
}
bw_session_ensure || { echo "✘ bitwarden unlock failed — chezmoi templates need it"; exit 1; }
bw sync

# CHEZMOI — init on a fresh machine, update on every later run
if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
    echo "→ chezmoi update (pull + apply)"
    chezmoi update || { echo "✘ chezmoi update FAILED — everything below depends on it"; exit 1; }
else
    sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply git@github.com:mattiasbonte/dotfiles.git \
        || { echo "✘ chezmoi init/apply FAILED — everything below depends on it; fix and re-run"; exit 1; }
fi

# Post Chezmoi Setup
source ~/.zshrc 2>/dev/null || fail "source ~/.zshrc"
command -v node >/dev/null 2>&1 || try "nvm install node" nvm install node

# Shortcuts (register in zoxide; only dirs that exist)
if command -v zoxide >/dev/null 2>&1; then
    for d in ~/DOTS ~/MIND ~/NOTES ~/.config ~/Downloads ~/DEV/GO/breaks \
             ~/.local/share/chezmoi ~/DEV/PROFESSION/WINTRO/wintro-mono/app; do
        [ -d "$d" ] && zoxide add "$d"
    done
else
    fail "zoxide not available — shortcuts not registered"
fi

# --
# Default Applications
# --
# Set Zed as default editor for markdown and text files
try "xdg-mime markdown"   xdg-mime default dev.zed.Zed.desktop text/markdown
try "xdg-mime x-markdown" xdg-mime default dev.zed.Zed.desktop text/x-markdown
try "xdg-mime plain"      xdg-mime default dev.zed.Zed.desktop text/plain

# --
# Sytemd
# --
try "loginctl linger" loginctl enable-linger $USER

# Personal Config
try "enable wise-config.service" systemctl --user enable wise-config.service # starts with the next graphical session
# laptop-specific user units (files come from chezmoi)
case "$(cat /etc/hostname)" in wise-laptop*)
    for u in aether-break.service aether-secrets-unlock.service aether-tunnel.service \
             wintro-notes-sync.service aether-backup-daily.timer aether-laptop-sync.timer \
             chezmoi-re-add.timer laptop-heartbeat.timer; do
        [ -f "$HOME/.config/systemd/user/$u" ] && try "enable $u" systemctl --user enable "$u"
    done ;;
esac
try "enable bluetooth" sudo systemctl enable --now bluetooth.service # system service, not user
case "$(cat /etc/hostname)" in wise-laptop*) try "enable autorandr" systemctl --user enable autorandr.service ;; esac # multi-display is a laptop concern


# Redis
try "valkey enable+start" sudo systemctl enable --now valkey.service

# Spotify
[ -x "$HOME/go/bin/go-spotify-cli" ] || try "go-spotify-cli install" go install github.com/envoy49/go-spotify-cli@latest

# ── VERIFY — assert outcomes, not attempts ──
echo; echo "── verifying outcomes"
vfile "$HOME/.local/share/chezmoi/.git"
vfile "$HOME/.config/tmux/tmux.conf"
vfile "$HOME/.config/alacritty/alacritty.toml"
vfile "$HOME/.config/systemd/user/wise-config.service"
vfile "$HOME/.zen/profiles.ini"
command -v node >/dev/null 2>&1 || fail "verify: node not on PATH"
systemctl --user is-enabled wise-config.service &>/dev/null || fail "verify: wise-config.service not enabled"
systemctl is-active bluetooth.service &>/dev/null || fail "verify: bluetooth not active"
systemctl is-active valkey.service &>/dev/null || fail "verify: valkey not active"
[ -x "$HOME/go/bin/go-spotify-cli" ] || fail "verify: go-spotify-cli missing"

# SUMMARY
echo; echo
if [ ${#FAILED[@]} -gt 0 ]; then
    { echo "post-init: ${#FAILED[@]} step(s) failed ($(date -Is))"
      printf '  • %s\n' "${FAILED[@]}"
    } > "$HOME/POSTINIT-FAILURES.txt"
    gum style --border rounded --border-foreground 1 --padding "1 3" --margin "1 2" \
        "⚠  POST-INIT — ${#FAILED[@]} step(s) failed" "" \
        "$(printf '• %s\n' "${FAILED[@]}")" "" \
        "Details: ~/POSTINIT-FAILURES.txt" \
        "Re-run:  bash ~/DOTS/arch/post-init.sh" \
        "(idempotent — only redoes what failed)"
    exit 1
else
    rm -f "$HOME/POSTINIT-FAILURES.txt"
    gum style --border rounded --border-foreground 2 --padding "1 3" --margin "1 2" \
        "✅  POST-INIT COMPLETE — all steps verified" "" \
        "Next: log out → back in (keyboard config, user services start)"
fi

# Tailscale auth (last on purpose: it blocks on a browser URL — skipping
# or Ctrl+C here can no longer cost any other step)
if command -v tailscale >/dev/null && ! tailscale status >/dev/null 2>&1; then
    gum confirm "Connect Tailscale now? (prints an auth URL to open in a browser)" && sudo tailscale up || echo "later: sudo tailscale up"
fi

# Reboot
gum confirm --default=false "Reboot now?" && { echo "Rebooting system..."; reboot; } || echo "Reboot skipped. You can reboot manually later."
