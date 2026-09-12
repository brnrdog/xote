/* Signal-based client-side router.

   Router state is a global singleton keyed by `Symbol.for("xote.router.state")`
   so every Xote bundle in a page shares the same location signal. Base-path
   handling, scroll restoration and history plumbing are internal. */

type location = {
  pathname: string,
  search: string,
  hash: string,
}

/* The current app-relative location (base path already stripped) */
let location: unit => Signal.t<location>

/* Initialize the router from the browser. Call once at app entry. */
let init: (~basePath: string=?, unit) => unit

/* Initialize the router for server rendering, without touching browser APIs */
let initSSR: (
  ~basePath: string=?,
  ~pathname: string=?,
  ~search: string=?,
  ~hash: string=?,
  unit,
) => unit

/* Navigate, pushing a new history entry */
let push: (string, ~search: string=?, ~hash: string=?, unit) => unit

/* Navigate, replacing the current history entry */
let replace: (string, ~search: string=?, ~hash: string=?, unit) => unit

type routeConfig = {
  pattern: string,
  render: Route.params => View.node,
}

/* Render `render` while the pattern matches the current location */
let route: (string, Route.params => View.node) => View.node

/* Render the first matching route */
let routes: array<routeConfig> => View.node

/* Anchor that navigates without a full page load */
let link: (
  ~to: string,
  ~attrs: array<(string, View.attrValue)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/* JSX flavour of `link`: `<Router.Link to="/about" class="nav-link">` */
module Link: {
  /* Deprecated re-export, kept for existing `Router.Link.Prop.*` call sites.
   Use `MaybeSignal` directly. */
  module Prop = Prop

  type props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> = {
    to: string,
    class?: 'class,
    id?: 'id,
    style?: 'style,
    target?: 'target,
    @as("aria-label") ariaLabel?: 'ariaLabel,
    /* Escape hatch for attributes with no prop of their own, merged after them */
    attrs?: array<(string, 'attrs)>,
    onClick?: Dom.event => unit,
    children?: View.node,
  }

  let make: props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> => View.node

  let jsx: props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> => View.node
  let jsxs: props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs> => View.node
  let jsxKeyed: (
    props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs>,
    ~key: string=?,
    unit,
  ) => View.node
  let jsxsKeyed: (
    props<'class, 'id, 'style, 'target, 'ariaLabel, 'attrs>,
    ~key: string=?,
    unit,
  ) => View.node
}
