module Route = Route

// Browser location type
type location = {
  pathname: string,
  search: string,
  hash: string,
}

// ============================================================================
// GLOBAL SINGLETON STATE MANAGEMENT
// ============================================================================
// This ensures all Xote Router instances share the same state, even when
// multiple copies of Xote are bundled (e.g., component library + app).
// We use JavaScript's Symbol.for() to create a globally unique key that
// all bundles will share.

// Type for the global router state stored in globalThis
type globalRouterState = {
  location: Signal.t<location>,
  basePath: ref<string>,
  mutable initialized: bool,
  mutable popStateHandler: option<Dom.event => unit>,
}

// External binding for Symbol.for() - creates/retrieves a global symbol
@val @scope("Symbol")
external symbolFor: string => 'symbol = "for"

// Get the global symbol key used to store router state
let getSymbolKey = (): 'symbol => {
  symbolFor("xote.router.state")
}

// Get or create the global router state
// This function is idempotent - safe to call multiple times
let getGlobalState = (): globalRouterState => {
  // Check if global state exists
  // We use Symbol.for() inline to ensure the same symbol across all Xote bundles
  let existingState: option<globalRouterState> = %raw(`globalThis[Symbol.for("xote.router.state")]`)

  switch existingState {
  | Some(state) => state
  | None => {
      // Create new global state
      let state: globalRouterState = {
        location: Signal.make({
          pathname: "/",
          search: "",
          hash: "",
        }),
        basePath: ref("/"),
        initialized: false,
        popStateHandler: None,
      }

      // Store in globalThis using the same symbol
      ignore(state)
      let _: unit = %raw(`globalThis[Symbol.for("xote.router.state")] = state`)
      state
    }
  }
}

// Convenience accessors for global state
// These replace the old module-level state variables
let location = (): Signal.t<location> => getGlobalState().location
let basePath = (): ref<string> => getGlobalState().basePath

// Warn if Router is used before initialization
let warnIfNotInitialized = (methodName: string): unit => {
  let state = getGlobalState()
  if !state.initialized {
    ignore(methodName)
    let _: unit = %raw(`console.warn(
      '[Xote Router] ' + methodName + ' called before Router.init(). ' +
      'Make sure to call Router.init() at your app entry point. ' +
      'This may cause incorrect routing behavior.'
    )`)
  }
}

// Normalize base path: ensure starts with "/", no trailing "/"
// Examples: "" → "/", "project" → "/project", "/project/" → "/project"
let normalizeBasePath = (path: string): string => {
  if path == "" || path == "/" {
    "/"
  } else {
    let withLeading = if String.startsWith(path, "/") {
      path
    } else {
      "/" ++ path
    }
    if String.endsWith(withLeading, "/") {
      String.slice(withLeading, ~start=0, ~end=String.length(withLeading) - 1)
    } else {
      withLeading
    }
  }
}

// Strip base path from browser pathname to get app-relative path
// Examples (base="/project"): "/project/home" → "/home", "/project" → "/"
let stripBasePath = (pathname: string): string => {
  let base = basePath().contents
  if base == "/" {
    pathname
  } else if pathname == base {
    "/"
  } else if String.startsWith(pathname, base ++ "/") {
    String.slice(pathname, ~start=String.length(base))
  } else {
    pathname // Pass through if doesn't match base
  }
}

// Add base path to app-relative pathname for browser history
// Examples (base="/project"): "/home" → "/project/home", "/" → "/project"
let addBasePath = (pathname: string): string => {
  let base = basePath().contents
  if base == "/" {
    pathname
  } else if pathname == "/" {
    base
  } else {
    base ++ pathname
  }
}

// External bindings for History API
type historyState

@val @scope(("window", "history"))
external pushState: (historyState, string, string) => unit = "pushState"

@val @scope(("window", "history"))
external replaceState: (historyState, string, string) => unit = "replaceState"

@val @scope("window")
external historyState: Nullable.t<historyState> = "history.state"

// Scroll position helpers
let getScrollPosition = (): (float, float) => {
  let x: float = %raw(`window.scrollX || window.pageXOffset || 0`)
  let y: float = %raw(`window.scrollY || window.pageYOffset || 0`)
  (x, y)
}

let scrollTo = (x: float, y: float): unit => {
  ignore(x)
  ignore(y)
  let _: unit = %raw(`window.scrollTo(x, y)`)
}

