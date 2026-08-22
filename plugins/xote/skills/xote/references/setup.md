# Setting up a xote project

## Install

```bash
npm install xote
```

`rescript-signals` comes along as xote's only runtime dependency. The
`@xote.component` PPX ships as prebuilt binaries (linux x64/arm64, macOS
x64/arm64, Windows x64) selected by a postinstall script — no OCaml toolchain
is needed. If the postinstall was skipped (`--ignore-scripts`), the PPX will not
be on disk and any `ppx-flags` entry pointing at it fails the build.

## rescript.json

```json
{
  "name": "my-app",
  "sources": [{ "dir": "src", "subdirs": true }],
  "package-specs": { "module": "esmodule", "in-source": true },
  "suffix": ".res.mjs",
  "dependencies": ["rescript-signals", "xote"],
  "jsx": { "version": 4, "module": "XoteJSX" },
  "ppx-flags": ["xote/ppx/ppx"],
  "compiler-flags": ["-open Xote"]
}
```

What each line buys:

- `"jsx": {"version": 4, "module": "XoteJSX"}` — **required** for JSX. Without
  it ReScript compiles JSX against React's transform.
- `"ppx-flags": ["xote/ppx/ppx"]` — enables `@xote.component`, the recommended
  component style. Omit it to write `@jsx.component` with explicit thunks
  instead; see `components.md`. Its semantics are not frozen yet, so treat a
  minor xote upgrade as something to recompile and re-test.
- `"compiler-flags": ["-open Xote"]` — optional. Xote compiles with
  `namespace: true`, so its modules are `Xote.View`, `Xote.Signal`, … The flag
  makes them available unqualified (`View`, `Signal`). Every example in these
  references assumes it. Without the flag, qualify: `Xote.View.mountById(…)`.
- `"package-specs"` with `in-source: true` and `suffix: ".res.mjs"` — matches
  what xote itself ships, and is what the Vite setup below expects.

## Entry point

```rescript
/* src/Main.res */
View.mountById(<App />, "app")
```

```html
<!-- index.html -->
<div id="app"></div>
<script type="module" src="/src/Main.res.mjs"></script>
```

`mountById` takes a `node`, not a function. `View.mount(node, element)` is the
variant that takes a DOM element you already have.

## Vite

No plugin is needed — ReScript compiles to plain ESM that Vite consumes
directly.

```js
// vite.config.js
import { defineConfig } from "vite";

export default defineConfig({
  optimizeDeps: { include: ["rescript-signals"] },
});
```

Run the compiler in watch mode alongside the dev server:

```json
{
  "scripts": {
    "res:dev": "rescript -w",
    "dev": "vite",
    "build": "rescript && vite build"
  }
}
```

**The ReScript compiler must run before any bundler step.** Vite consumes the
generated `.res.mjs` files; stale output is the most common "my change did
nothing" report.

## Package entry points

Import the narrowest entry you need — the root entry is client-only by design,
and each subpath is separately tree-shakeable.

| Entry | Contains |
|---|---|
| `xote` / `xote/client` | `View`, `Html`, `XoteJSX`, `MaybeSignal`, signal shims |
| `xote/router` | `Router`, `Route` |
| `xote/ssr` | `SSR`, `SSRState`, `SSRContext` |
| `xote/hydration` | `Hydration` |
| `xote/mdx` | the optional MDX integration |

In ReScript you rarely touch these: `dependencies: ["xote"]` puts every public
module in scope. They matter for JavaScript consumers and for bundler config.

## Verifying the setup

```bash
npx rescript          # must succeed before anything else
```

Then render something that changes on its own — a counter with a button — and
confirm the number moves. A build that compiles but renders a frozen value
means the JSX module or the PPX flag is wrong.
