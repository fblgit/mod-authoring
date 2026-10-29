# Audit checklist for an existing mod

Set `D=<mod dir>`. Run `claude plugin validate $D --strict` and `claude plugin test $D` first; each item below says what else to check.

## Static rules (validate errors)

- [ ] `$` never used as a value (`const u = $.ui`). Verify: `grep -nE '=\s*\$\.[a-z]+\s*[;,)]|\(\$\)\s*=>' $D/hooks/*.ts*`; validate error `is used as a value`.
- [ ] Event names are string literals. Verify: validate `not a string literal`.
- [ ] No local named `on`. Verify: `grep -n 'const on\b\|function on\b' $D/hooks/*`.
- [ ] No `import()` or `require`. Verify: `grep -nE 'import\(|require\(' $D/hooks/*`.
- [ ] Atoms are `const` with literal `plugin` and `key`. Verify: `grep -n 'atom(' $D/hooks/*`; error `takes a source the scan can read`.
- [ ] Same event never registered twice without a matcher. Verify: error `registered twice without a matcher`.
- [ ] `telemetry.log` / `telemetry.mark` hooks carry `{ to: 'collector' }`. Verify: `grep -n 'telemetry\.' $D/hooks/*`.

## Layout

- [ ] `hooks/hooks.json` has `"modules":["./register.tsx"]` (one path). Verify: validate prints a `hooks:` line.
- [ ] `plugin.json` has `name` (lowercase, hyphens, max 64) and `version`; bump the version after edits (marketplace installs are cached). Verify: `cat $D/.claude-plugin/plugin.json`.
- [ ] `types` points at an existing file if `$.state` is used (optional from 2.1.299). Verify: `ls $D/types`.

## State

- [ ] Every `atom` key is declared in `PluginState`. Verify: error `is not declared`.
- [ ] No state held only in module variables when a drawing depends on it (resets on every save). Verify: `grep -nE '^(let|var) ' $D/hooks/*`.
- [ ] `ui.render` only reads state (`read`), never `update`. Verify: read the render body.
- [ ] Persisted atoms have a `shape` tag, changed when fields change. Verify: `grep -n 'shape' $D/hooks/* $D/types/*`.
- [ ] `/clear` `/resume` `/branch` reload saved values in `classic.SessionStart`, also in `session.start`. Verify: `grep -n 'SessionStart' $D/hooks/*`.
- [ ] `$.store`: one key per item, saved on every change, under 4 MiB. Verify: `grep -n 'store\.' $D/hooks/*`.

## UI

- [ ] Every list child has a unique, non-empty `key`. Verify: render in a test and call `claude --debug-file`; grep `needs a key|is drawn twice`.
- [ ] Trees within limits (depth 32, 20,000 elements, 100,000 chars; see limits.md). Verify: grep log for `refused:`.
- [ ] Features newer than the supported build are gated (version table in limits.md). Verify: compare against the minimum version in the README.
- [ ] Surface-specific elements check `e.surface` (desktop and VS Code draw fewer). Verify: `grep -n 'surface' $D/hooks/*`.
- [ ] `$.ui.open` runs from a command or button, never from a timer; `focus` is omitted or `true`. Verify: `grep -n 'ui\.open' $D/hooks/*`.
- [ ] Redraws use `invalidate('ui.render')` at most 10/s (30/s visible pane). Verify: `grep -n 'invalidate' $D/hooks/*`.
- [ ] Names (command, tool, pane) match letters, digits, `_`, `-`, max 64. Verify: grep `register`/`pane:`.

## Guards and hooks

- [ ] Every gating hook (`tool.call`, `tool.check`, `prompt.submit`, `plugin.register`) has `.catch`. Verify: validate line `gating hook without .catch` must be absent.
- [ ] `.catch` finishes in 1 s and fails closed: `if (next.called) return next(e)` else `{ deny }`. Verify: read the handler.
- [ ] No hook rewrites a call's input in auto mode (blocked). Verify: grep `next({` in `tool.call` hooks.
- [ ] Hooks finish in 10 s (`prompt.edit` 50 ms); no loop that never awaits (crashes the worker). Verify: grep `while (`.
- [ ] Every hook ends with `next(e)` or a result, including paths that did not match. Verify: read each branch.
- [ ] Registered commands have a matching `command.run` hook. Verify: log `registered /x but no command.run hook answered it`.

## Security and reach

- [ ] `calls:` in validate lists only what the mod needs (see security-admin.md). Verify: `claude plugin validate $D | sed -n '/calls:/,/^$/p'`.
- [ ] `env reads/writes:` is minimal; no secrets read. Verify: validate output, `grep -n 'process.env' $D/hooks/*`.
- [ ] `process.run`, `http.fetch`, `fs.write`, `model.complete` have a documented reason. Verify: `grep -nE 'process\.run|http\.fetch|fs\.write|model\.complete' $D/hooks/*`.
- [ ] `http.fetch` URLs are fixed, not built from prompt or tool text. Verify: read call sites.
- [ ] No secrets in `plugin.json`, `userConfig` defaults, or `$.store`. Verify: `grep -rniE 'key|token|secret|password' $D`.
- [ ] Limits respected: process.run 30 s default, fetch 4 MiB, fs 4 MiB per file. Verify: grep call options.

## Lifecycle

- [ ] Agents registered in `session.start`, not at module load. Verify: `grep -n 'agent.register' $D/hooks/*`.
- [ ] Reload works: save the module in `--plugin-dir` mode; no `reload failed` line. Verify: `claude --debug-file f.log --plugin-dir $D`.
- [ ] Mod name is unique among loaded plugins (`another plugin of that name loads first`). Verify: `/plugin`.

## Tests

- [ ] `*.test.ts(x)` exists and passes. Verify: `claude plugin test $D` exits 0.
- [ ] Stubs registered before the first `$` call; API stubs return `{ value }`. Verify: errors `after the test first called $`, `returned neither { value } nor { deny }`.
- [ ] Each guard has a deny test and a failure (throw) test. Verify: `grep -c 'test(' $D/*.test.ts*`.
- [ ] Each test finishes in 5 s. Verify: the run output.

## Final commands

| Command | Pass means |
| :- | :- |
| `claude plugin validate $D --strict` | no errors or warnings; `ICON_MISSING` may fail `--strict` 🙈 (not in docs; drop `--strict` then) |
| `claude plugin validate $D --json` | machine-readable report for CI |
| `claude plugin test $D` | exit 0 |
| `claude --debug-file f.log --plugin-dir $D` then `grep <name> f.log` | no `not loaded:` or `hook skipped:` |
