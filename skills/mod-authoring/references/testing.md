# Testing

Run: `claude plugin test [dir]`. Files end in `.test.ts` or `.test.tsx`. Exit 1 on failure. Default timeout 5 seconds per test (`timeoutMs` to change).

```ts
import { expect, mock, test, tier } from 'claude-code/testing'
test('name', async ($, on) => { /* $ acts as Claude Code; on registers stubs */ })
```

## Rules

| Rule | Why |
| :- | :- |
| register every stub before the first `$` call | else `on(...) after the test first called $` |
| `session.start` does not run by itself | fire `$.session.start({surface,isInteractive,cwd})` and stub `session.start` and `command.register` |
| a `ui.render` hook that returns `next(e)` needs a `ui.render` stub | else `no implementation for ui.render` |
| `turn.step` stub is an async generator | read the stream to its end |
| API-call stubs return `{ value }`; event stubs return the event result | bare value fails: `returned neither { value } nor { deny }` |
| a stub that throws is skipped; `() => ({deny:'x'})` makes the call reject | |
| each test starts with `$.state` at defaults (like after `/clear`) | |

## Stub cheatsheet

| Call or event | Stub |
| :- | :- |
| `command.register` `ui.toast` `ui.log` `ui.status` `ui.close` `store.set` | `() => ({ value: undefined })` |
| `store.get` | `($, e) => ({ value: saved.get(e.key) })` |
| `ui.open` | `() => ({ value: { isPlaced: true } })` |
| `agent.list` | `() => ({ value: [] })` |
| `model.complete` | `() => ({ value: { isAnswered: true, text, usage } })` |
| `process.run` | `($, e) => ({ value: { exitCode: 0, stdout: '', stderr: '' } })` |
| `tool.call` | `() => ({ result: 'ok' })` |
| `session.start` | `() => ({ cwd: '/work' })` |
| `ui.render` | `() => ({ type: 'Text', props: {}, children: ['x'] })` |

Ready-made: `mock.clock(on)` (`advance`, `set`, `settle`, `sleep`), `mock.store(on, init)`, `mock.env(on, vars)`, `mock.session(on)`.

## Drawing

```ts
const ui = await $.ui.mount({ plugin, component: 'Pane', requestId, surface, viewport, props })
await ui.press({ key }); await ui.input({ key, text }); await ui.select({ key, value })
await ui.find({ type: 'Text', text: /re/ }); await ui.unmount()
```

Loop `for (const surface of ['terminal','desktop'] as const)`. Props for Pane: `title isFocused bodyColumns placement scroll{offset,bodyRows} view`. The kit checks tree validity per surface, not paint.

## Timers, events, policy

- Timers: `const clock = mock.clock(on); await clock.advance(1000)`.
- Fire events: `$.tool.call`, `$.command.run`, `$.prompt.submit`, `$.turn.complete`, `$.classic.Stop`.
- Policy mods: `tier('prepend')` at top; `test(name, { plugins: [inlineMod] }, body)`.
- `expect` has `toBe toEqual toMatch toMatchObject toContain toBeDefined toBeUndefined toThrow` and `.not`.
