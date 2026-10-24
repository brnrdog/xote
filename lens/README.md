# xote-lens

Devtools for [Xote](https://github.com/brnrdog/xote) apps, for people and AI agents. It renders a component headlessly, drives it, and explains its reactive behaviour: what a click wrote, what ran because of it, which DOM nodes changed, and why. All output is also JSON (`--json`) and MCP tools (`xote-lens mcp`).

It is built on `Xote.Devtools` (the `xote/devtools` entry); the reactive graph comes from `rescript-signals`' debug hooks (`Signals.Debug`). Without them it still reports scopes, DOM writes, keyed passes and hydration, and says the graph is not visible.

## Commands

```sh
xote-lens api View.tracked          # a public declaration with its doc, from Xote's .resi files
xote-lens api --digest              # the whole public API as compact Markdown (--out file to save it)
xote-lens check                     # build, then compiler errors + Xote-specific findings (--no-build)
xote-lens expand Counter            # what @xote.component did to Counter.res, line by line
xote-lens render Counter --act "click #inc" --why "#value"
xote-lens render Greeting --hydrate # server render, hydrate, compare server and client markup
xote-lens why Counter "#value" --act "click #inc"
xote-lens graph Todos --around 3 --depth 2
xote-lens mcp                       # all of the above as MCP tools over stdio
```

Run it inside a ReScript project (it finds the nearest `rescript.json`) or pass `--root`; build first, since `render` loads the compiled `.res.mjs`. `--no-stacks` skips capturing creation and write sites (faster). A target is a compiled module name with an optional export path: `Counter` is `Counter.res`'s `make`, `App.Header` the nested module `Header`'s `make`, `App.view` the export `view` (a component or a node).

### `render`

```
$ xote-lens render Counter --act "click #inc" --why "#doubled"
Counter (src/Counter.res.mjs) rendered client-side
  graph: 1 signal, 3 computeds, 2 effects (2 bindings)
click #inc
  1 write · 3 computeds · 2 effects (2 bindings) · 2 DOM writes · scopes +0/-0
  wrote signal "count" = 1  (src/Counter.res.mjs:37:39)
  ran   effect #5 (text → p#value)
  …
why #doubled
  effect #6 ran
  └─ computed #4 recomputed  (src/Counter.res.mjs:33:29)
     └─ computed "doubled" recomputed  (src/Counter.res.mjs:10:29)
        └─ signal "count" written  (src/Counter.res.mjs:37:39)
```

`--act "<action> <selector> [value]"` (repeatable) dispatches `click`, `input`, `change`, `submit`, `keydown`, `keyup`, `focus` or `blur`; `--settle <ms>` keeps recording after each for async work. Each act reports **counts** (writes, computeds, effects and bindings, the library's DOM-writing effects; DOM writes, scopes created and released, keyed passes) to read as a reactive budget: an update to one text node should show one DOM write, a reorder no new scopes. `--why <selector|id>` explains an element's or node's last update, `--graph` (with `--around <id> --depth <n>`) prints the graph, `--html` the full markup.

Sites are `file:line:col` in the compiled `.res.mjs` next to its `.res`. Named signals (`Signal.make(0, ~name="count")`) show up by name.

`--ssr` renders in a server process with no DOM, so `SSRContext.isServer` really is true. `--hydrate` then hydrates that markup and compares it with what the client renders alone; each difference is a `hydration-mismatch` at a path like `div#greeting > p [class]`. The server's `SSRState` payload is in the page before the app's modules load, and each key is reported with its server value and the client signal it restored into. `--markers` outlines the server markup, naming each hydration marker (`<!--$-->` reactive text, `<!--kl-->` keyed list, `<!--k:a-->` keyed row "a", …).

### Diagnostics

| Rule | From | Finds |
|---|---|---|
| `compile-error`, `compiler-warning-N` | `check` | The compiler's own findings, with locations |
| `effect-returns-unit` | `check` | An effect body returning `unit` instead of `option<unit => unit>`, with the fix |
| `one-shot-prop` | `check` (site map) | `<Card label={Signal.get(x)} />`: a user-component prop read once, never updated |
| `possible-hidden-read` | `check` (site map) | A `View.probe` site: a call the ppx cannot see into |
| `raw-captures-binding` | `check` | `%raw` code naming a surrounding ReScript binding |
| `unresolved-read` | `render`/`act` | A probe site that turned out to read a signal: a leaf that will not update |
| `get-in-effect` | `render`/`act` | An effect that writes a signal it also reads |
| `leaked-effect` | `render`/`act` | An effect still running after the scope that created it was released |
| `undisposed-computed` | `render`/`act` | A computed still subscribed after its scope was released |
| `unowned-effect` | `render`/`act` | An effect created inside another node's run, with no scope to own it |
| `hydration-mismatch` | `render --hydrate` | Server markup that differs from the client's |
| `ssr-state-decode-failed` | `render --hydrate` | A server state value the client's codec cannot decode (the signal keeps its initial value) |
| `ssr-state-unrestored` | `render --hydrate` | A key the server sends that nothing on the client restores |
| `ssr-state-missing` | `render --hydrate` | A key the client restores that the server never registered |
| `console` | `render`/`act` | Anything the app printed with `console.warn` or `console.error` |

The site-map rules need the ppx's `-sitemap` flag: `"ppx-flags": [["xote/ppx/ppx", "-sitemap"]]`.

## MCP

```json
{ "mcpServers": { "xote-lens": { "command": "npx", "args": ["xote-lens", "mcp"] } } }
```

Tools: `xote_api`, `xote_check`, `xote_expand`, `xote_render`, `xote_act`, `xote_why`, `xote_graph`, `xote_inspect`, `xote_html`, `xote_diagnostics`, each returning the JSON the CLI prints with `--json`. `xote_render` starts a fresh session process, so it sees freshly built modules; the other session tools act on the latest render.

## Programmatic use

```js
import { createSession, check, loadApi, query } from "xote-lens";

const session = await createSession({ root: process.cwd() });
await session.render({ target: "Counter" });
const act = await session.act({ action: "click", selector: "#inc" });
console.log(act.counts, session.why({ selector: "#value" }));
session.close();
```

A session renders once (module state cannot be reset in place); render again in a new process.

## Tests

`npm test` (or `npm run lens:test` from the repo root) builds the ppx, links the repo's Xote into `test/fixture`, builds it, and drives it through the CLI and the MCP server. It needs `ocamlopt`, like `npm run ppx:test`.
