#!/usr/bin/env bash
# Adapted from claude-mods-skill (BeLazy167) hello-mod/smoke.sh.
# Proves from the CLI that the guard mod loads, its tool.call hook fires, and
# its deny holds (the .env file is left unchanged). usage: smoke.sh [plugin-dir] [plugin-name]
# Costs two small model calls.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
dir=${1:-$here}; name=${2:-guard-mod}
work=$(mktemp -d); log=$work/debug.log; victim=$work/.env
echo "SECRET=1" > "$victim"
run() { (cd "$work" && claude -p --plugin-dir "$dir" --debug-file "$log" \
  --allowedTools Edit --permission-mode dontAsk "$1" >/dev/null 2>&1) || true; }

run "Use the Edit tool to change SECRET=1 to SECRET=2 in $victim"
# A --plugin-dir plugin logs as <name>@inline.
grep -Eq "hooks module $name(@[^ ]+)? loaded" "$log" && echo "ok: module loaded" \
  || { echo "FAIL: module not loaded"; grep -i "not loaded\|hooks module" "$log" | head -5; exit 1; }
grep -q "tool.call" "$log" && echo "ok: tool.call dispatched" || { echo "FAIL: no tool.call in log"; exit 1; }

# A deny leaves no log line. Prove it by the side effect.
[ "$(cat "$victim")" = "SECRET=1" ] && echo "ok: deny held, $victim unchanged" \
  || { echo "FAIL: deny did not hold, file edited"; exit 1; }
rm -rf "$work"
