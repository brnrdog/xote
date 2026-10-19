/***
Server-side rendering to HTML strings.

The emitted markup carries comment markers (`<!--$-->`, `<!--#-->`, `<!--kl-->`,
`<!--k:KEY-->`, `<!--lc-->`) that `Hydration` uses to find reactive boundaries
without re-rendering. They are inert in the browser and cost nothing once
hydration has run.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

let html = SSR.renderDocument(
  ~head="<title>My app</title>",
  ~scripts=["/client.js"],
  app,
)
```
*/

/**
Options shared by the render functions.

- `nonce` — added to every generated `<script>` tag, for a
  `script-src 'nonce-...'` Content-Security-Policy.
- `renderId` — namespaces the hydration markers, so several independently
  rendered trees can coexist on one page. Pass the same value to
  `Hydration.hydrate`.
*/
type renderOptions = {
  nonce?: string,
  renderId?: string,
}

/**
Renders a component to an HTML string.

Signals are read at their current value and effects do not run: the output is a
snapshot. Use `renderToStringWithRoot` when the result will be hydrated.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

let html = SSR.renderToString(app)

// Namespaced markers plus a CSP nonce.
let scoped = SSR.renderToString(app, ~options={renderId: "sidebar", nonce: "r4nd0m"})
```
*/
let renderToString: (unit => View.node, ~options: renderOptions=?) => string

/**
Renders a component wrapped in a hydration root marker.

The wrapper carries the id `Hydration.hydrateById` looks for, so this is the
right entry point whenever the markup will become interactive.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

let html = SSR.renderToStringWithRoot(app, ~rootId="root")
// The client then calls Hydration.hydrateById(app, "root").
```
*/
let renderToStringWithRoot: (
  unit => View.node,
  ~rootId: string=?,
  ~options: renderOptions=?,
) => string

/**
A `<script>` tag that sets `window.__XOTE_HYDRATED__`.

Include it in the document so client code can tell server-rendered markup from
a fresh client render. Pass `~nonce` when a Content-Security-Policy requires
one.

## Examples

```rescript
let tag = SSR.generateHydrationScript()
let withNonce = SSR.generateHydrationScript(~nonce="r4nd0m")
```
*/
let generateHydrationScript: (~nonce: string=?) => string

/**
Renders a full HTML document around a component.

Assembles `<html>`, `<head>` and `<body>` and returns the complete response
body. `~stateScript` is where the output of `SSRState.generateScript` goes, so
the client can restore signal state before hydrating.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

let html = SSR.renderDocument(
  ~head="<title>My app</title><meta name=\"description\" content=\"Demo\" />",
  ~bodyAttrs="class=\"dark\"",
  ~styles=["/app.css"],
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app,
)
```
*/
let renderDocument: (
  ~head: string=?,
  ~bodyAttrs: string=?,
  ~scripts: array<string>=?,
  ~styles: array<string>=?,
  ~stateScript: string=?,
  ~nonce: string=?,
  unit => View.node,
) => string
