#!/usr/bin/env bash
# --
# BOOTSTRAP — the one command that brings any Arch machine up to date with the dotfiles.
# Fresh install or long-configured machine: every step checks first and skips
# what is already done, so re-running it is fast and harmless.
#
# Usage:
#   bash ~/DOTS/bootstrap.sh [--dry-run] [--no-upgrade]
#   curl -fsSL https://raw.githubusercontent.com/mattiasbonte/dots/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/mattiasbonte/dots/main/bootstrap.sh | bash -s -- --dry-run
#
# Steps: system upgrade + prerequisites (pacman -Syu, paru -Sua) → Bitwarden login/unlock (the only password step)
#        → GitHub SSH key + known_hosts → chezmoi age key → chezmoi source
#        (clone, fast-forward, or reset a clean clone that diverged after a history
#        rewrite) → chezmoi apply → remaining manual steps.
#
# --dry-run prints what would change without changing it (it still runs
# `git fetch` so the divergence check sees the real origin).
# --
set -euo pipefail

BW_SSH_ITEM="dotfiles: machine ssh key"   # attachments: id_ed25519, id_ed25519.pub
BW_AGE_ITEM="dotfiles: chezmoi age key"   # attachment:  key.txt
CHEZMOI_REPO="git@github.com:mattiasbonte/dotfiles.git"
CHEZMOI_SRC="${CHEZMOI_SRC:-$HOME/.local/share/chezmoi}"
CHEZMOI_BRANCH="main"
SSH_KEY="$HOME/.ssh/id_ed25519"
AGE_KEY="$HOME/.config/chezmoi/key.txt"
BW_SESSION_CACHE="${XDG_RUNTIME_DIR:-/tmp}/bw-session"   # shared with the chbw/chup helpers
PREREQS=(git chezmoi bitwarden-cli jq age openssh)
# github.com's published ed25519 host key fingerprint (docs.github.com, "GitHub's SSH key fingerprints")
GITHUB_ED25519_FP="SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU"

DRY_RUN=0 NO_UPGRADE=0
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1 ;;
        --no-upgrade) NO_UPGRADE=1 ;;
        -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]:-/dev/null}" 2>/dev/null || true; exit 0 ;;
        *) echo "✘ unknown argument: $arg" >&2; exit 2 ;;
    esac
done

