# The `$` API

Every call is also an event, so another mod can observe, rewrite or refuse it.

## Namespaces

| Namespace | Methods |
| :- | :- |
| `$.plugin` | `name`, `root` |
| `$.ui` | `resolve`, `invalidate`, `open`, `close`, `panes`, `focus`, `scroll`, `toast`, `notify`, `status`, `log`, `notice`, `ask`, `copy`, `selection`, `blit` |
| `$.command` | `register`, `run`, `list` |
| `$.tool` | `register`, `call`, `check`, `list` |
| `$.agent` | `register`, `spawn`, `list` |
| `$.model` | `complete`, `fork`, `classify` |
| `$.prompt` | `submit`, `read`, `fill`, `suggest`, `compose` |
| `$.turn` | `abort` |
| `$.session` | `messages`, `cwd`, `root`, `model`, `turns`, `id`, `repo`, `surfaces`, `usage`, `version`, `compact`, `send`, `append`, `authorize` |
| `$.config` `$.settings` `$.env` | `list/set`, `read`, `get/set` |
| `$.fs` | `read`, `write`, `list`, `exists`, `stat`, `ancestors` |
| `$.store` `$.state` | `get/set/delete/keys`, `get/set` |
| `$.clock` | `now`, `sleep`, `after`, `every` |
| `$.http` `$.process` `$.mcp` | `fetch`, `run/spawn`, `call/connect` |
| `$.audio` `$.telemetry` | `play/speak`, `log/mark` |

## Common recipes

| Goal | Code |
| :- | :- |
| add a command | `await $.command.register({name, description, argumentHint?, immediate?})` in `session.start`, answer in `command.run` |
| add a tool | `$.tool.register({name, description, inputSchema, isDeferred?})`, serve with `tool.call {tool:'mcp__<plugin>__<name>'}` returning `{result}` |
| timer | `$.clock.every(ms, fn)` in `session.start`; returns `{cancel()}`; dies on reload |
| show without a turn | `$.ui.status(text)`, `$.ui.toast(text,{timeoutMs})`, `$.ui.log(text,{to:'debug'})` |
| start a turn | `$.prompt.submit({text})`; do not await it inside a busy handler |
| model call | `r = await $.model.complete({model,prompt,maxTokens}); r.isAnswered ? r.text : r.reason` |
| message a session | `$.session.send({to:{sessionId}|{agentId}, text})` resolves `{isDelivered}` |
| run a program | `$.process.run([argv])` resolves `{exitCode,stdout,stderr}`; rejects on start failure or timeout |

## Interrupts

After the user presses Esc, new work is refused until their next input. Refused calls return `{drop}`, `{deny}` or reject with the text `the session was stopped and nobody has sent input since`. Retry from a `turn.complete` hook.

## Non-interactive runs

`claude -p` and the SDK run hooks but draw nothing. A mod that submits a prompt every turn never exits without `--max-turns`.
