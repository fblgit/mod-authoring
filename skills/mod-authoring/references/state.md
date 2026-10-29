# State

| Where | Lasts until | Use for |
| :- | :- | :- |
| module variable | module reload (every save in dev) | values you can lose |
| `$.state` | session end, or `/clear` `/resume` `/branch` | values a drawing depends on; survives reload |
| `$.store` | you delete it, or `cleanupPeriodDays` of no use | settings, history; shared by every session on the machine |

## `$.state` setup

1. Declare in `types/index.d.ts`:

```ts
declare module 'claude-code' {
  interface PluginState {
    'my-mod': { count: number; items: string[] }
  }
}
```

2. Manifest: `"types": "./types/index.d.ts"`.
3. Module:

```ts
import { atom, read, update } from 'claude-code'
const count = atom({ plugin: 'my-mod', key: 'count' } as const, 0)
// draw:  const n = await read($, count)
// write: onPress: () => update($, count, v => v + 1)
```

Rules: `const` atom; literal `plugin` and `key`; every key declared; `ui.render` reads only. A read while drawing subscribes the site, so a write redraws it with no invalidate. `derive` and `memberOf` also come from `claude-code`.

## Shape tag

An old value outlives a reload. Declare the key as `Shaped<T>` and pass `{ shape: 'calls-1' }` to `atom`; a value stored under another tag reads as the initial value. Change the tag when the fields change.

## Resets

`/clear`, `/resume`, `/branch` reset `$.state` to defaults and `session.start` does not fire again. Copy saved values back:

```ts
on('classic.SessionStart', { source: ['clear', 'resume', 'fork'] }, async ($, e, next) => {
  await loadSaved($)   // top-level function above register
  return next(e)
})
```

Also load in `session.start`, because a reload reruns it.

## `$.store`

- JSON file under `~/.claude/plugins/store/`, 4 MiB total.
- `get` then `set` is not atomic across sessions. Use one key per item, or reread right before writing.
- Save on every change so the store never lags `$.state`.
