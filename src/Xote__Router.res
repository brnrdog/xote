open Signals
module Component = Xote__Component
module Route = Xote__Route

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
      %raw(`globalThis[Symbol.for("xote.router.state")] = state`)
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
    %raw(`console.warn(
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
    String.sliceToEnd(pathname, ~start=String.length(base))
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
type historyState = {.}

@val @scope(("window", "history"))
external pushState: (historyState, string, string) => unit = "pushState"

@val @scope(("window", "history"))
external replaceState: (historyState, string, string) => unit = "replaceState"

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

// Imperative navigation - push new history entry
// pathname: App-relative path (will have base path added automatically)
let push = (pathname: string, ~search: string="", ~hash: string="", ()): unit => {
  warnIfNotInitialized("Router.push()")

  let newLocation = {pathname, search, hash}

  // Add base path for browser URL
  let browserPathname = addBasePath(pathname)
  let url = browserPathname ++ search ++ hash

  let state: historyState = %raw("{}")
  pushState(state, "", url)
  Signal.set(location(), newLocation)
}

// Imperative navigation - replace current history entry
// pathname: App-relative path (will have base path added automatically)
let replace = (pathname: string, ~search: string="", ~hash: string="", ()): unit => {
  warnIfNotInitialized("Router.replace()")

  let newLocation = {pathname, search, hash}

  // Add base path for browser URL
  let browserPathname = addBasePath(pathname)
  let url = browserPathname ++ search ++ hash

  let state: historyState = %raw("{}")
  replaceState(state, "", url)
  Signal.set(location(), newLocation)
}

// Route definition for routes() component
type routeConfig = {
  pattern: string,
  render: Route.params => Component.node,
}

// Single route component - renders if pattern matches
let route = (pattern: string, render: Route.params => Component.node): Component.node => {
  warnIfNotInitialized("Router.route()")

  let signal = Computed.make(() => {
    let loc = Signal.get(location())
    switch Route.match(pattern, loc.pathname) {
    | Match(params) => [render(params)]
    | NoMatch => []
    }
  })
  Component.signalFragment(signal)
}

// Routes component - renders first matching route
let routes = (configs: array<routeConfig>): Component.node => {
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
  Component.signalFragment(signal)
}

// Link component - handles navigation without page reload
let link = (
  ~to: string,
  ~attrs: array<(string, Component.attrValue)>=[],
  ~children: array<Component.node>=[],
  (),
): Component.node => {
  warnIfNotInitialized("Router.link()")

  let handleClick = (_evt: Dom.event) => {
    %raw(`_evt.preventDefault()`)
    push(to, ())
  }

  Component.a(
    ~attrs=Array.concat(attrs, [Component.attr("href", addBasePath(to))]),
    ~events=[("click", handleClick)],
    ~children,
    (),
  )
}

// JSX Link component
module Link = {
  module ReactiveProp = Xote__ReactiveProp

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
    children?: Component.node,
  }

  /* Helper to detect if a value is a ReactiveProp variant */
  let isReactiveProp = (value: 'a): bool => {
    %raw(`value && typeof value === 'object' && ('TAG' in value) && (value.TAG === 'Static' || value.TAG === 'Reactive')`)
  }

  /* Helper to convert string attribute value */
  let convertAttrValue = (key: string, value: 'a): (string, Component.attrValue) => {
    if isReactiveProp(value) {
      let rp: ReactiveProp.t<string> = Obj.magic(value)
      switch rp {
      | Static(s) => Component.attr(key, s)
      | Reactive(signal) => Component.signalAttr(key, signal)
      }
    } else if typeof(value) == #function {
      let f: unit => string = Obj.magic(value)
      Component.computedAttr(key, f)
    } else if typeof(value) == #object {
      let sig: Signal.t<string> = Obj.magic(value)
      Component.signalAttr(key, sig)
    } else {
      let s: string = Obj.magic(value)
      Component.attr(key, s)
    }
  }

  /* Convert props to attrs array */
  let propsToAttrs = (props: props<_, _, _, _, _>): array<(string, Component.attrValue)> => {
    let attrs = []

    switch props.class {
    | Some(v) => attrs->Array.push(convertAttrValue("class", v))
    | None => ()
    }

    switch props.id {
    | Some(v) => attrs->Array.push(convertAttrValue("id", v))
    | None => ()
    }

    switch props.style {
    | Some(v) => attrs->Array.push(convertAttrValue("style", v))
    | None => ()
    }

    switch props.target {
    | Some(v) => attrs->Array.push(convertAttrValue("target", v))
    | None => ()
    }

    switch props.ariaLabel {
    | Some(v) => attrs->Array.push(convertAttrValue("aria-label", v))
    | None => ()
    }

    attrs
  }

  /* Extract children from props */
  let getChildren = (props: props<_, _, _, _, _>): array<Component.node> => {
    switch props.children {
    | Some(Component.Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* JSX component function */
  let make = (props: props<_, _, _, _, _>): Component.node => {
    warnIfNotInitialized("Router.Link")

    let handleClick = (evt: Dom.event) => {
      %raw(`evt.preventDefault()`)
      push(props.to, ())

      // Call user's onClick if provided
      switch props.onClick {
      | Some(handler) => handler(evt)
      | None => ()
      }
    }

    Component.a(
      ~attrs=Array.concat(propsToAttrs(props), [Component.attr("href", addBasePath(props.to))]),
      ~events=[("click", handleClick)],
      ~children=getChildren(props),
      (),
    )
  }

  /* JSX transform functions */
  let jsx = make
  let jsxs = make
  let jsxKeyed = (props: props<_, _, _, _, _>, ~key: option<string>=?, _: unit) => {
    let _ = key
    make(props)
  }
  let jsxsKeyed = jsxKeyed
}
