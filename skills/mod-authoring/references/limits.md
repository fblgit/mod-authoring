# Limits and version gates

## Limits

| What | Value |
| :- | :- |
| hook own time (excludes `next` and `$` calls except `$.clock.sleep`) | 10 s; `prompt.edit` 50 ms |
| `.catch` handler | 1 s |
| all `session.end` hooks | 1.5 s default |
| `$.process.run` | 30 s default, 10 min max; stdout and stderr 4 MiB each |
| `$.http.fetch` | 30 s, 5 redirects, 4 MiB request and response |
| `$.fs.read/write` | 4 MiB per file |
| `$.store` | 4 MiB JSON total |
| `$.model.complete` maxTokens | 1024 default, up to 64,000 |
| `$.session.messages()` | newest 4,096 |
| tree depth | 32 |
| elements and text children per tree | 20,000 |
| text drawn per tree | 100,000 characters |
| `Raster` cells | 262,144 (columns up to 512, rows up to 256) |
| `Image` bytes | 2 MiB; columns and rows up to 255 |
| `Svg` source | 131,072 characters |
| `Link` href | 2,048 |
| `Code` language/path, `Select` value, `Client` module | 10,000 |
| drop or deny reason | 4,096 |
| names (command, tool, agent type, pane) | letters digits `_` `-`, 64 |
| `invalidate('ui.render')` | 10/s; 30/s for the visible terminal pane, expanded band, hint line |
| toast | 4 s default; `timeoutMs` 1 to 60000 whole ms; fullscreen draws 3 |
| unprompted pane | placed at 144 columns, 110 after the user opened it once |
| scopes per file | 2,000 |
| call and event nesting | 28,000 |
| one `claude plugin test` | 5 s |

## Version gates

| Feature | Version |
| :- | :- |
| mods (terminal) / desktop Code tab / VS Code panel | 2.1.287 / 2.1.286 / ext 2.1.299 (2.1.304 if no feature-flag fetch) |
| `agent.list` statuses `idle`, `waiting` | 2.1.289 |
| `ui.fault`; `tool.check` `agentId`, `ceiling` | 2.1.289; 2.1.290 |
| `prompt.mention`; `serverToolUses` on turn.step | 2.1.290 |
| `.catch` `re-entry` kind; `$.model.complete` block arrays | 2.1.292 |
| `isDeferred` on tool registration | 2.1.293 |
| `mock.session` | 2.1.293 |
| Button children other than one string | 2.1.295 |
| spacing steps, `size weight mono tabular`, state note in `/plugin` | 2.1.299 |
| `types` optional in manifest | 2.1.299 |
| `Input` `rows` | 2.1.301 |
| `tool.check` `isReadOnly`; `settings.read` key; interrupt handling of calls | 2.1.304 |
| model aliases in `turn.step` | 2.1.309 |
| `Image` in tmux | 2.1.310 |

A tree using a feature newer than the running build does not draw.
