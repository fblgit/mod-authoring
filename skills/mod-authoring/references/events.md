# Events

Hooks form a middleware chain; the first mod is outermost. A hook that fails before `next` is skipped. After `next` resolved, its result stands.

## What a hook returns

| Intent | Code |
| :- | :- |
| observe | `return next(e)` |
| rewrite | `return next({ ...e, text: e.text.trim() })` |
| answer | `return { deny: 'why' }`, `{ result }` or `{ text }` |

## Matchers

Second argument of `on`. Each field is a string, an array or a RegExp.

- `{ tool: 'Bash' }`, `{ tool: ['Edit','Write'] }`, `{ tool: /^mcp__x__/ }`
- `{ component: 'Pane', requestId: 'id' }`
- `{ command: 'name' }`
- wildcards: `'classic.*'`, `'*'`

## Inventory

| Group | Events |
| :- | :- |
| tools | `tool.call`, `tool.check`, `tool.describe` |
| prompts | `prompt.submit`, `prompt.fill`, `prompt.suggest`, `prompt.edit`, `prompt.autocomplete`, `prompt.compose`, `prompt.section`, `prompt.context`, `prompt.attachment`, `prompt.mention`, `skill.prompt`, `attribution.text` |
| commands | `command.run`, `command.describe`, `config.set`, `config.describe`, `settings.read` |
| turns | `turn.start`, `turn.step` (async generator), `turn.complete` |
| session | `session.start`, `session.end`, `session.compact`, `session.receive`, `session.send`, `session.append`, `session.attach`, `session.detach`, `session.measure` |
| subagents | `agent.offer`, `agent.spawn` |
| interface | `ui.render`, `ui.resolve`, `ui.press`, `ui.input`, `ui.select`, `ui.focus`, `ui.scroll`, `ui.close`, `ui.message`, `ui.fault` |
| mods | `plugin.register`, `engine.create` |
| settings hooks | `classic.<Event>` such as `classic.Stop`, `classic.SessionStart`, `classic.SubagentStop` |
| any `$` call | named without `$.`, such as `fs.read`, `ui.open` |

## Key results

| Event | Return |
| :- | :- |
| `tool.call` | `next(e)`, `{deny}`, `{result}` |
| `tool.check` | `{decision:'allow'|'ask'|'deny', reason?}` |
| `prompt.submit` | `next({...e,text})`, `next({...e,context})`, `{drop}` |
| `command.run` | `{text}`, `{}` (prints nothing), `next(e)` |
| `turn.complete` | `{text}` adds a line under the answer |

## Failure handling

```ts
on('tool.call', { tool: 'Bash' }, guard).catch(async ($, e, next) => {
  if (next.called) return next(e)
  return { deny: 'guard failed: ' + next.error.kind }
})
```

At `tool.check` and `plugin.register` a refusal after `next` still holds. Handler limit is 1 second.

## Order

1. managed settings `PreToolUse` hooks
2. built-in guard and `prependPlugins`
3. mods the user installed
4. `appendPlugins`
5. other built-ins
6. settings-file `PreToolUse` hooks, then the engine
