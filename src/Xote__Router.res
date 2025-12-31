open Signals
module Component = Xote__Component
module Route = Xote__Route

// Browser location type
type location = {
  pathname: string,
  search: string,
  hash: string,
}

// Global location signal - the core router state
let location: Signal.t<location> = Signal.make({
  pathname: "/",
  search: "",
  hash: "",
})

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
let getCurrentLocation = (): location => {
  pathname: %raw(`window.location.pathname`),
  search: %raw(`window.location.search`),
  hash: %raw(`window.location.hash`),
}

// Initialize router - call this once at app start
let init = (): unit => {
  // Set initial location from browser
  Signal.set(location, getCurrentLocation())

  // Listen for popstate (back/forward buttons)
  let handlePopState = (_evt: Dom.event) => {
    Signal.set(location, getCurrentLocation())
  }

  addEventListener("popstate", handlePopState)

  // Note: No cleanup needed for SPA scenarios
  // If cleanup is needed, return a disposer function
}

// Imperative navigation - push new history entry
let push = (pathname: string, ~search: string="", ~hash: string="", ()): unit => {
  let newLocation = {pathname, search, hash}
  let url = pathname ++ search ++ hash
  let state: historyState = %raw("{}")
  pushState(state, "", url)
  Signal.set(location, newLocation)
}

// Imperative navigation - replace current history entry
let replace = (pathname: string, ~search: string="", ~hash: string="", ()): unit => {
  let newLocation = {pathname, search, hash}
  let url = pathname ++ search ++ hash
  let state: historyState = %raw("{}")
  replaceState(state, "", url)
  Signal.set(location, newLocation)
}

// Route definition for routes() component
type routeConfig = {
  pattern: string,
  render: Route.params => Component.node,
}

// Single route component - renders if pattern matches
let route = (pattern: string, render: Route.params => Component.node): Component.node => {
  let signal = Computed.make(() => {
    let loc = Signal.get(location)
    switch Route.match(pattern, loc.pathname) {
    | Match(params) => [render(params)]
    | NoMatch => []
    }
  })
  Component.signalFragment(signal)
}

// Routes component - renders first matching route
let routes = (configs: array<routeConfig>): Component.node => {
  let signal = Computed.make(() => {
    let loc = Signal.get(location)
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
  let handleClick = (_evt: Dom.event) => {
    %raw(`_evt.preventDefault()`)
    push(to, ())
  }

  Component.a(
    ~attrs=Array.concat(attrs, [Component.attr("href", to)]),
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
      ~attrs=Array.concat(propsToAttrs(props), [Component.attr("href", props.to)]),
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
