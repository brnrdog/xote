// Router with signals and components

module Signal = Xote__Signal
module Computed = Xote__Computed
module Component = Xote__Component
module Route = Xote__Route
module Core = Xote__Core

// Browser location type
type location = {
  pathname: string,
  search: string,
  hash: string,
}

// Global location signal - the core router state
let location: Core.t<location> = Signal.make({
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
let push = (pathname: string, ~search: string = "", ~hash: string = "", ()): unit => {
  let newLocation = {pathname, search, hash}
  let url = pathname ++ search ++ hash
  let state: historyState = %raw("{}")
  pushState(state, "", url)
  Signal.set(location, newLocation)
}

// Imperative navigation - replace current history entry
let replace = (pathname: string, ~search: string = "", ~hash: string = "", ()): unit => {
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
  ~attrs: array<(string, Component.attrValue)> = [],
  ~children: array<Component.node> = [],
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
