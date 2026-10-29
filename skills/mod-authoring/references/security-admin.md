# Security and administration

Source: docs plugins/mods/admin. Version gate: guard note check needs v2.1.299+.

## What a mod can reach

| Fact | Detail |
| :- | :- |
| Permissions | Those of the installing user. No sandbox. |
| Reach | Files, processes, network, env, settings, MCP, model calls, prompts, other sessions |
| Settings hooks | Command/HTTP/prompt/agent hooks run as before, alongside mods |
| Managed `PreToolUse` | Runs before any mod `tool.call`; if it blocks, no mod `tool.call` runs; re-runs on a mod-rewritten call |
| Other-source `PreToolUse` | Run after the last mod; skipped if a mod answers the call itself |
| `$.http.fetch` | Refused for every mod if org policy disallows WebFetch |
| Plugin controls | `strictKnownMarketplaces` etc. decide if a mod installs at all |

## Built-in guard `sec-default@builtin`

| Item | Detail |
| :- | :- |
| Loads when | Machine has managed settings, OR session uses `/login` credentials of Team/Enterprise |
| Does not load | API key / Bedrock / Vertex / Foundry on a machine without managed settings; long-lived `CLAUDE_CODE_OAUTH_TOKEN` |
| Name in `/plugin`, log | `cc-plugin-sec-default` |
| Users can turn off | No. Runs ahead of user mods. |
| Protects | Managed hooks' input and decisions, system prompt, managed CLAUDE.md, what mods read as settings, managed MCP tools |
| Precedence | User mod cannot approve a call a `deny` or `ask` rule refuses, nor one a `PreToolUse` hook blocked |
| Still skippable | Auto mode: mod-approved call skips classifier unless `--permission-prompt-tool` or SDK `canUseTool` |
| Fails closed | Cannot read managed settings: refuses every user mod. Cannot check deny rules: refuses the call. |
| Source | `mods/sec-default` in the claude-code repo |

## Options (managed settings only, key `cc-plugin-sec-default@builtin`)

```json
{ "pluginConfigs": { "cc-plugin-sec-default@builtin": { "options": { "allowManagedModsOnly": true } } } }
```

| Option | Unset | `true` |
| :- | :- | :- |
| `allowManagedModsOnly` | user mods run | only org mods and built-ins run; refuses user-installed and `--plugin-dir` |
| `allowModsToOverrideDenyRules` | deny beats user mods | user mod may approve a denied call |

Rules: user/project/local settings or `--settings` change nothing. `pluginConfigs` takes only the `cc-plugin-` id form (`prependPlugins` takes both). If `prependPlugins` is set, list the guard, or options do not apply.
`allowManagedModsOnly` leaves settings hooks, status lines, `/goal` working.

## Policy table (managed settings)

| Want | Set |
| :- | :- |
| No installed mod runs, settings hooks stay | `allowManagedModsOnly` (no org mods) |
| No mods, no hooks, managed hooks too | `disableAllHooks: true` |
| Only org mods | `allowManagedModsOnly` + install org mods |
| Any mod from approved marketplaces | marketplace restrictions + `disableSideloadFlags: true` |
| Any mod, your mod checks others | install yours; `prependPlugins` with it and `sec-default@builtin` |

| Key | Effect |
| :- | :- |
| `allowManagedHooksOnly` | only org mods and built-ins load; also blocks hooks in users' settings files |
| `disableAllHooks` | stops all mods and every settings hook (managed `PreToolUse` too), status lines, `/goal` |
| `disableSideloadFlags` | rejects `--plugin-dir`, `--plugin-url`, `--agents`, `--mcp-config`; mods Claude writes mid-session do not load |
| `prependPlugins` / `appendPlugins` | org mod before / after all user mods; list replaces default, keep `sec-default@builtin` |
| `enabledPlugins`, `extraKnownMarketplaces` | install org mod so it counts as yours |
| `pluginConfigs` | guard options |

## Org mod conditions (all three)

- Managed `enabledPlugins` sets the plugin `true`.
- Marketplace named by absolute directory path in managed settings (`extraKnownMarketplaces`).
- Marketplace lists plugin by relative path (loaded in place).

Directory and parents writable by admin only. Plugins copied to cache (GitHub, git, URL, npm) count as user: skipped by prepend/append, refused by `allowManagedModsOnly`. Check: `claude --debug`, line `hooks module <id> loaded` with `tier prepend` (vs `tier user`).

## Hooks the guard passes over (user mods, guard loaded)

`classic.<Event>`, `prompt.compose`, `prompt.section`, `prompt.context`, `prompt.attachment`, `skill.prompt`, `attribution.text`, `session.compact`, `settings.read`, `session.append{door=attachment|hook-context|compaction}`. Also `tool.describe` for org tools and the skill-text row (no note). Fix: run the mod as org's, or drop the guard (`"prependPlugins": []`, loses all of it).

## Review a mod: `claude plugin validate <dir>`

| Line | Meaning |
| :- | :- |
| `hooks:` `tool.call`, `prompt.submit` | sees and can change every call / prompt |
| `hooks:` `session.append` | can rewrite each stored row |
| `hooks:` `ui.render{component=AskUserQuestion}` | can redraw the question dialog |
| `hooks:` `tool.check` | can approve/deny before the permission prompt |
| `calls:` `$.fs.read/write` | any file the user can |
| `calls:` `$.process.run/spawn` | starts programs as user |
| `calls:` `$.http.fetch` | network |
| `calls:` `$.env.get`, `$.settings.read` | may read API keys; `env reads:` lists vars |
| `calls:` `$.env.set` | changes env of Claude Code, commands, MCP servers; `env writes:` lists |
| `calls:` `$.mcp.call` | MCP tool under session permission rules |
| `calls:` `$.model.complete` | spends user plan/key |
| `calls:` `$.prompt.submit` | submits as the user's words |
| `calls:` `$.session.send` | message another session/subagent/teammate reads |

A mod using `$` in a way validate cannot read is refused at load.

## Policy mod (prepend, fails closed)

```js
const BLOCKED = ['process.run', 'process.spawn']
async function checkMod($, e, next) {
  const bad = e.uses.calls.filter((c) => BLOCKED.includes(c))
  if (e.tier === 'user' && bad.length) return { refuse: 'policy: ' + bad.join(', ') }
  return next(e)
}
export function register(on) {
  on('plugin.register', checkMod).catch(async ($, e, next) => {
    if (e.tier !== 'user') return next(e)
    return { refuse: 'policy check failed, mod not loaded' }
  })
  on('fs.write', async ($, e, next) => { // API-call hook: name without "$."
    $.ui.log('audit fs.write by ' + next.origin.plugin + ' ' + JSON.stringify(e.path), { to: 'debug' })
    return next(e)
  })
}
```

| Fact | Detail |
| :- | :- |
| `e.tier` | `prepend`, `user`, `append`, `builtin` |
| `e.uses.calls` | `namespace.method` list, as validate prints |
| Without `.catch` | throw or timeout skips the hook: fails open, mod loads |
| Block one call only | return `{ deny: 'reason' }` from a hook on that call name |
| Refusal log | `refused by <plugin>: <reason>` in debug log |

## Gaps

| Case | Effect |
| :- | :- |
| Worker thread crashes 3 times | every non-built-in mod unloaded, yours too, until `/reload-plugins` or new session |
| `claude --safe-mode` | no installed mods, org mods included |
| Server-managed settings | guard stays loaded until server confirms settings |
| Test policy mod | docs plugins/mods/test, "test a mod that judges other mods" (not read here 🙈) |
