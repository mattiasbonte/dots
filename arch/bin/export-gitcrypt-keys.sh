#!/usr/bin/env bash
# Export the git-crypt keys for the whole-repo-encrypted repos so a second
# machine can unlock its clones. Run on a machine whose clones are unlocked.
# The keys are secrets: never commit them (~/.config/git-crypt is chezmoi-ignored).
set -euo pipefail

OUT="$HOME/.config/git-crypt"
mkdir -p "$OUT"; chmod 700 "$OUT"

for repo in aether belt; do
    dir="$HOME/DEV/GO/$repo"
    [ -d "$dir/.git" ] || { echo "skip $repo (no clone)"; continue; }
    git -C "$dir" crypt export-key "$OUT/$repo.gckey"
    chmod 600 "$OUT/$repo.gckey"
    echo "✔ $OUT/$repo.gckey"
done

cat <<TXT

Copy to the other machine (over your own network / Tailscale, not a public path):
  rsync -av --chmod=600 "$OUT/" wise@<other-host>:~/.config/git-crypt/

Then there:  bash ~/DOTS/arch/post-init.sh    # unlocks + builds aether/belt
TXT
