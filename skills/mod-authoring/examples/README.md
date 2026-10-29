# Examples

Each folder is a complete loadable mod.

| Example | Shows | Check |
| :- | :- | :- |
| minimal/ | manifest, hooks.json, a /minimal command | validate |
| guard/ | tool.call guard with `.catch` that fails closed | validate |
| test/ | a /greet command plus its test, `hooks/register.example.ts` (copy it as `register.test.ts` in your own mod; it is not named `*.test.ts` here so a host repo's `claude plugin test` does not run it) | validate, `claude plugin test` |
| band/ | AbovePrompt band with a Hide button | validate |
| state/ | `$.state` counter pane, reload on `/clear` | validate |
| redact-output/ | `tool.call` wrapper that rewrites Bash stdout (token redaction), fails closed; test in `hooks/register.example.ts` | validate, test (copy as `register.test.ts`) |
| dice-tool/ | registers a model-callable tool in `session.start` and serves it from `tool.call` (`mcp__<plugin>__<tool>`); test in `hooks/register.example.ts` | validate, test (copy as `register.test.ts`) |

guard/smoke.sh proves the deny by its side effect (an `.env` file stays unchanged). It makes two `claude -p` model calls, so run it on purpose: `bash guard/smoke.sh`.

redact-output and dice-tool are adapted from claude-mods-skill (BeLazy167).

Run one: `claude --plugin-dir ./minimal`.
Check one: `claude plugin validate ./minimal`.
