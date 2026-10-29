# UI deep

Extends `ui.md`. Sources: public interface docs, `claude-code.d.ts` 2.1.309. Unmarked = in those. Surfaces: `mobile` has no Input/Select/Client; `vscode` no Client; `terminal` no Svg, and only terminal has Raster and Image.

## Raster (terminal only)

| Prop | Rule |
| :- | :- |
| `key` | unique among Rasters in one tree; what `$.ui.blit` names |
| `columns` / `rows` | 1-512 / 1-256; site clips what it cannot show |
| `cells` | base64 of `columns*rows` little-endian u32 triplets `[codePoint, fg, bg]`, row-major |
| code point | one printable width-1 BMP char (blocks, box drawing, braille ok); else tree refused naming the cell index |
| color | `0x00RRGGBB`; `0x01000000` = terminal default |

```js
const DEF = 0x01000000
const pack = rows => new Uint8Array(Uint32Array.from(
  rows.flat().flatMap(([ch, fg]) => [ch.codePointAt(0), fg, DEF])).buffer).toBase64()
Raster({ key: 'grid', columns: 3, rows: 2, cells: pack(rows) })
// animate without a render pass (same size, same key):
await $.ui.blit({ requestId: 'heat', key: 'grid', columns: 3, rows: 2, cells: pack(next) })
```

- `.toBase64()` on Uint8Array: runtime support not checked here 🙈 (docs example uses it).

## Image (terminal only)

| Prop | Rule |
| :- | :- |
| `key?` | needed for `$.ui.blit({requestId,key,source})` swaps |
| `columns` / `rows` | 1-255 each; picture scaled to fill |
| `alt` | required (may be `' '`); drawn dim where no picture can show; read by screen reader |
| `source` | one of the rows below |

| source | Shape / limit |
| :- | :- |
| PNG bytes | `{ png: base64 }` |
| RGBA bytes | `{ rgba: base64, width, height }` width, height 1-2048 |
| PNG file | `{ file: '/abs/path', format: 'png' }` path <= 3072 bytes; optional counter that changes with content so a redraw rereads |
| raw file | `{ file, format, width, height }` raw pixels; Linux `/dev/shm` is memory |
| shared memory | `{ shm: '/name', format, width, height }`; terminal unlinks each; denied while frames are not written |

| Terminal | Draws |
| :- | :- |
| kitty, Ghostty | kitty graphics protocol |
| iTerm2 3.5+ | inline images, fullscreen rendering only; bytes only, file/shm show `alt` |
| other, or cannot read this machine's files | `alt` |

- Blit: bytes and `file` fold to the last per frame (~60/s); every `shm` source reaches the terminal. Pixels never cross `$`.
- tmux: not in docs 🙈 (likely `alt` unless passthrough; not measured).

## Client (second file; terminal, desktop)

| Item | Rule |
| :- | :- |
| props | `module` (string literal relative path, `.tsx .jsx .ts .js .mjs`; variable refused at load), `key` (unique, keeps local state across redraws), `props` (JSON, <=100000 chars), `width`, `height`, `flexGrow` |
| module | `(props, surface) => tree`; default export or one PascalCase export; **no `$`** |
| surface | `elements` (no Client/Raster/Image), `state`, `setState`, `columns`, `rows`, `every(ms, fn)` returns clear, `onPointer(fn)`, `onKey(fn)`, `post(data)`, `ms` |
| key event | `{ key, ctrl?, shift?, meta? }`; Escape never arrives (returns focus) |
| pointer | `type: down move up enter leave`; region-relative cells; after `down` the instance holds the pointer until up |
| redraw | on new props, `setState`, resize |

```js
// hooks side
on('ui.message', ($, e, next) => { /* e.element = Client key, e.data = posted JSON */ return next(e) })
on('ui.fault', ($, e, next) => ($.ui.log(e.reason), next(e)))   // e.phase, e.reason; observe only
```

