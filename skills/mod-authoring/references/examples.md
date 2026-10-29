# Mods to read

Start with `../examples/` (see its README): each passes `claude plugin validate`. Then read the closest public mod below before a larger build. Public mods track their own Claude Code version: check their README before you copy an API. Adapted from claude-mods-skill `references/examples.md`; links as given there, not re-checked (not measured).

## This repo

| Example | Pattern |
| :- | :- |
| `examples/guard` | `tool.call` guard, fail-closed `.catch` |
| `examples/redact-output` | rewrite a tool's result after `next`; `.catch` that refuses |
| `examples/band` | band above the prompt |
| `examples/state` | `$.state` counter pane |
| `examples/test` | slash command plus its test |
| `examples/dice-tool` | a tool the model calls, served by a `tool.call` hook |

## Anthropic

| Mod | Pattern | Source |
| :- | :- | :- |
| diff | pane beside the transcript, Buttons bound to keybinding actions, own scrolling, tests | github.com/anthropics/claude-code/tree/main/mods/diff |
| agents-md | `userConfig` option with a picker, `prompt.context`, `session.compact` | github.com/anthropics/claude-code/tree/main/mods/agents-md |
| sec-default | policy guard protecting managed settings from other plugins | github.com/anthropics/claude-code/tree/main/mods/sec-default |
| telemetry | `engine.create` adds a noun to `$`; ships its types contract | github.com/anthropics/claude-code/tree/main/mods/telemetry |
| token-weather | context-window chart in the band above the prompt | github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/token-weather |
| blast-radius | holds a risky shell command, asks with proceed and cancel Buttons | github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/blast-radius |
| replay-theater | `/replay` steps through the last turn's file edits | github.com/anthropics/claude-code-playground/tree/main/claude-code/mods/replay-theater |

## Community

| Mod | Pattern | Source |
| :- | :- | :- |
| secret-redactor | placeholders for secrets before the model reads them, restored on the next call | github.com/ray-amjad/awesome-claude-code-function-hooks/tree/main/plugins/secret-redactor |
| cc-pr-tracker | lines above the prompt from `$.process.run` on `gh`, `$.clock.every`, toasts | github.com/sezaakgun/cc-pr-tracker |
| cc-arcade | interactive `Client` surface modules, `ui.press`, `$.store` | github.com/sezaakgun/cc-arcade |
| gh-ci-status, time | pinned status line; a render per message | github.com/diegorv/claude-functions-hook |
| launch-codes | confirmation code before risky Bash commands, tests, types contract | github.com/OneWave-AI/claude-code-mods/tree/main/launch-codes |
| human-in-the-loop | model-called tools that wait in a pane for the person | github.com/tzafrir/human-in-the-loop |
| flightdeck | observe-only dashboard pane: every hook passes its event on | github.com/scasella/claude-flightdeck |
| aside | side chat over a tool-less fork of the transcript (`$.model.fork`) | github.com/JayDoubleu/aside |
| claude-mermaid | rewrites assistant rows: mermaid fences drawn as box art | github.com/galElmalah/claude-mermaid |
| terminal-browser | a browser in a pane beside the conversation | github.com/zenbu-labs/terminal-browser |

## Find more

- Docs: code.claude.com/docs/en/plugins/mods/overview, then `create`, `events`, `interface`, `api`, `test`, `troubleshoot`, `reference`.
- Catalogue with a validator scan of each mod's reach: github.com/karanb192/awesome-claude-code-mods (browse at mods.aidojo.si).
- Design thread and bug reports: github.com/anthropics/claude-code/issues/91870.
