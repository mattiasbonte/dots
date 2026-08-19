#!/usr/bin/env bash
# Zen config that survives a fresh install.
#
# Zen profile directories are randomly named per machine, so tracking
# ~/.zen/<random>.Default (release)/... in chezmoi only works while we also
# force profiles.ini — and breaks as soon as Zen makes its own profile.
# Instead the tracked config lives in ~/.config/zen-profile (chezmoi-managed,
# machine-neutral) and is copied INTO whichever profile is active.
#
#   zen-config.sh export   # capture this machine's config into the tracked dir
#   zen-config.sh apply    # push the tracked config into the active profile
set -euo pipefail

SRC="$HOME/.config/zen-profile"
# Files worth tracking: expensive to recreate, small, textual.
FILES=(zen-keyboard-shortcuts.json containers.json handlers.json xulstore.json zen-themes.json)
DIRS=(chrome)

active_profile() {
    local ini="$HOME/.zen/profiles.ini" p
    [ -f "$ini" ] || return 1
    # [Install<hash>] Default= wins over a [ProfileN] Default=1
    p=$(awk -F= '/^\[Install/{i=1;next} i&&/^Default=/{print $2;exit}' "$ini")
    [ -z "$p" ] && p=$(awk -F= '/^\[Profile/{d=0;path=""} /^Path=/{path=$2} /^Default=1/{d=1} d&&path{print path;exit}' "$ini")
    [ -n "$p" ] && printf '%s/.zen/%s\n' "$HOME" "$p"
}

zen_running() { pgrep -f 'zen-bin|zen-browser' >/dev/null; }

PROFILE=$(active_profile) || { echo "✘ cannot resolve the active Zen profile"; exit 1; }
[ -d "$PROFILE" ] || { echo "✘ active profile does not exist: $PROFILE"; exit 1; }

case "${1:-apply}" in
export)
    mkdir -p "$SRC"
    for f in "${FILES[@]}"; do [ -f "$PROFILE/$f" ] && cp -a "$PROFILE/$f" "$SRC/$f"; done
    for d in "${DIRS[@]}"; do [ -d "$PROFILE/$d" ] && { rm -rf "${SRC:?}/$d"; cp -a "$PROFILE/$d" "$SRC/$d"; }; done
    TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
    cp "$PROFILE/places.sqlite" "$TMP"        # live DB is locked while Zen runs
    python3 - "$TMP" "$SRC/spaces.json" <<'PY'
import json,sqlite3,sys
con=sqlite3.connect(sys.argv[1]); con.row_factory=sqlite3.Row
def rows(sql):
    try: return [dict(r) for r in con.execute(sql)]
    except sqlite3.OperationalError: return []
data={
 "workspaces": rows("SELECT uuid,name,icon,container_id,position,theme_type,theme_colors,theme_opacity,theme_rotation,theme_texture FROM zen_workspaces ORDER BY position"),
 "pins": rows("SELECT uuid,title,url,container_id,workspace_uuid,position,is_essential,is_group,parent_uuid,edited_title,is_folder_collapsed,folder_icon,folder_parent_uuid FROM zen_pins ORDER BY workspace_uuid,position"),
}
json.dump(data,open(sys.argv[2],'w'),indent=2,ensure_ascii=False)
print(f"exported {len(data['workspaces'])} spaces, {len(data['pins'])} pins")
PY
    echo "✔ tracked config written to $SRC (profile: $(basename "$PROFILE"))"
    ;;
apply)
    [ -d "$SRC" ] || { echo "✘ nothing tracked at $SRC"; exit 1; }
    zen_running && { echo "✘ close Zen first — it rewrites prefs.js and holds places.sqlite"; exit 1; }
    for f in "${FILES[@]}"; do [ -f "$SRC/$f" ] && cp -a "$SRC/$f" "$PROFILE/$f"; done
    for d in "${DIRS[@]}"; do [ -d "$SRC/$d" ] && { rm -rf "$PROFILE/${d:?}"; cp -a "$SRC/$d" "$PROFILE/$d"; }; done

    [ -f "$SRC/spaces.json" ] && python3 - "$SRC/spaces.json" "$PROFILE" <<'PY'
import json,sqlite3,sys,time,os,re,shutil
data=json.load(open(sys.argv[1])); prof=sys.argv[2]; db=os.path.join(prof,"places.sqlite")
shutil.copy2(db, db+".bak")
con=sqlite3.connect(db); now=int(time.time()*1000)
# Zen creates these tables only once its workspace UI initialises; on a fresh
# profile they may not exist yet, so create them if absent.
con.executescript("""
CREATE TABLE IF NOT EXISTS zen_workspaces (id INTEGER PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, name TEXT NOT NULL,
 icon TEXT, container_id INTEGER, position INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL,
 updated_at INTEGER NOT NULL, theme_type TEXT, theme_colors TEXT, theme_opacity REAL, theme_rotation INTEGER, theme_texture REAL);
CREATE TABLE IF NOT EXISTS zen_pins (id INTEGER PRIMARY KEY, uuid TEXT UNIQUE NOT NULL, title TEXT NOT NULL, url TEXT,
 container_id INTEGER, workspace_uuid TEXT, position INTEGER NOT NULL DEFAULT 0, is_essential BOOLEAN NOT NULL DEFAULT 0,
 is_group BOOLEAN NOT NULL DEFAULT 0, parent_uuid TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
 edited_title BOOLEAN NOT NULL DEFAULT 0, is_folder_collapsed BOOLEAN NOT NULL DEFAULT 0, folder_icon TEXT DEFAULT NULL,
 folder_parent_uuid TEXT DEFAULT NULL);
""")
def upsert(table, rows, keys):
    for r in rows:
        cols=list(r.keys())+["created_at","updated_at"]
        vals=[r[c] for c in r]+[now,now]
        sets=",".join(f"{c}=excluded.{c}" for c in keys)
        con.execute(f"INSERT INTO {table} ({','.join(cols)}) VALUES ({','.join('?'*len(cols))}) "
                    f"ON CONFLICT(uuid) DO UPDATE SET {sets},updated_at=excluded.updated_at", vals)
upsert("zen_workspaces", data["workspaces"], ["name","icon","position","theme_type","theme_colors","theme_opacity","theme_rotation","theme_texture"])
upsert("zen_pins", data["pins"], ["title","url","workspace_uuid","position","is_essential","is_group","parent_uuid"])
con.commit()

# The active-space pref points at a workspace uuid. A profile Zen created for
# itself references one that does not exist here, and Zen then shows nothing.
uuids={w["uuid"] for w in data["workspaces"]}
prefs=os.path.join(prof,"prefs.js")
if uuids and os.path.exists(prefs):
    txt=open(prefs).read()
    m=re.search(r'"zen\.workspaces\.active",\s*"([^"]*)"', txt)
    if not m or m.group(1) not in uuids:
        first=data["workspaces"][0]["uuid"]
        line=f'user_pref("zen.workspaces.active", "{first}");'
        txt=re.sub(r'user_pref\("zen\.workspaces\.active",\s*"[^"]*"\);', line, txt) if m else txt.rstrip()+"\n"+line+"\n"
        open(prefs,"w").write(txt)
        print(f"active space repaired -> {data['workspaces'][0]['name']}")
print(f"applied {len(data['workspaces'])} spaces, {len(data['pins'])} pins")
PY
    echo "✔ applied into $(basename "$PROFILE")"
    ;;
*) echo "usage: zen-config.sh [export|apply]"; exit 1 ;;
esac
