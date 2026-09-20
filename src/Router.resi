/***
Signal-based client-side router.

Router state is a global singleton keyed by `Symbol.for("xote.router.state")`
so every Xote bundle in a page shares the same location signal. Base-path
handling, scroll restoration and history plumbing are internal.

Call `init` once at app entry (or `initSSR` when rendering on the server), then
describe the screens with `routes` and navigate with `link` or `push`.

## Examples

```rescript
let app = () => {
  Router.init()

  <div>
    <nav> {Router.link(~to="/about", ~children=[View.text("About")], ())} </nav>
    {Router.routes([
      {pattern: "/", render: _params => <h1> {View.text("Home")} </h1>},
      {
        pattern: "/users/:id",
        render: params =>
          <h1> {View.text("User " ++ Dict.get(params, "id")->Option.getOr("?"))} </h1>,
      },
    ])}
  </div>
}
```
*/

/**
An app-relative location, with the base path already stripped.

`search` and `hash` include their leading `?` and `#`, and are empty strings
when absent.

## Examples

```rescript
let current: Router.location = {pathname: "/users/42", search: "?tab=posts", hash: ""}
current.pathname == "/users/42"
```
*/
type location = {
  pathname: string,
  search: string,
  hash: string,
}

/**
The current app-relative location, as a signal.

Read it with `Signal.get` inside a computed, an effect or a tracked block to
re-run on every navigation. Most screens need `routes` rather than this, but it
is the escape hatch for anything driven by the query string or hash.

## Examples

```rescript
let tab = Computed.make(() => Signal.get(Router.location()).search)

Effect.run(() => {
  Console.log(Signal.get(Router.location()).pathname)
  None
})
```
*/
let location: unit => Signal.t<location>

/**
Initializes the router from the browser. Call once at app entry.

Reads the current URL and subscribes to history events. `~basePath` is stripped
from every pathname before matching, so an app served from a subdirectory can
still use root-relative patterns.

## Examples

```rescript
Router.init()

// Served from https://example.com/docs/ — patterns stay root-relative.
Router.init(~basePath="/docs", ())
```
*/
let init: (~basePath: string=?, unit) => unit

/**
Initializes the router for server rendering, without touching browser APIs.

Seed it with the request's URL so `routes` matches the same screen the client
will hydrate.

## Examples

```rescript
Router.initSSR(~pathname="/users/42", ~search="?tab=posts", ())
let html = SSR.renderToString(() => Router.route("/users/:id", _params => View.text("User")))
```
*/
let initSSR: (
  ~basePath: string=?,
  ~pathname: string=?,
  ~search: string=?,
  ~hash: string=?,
  unit,
) => unit

/**
Navigates, pushing a new history entry. The back button returns to the previous
location.

## Examples

```rescript
Router.push("/about", ())
Router.push("/users/42", ~search="?tab=posts", ~hash="#bio", ())
```
*/
let push: (string, ~search: string=?, ~hash: string=?, unit) => unit

/**
Navigates, replacing the current history entry. The previous location is not
kept in the back stack.

Use it for redirects, and for state changes the user should not have to step
back through.

## Examples

```rescript
Router.replace("/login", ())
Router.replace("/results", ~search="?page=2", ())
```
*/
let replace: (string, ~search: string=?, ~hash: string=?, unit) => unit

/**
One entry in a `routes` table: a pattern and what to render when it matches.

## Examples

```rescript
let home: Router.routeConfig = {
  pattern: "/",
  render: _params => <h1> {View.text("Home")} </h1>,
}
```
*/
type routeConfig = {
  pattern: string,
  render: Route.params => View.node,
}

/**
Renders `render` while the pattern matches the current location, and nothing
otherwise.

Standalone and independent: several `route` calls can match at once. Use
`routes` when exactly one screen should win.

## Examples

```rescript
let view = Router.route("/users/:id", params =>
  <h1> {View.text("User " ++ Dict.get(params, "id")->Option.getOr("?"))} </h1>
)
```
*/
let route: (string, Route.params => View.node) => View.node

/**
Renders the first matching route.

Order matters: the first entry whose pattern matches wins, so list specific
patterns before general ones and put a catch-all last.

## Examples

```rescript
let view = Router.routes([
  {pattern: "/", render: _params => <h1> {View.text("Home")} </h1>},
  {
    pattern: "/users/:id",
    render: params => <h1> {View.text(Dict.get(params, "id")->Option.getOr("?"))} </h1>,
  },
  // Catch-all: matches anything the entries above did not.
  {pattern: "/:rest", render: _params => <h1> {View.text("Not found")} </h1>},
])
```
*/
let routes: array<routeConfig> => View.node

/**
An anchor that navigates without a full page load.

Renders a real `<a href>`, so middle-click, "open in new tab" and crawlers all
behave normally; only a plain left click is intercepted.

## Examples

```rescript
let nav = Router.link(
  ~to="/about",
  ~attrs=[View.attr("class", "nav-link")],
  ~children=[View.text("About")],
  (),
)
```
*/
let link: (
  ~to: string,
  ~attrs: array<(string, View.attrValue)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
JSX flavour of `link`: `<Router.Link to="/about" class="nav-link">`.

The common attributes have props of their own; anything else goes through
`attrs`. An `onClick` handler runs before navigation.

## Examples

```rescript
let nav =
  <nav>
    <Router.Link to="/" class="nav-link"> {View.text("Home")} </Router.Link>
    <Router.Link to="/about" class="nav-link" ariaLabel="About this site">
      {View.text("About")}
    </Router.Link>
  </nav>
```
*/
module Link: {
  /**
  Deprecated re-export, kept for existing `Router.Link.Prop.*` call sites.
  Use `MaybeSignal` directly.
  */
  module Prop = Prop

  /**
  Props of `Router.Link`.

  `to` is the app-relative target. The remaining props are deliberately
  polymorphic, so each accepts a plain value, a `Signal.t` or a thunk.

  - `attrs` — escape hatch for attributes with no prop of their own, merged
    after them.
  - `onClick` — runs before navigation.
  */
  type props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> = {
    to: string,
    class?: 'class,
    id?: 'id,
    style?: 'style,
    target?: 'target,
    @as("aria-label") ariaLabel?: 'ariaLabel,
    /** Escape hatch for attributes with no prop of their own, merged after them */
    attrs?: array<(string, 'attrs)>,
    onClick?: Dom.event => unit,
    children?: View.node,
  }

  /** Renders the anchor. Called for you by `<Router.Link />`; see the module doc for usage. */
  let make: props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> => View.node

  /** JSX runtime entry point. Prefer `<Router.Link />`. */
  let jsx: props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> => View.node

  /** JSX runtime entry point for multiple children. Prefer `<Router.Link />`. */
  let jsxs: props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> => View.node

  /** Keyed JSX runtime entry point. Prefer `<Router.Link />`. */
  let jsxKeyed: (
    props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs>,
    ~key: string=?,
    unit,
  ) => View.node

  /** Keyed JSX runtime entry point for multiple children. Prefer `<Router.Link />`. */
  let jsxsKeyed: (
    props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs>,
    ~key: string=?,
    unit,
  ) => View.node
}
