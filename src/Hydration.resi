/***
Client-side hydration of server-rendered markup.

Walks the existing DOM produced by `SSR`, attaches effects and event listeners
and sets up keyed-list reconciliation without re-rendering. The component
passed here must produce the same tree the server rendered; mismatches leave
stale markup in place.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

// The server rendered this markup with SSR.renderToStringWithRoot.
Hydration.hydrateById(app, "root")
```
*/

/**
Options for `hydrate` and `hydrateById`.

- `renderId` — must match the `renderId` given to `SSR.renderToString`, so the
  hydration markers line up when several independent trees share a page.
- `onHydrated` — called once, after the tree is attached and interactive.
*/
type hydrateOptions = {
  renderId?: string,
  onHydrated?: unit => unit,
}

/**
Hydrates a component into an existing container element.

The container's children are adopted rather than replaced: the markup stays,
and only event listeners and reactive bindings are attached. Use `View.mount`
instead when rendering from scratch in the browser.

## Examples

```rescript
@val external document: {..} = "document"

let app = () => <p> {View.text("Hello")} </p>
let container: Dom.element = document["getElementById"]("root")

Hydration.hydrate(app, container)

// With options.
Hydration.hydrate(
  app,
  container,
  ~options={renderId: "app", onHydrated: () => Console.log("interactive")},
)
```
*/
let hydrate: (unit => View.node, Dom.element, ~options: hydrateOptions=?) => unit

/**
`hydrate` by element id. Does nothing when no element has that id.

## Examples

```rescript
let app = () => <p> {View.text("Hello")} </p>

Hydration.hydrateById(app, "root")
Hydration.hydrateById(app, "root", ~options={onHydrated: () => Console.log("interactive")})
```
*/
let hydrateById: (unit => View.node, string, ~options: hydrateOptions=?) => unit