// Create history state with scroll position
let makeHistoryState = (scrollX: float, scrollY: float): historyState => {
  ignore(scrollX)
  ignore(scrollY)
  %raw(`({ scrollX: scrollX, scrollY: scrollY })`)
}

let emptyHistoryState = (): historyState => {
  %raw(`({})`)
}

// Extract scroll position from history state
let getScrollFromState = (state: historyState): option<(float, float)> => {
  ignore(state)
  let scrollX: Nullable.t<float> = %raw(`state && state.scrollX`)
  let scrollY: Nullable.t<float> = %raw(`state && state.scrollY`)
  switch (Nullable.toOption(scrollX), Nullable.toOption(scrollY)) {
  | (Some(x), Some(y)) => Some((x, y))
  | _ => None
  }
}

// Save current scroll position to current history entry
let saveScrollPosition = (): unit => {
  let (x, y) = getScrollPosition()
  let state = makeHistoryState(x, y)
  let url: string = %raw(`window.location.href`)
  replaceState(state, "", url)
}

@val @scope("window")
external addEventListener: (string, Dom.event => unit) => unit = "addEventListener"

@val @scope("window")
external removeEventListener: (string, Dom.event => unit) => unit = "removeEventListener"

// Parse current browser location from window.location
// Strips base path from pathname to get app-relative path
let getCurrentLocation = (): location => {
  let browserPathname: string = %raw(`window.location.pathname`)
  {
    pathname: stripBasePath(browserPathname),
    search: %raw(`window.location.search`),
    hash: %raw(`window.location.hash`),
  }
}

// Initialize router - call this at app start
// This function is idempotent and safe to call multiple times.
// Subsequent calls will update the basePath and re-sync location.
//
// basePath: Optional base path for the app (e.g., "/project-name")
//           Routes will be relative to this base. Defaults to "/"
//
// IMPORTANT: In apps with nested Xote dependencies (e.g., component library + app),
// the app should call init() with the basePath. All Router instances across
// all bundles will share the same state via the global singleton.
let init = (~basePath as basePathArg: string="/", ()): unit => {
  let state = getGlobalState()

  // Normalize and update base path
  let normalizedBasePath = normalizeBasePath(basePathArg)
  state.basePath := normalizedBasePath

  // Set/update location from browser (with base path stripped)
  Signal.set(state.location, getCurrentLocation())

  // Only set up the popstate listener once
  // If already initialized, we don't add another listener
  if !state.initialized {
    let handlePopState = (_evt: Dom.event) => {
      Signal.set(location(), getCurrentLocation())

      // Restore scroll position from history state (for back/forward navigation)
      switch Nullable.toOption(historyState) {
      | Some(hState) =>
        switch getScrollFromState(hState) {
        | Some((x, y)) => scrollTo(x, y)
        | None => ()
        }
      | None => ()
      }
    }

    // Store handler reference in global state
    state.popStateHandler = Some(handlePopState)

    // Add the listener
    addEventListener("popstate", handlePopState)

    // Mark as initialized
    state.initialized = true
  }

  // Note: No cleanup/disposal needed for typical SPA scenarios
  // The popstate listener lives for the entire app lifetime
}

// Initialize router for server-side rendering
// Sets the base path and location signal without accessing browser APIs
// pathname: The app-relative path being rendered (e.g., "/docs/core-concepts/signals")
let initSSR = (
  ~basePath as basePathArg: string="/",
  ~pathname: string="/",
  ~search: string="",
  ~hash: string="",
  (),
): unit => {
  let state = getGlobalState()
  let normalizedBasePath = normalizeBasePath(basePathArg)
  state.basePath := normalizedBasePath
  Signal.set(state.location, {pathname, search, hash})
  state.initialized = true
}

// Imperative navigation - push new history entry
// pathname: App-relative path (will have base path added automatically)
let push = (pathname: string, ~search: string="", ~hash: string="", ()): unit => {
  warnIfNotInitialized("Router.push()")

  // Save current scroll position to current history entry before navigating
  saveScrollPosition()

  let newLocation = {pathname, search, hash}

  // Add base path for browser URL
  let browserPathname = addBasePath(pathname)
  let url = browserPathname ++ search ++ hash

  pushState(emptyHistoryState(), "", url)
  Signal.set(location(), newLocation)

  // Scroll to top for new navigation
  scrollTo(0.0, 0.0)
}

