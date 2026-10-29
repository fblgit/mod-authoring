# Troubleshooting

First: `claude plugin validate <dir>`. Then `claude --debug-file f.log --plugin-dir <dir>` and grep for the mod name.

Where the one-line message appears: hot-reloading session = dim transcript line; other interactive sessions = debug log only; `claude -p` = stderr for load failures.

Own debug lines: `$.ui.log('msg', { to: 'debug' })`.

## Symptom to cause

| Symptom | Cause | Fix |
| :- | :- | :- |
| nothing the mod adds appears | module not loaded | check `/plugin` "mods active"; log line `not loaded:` |
| `validate` shows no `hooks:` line | `hooks.json` lacks `modules` | add `"modules":["./register.tsx"]` |
| `hook skipped: threw …` | hook threw, timed out or wrong shape | fix error; add `.catch` to guards |
| pane empty or shows engine content | tree failed validation | read `ui.render hook skipped: returned the wrong shape (a tree Pane refuses: …)` |
| `ui.render (Pane) refused:` | tree over a size limit | shrink; see limits.md |
| `needs a key` / `is drawn twice` | missing or duplicate key | unique non-empty string keys |
| `threw while drawn` | bad prop value reached the painter | fix value; engine drew its own |
| `$.ui.open` ran, no pane | not user-initiated and terminal under 144 columns | open from command/button; check `isPlaced` |
| `registered /x but no command.run hook answered it` | no hook, wrong matcher, returned `next(e)`, or hook skipped | add `command.run {command:'x'}` hook |
| `ui.open: focus is true or left out` | passed `false` | omit the field |
| hotkeys do nothing | no focus, collapsed band, or VS Code | Ctrl+X Tab to focus; VS Code has none |
| band missing | an earlier mod answered without `next` | log: `answered ui.render without next()` |
| works in terminal, not desktop/VS Code | element or site not drawn there | check `e.surface`; tables in ui.md |
| value resets on save | module variable | use `$.state` or `$.store` |
| value resets after `/clear` | `$.state` reset, `session.start` not refired | reload in `classic.SessionStart` |
| edits ignored | editing an installed copy | use `--plugin-dir` |
| `was unloaded: it crashed the hooks worker` | loop that never awaits blocks the thread | fix hook; `/reload-plugins` |
| all mods off, `crashed 3 times` | worker crashed thrice | `/reload-plugins` |
| toast missing | holdToasts pane, newer toast replaced it, over 3 in fullscreen | log lines `gave way`, `left the stack, never drawn` |
| `Stopped:` toast | mod tried to start work after Esc | retry from `turn.complete` |
| `$.agent.register refused … no longer loaded` | called from an old copy after reload | register in `session.start` |
| `another plugin of that name loads first` | duplicate plugin name | rename |
| `a hook changed this call's input after the model wrote it` (auto mode) | a hook rewrote a reviewed call | stop rewriting or leave auto mode |
| `reload failed, the previous version stays loaded` | save broke the module | fix, then `/reload-plugins` |

## Check whether mods can load

Run `claude plugin test` in a directory with no mod: `no hooks module to load` = mods can load; `hooks modules are turned off here` = `disableAllHooks` or policy.

## Refusal messages (`hooks module X not loaded:`)

`disableAllHooks in managed settings`, `only managed plugins and built-in plugins run`, `… (--bare)`, `another plugin of that name loads first`, rollout switch served off.
