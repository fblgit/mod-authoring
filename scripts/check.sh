#!/usr/bin/env bash
# Checks every example against the installed Claude Code: validate, test, tsc.
# Run after each Claude Code update. Makes no model call. Adapted from claude-mods-skill.
# usage: scripts/check.sh   (needs claude and npx)
set -euo pipefail
cd "$(dirname "$0")/.."
echo "claude $(claude --version)"
tmp=""
trap '[ -n "$tmp" ] && rm -f "$tmp"' EXIT
for m in skills/mod-authoring/examples/*/; do
  m=${m%/}
  claude plugin validate "$m" >/dev/null 2>&1 || { echo "FAIL: validate $m"; claude plugin validate "$m"; exit 1; }
  # Examples keep the test as hooks/register.example.ts; run it as register.test.ts.
  if [ -f "$m/hooks/register.example.ts" ]; then
    tmp="$m/hooks/register.test.ts"
    cp "$m/hooks/register.example.ts" "$tmp"
    (cd "$m" && claude plugin test >/dev/null 2>&1) || { echo "FAIL: test $m"; (cd "$m" && claude plugin test); exit 1; }
    rm -f "$tmp"; tmp=""
  fi
  # Types are laid when Claude Code loads the mod; skip tsc until then.
  if [ -f "$m/.claude-plugin/types/tsconfig.json" ] || [ -f "$m/tsconfig.json" ]; then
    npx -y -p typescript@5 tsc -p "$m" --noEmit || { echo "FAIL: tsc $m"; exit 1; }
  else
    echo "skip: tsc $m (types not laid; load once with claude --plugin-dir $m)"
  fi
  echo "ok: $m"
done