// Imperative navigation - replace current history entry
// pathname: App-relative path (will have base path added automatically)
let replace = (pathname: string, ~search: string="", ~hash: string="", ()): unit => {
  warnIfNotInitialized("Router.replace()")

  let newLocation = {pathname, search, hash}

  // Add base path for browser URL
  let browserPathname = addBasePath(pathname)
  let url = browserPathname ++ search ++ hash

  replaceState(emptyHistoryState(), "", url)
  Signal.set(location(), newLocation)

  // Scroll to top for new navigation
  scrollTo(0.0, 0.0)
}

// Route definition for routes() component
type routeConfig = {
  pattern: string,
  render: Route.params => View.node,
}

// Single route component - renders if pattern matches
let route = (pattern: string, render: Route.params => View.node): View.node => {
  warnIfNotInitialized("Router.route()")

  let signal = Computed.make(() => {
    let loc = Signal.get(location())
    switch Route.match(pattern, loc.pathname) {
    | Match(params) => [render(params)]
    | NoMatch => []
    }
  })
  View.signalFragment(signal)
}

// Routes component - renders first matching route
let routes = (configs: array<routeConfig>): View.node => {
  warnIfNotInitialized("Router.routes()")

  let signal = Computed.make(() => {
    let loc = Signal.get(location())
    let matched = configs->Array.findMap(config => {
      switch Route.match(config.pattern, loc.pathname) {
      | Match(params) => Some(config.render(params))
      | NoMatch => None
      }
    })

    switch matched {
    | Some(node) => [node]
    | None => [] // No matching route - render nothing
    }
  })
  View.signalFragment(signal)
}

// Link component - handles navigation without page reload
let link = (
  ~to: string,
  ~attrs: array<(string, View.attrValue)>=[],
  ~children: array<View.node>=[],
  (),
): View.node => {
  warnIfNotInitialized("Router.link()")

  let handleClick = (_evt: Dom.event) => {
    let _: unit = %raw(`_evt.preventDefault()`)
    push(to, ())
  }

  Html.a(
    ~attrs=Array.concat(attrs, [View.attr("href", addBasePath(to))]),
    ~events=[("click", handleClick)],
    ~children,
    (),
  )
}

// JSX Link component
module Link = {
  module Prop = Prop

  type props<'class, 'id, 'style, 'target, 'ariaLabel> = {
    /* Required navigation prop */
    to: string,
    /* Common attributes - can be static or reactive */
    class?: 'class,
    id?: 'id,
    style?: 'style,
    target?: 'target,
    @as("aria-label") ariaLabel?: 'ariaLabel,
    /* Event handlers */
    onClick?: Dom.event => unit,
    /* Children */
    children?: View.node,
  }

  /* Convert props to attrs array */
  let propsToAttrs = (props): array<(string, View.attrValue)> => {
    let attrs = []

    switch props.class {
    | Some(v) => attrs->Array.push(RuntimeJsxProp.toStringAttr("class", v))
    | None => ()
    }

    switch props.id {
    | Some(v) => attrs->Array.push(RuntimeJsxProp.toStringAttr("id", v))
    | None => ()
    }

    switch props.style {
    | Some(v) => attrs->Array.push(RuntimeJsxProp.toStringAttr("style", v))
    | None => ()
    }

    switch props.target {
    | Some(v) => attrs->Array.push(RuntimeJsxProp.toStringAttr("target", v))
    | None => ()
    }

    switch props.ariaLabel {
    | Some(v) => attrs->Array.push(RuntimeJsxProp.toStringAttr("aria-label", v))
    | None => ()
    }

    attrs
  }

  /* Extract children from props */
  let getChildren = (props): array<View.node> => {
    switch props.children {
    | Some(View.Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* JSX component function */
  let make = (props): View.node => {
    warnIfNotInitialized("Router.Link")

    let handleClick = (evt: Dom.event) => {
      let _: unit = %raw(`evt.preventDefault()`)
      push(props.to, ())

      // Call user's onClick if provided
      switch props.onClick {
      | Some(handler) => handler(evt)
      | None => ()
      }
    }

    Html.a(
      ~attrs=Array.concat(propsToAttrs(props), [View.attr("href", addBasePath(props.to))]),
      ~events=[("click", handleClick)],
      ~children=getChildren(props),
      (),
    )
  }

  /* JSX transform functions */
  let jsx = make
  let jsxs = make
  let jsxKeyed = (props, ~key: option<string>=?, _: unit) => {
    switch key {
    | Some(key) => View.Keyed({key, identity: Obj.magic(props), child: make(props)})
    | None => make(props)
    }
  }
  let jsxsKeyed = jsxKeyed
}
