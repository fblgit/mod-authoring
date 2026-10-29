# Troubleshooting

Version tags mark the build a row was last seen on; the types file wins. Added rows adapted from claude-mods-skill gotchas.md and anthropics/claude-code#91870.

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
| no mod loads at all (older than 2.1.287, `--safe-mode`, `--bare`, `disableAllHooks`, untrusted workspace, managed settings) | any of those | `claude --version`; check each; `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS` is ignored from 2.1.287 |
| `claude plugin test`: `the rollout switch served off` (2.1.287) | reported on an LLM gateway with no Anthropic account (#91870) | nothing to fix in the mod |
| `name: Plugin name "claude-x" is reserved` (2.1.290) | names starting `claude-`, `anthropic-` or `cc-plugin-` pass as Anthropic's | name it for what it does; 2.1.312 also rejects `anthropics-`, `claude`, `anthropic`, `claude-code`, `claude-mods`, `official` beside claude/anthropic |
| `$.ui is used as a value` | `$` or a noun assigned, destructured or computed-indexed | write `$.noun.verb(...)` at each call site |
| `$ is passed to "f", which is not a function declared at the top` (2.1.290) | `$` passed to a function declared inside `register` or another function (an import from the mod's own files is accepted; checked on 2.1.312) | move the helper to the top level of the file, or import it from a file of the mod |
| `on("tool.call") is registered twice` (2.1.290) | two plain hooks on one event in one module | merge them, or give each its own matcher |
| module refused at load | import of `fs`, `path`, npm, `require`, or dynamic `import()` | only relative plugin files and `claude-code`, by `import` declaration |
| module file not loaded | suffix not one of `.ts .tsx .js .jsx .mjs .cjs .mts .cts` | rename |
| guard threw, tool ran anyway | failed hook is skipped: guards fail open | `.catch(($, e, next) => next.called ? next(e) : { deny: 'why' })`; validate lists `gating hook without .catch` |
| tool ran, model told it was refused | `deny` returned after `next(e)` | deny before `next` |
| hook returns `{}` or `undefined` | wrong shape, hook skipped, tool runs | return `next(e)` or a full result |
| rewritten result ignored | returned `{ ...r, text }` from `next` | `text` and `ref` are set by core; answer `{ result: newResult }` |
| hook skipped after about 10 s | hook budget; waits on `next` or `$` do not count, `$.clock.sleep` does | long work in `session.start` plus `$.clock`; read `next.budget.remainingMs`; `.catch` still runs on overrun (1 s grace) |
| `$.state.set` denied | written while drawing | write from a handler, `update($, atom, fn)`, or another event |
| `agent.spawn` does not fire for a named teammate (2.1.287) | reported in #91870 | track its loop by `agentId` on `tool.call` and `turn.complete` |
| `turn.start` has no `agentId` (2.1.289) | not carried there yet | use `turn.step` or `turn.complete` |
| deny guard on paths bypassed | `..`, symlinks, other spellings | allow-list on `(await $.fs.stat(path, { resolve: true })).realPath` |
| subagent in a worktree ran in the main tree (before 2.1.288) | a `tool.call` hook broke worktree isolation | fixed in 2.1.288; update |
| `Box is not defined` | elements are not globals | `const { Box, Text } = $.ui.resolve(e)` in the hook; `h` is global |
| element missing on one surface | `mobile` has no `Input`, `vscode` no `Client`, only `terminal` has `Raster` and `Image` | narrow on `e.surface`; test on `terminal` and `desktop` |
| band or pane overflows | sized to `e.viewport.columns` | size to `e.props.bodyColumns` |
| `Text key="..."` not found in a test (2.1.290) | `Text` takes no `key`; it is dropped | `ui.find({ type: 'Text', text: /.../ })`; keys go on `Box`, `Button`, `Input` |
| client module not found | path was an expression | `Client({ module: './board.js' })` with a string literal |
| test: `no implementation for session.start` | nothing sits beneath the plugin in a test | answer it: `on('session.start', ($, e) => ({ cwd: e.cwd }))`; same for `command.register`, `ui.open`, `process.run` |
| `$.store` undefined in a test (2.1.290) | test `$` has no `store` noun | `mock.store(on, {})`, or answer `store.get`/`store.set` with your own `Map` |
| `tsc` rejects a mount target | `props` must be the site's full props | copy the `BAND` or `PANE` constant from the examples |
| `Plugin "x" not found in marketplace "repo-name"` | marketplace name is the `name` in marketplace.json | use that name after `@` |
| users do not get the update | installed plugins are cached by `version` | bump `version` each release; develop with `--plugin-dir` |
| types stale after an update | types are rewritten on each load | load the mod once; never commit `.claude-plugin/types/`; commit root `tsconfig.json` |

## Check whether mods can load

Run `claude plugin test` in a directory with no mod: `no hooks module to load` = mods can load; `hooks modules are turned off here` = `disableAllHooks` or policy.

## Refusal messages (`hooks module X not loaded:`)

`disableAllHooks in managed settings`, `only managed plugins and built-in plugins run`, `… (--bare)`, `another plugin of that name loads first`, rollout switch served off.