- `ui.message`: only this plugin's hooks; one per instance per frame; `{ props }` returns next props with no redraw.
- `ui.fault`: engine redraws the site unasked; to fall back leave the `Client` out. A Client born in that redraw that fails: no second redraw, call `$.ui.invalidate`.

## Svg, Markdown, Link

| Element | Rule |
| :- | :- |
| `Svg` | desktop, vscode only; props `source alt width height isInteractive` |
| `Markdown` | `text` prop, not children; `key` needed with `onLinkPress`; `pressableLinks` limits which links; plain click raises `ui.press` with link `href` (fullscreen terminal; ctrl/alt-click still opens); scheme not https/http/file draws as text |
| `Link` desktop/vscode | plain text unless `href` is `https:` or `http://localhost`, no `@` (use `%40`), equals `new URL(href).href` (no uppercase host, space, `:443`) |

## Hover and position (Box, Text)

| Prop | Rule |
| :- | :- |
| `hover` | overrides that move no sibling; no hook runs, nothing crosses to plugin |
| `scope` | names a hover group; same-scope elements in any site light together; non-plain-string scope = inert |
| `position:'absolute'` | `top left` offsets, out of flow, clipped by its site region |
| reveal | `<Box key="k"><Text>g</Text><Box position="absolute" top={-2} left={2} display="none" hover={{display:'flex'}}>card</Box></Box>` |

## Controls events

| Event | `e` fields | Core then |
| :- | :- | :- |
| `ui.press` | plugin element component surface | runs `onPress`; return `{element}` to take it |
| `ui.input` | + kind value | `onInput`/`onSubmit`; `next({...e,value})` rewrites typing |
| `ui.select` | + value | `onSelect`; `next({...e,value})` rewrites pick |
| `ui.focus` | requestId, element | before focus ring moves; `{}`/`{deny}` keeps it |
| `ui.scroll` | requestId, by, offset | before site window moves; no `next` = you draw rows yourself |


## $.ui calls

| Call | Does |
| :- | :- |
| `ask(q, opts?)` | engine AskUserQuestion dialog; 2-4 labels or `{options,header<=12 chars,multiSelect}`; resolves label (multi comma-joined, or "Other" text); rejects on dismiss and in `-p` |
| `toast(text,{timeoutMs})` | box over transcript top right, default 4000 ms; first 2000 chars; click dismisses; pointer holds it; no model/transcript effect |
| `notify(text,{title})` | native notice via user's channel; `{isSent:true,channel}` or `{isSent:false,reason: disabled no-channel no-surface refused}`; rejects on hook `{deny}` |
| `copy({text,surface})` | clipboard; pass `e.surface` from a press; `{isCopied}` or `{isCopied:false,reason}` |
| `selection()` | `{text,requestId?}` of last mouse selection; undefined if none, fullscreen off, `-p`, or remote without support |
| `notice(tool_use_id, text)` | line in that call's open dialog; `undefined` removes |
| `scroll({to,in,block})` | scrollIntoView; `in` required for `start`/`end`; transcript rows move only while answering user input |
| `focus({requestId,key})` | needs site to hold the keys, else `{deny}` |

- Panel (desktop/vscode) cuts a status line at 200 chars or two rows, a toast at 500.
- `AskUserQuestion` render site: tree holds the engine reference exactly once or the engine draws its own dialog; panel keeps its card and draws your elements above; props to `next` do not change the card.

## holdToasts

- `$.ui.open({ id, holdToasts: true })`: for a dialog-like pane. Toasts (yours, other mods', engine short-lived) wait while that pane is the one showing; timer not started; past 50 waiting, older ones drop.
- Only `true` or omitted: `false` throws (`focus`, `closeOnEscape` same). Add conditionally: `...(x ? {holdToasts:true} : {})`.
- Terminal only; effect on desktop/vscode: not in docs 🙈.
