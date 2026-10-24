# xote-lens

Devtools for [Xote](https://github.com/brnrdog/xote) apps, for people and for AI agents. It renders a component headlessly, drives it, and explains its reactive behaviour: what a click wrote, what ran because of it, which DOM nodes changed, and why. Everything it prints is also available as JSON (`--json`) and as MCP tools (`xote-lens mcp`).

It is built on `Xote.Devtools` (the `xote/devtools` entry). The reactive graph comes from the debug hooks of `rescript-signals` (`Signals.Debug`). Against a release without them, xote-lens still reports scopes, DOM writes, keyed passes and hydration, and says the graph is not visible.

## Commands

```sh
xote-lens api View.tracked          # a public declaration with its doc, from Xote's .resi files
xote-lens api --digest              # the whole public API as compact Markdown (for an agent's context)
xote-lens check                     # build, then compiler errors + Xote-specific findings
xote-lens expand Counter            # what @xote.component did to Counter.res, line by line
xote-lens render Counter --act "click #inc" --why "#value"
xote-lens render Greeting --hydrate # server render, hydrate, compare server and client markup
xote-lens graph Todos --around 3
xote-lens mcp                       # all of the above as MCP tools over stdio
```

Run it from anywhere inside a ReScript project (it finds the nearest `rescript.json`), or pass `--root`. Build the project first: `render` loads the compiled `.res.mjs`.

A target is a compiled module name with an optional export path: `Counter` is `Counter.res`'s `make`, `App.Header` is the nested module `Header`'s `make`, and `App.view` is the export `view` (a component or a node).

### `render`

```
$ xote-lens render Counter --act "click #inc" --why "#doubled"
Counter (src/Counter.res.mjs) rendered client-side
  graph: 1 signal, 3 computeds, 2 effects (2 bindings)
  html: <div id="counter"><p id="value">0</p><p id="doubled">0</p>…
click #inc
  1 write · 3 computeds · 2 effects (2 bindings) · 2 DOM writes · scopes +0/-0
  wrote signal "count" = 1  (src/Counter.res.mjs:37:39)
  ran   effect #5 (text → p#value)
  ran   computed "doubled"  (src/Counter.res.mjs:10:29)
  …
why #doubled
  effect #6 ran
  └─ computed #4 recomputed  (src/Counter.res.mjs:33:29)
     └─ computed "doubled" recomputed  (src/Counter.res.mjs:10:29)
        └─ signal "count" written  (src/Counter.res.mjs:37:39)
```

`--act "<action> <selector> [value]"` dispatches `click`, `input`, `change`, `submit`, `keydown`, `keyup`, `focus` or `blur`, and repeats. Each act reports its **counts**: writes, computeds, effects (bindings are the library's DOM-writing effects), DOM writes, scopes created and released, keyed passes. Read them as a reactive budget. An update that should touch one text node should show one DOM write, and a reorder should create no scopes.

Sites are `file:line:col` in the compiled `.res.mjs`, which sits next to its `.res` source. Name long-lived signals (`Signal.make(0, ~name="count")`) and they show up by name.

`--ssr` renders on a server process with no DOM, so `SSRContext.isServer` really is true. `--hydrate` then hydrates that markup in the page and compares it with what the client renders on its own. Each difference is a `hydration-mismatch` error, at a path like `div#greeting > p [class]`.

### Diagnostics

| Rule | From | Finds |
|---|---|---|
| `compile-error`, `compiler-warning-N` | `check` | The compiler's own findings, with locations |
| `effect-returns-unit` | `check` | An effect body that returns `unit` instead of `option<unit => unit>`, with the fix |
| `one-shot-prop` | `check` (site map) | `<Card label={Signal.get(x)} />`: a user-component prop read once, never updated |
| `possible-hidden-read` | `check` (site map) | A `View.probe` site: a call the ppx cannot see into |
| `raw-captures-binding` | `check` | `%raw` code naming a surrounding ReScript binding |
| `unresolved-read` | `render`/`act` | A probe site that turned out to read a signal: a leaf that will not update |
| `get-in-effect` | `render`/`act` | An effect that writes a signal it also reads |
| `leaked-effect` | `render`/`act` | An effect still running after the scope that created it was released |
| `undisposed-computed` | `render`/`act` | A computed still subscribed after its scope was released |
| `unowned-effect` | `render`/`act` | An effect created inside another node's run, with no scope to own it |
| `hydration-mismatch` | `render --hydrate` | Server markup that differs from the client's |
| `console` | `render`/`act` | Anything the app printed with `console.warn` or `console.error` |

`check` reads the site map the ppx writes when given `-sitemap`:

```json
"ppx-flags": [["xote/ppx/ppx", "-sitemap"]]
```

## MCP

```json
{ "mcpServers": { "xote-lens": { "command": "npx", "args": ["xote-lens", "mcp"] } } }
```

The tools are `xote_api`, `xote_check`, `xote_expand`, `xote_render`, `xote_act`, `xote_why`, `xote_graph`, `xote_inspect`, `xote_html` and `xote_diagnostics`. Each returns the JSON the CLI prints with `--json`. `xote_render` starts a fresh session in a new process, so it always sees freshly built modules. The other session tools act on the latest render.

## Programmatic use

```js
import { createSession, check, loadApi, query } from "xote-lens";

const session = await createSession({ root: process.cwd() });
await session.render({ target: "Counter" });
const act = await session.act({ action: "click", selector: "#inc" });
console.log(act.counts, session.why({ selector: "#value" }));
session.close();
```

A session renders once: module state cannot be reset in place, so render again in a new process.

## Tests

`npm test` (or `npm run lens:test` from the repo root) builds the ppx, links the repo's Xote into `test/fixture`, builds it, and drives it through the CLI and the MCP server. It needs `ocamlopt`, like `npm run ppx:test`.
