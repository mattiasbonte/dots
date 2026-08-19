#!/usr/bin/env bash
# git-crypt keys for the whole-repo-encrypted repos (aether, belt), via
# Bitwarden — the same trust root chezmoi already uses.
#
#   gitcrypt-keys.sh push   # once, from a machine with unlocked clones
#   gitcrypt-keys.sh pull   # on any new machine (post-init does this for you)
#
# Keys land in ~/.config/git-crypt (0600, chezmoi-ignored — never committed).
set -euo pipefail

ITEM_NAME="git-crypt keys"
REPOS=(aether belt)
OUT="$HOME/.config/git-crypt"

command -v bw >/dev/null || { echo "✘ bitwarden-cli not installed"; exit 1; }
command -v jq >/dev/null || { echo "✘ jq not installed"; exit 1; }
[ -n "${BW_SESSION:-}" ] || { echo "✘ vault locked — run 'chbw' first (or let post-init unlock it)"; exit 1; }

item_id() { bw list items --search "$ITEM_NAME" 2>/dev/null | jq -r --arg n "$ITEM_NAME" '.[]|select(.name==$n)|.id' | head -1; }

case "${1:-pull}" in
pull)
    mkdir -p "$OUT"; chmod 700 "$OUT"
    bw sync >/dev/null 2>&1 || true   # the item may have been pushed seconds ago elsewhere
    id=$(item_id)
    [ -n "$id" ] || { echo "✘ no Bitwarden item named '$ITEM_NAME' — run this with 'push' on the laptop first"; exit 1; }
    for repo in "${REPOS[@]}"; do
        dest="$OUT/$repo.gckey"
        [ -s "$dest" ] && { echo "✔ $repo.gckey already present"; continue; }
        aid=$(bw get item "$id" | jq -r --arg f "$repo.gckey" '.attachments[]?|select(.fileName==$f)|.id')
        [ -n "$aid" ] || { echo "⚠ no attachment '$repo.gckey' on '$ITEM_NAME'"; continue; }
        bw get attachment "$aid" --itemid "$id" --output "$dest" >/dev/null
        chmod 600 "$dest"; echo "✔ fetched $repo.gckey"
    done
    ;;
push)
    mkdir -p "$OUT"; chmod 700 "$OUT"
    id=$(item_id)
    if [ -z "$id" ]; then
        echo "→ creating Bitwarden item '$ITEM_NAME'"
        id=$(bw get template item \
            | jq --arg n "$ITEM_NAME" '.type=2 | .name=$n | .notes="git-crypt export-keys for aether + belt. Restores a machine: gitcrypt-keys.sh pull" | .secureNote={type:0} | .login=null' \
            | bw encode | bw create item | jq -r '.id')
    fi
    for repo in "${REPOS[@]}"; do
        dir="$HOME/DEV/GO/$repo"
        [ -d "$dir/.git" ] || { echo "skip $repo (no clone)"; continue; }
        head -c 10 "$dir/Makefile" 2>/dev/null | grep -q GITCRYPT && { echo "skip $repo (clone is locked here)"; continue; }
        f="$OUT/$repo.gckey"
        git -C "$dir" crypt export-key "$f"; chmod 600 "$f"
        # replace any previous attachment of the same name
        old=$(bw get item "$id" | jq -r --arg f "$repo.gckey" '.attachments[]?|select(.fileName==$f)|.id')
        [ -n "$old" ] && bw delete attachment "$old" --itemid "$id" >/dev/null 2>&1 || true
        bw create attachment --file "$f" --itemid "$id" >/dev/null
        echo "✔ stored $repo.gckey in Bitwarden"
    done
    bw sync >/dev/null 2>&1 || true
    ;;
*) echo "usage: gitcrypt-keys.sh [pull|push]"; exit 1 ;;
esac