# ── helpers ──
say()  { echo "→ $*"; }
ok()   { echo "✔ $*"; }
warn() { echo "⚠ $*" >&2; }
die()  { echo "✘ $*" >&2; exit 1; }
# run CMD…: execute, or only print it under --dry-run
run()  { if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
# In curl mode stdin is the script itself: interactive input must come from the terminal.
TTY=/dev/tty
tty_ok() { [ -r "$TTY" ] && { : <"$TTY"; } 2>/dev/null; }
# run_tty CMD…: like run, with stdin from the terminal when there is one
run_tty() { if [ "$DRY_RUN" = 1 ]; then run "$@"; elif tty_ok; then "$@" <"$TTY"; else "$@"; fi; }
pause() { tty_ok || die "no terminal to wait on — re-run interactively"; read -r -p "$1 " _ <"$TTY"; }

# ── 1. system upgrade + prerequisites ──
# A full -Syu every run (Arch has no partial upgrades); the prerequisites ride
# along in the same transaction. --no-upgrade skips it on a metered link.
install_prereqs() {
    local missing=() p
    for p in "${PREREQS[@]}"; do pacman -Qq "$p" &>/dev/null || missing+=("$p"); done
    if [ "$NO_UPGRADE" = 1 ]; then
        [ ${#missing[@]} -eq 0 ] && { ok "prerequisites installed (upgrade skipped)"; return; }
        say "installing: ${missing[*]}"
        run sudo pacman -S --needed --noconfirm "${missing[@]}"
        return
    fi
    say "system upgrade${missing[*]:+ + installing: ${missing[*]}}"
    run sudo pacman -Syu --needed --noconfirm "${missing[@]}"
    if command -v paru &>/dev/null; then
        say "AUR upgrade"
        run_tty paru -Sua --noconfirm || warn "AUR upgrade failed (non-fatal)"
    fi
}

# ── 2. Bitwarden ──
bw_unlocked() { [ -n "${BW_SESSION:-}" ] && bw status 2>/dev/null | jq -e '.status == "unlocked"' &>/dev/null; }

bw_ensure() {
    command -v bw &>/dev/null || { [ "$DRY_RUN" = 1 ] && { warn "bw not installed (dry-run): skipping Bitwarden"; return 1; }; die "bw missing after install"; }
    if [ -z "${BW_SESSION:-}" ] && [ -r "$BW_SESSION_CACHE" ]; then
        BW_SESSION="$(<"$BW_SESSION_CACHE")"; export BW_SESSION
    fi
    if bw_unlocked; then ok "Bitwarden unlocked (cached session)"; return 0; fi
    if [ "$DRY_RUN" = 1 ]; then warn "Bitwarden locked (dry-run: not prompting; Bitwarden steps are skipped)"; return 1; fi
    tty_ok || die "Bitwarden needs a terminal for the master password"
    if ! bw login --check &>/dev/null; then
        say "Bitwarden login (email, master password, 2FA)"
        bw login <"$TTY" || die "bw login failed"
    fi
    say "unlock the Bitwarden vault (master password):"
    BW_SESSION="$(bw unlock --raw <"$TTY")" || die "bw unlock failed"
    [ -n "$BW_SESSION" ] || die "bw unlock returned no session"
    export BW_SESSION
    (umask 077; printf '%s\n' "$BW_SESSION" >"$BW_SESSION_CACHE")
    ok "Bitwarden unlocked (session cached in $BW_SESSION_CACHE)"
    bw_sync_or_relogin
}

# An unused CLI login expires server-side: login --check and unlock still pass
# offline, then sync fails (invalid_grant) and bw logs itself out, which breaks
# every later bw call (chezmoi templates). Log in again once in that case.
bw_sync_or_relogin() {
    bw sync >/dev/null && return 0
    if bw status 2>/dev/null | jq -e '.status == "unauthenticated"' &>/dev/null; then
        warn "Bitwarden login expired; logging in again"
        bw login <"$TTY" >/dev/null || die "bw login failed"
        BW_SESSION="$(bw unlock --raw <"$TTY")" && [ -n "$BW_SESSION" ] || die "bw unlock failed"
        export BW_SESSION
        (umask 077; printf '%s\n' "$BW_SESSION" >"$BW_SESSION_CACHE")
        bw sync >/dev/null || warn "bw sync failed; using the local vault copy"
    else
        warn "bw sync failed; using the local vault copy"
    fi
}

# bw_item_id NAME → id of the item with exactly that name (empty if none)
bw_item_id() {
    bw list items --search "$1" 2>/dev/null | jq -r --arg n "$1" '[.[] | select(.name == $n)][0].id // empty'
}
# bw_attach ITEM_ID FILE_NAME DEST → download an attachment to DEST with mode 600
bw_attach() {
    local tmp; tmp="$(mktemp "$(dirname "$3")/.bw.XXXXXX")"
    if bw get attachment "$2" --itemid "$1" --output "$tmp" >/dev/null && [ -s "$tmp" ]; then
        chmod 600 "$tmp"; mv "$tmp" "$3"
    else
        rm -f "$tmp"; return 1
    fi
}

# ── 3. GitHub SSH key ──
# (captured, not piped: ssh exits 1 even on success and pipefail would hide the match)
github_ssh_ok() { local out; out="$(ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 || true)"; [[ $out == *"successfully authenticated"* ]]; }

known_hosts_github() {
    mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
    if ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" &>/dev/null; then ok "github.com in known_hosts"; return; fi
    say "adding github.com to known_hosts"
    local line; line="$(ssh-keyscan -t ed25519 github.com 2>/dev/null)" || die "ssh-keyscan github.com failed (network?)"
    [[ "$(ssh-keygen -lf - <<<"$line")" == *"$GITHUB_ED25519_FP"* ]] \
        || die "github.com host key fingerprint does not match $GITHUB_ED25519_FP"
    if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] append github.com ed25519 key to ~/.ssh/known_hosts"; return; fi
    printf '%s\n' "$line" >>"$HOME/.ssh/known_hosts"
}

print_ssh_item_howto() {
    cat <<EOF
  To store a dedicated machine key once (any machine with the vault unlocked):
    ssh-keygen -t ed25519 -C "dotfiles machine key" -f /tmp/dk -N ""
    # add /tmp/dk.pub at https://github.com/settings/ssh/new
    id=\$(bw get template item | jq '.type=2 | .secureNote={type:0} | .notes=null | .name="$BW_SSH_ITEM"' \\
          | bw encode | bw create item | jq -r .id)
    cp /tmp/dk id_ed25519 && cp /tmp/dk.pub id_ed25519.pub
    bw create attachment --file id_ed25519 --itemid "\$id"
    bw create attachment --file id_ed25519.pub --itemid "\$id"
    shred -u /tmp/dk id_ed25519; rm /tmp/dk.pub id_ed25519.pub
EOF
}

# Fallback: a per-host key, added with gh or pasted by hand.
ssh_key_fallback() {
    local host; host="$(cat /etc/hostname 2>/dev/null || hostname)"
    if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] ssh-keygen -t ed25519 -C $host -f $SSH_KEY, then add it to GitHub"; return; fi
    [ -f "$SSH_KEY" ] || ssh-keygen -t ed25519 -C "$host" -f "$SSH_KEY" -N "" -q
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        gh ssh-key add "$SSH_KEY.pub" --title "$host" &>/dev/null || true
    fi
    github_ssh_ok && return
    echo; say "add this key at https://github.com/settings/ssh/new  (title: $host)"; echo
    cat "$SSH_KEY.pub"; echo
    pause "Press Enter once it is added…"
}

ssh_key_ensure() {
    local id=""
    known_hosts_github
    if [ -f "$SSH_KEY" ]; then
        ok "SSH key present ($SSH_KEY)"
    elif [ "${BW_OK:-0}" = 1 ] && id="$(bw_item_id "$BW_SSH_ITEM")" && [ -n "$id" ]; then
        say "fetching the machine SSH key from Bitwarden ('$BW_SSH_ITEM')"
        if [ "$DRY_RUN" = 1 ]; then
            echo "  [dry-run] bw get attachment id_ed25519{,.pub} → ~/.ssh/"
        else
            bw_attach "$id" id_ed25519 "$SSH_KEY" || die "could not fetch attachment id_ed25519 from '$BW_SSH_ITEM'"
            bw_attach "$id" id_ed25519.pub "$SSH_KEY.pub" || ssh-keygen -y -f "$SSH_KEY" >"$SSH_KEY.pub"
            ok "SSH key installed from Bitwarden"
        fi
    else
        [ "${BW_OK:-0}" = 1 ] && { warn "Bitwarden item '$BW_SSH_ITEM' not found"; print_ssh_item_howto; }
        say "falling back to a per-host key"
        ssh_key_fallback
    fi
    [ "$DRY_RUN" = 1 ] && [ ! -f "$SSH_KEY" ] && return 0
    github_ssh_ok || die "GitHub rejects the SSH key — chezmoi cannot clone the private repo"
    ok "GitHub SSH authenticated"
}

# ── 4. age key ──
age_key_ensure() {
    if [ -f "$AGE_KEY" ]; then ok "age key present ($AGE_KEY)"; return; fi
    [ "${BW_OK:-0}" = 1 ] || { warn "age key missing and Bitwarden locked: skipped"; return; }
    local id; id="$(bw_item_id "$BW_AGE_ITEM")"
    if [ -z "$id" ]; then
        warn "Bitwarden item '$BW_AGE_ITEM' not found; continuing without an age key (encryption not live yet)"
        return
    fi
    say "fetching the chezmoi age key from Bitwarden ('$BW_AGE_ITEM')"
    run mkdir -p "$(dirname "$AGE_KEY")"
    if [ "$DRY_RUN" = 1 ]; then echo "  [dry-run] bw get attachment key.txt → $AGE_KEY"; return; fi
    bw_attach "$id" key.txt "$AGE_KEY" || die "could not fetch attachment key.txt from '$BW_AGE_ITEM'"
    ok "age key installed"
}

# ── 5. chezmoi source ──
FRESH_CLONE=0
git_src() { git -C "$CHEZMOI_SRC" "$@"; }

# Diverged clone with nothing of its own? Tree identical, every local patch
# already upstream, or every local commit has a rewritten twin upstream
# (same author, date and message — what filter-repo preserves).
diverged_but_disposable() {
    local up="$1"
    git_src diff --quiet "$up" HEAD && { echo "tree identical to $up"; return 0; }
    local cherry; cherry="$(git_src cherry "$up" HEAD)"
    ! grep -q '^+' <<<"$cherry" && { echo "every local commit's patch is already in $up"; return 0; }
    local fmt='%an%x1f%ae%x1f%at%x1f%s' upstream_ids missing
    upstream_ids="$(git_src log --format="$fmt" "$up")"
    missing="$(git_src log --format="$fmt" "$up..HEAD" | grep -vxF -f <(printf '%s\n' "$upstream_ids") || true)"
    [ -z "$missing" ] && { echo "every local commit has a rewritten twin in $up (history rewrite)"; return 0; }
    return 1
}

chezmoi_source_sync() {
    if [ ! -d "$CHEZMOI_SRC/.git" ]; then
        [ -e "$CHEZMOI_SRC" ] && die "$CHEZMOI_SRC exists but is not a git repo — move it aside"
        say "no chezmoi source yet: will clone $CHEZMOI_REPO"
        FRESH_CLONE=1; return
    fi
    local up="origin/$CHEZMOI_BRANCH" branch dirty
    branch="$(git_src symbolic-ref --short -q HEAD || true)"
    [ "$branch" = "$CHEZMOI_BRANCH" ] || die "chezmoi source is on '${branch:-detached HEAD}', expected $CHEZMOI_BRANCH"
    say "fetching chezmoi source"
    git_src fetch --prune origin || die "git fetch failed in $CHEZMOI_SRC"
    dirty="$(git_src status --porcelain --untracked-files=no)"
    if [ -n "$dirty" ]; then
        warn "chezmoi source has uncommitted changes:"; printf '%s\n' "$dirty" | head -20 >&2
        [ "$DRY_RUN" = 1 ] || die "commit, stash or discard them in $CHEZMOI_SRC, then re-run"
        warn "(dry-run: continuing the analysis anyway)"
    fi
    local head upstream; head="$(git_src rev-parse HEAD)"; upstream="$(git_src rev-parse "$up")"
    if [ "$head" = "$upstream" ]; then
        ok "chezmoi source up to date with $up"
    elif git_src merge-base --is-ancestor HEAD "$up"; then
        say "fast-forwarding chezmoi source to $up ($(git_src rev-list --count HEAD.."$up") new commits)"
        run git -C "$CHEZMOI_SRC" merge --ff-only --quiet "$up"
    elif git_src merge-base --is-ancestor "$up" HEAD; then
        warn "chezmoi source is $(git_src rev-list --count "$up"..HEAD) commit(s) ahead of $up (not pushed); leaving it"
    else
        local reason
        if reason="$(diverged_but_disposable "$up")"; then
            say "chezmoi source diverged from $up but has no local-only content ($reason)"
            say "resetting it to $up (the remote history was rewritten)"
            run git -C "$CHEZMOI_SRC" reset --hard --quiet "$up"
        else
            local fmt='%an%x1f%ae%x1f%at%x1f%s' upstream_ids own
            upstream_ids="$(git_src log --format="$fmt" "$up")"
            own="$(git_src log --reverse --format="%h %s%x1f$fmt" "$up..HEAD" \
                   | while IFS=$'\x1f' read -r line rest; do grep -qxF "$rest" <<<"$upstream_ids" || echo "$line"; done)"
            warn "chezmoi source diverged from $up and has local commits that are not upstream:"
            printf '    %s\n' "$own" >&2
            cat >&2 <<EOF
  Nothing was changed. To move them onto the new history (keeping a backup branch):
    git -C $CHEZMOI_SRC branch backup-before-bootstrap
    git -C $CHEZMOI_SRC reset --hard $up
    git -C $CHEZMOI_SRC cherry-pick $(awk '{print $1}' <<<"$own" | tr '\n' ' ')
  Then re-run this script.
EOF
            [ "$DRY_RUN" = 1 ] && return 0
            exit 1
        fi
    fi
}

# ── 6. chezmoi apply ──
chezmoi_apply() {
    if [ "$FRESH_CLONE" = 1 ]; then
        say "chezmoi init --apply"
        run_tty chezmoi init --apply "$CHEZMOI_REPO"
    else
        say "chezmoi init (regenerate config) + apply"
        run_tty chezmoi init
        run_tty chezmoi apply
    fi
    [ "$DRY_RUN" = 1 ] || ok "chezmoi applied"
}

# ── 7. what is left ──
remaining_steps() {
    local todo=()
    if command -v tailscale &>/dev/null && ! tailscale status &>/dev/null; then todo+=("sudo tailscale up"); fi
    [ -d "/usr/lib/modules/$(uname -r)" ] || todo+=("reboot (the running kernel $(uname -r) was replaced)")
    echo
    if [ ${#todo[@]} -eq 0 ]; then ok "bootstrap complete — nothing left to do"; return; fi
    echo "Remaining manual steps:"; printf '  • %s\n' "${todo[@]}"
}

main() {
    [ "$(id -u)" != 0 ] || die "run as your user, not root (sudo is used where needed)"
    command -v pacman &>/dev/null || die "this script is for Arch Linux (pacman not found)"
    [ "$DRY_RUN" = 1 ] && say "dry run: nothing will be changed"
    install_prereqs
    BW_OK=0; bw_ensure && BW_OK=1
    ssh_key_ensure
    age_key_ensure
    chezmoi_source_sync
    if [ "$BW_OK" = 1 ] || [ "$DRY_RUN" = 1 ]; then chezmoi_apply; else die "Bitwarden is required for chezmoi apply"; fi
    remaining_steps
}

main "$@"
