# Examples

Each folder is a complete loadable mod.

| Example | Shows | Check |
| :- | :- | :- |
| minimal/ | manifest, hooks.json, a /minimal command | validate |
| guard/ | tool.call guard with `.catch` that fails closed | validate |
| test/ | a /greet command plus its test, `hooks/register.example.ts` (copy it as `register.test.ts` in your own mod; it is not named `*.test.ts` here so a host repo's `claude plugin test` does not run it) | validate, `claude plugin test` |
| band/ | AbovePrompt band with a Hide button | validate |
| state/ | `$.state` counter pane, reload on `/clear` | validate |

Run one: `claude --plugin-dir ./minimal`.
Check one: `claude plugin validate ./minimal`.
