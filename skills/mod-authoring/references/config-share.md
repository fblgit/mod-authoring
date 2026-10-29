# Config, namespaces, sharing, authoring loop

## userConfig and options
| Item | Fact |
| :- | :- |
| declare | `userConfig` in `plugin.json`; each field has a `type`; field schema beyond `type`/`default`/`options`/`required`/`sensitive` is in the plugins components doc, not copied here 🙈 |
| receive | `register(on, options)`; `options` = declared fields, defaults filled in (`PluginOptions`: string, number, boolean, string[]) |
| stored | settings.json `pluginConfigs[<plugin>].options`; sensitive ones in secure storage |
| key | `<name>@<marketplace>` (e.g. `acme-guard@acme-tools`); `--plugin-dir` plugin: `<name>` or `<name>@inline` |
| validation | checked against declared `type` before load; required field with no value fails the load, naming the field |
| string with `options` | `"options": ["gist","turbo"]`, `default` among them; `/config` shows a picker; stored value outside the list = unset, default applies |
| config menu | each non-secret field is a row; a change reloads the module with new `options` |
| managed | org sets values in managed settings `pluginConfigs` (guard: `cc-plugin-sec-default@builtin`) |
| change by code | `$.config.set` takes `<plugin>.<field>` for a userConfig field (typings) |

```json
{ "pluginConfigs": { "my-mod@inline": { "options": { "mode": "turbo" } } } }
```

## settings.read
| Item | Fact |
| :- | :- |
| call | `await $.settings.read()` merged; `({ source })` one source; `({ key })` one top-level key (undefined if unset) |
| sources | `user`, `project`, `local`, `flag`, `policy`; rising precedence user to policy; no file = `{}`; `plugin` is a layer name only, not a valid `source` |
| result | plain-data snapshot each call |
| hook | `on('settings.read', ($, e, next) => ...)`; `e.layers` (`{source, settings}[]`, lowest first; empty in `claude plugin test`), `e.source` (only when a source was asked) |
| return | `next(e)` unchanged; `{ value }` replaces; `{ deny: reason }` refuses (mod call rejects `<mod>: $.settings.read: <reason>`) |
| whose read | `next.origin` is `{ plugin:'engine', tier:'core' }` for Claude Code's own merge; else the calling mod |
| gate | engine's own read and `e.layers`: v2.1.304+ |
| limits | keys that decide which plugins load are read before plugins load: your answer applies from the next load; a key read per-source (e.g. `env`) ignores a merged change |
| guard | with managed settings or Team/Enterprise login the built-in guard can skip this hook in a user's mod; check `claude --debug` |
| reads secrets | `claude plugin validate` lists `$.env.get`, `$.settings.read` under `env reads:` |

## engine.create: add a `$` namespace
| Item | Fact |
| :- | :- |
| when | once per load; fold builds `$`; at this event `$` is empty, so test `next.is("engine.create", e)` before reading `$` |
| shape | post-order: `const built = await next(e); return { ...built, voice: { say } }` |
| input | `e.plugins`: modules being built (managed first) |
| withhold | omit a noun from the result; a mod outside the `user` tier can withhold one |
| context | other mods calling your method run your `$` calls in THEIR hook's context until the event's hooks return (relative paths resolve there) |
| contract | `plugin.json` `"types": "<file>.d.ts"` exporting the noun's types at top level |
| depend | `plugin.json` `dependencies` lists plugins; each one's contract is laid in `.claude-plugin/types/` so it is typed with nothing copied |
| build | `PluginNoun` = nouns beyond the core engine; hot reload re-runs engine.create for that plugin alone |

```ts
on('engine.create', async ($, e, next) => {
  const built = await next(e)
  return { ...built, voice: { say: (t: string) => t.toUpperCase() } }
})
```

## Dev loop
| Step | Fact |
| :- | :- |
| session mods | Claude writes in `~/.claude/dev-mods/<dir>` (mods folder; per create doc); protected dir: default/acceptEdits modes ask per file |
| approve | first saved file asks to enable hot reloading for the session; a mod loads only once approved, in a trusted workspace |
| no load | nobody to approve (`claude -p`, `dontAsk`); org allowlist without `skills-dir`; see create.md "sessions that skip the approval" |
| from disk | `claude --plugin-dir <folder>` (repeatable), session only |
| env | `CLAUDE_CODE_PLUGIN_DIRS`: absolute paths (`~` ok) split by `:` (`;` Windows); from process env or `env` in `~/.claude/settings.json`, never project settings |
| watch | interactive: saving reloads hooks module, `register` reruns, timers dropped; saves during a turn reload at turn end |
| headless | `claude -p` loads fresh; long-lived headless watches only with `CLAUDE_CODE_PLUGIN_DIR_WATCH=1` |
| state | module variables are lost on reload; keep state in `$.state` / `$.store` |
| types | hot-reloaded folders get `.claude-plugin/types/{claude-code,claude-code-tools,claude-code-mcp}/index.d.ts` plus `tsconfig.json`; check with `tsc -p <mod folder>`; not written for non-hot-reloaded folders |
| validate | `claude plugin validate <dir>` (manifest, hooks module, marketplace file in one run) |
| installed | marketplace is a folder + relative `source`: read from that folder; edit, then `/reload-plugins`. Git/npm/URL source: new version, `claude plugin update`, then `/reload-plugins` |

## Package and share
```json
// .claude-plugin/marketplace.json (beside plugin.json for a one-mod repo)
{ "name": "<marketplace>", "owner": { "name": "<author>" },
  "plugins": [{ "name": "<mod>", "source": "./" }] }
```
| Audience | How |
| :- | :- |
| anyone | `/plugin install <mod> --marketplace <owner>/<repo>` (terminal session) |
| scripted | `claude plugin install <mod> --marketplace <owner>/<repo>` |
| desktop app | + next to prompt, Plugins, Add marketplace `<owner>/<repo>`, Add plugin |
| flow seen | `Add marketplace?` (`y`), then details and scope (user first), Enter |
| few people | send the directory or a `.zip` |
| team | own marketplace (private repo, one dir per plugin) |
| public | public marketplace repo, or submit to Anthropic's directory |
| `<mod>` | the `name` in `plugin.json` |
| org | a mod copied from git/URL/npm counts as a user's; org-owned needs `prependPlugins`/`appendPlugins` + folder marketplace (see security-admin.md) |

## Env vars and settings
| Name | Where | Effect |
| :- | :- | :- |
| `CLAUDE_CODE_PLUGIN_DIRS` | env or user settings `env` | load folders like `--plugin-dir` |
| `CLAUDE_CODE_PLUGIN_DIR_WATCH` | env | `1`: headless session reloads on save |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | env | stops built-in mods' requests only; user mods can still fetch |
| `CLAUDE_CODE_DISABLE_WEB_FETCH` | env | WebFetch off |
| `CLAUDE_CODE_ENABLE_FUNCTION_HOOKS` | env | ignored at any value from v2.1.287 |
| `pluginConfigs` | user or managed settings | `userConfig` values by plugin id |
| `allowModsToOverrideDenyRules` | managed, guard option | see security-admin.md |
