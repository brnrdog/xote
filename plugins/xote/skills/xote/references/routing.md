# Routing

A signal-based client-side router. Location is a signal, so anything that reads
it updates on navigation without a subscription of your own.

## Initialize once, at the entry point

```rescript
Router.init(())                          /* no base path */
Router.init(~basePath="/my-app", ())     /* app served from a subdirectory */
```

`Router.init` must run before any other routing call on the client — it reads
`window.location` and installs the history listeners. On the server call
`Router.initSSR` instead, which sets the location without touching browser
APIs:

```rescript
Router.initSSR(~pathname="/users/42", ~search="?tab=posts", ())
```

Router state is a global singleton keyed by `Symbol.for("xote.router.state")`,
so several xote bundles on one page share the same location.

## Routes

```rescript
let app = () =>
  Router.routes([
    {pattern: "/", render: _ => <Home />},
    {pattern: "/about", render: _ => <About />},
    {
      pattern: "/users/:id",
      render: params => <UserPage id={params->Dict.get("id")->Option.getOr("")} />,
    },
  ])
```

`Router.routes` renders the **first** match, so order matters — put specific
patterns before general ones. `Router.route(pattern, render)` is the
single-route form. Params arrive as `Dict.t<string>`; a missing key means the
pattern and the lookup disagree.

All patterns are relative to the base path. Browser URLs are prefixed and
stripped automatically, so never write the base path into a pattern or a link.

## Navigation

```rescript
<Router.Link to="/about" class="nav-link"> {"About"} </Router.Link>
<Router.Link to="/users/42" attrs=[("aria-current", "page")]> {"Profile"} </Router.Link>
```

`Router.Link` renders an `<a>` that navigates without a page reload. It takes
`to`, `class`, `id`, `style`, `target`, `aria-label`, `attrs`, `onClick` and
children. `Router.link(~to, ~attrs?, ~children?, ())` is the function-based
form.

Programmatic navigation:

```rescript
Router.push("/users/42", ())
Router.push("/search", ~search="?q=signals", ())
Router.replace("/login", ())        /* no history entry */
```

Scroll position is saved and restored across back/forward navigation via
`history.state`.

## Reading the location

```rescript
let loc = Router.location()   /* Signal.t<{pathname, search, hash}> */

<span> {() => Signal.get(loc).pathname} </span>
```

Reading it inside JSX makes that leaf update on navigation — this is how you
build an "active link" style without any router-specific API:

```rescript
<Router.Link
  to="/about"
  attrs=[
    View.optionalComputedAttr("data-active", () =>
      Signal.get(Router.location()).pathname === "/about" ? Some("") : None
    ),
  ]>
  {"About"}
</Router.Link>
```

## Matching outside the router

`Route.match(pattern, path)` returns `Match(params)` or `NoMatch`, for when you
need pattern matching without rendering. The rest of `Route` — `parsePattern`,
`matchPath`, `compile`, `matchCompiled`, `matchPathname` — is deprecated and
will be removed; `Route.match` replaces all of them.
