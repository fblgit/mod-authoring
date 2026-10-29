# Interface

`ui.render` fires for each render site. The hook returns a tree, `next(e)` to leave it, or `next({...e, props})` to tweak it. Elements come from `const { Box, Text, Button } = $.ui.resolve(e)`.

## Render sites

| Site | Draws in | Notes |
| :- | :- | :- |
| `Pane` | terminal, desktop, vscode | `requestId` = pane id; props `title isFocused bodyColumns placement scroll view` |
| `AbovePrompt` (band) | terminal, desktop | shared by all mods; props `hasSurvey isWorking maxRows bodyColumns scroll view` |
| `Spinner` | all | props `word message suffix mode`; requestId = agent id |
| `UserMessage` `AssistantMessage` `ToolUse` `ToolResult` `ToolGroup` | all | tool call id / message id |
| `CommandOutput` | terminal, desktop | `props.command`, `props.text` |
| `AskUserQuestion` | all | tree must hold the engine reference exactly once |
| `ToolProgress` `TurnDuration` `InfoNotice` | terminal | |
| `SessionMode` `PromptHint` | terminal, desktop | |

## Pane

- Open: `await $.ui.open({ id, title, focus?, closeOnEscape?, holdToasts?, rows?, columns? })` resolves `{isPlaced, reason}`.
- Close: `$.ui.close({ id })`. List: `$.ui.panes()`.
- Opened by a user action: placed at any width. Opened by a timer or turn hook: placed only at 144+ columns (110+ after the user opened it once).
- `placement` is `'dock'` (beside transcript) or `'inline'` (above prompt).
- Height: dock uses `scroll.bodyRows`; inline grows to a limit (`rows` option). A taller tree scrolls as a whole.
- Opening draws nothing by itself; a `ui.render` hook must answer for the id.
- A pane never redraws on a timer: call `$.ui.invalidate('ui.render')` or read `$.state`.

## Band

A returned tree replaces later mods' drawing. Keep theirs by embedding `await next(e)` as a child in a plain Box (no width/height/position/overflow props). The user can collapse it and the mod cannot tell. Never make it the only place for something to answer.

## Elements

| Element | Props (main) | Where |
| :- | :- | :- |
| `Box` | flex props, `gap columnGap rowGap padding margin` (number or `xs sm md lg xl`), `width height minWidth`, `borderStyle`, `borderColor`, `backgroundColor`, `position top left`, `overflow`, `display`, `hover` | all |
| `Text` | `color backgroundColor bold italic underline strikethrough dimColor inverse wrap weight size mono tabular` | all |
| `Button` | `key label children onPress hotkey plain dimColor autoFocus action variant role` | all |
| `Link` | `href label` | all |
| `Code` | `source language path startLine format wrap` | all |
| `Markdown` | `text key dimColor onLinkPress pressableLinks` (text, not children) | all |
| `Input` | `key label placeholder value submitLabel rows onSubmit onInput autoFocus` | all |
| `Select` | `key label options value onSelect autoFocus` | all |
| `Svg` | `source alt width height isInteractive` | desktop, vscode |
| `Client` | `module key props width height flexGrow` | terminal, desktop |
| `Raster` | `key columns rows cells` | terminal |
| `Image` | `key source columns rows alt` | terminal |

- `borderStyle`: `single double round bold singleDouble doubleSingle classic arrow dashed quote`. Anything else draws no border.
- `wrap`: `wrap truncate truncate-start truncate-middle truncate-end`.
- Spacing steps need 2.1.299+. Across/down cells: xs 1/0, sm 1/0, md 2/1, lg 3/1, xl 4/2.
- Typography props `size weight mono tabular` need 2.1.299+; terminal ignores size, mono, tabular. `bold` is deprecated for `weight:'semibold'`.
- `variant`: `primary` or `secondary`. `role`: `dismiss`. Other values throw.
- Button children: strings and Text only (2.1.295+). One row can be one Button.

## Keys

| Key | Action |
| :- | :- |
| Tab, arrows | move between controls; arrows scroll when content overflows |
| Enter | press, submit or pick |
| hotkey | presses a Button (one digit or lowercase letter); pane or band needs focus; later duplicate wins |
| PgUp PgDn Home End | scroll |
| Ctrl+X then X | close pane |
| Ctrl+X then arrow | resize pane |
| Ctrl+X then Ctrl+A | collapse band |
| Ctrl+X then Tab | focus pane |
| Esc | back to prompt (and closes with `closeOnEscape`) |

VS Code: no hotkeys, no `autoFocus`, no `rows` or `columns` on open. A panel 800px+ docks panes; narrower shows panes inline with 12 rows.

## Redraw

| Trigger | How |
| :- | :- |
| props or width change | automatic |
| your data changed | `$.ui.invalidate('ui.render')` |
| `$.state` value read while drawing changed | automatic |
| timer | `$.clock.every(1000, () => $.ui.invalidate('ui.render'))` in `session.start` |

Invalidate is throttled and coalesced; the hook reads the latest data.

## Surface checks

Branch on `e.surface` (`terminal`, `desktop`, `vscode`, `mobile`). Fall back to `Text` where an element is missing.
