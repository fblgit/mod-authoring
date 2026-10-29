---
name: mod-authoring
description: Build, change, debug, test or audit a Claude Code mod (a plugin whose hooks module runs inside Claude Code: panes, bands, toasts, commands, tool-call guards). Thin index plus rules; details in references/ and examples/.
---

# Claude mods

A mod is a plugin with `hooks/hooks.json` `{"modules":["./register.tsx"]}` and a module exporting `register(on, options)`. No build step, no Node, no DOM. Needs Claude Code 2.1.287+ (desktop Code tab 2.1.286+, VS Code extension 2.1.299+).

Authority: `.claude-plugin/types/claude-code/index.d.ts` (this build) over the public docs over these notes.

## Read only what you need

| Need | File |
| :- | :- |
| files, manifest, static-analysis rules | references/anatomy.md |
| events, `next`, matchers, `.catch` | references/events.md |
| `$` API: commands, tools, timers, sessions | references/api.md |
| panes, elements, keys, redraw, surfaces | references/ui.md |
| `$.state` vs `$.store` | references/state.md |
| `claude plugin test` | references/testing.md |
| symptom to cause | references/troubleshooting.md |
| limits and version gates | references/limits.md |
| subagent and swarm panes | references/subagents.md |
| Raster, Image, Client, Svg, control events, dialogs | references/ui-deep.md |
| userConfig, settings.read, `$` namespaces, sharing | references/config-share.md |
| trust, guard, managed settings, policy mods | references/security-admin.md |
| audit an existing mod | references/audit-checklist.md |

Copyable code: examples/README.md.

## Rules

1. Write calls in full as `$.ns.method()`. Never alias or destructure `$` or `$.ui`.
2. Pass `$` only to top-level functions in the same file.
3. Event names are string literals. Register each event once per matcher.
4. Static `import` only; the one bare import is `claude-code`.
5. `next(e)` observes, `next({...e, x})` rewrites, returning an object answers. `e` is frozen.
6. Guard hooks end in `.catch(...)` or they fail open.
7. Module variables reset on reload. Drawn values go in `$.state`; cross-session values in `$.store`.
8. `ui.render` reads state and never writes it.
9. Give every Input, Select and list Button a unique string `key`.
10. `focus`, `closeOnEscape`, `holdToasts`, `autoFocus` accept only `true`. Omit them, never pass `false`.
11. Size to `e.props.bodyColumns`, not `e.viewport.rows`.
12. `$.ui.open` from a timer may not be placed on a narrow terminal. Open from a command and check `isPlaced`.
13. `/clear`, `/resume`, `/branch` reset `$.state` without refiring `session.start`. Reload in `classic.SessionStart`.
14. `$.command.register` throws on a taken name and aborts the hook. Register last.

## Loop

1. `claude plugin validate <dir>`
2. `claude --debug-file f.log --plugin-dir <dir>` (hot reloads on save)
3. `claude plugin test <dir>`
