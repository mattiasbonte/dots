#!/usr/bin/env bash
# Zen spaces + pinned tabs live in places.sqlite (26 MB of history — not
# trackable). This exports just the structural rows to a small JSON file that
# chezmoi tracks, and imports them on another machine.
#
#   zen-config.sh export   # on the machine that owns the config
#   zen-config.sh import   # on a new machine, with Zen closed
set -euo pipefail

OUT="$HOME/.config/zen/spaces.json"
PROFILE=$(awk -F= '/^Path=/{p=$2} /^Default=1/{d=1} END{print p}' "$HOME/.zen/profiles.ini" 2>/dev/null)
# profiles.ini lists the tracked profile under Install<hash>.Default — prefer it
INSTALL_DEFAULT=$(awk -F= '/^\[Install/{i=1} i&&/^Default=/{print $2; exit}' "$HOME/.zen/profiles.ini" 2>/dev/null)
[ -n "$INSTALL_DEFAULT" ] && PROFILE="$INSTALL_DEFAULT"
DB="$HOME/.zen/$PROFILE/places.sqlite"
[ -f "$DB" ] || { echo "✘ no places.sqlite at $DB"; exit 1; }

case "${1:-export}" in
export)
    mkdir -p "$(dirname "$OUT")"
    TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
    cp "$DB" "$TMP"   # the live DB is locked while Zen runs
    sqlite3 "$TMP" <<'SQL' | python3 -c "import sys,json; print(json.dumps(json.loads(sys.stdin.read()), indent=2))" > "$OUT"
.mode json
SELECT json_object(
  'workspaces', (SELECT json_group_array(json_object(
      'uuid',uuid,'name',name,'icon',icon,'container_id',container_id,'position',position,
      'theme_type',theme_type,'theme_colors',theme_colors,'theme_opacity',theme_opacity,
      'theme_rotation',theme_rotation,'theme_texture',theme_texture))
    FROM (SELECT * FROM zen_workspaces ORDER BY position)),
  'pins', (SELECT json_group_array(json_object(
      'uuid',uuid,'title',title,'url',url,'container_id',container_id,'workspace_uuid',workspace_uuid,
      'position',position,'is_essential',is_essential,'is_group',is_group,'parent_uuid',parent_uuid,
      'edited_title',edited_title,'is_folder_collapsed',is_folder_collapsed,
      'folder_icon',folder_icon,'folder_parent_uuid',folder_parent_uuid))
    FROM (SELECT * FROM zen_pins ORDER BY workspace_uuid, position))
) AS x;
SQL
    python3 - "$OUT" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
# sqlite .mode json wraps the row; unwrap to the object itself
if isinstance(d,list) and len(d)==1 and 'x' in d[0]:
    d=json.loads(d[0]['x'])
    json.dump(d,open(sys.argv[1],'w'),indent=2)
print(f"✔ exported {len(d['workspaces'])} spaces, {len(d['pins'])} pins → {sys.argv[1]}")
PY
    ;;
import)
    [ -f "$OUT" ] || { echo "✘ nothing to import: $OUT missing"; exit 1; }
    pgrep -x zen >/dev/null && { echo "✘ close Zen first (it holds places.sqlite open)"; exit 1; }
    cp "$DB" "$DB.bak-$(date +%Y%m%d%H%M%S)"
    python3 - "$OUT" "$DB" <<'PY'
import json,sqlite3,sys,time
data=json.load(open(sys.argv[1])); con=sqlite3.connect(sys.argv[2]); now=int(time.time()*1000)
w=[(x['uuid'],x['name'],x['icon'],x['container_id'],x['position'],now,now,
    x['theme_type'],x['theme_colors'],x['theme_opacity'],x['theme_rotation'],x['theme_texture'])
   for x in data['workspaces']]
con.executemany("""INSERT INTO zen_workspaces
 (uuid,name,icon,container_id,position,created_at,updated_at,theme_type,theme_colors,theme_opacity,theme_rotation,theme_texture)
 VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
 ON CONFLICT(uuid) DO UPDATE SET name=excluded.name,icon=excluded.icon,position=excluded.position,
 updated_at=excluded.updated_at,theme_type=excluded.theme_type,theme_colors=excluded.theme_colors,
 theme_opacity=excluded.theme_opacity,theme_rotation=excluded.theme_rotation,theme_texture=excluded.theme_texture""", w)
p=[(x['uuid'],x['title'],x['url'],x['container_id'],x['workspace_uuid'],x['position'],x['is_essential'],
    x['is_group'],x['parent_uuid'],now,now,x['edited_title'],x['is_folder_collapsed'],x['folder_icon'],x['folder_parent_uuid'])
   for x in data['pins']]
con.executemany("""INSERT INTO zen_pins
 (uuid,title,url,container_id,workspace_uuid,position,is_essential,is_group,parent_uuid,created_at,updated_at,
  edited_title,is_folder_collapsed,folder_icon,folder_parent_uuid)
 VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
 ON CONFLICT(uuid) DO UPDATE SET title=excluded.title,url=excluded.url,workspace_uuid=excluded.workspace_uuid,
 position=excluded.position,is_essential=excluded.is_essential,is_group=excluded.is_group,
 parent_uuid=excluded.parent_uuid,updated_at=excluded.updated_at""", p)
con.commit()
print(f"✔ imported {len(w)} spaces, {len(p)} pins")
PY
    ;;
*) echo "usage: zen-config.sh [export|import]"; exit 1 ;;
esac
