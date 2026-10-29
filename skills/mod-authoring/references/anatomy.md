# Anatomy

## Files

| File | Required | Content |
| :- | :-: | :- |
| `.claude-plugin/plugin.json` | yes | `name` (lowercase, digits, hyphens, max 64), `version`, `description`, `author`, optional `types`, `userConfig`, `dependencies` |
| `hooks/hooks.json` | yes | `{"modules":["./register.tsx"]}`, one path relative to the file |
| hooks module | yes | exports `register(on, options)`; extensions `.js .mjs .cjs .jsx .ts .mts .cts .tsx` |
| `types/index.d.ts` | if `$.state` | declares `PluginState`; manifest `"types"` points at it |
| `*.test.ts(x)` | no | run by `claude plugin test` |
| `.claude-plugin/types/` | generated | the engine writes the API typings here |

## Static-analysis rules

| Rule | Error text |
| :- | :- |
| `$` is never a value | `$.ui is used as a value` |
| event name is a literal | `not a string literal` |
| do not shadow `on` | `"on" is declared again` |
| no `import()` or `require` | `a dynamic import()` |
| atom is a `const` with literal plugin/key | `takes a source the scan can read` |
| every state key declared in types | `is not declared` |
| scopes nest at most 2000 | `code nested too deep to scan` |
| same event twice without matcher | `registered twice without a matcher` |

`validate` prints `hooks:`, `calls:`, `env reads/writes:`, `state reads/writes:` and `gating hook with/without .catch`.

## Loading

| How | Notes |
| :- | :- |
| `claude --plugin-dir ./mod` | one session, hot reload, id `name@inline` |
| `CLAUDE_CODE_PLUGIN_DIRS` | absolute paths separated by `:` |
| marketplace install | cached by version; bump the version to see edits |
| `/reload-plugins` | recovers after a failed reload |
