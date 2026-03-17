@@warning("-21-26-27")
open Signals

// ============================================================================
// Types
// ============================================================================

type signalEntry = {
  id: int,
  name: option<string>,
  signal: Obj.t,
  kind: [#Signal | #Computed],
  createdAt: float,
}

type effectEntry = {
  id: int,
  name: option<string>,
  disposer: Effect.disposer,
  createdAt: float,
}

type graphNode = {
  id: int,
  kind: [#Signal | #Computed | #Effect],
  name: option<string>,
  value: option<string>,
  dependsOn: array<int>,
  dependedBy: array<int>,
}

type rec componentNode = {
  element: Dom.element,
  tag: string,
  effectCount: int,
  computedCount: int,
  depth: int,
  children: array<componentNode>,
}

// The global registry
type registry = {
  signals: Dict.t<signalEntry>,
  effects: Dict.t<effectEntry>,
  // Map from subs pointer identity to signal ID (for graph traversal)
  subsToSignalId: Dict.t<int>,
  mutable enabled: bool,
}

// ============================================================================
// Global Singleton (Symbol.for pattern, same as Router)
// ============================================================================

let getRegistry = (): registry => {
  let existing: option<registry> = %raw(`globalThis[Symbol.for("xote.devtools")]`)

  switch existing {
  | Some(r) => r
  | None => {
      let r: registry = {
        signals: Dict.make(),
        effects: Dict.make(),
        subsToSignalId: Dict.make(),
        enabled: false,
      }
      %raw(`globalThis[Symbol.for("xote.devtools")] = r`)
      r
    }
  }
}

// ============================================================================
// Enable / Disable
// ============================================================================

let enable = (): unit => {
  getRegistry().enabled = true
}

let disable = (): unit => {
  getRegistry().enabled = false
}

let isEnabled = (): bool => {
  getRegistry().enabled
}

// ============================================================================
// Registration (called by instrumented wrappers in Xote.res)
// ============================================================================

// Get a unique string key for a subs object (using its identity)
// We use a hidden property __xote_subs_id__ to tag subs objects
let nextSubsId: ref<int> = ref(0)

let getSubsKey = (subs: Obj.t): string => {
  let existingId: option<int> = %raw(`subs.__xote_subs_id__`)
  switch existingId {
  | Some(id) => Int.toString(id)
  | None => {
      nextSubsId := nextSubsId.contents + 1
      let id = nextSubsId.contents
      %raw(`subs.__xote_subs_id__ = id`)
      Int.toString(id)
    }
  }
}

let registerSignal = (id: int, name: option<string>, signal: Obj.t, kind: [#Signal | #Computed]): unit => {
  let r = getRegistry()
  if r.enabled {
    let entry: signalEntry = {
      id,
      name,
      signal,
      kind,
      createdAt: Date.now(),
    }
    r.signals->Dict.set(Int.toString(id), entry)

    // Map the subs object to this signal ID for graph traversal
    let subs: Obj.t = %raw(`signal.subs`)
    let subsKey = getSubsKey(subs)
    r.subsToSignalId->Dict.set(subsKey, id)
  }
}

let registerEffect = (id: int, name: option<string>, disposer: Effect.disposer): unit => {
  let r = getRegistry()
  if r.enabled {
    let entry: effectEntry = {
      id,
      name,
      disposer,
      createdAt: Date.now(),
    }
    r.effects->Dict.set(Int.toString(id), entry)
  }
}

let unregisterEffect = (id: int): unit => {
  let r = getRegistry()
  r.effects->Dict.delete(Int.toString(id))->ignore
}

// ============================================================================
// Query API
// ============================================================================

let getSignals = (): array<signalEntry> => {
  getRegistry().signals->Dict.valuesToArray
}

let getEffects = (): array<effectEntry> => {
  getRegistry().effects->Dict.valuesToArray
}

let getSignalValue = (entry: signalEntry): Obj.t => {
  %raw(`entry.signal.value`)
}

let getSignalValueString = (entry: signalEntry): string => {
  let value = getSignalValue(entry)
  %raw(`
    (function() {
      try {
        if (value === null) return "null";
        if (value === undefined) return "undefined";
        if (typeof value === "string") return JSON.stringify(value);
        if (typeof value === "number" || typeof value === "boolean") return String(value);
        if (Array.isArray(value)) return "Array(" + value.length + ")";
        if (typeof value === "object") return JSON.stringify(value).slice(0, 80);
        return String(value);
      } catch(e) {
        return "[unserializable]";
      }
    })()
  `)
}

let isComputed = (entry: signalEntry): bool => entry.kind == #Computed

// ============================================================================
// Dependency Graph Traversal
// ============================================================================
// Walks the internal linked-list structures of rescript-signals using raw JS.
// Signal -> subs.first -> link.nextSub chain gives subscribers
// Observer -> firstDep -> link.nextDep chain gives dependencies

// Get subscriber IDs for a signal (who depends on this signal?)
let getSubscriberIds = (signal: Obj.t): array<int> => {
  let r = getRegistry()
  let subsToSignalId = r.subsToSignalId
  %raw(`
    (function() {
      var result = [];
      var subs = signal.subs;
      if (!subs) return result;
      var link = subs.first;
      while (link) {
        // link.observer might be a subs (for computed) or an observer (for effect)
        var obs = link.observer;
        if (obs && obs.compute !== undefined) {
          // It's a computed's subs - look up its signal ID via our mapping
          var subsId = obs.__xote_subs_id__;
          if (subsId !== undefined) {
            var signalId = subsToSignalId[String(subsId)];
            if (signalId !== undefined) result.push(signalId);
          }
        } else if (obs && obs.id !== undefined) {
          // It's an effect observer - use negative ID to distinguish
          result.push(-obs.id);
        }
        link = link.nextSub;
      }
      return result;
    })()
  `)
}

// Get dependency IDs for a signal (what does this computed depend on?)
let getDependencyIds = (signal: Obj.t): array<int> => {
  let r = getRegistry()
  let subsToSignalId = r.subsToSignalId
  %raw(`
    (function() {
      var result = [];
      var subs = signal.subs;
      if (!subs || subs.compute === undefined) return result;
      // This is a computed - walk its dependency chain
      var link = subs.firstDep;
      while (link) {
        // link.subs points to the source signal's subs
        var srcSubs = link.subs;
        if (srcSubs && srcSubs.__xote_subs_id__ !== undefined) {
          var signalId = subsToSignalId[String(srcSubs.__xote_subs_id__)];
          if (signalId !== undefined) result.push(signalId);
        }
        link = link.nextDep;
      }
      return result;
    })()
  `)
}

// Get dependency IDs for an effect (what signals does this effect read?)
let getEffectDependencyIds = (entry: effectEntry): array<int> => {
  let r = getRegistry()
  let subsToSignalId = r.subsToSignalId
  let disposer = entry.disposer
  // The disposer closure captures the observer reference - we need to get it
  // We'll store the observer on the disposer during instrumentation
  %raw(`
    (function() {
      var result = [];
      var observer = disposer.__xote_observer__;
      if (!observer) return result;
      var link = observer.firstDep;
      while (link) {
        var srcSubs = link.subs;
        if (srcSubs && srcSubs.__xote_subs_id__ !== undefined) {
          var signalId = subsToSignalId[String(srcSubs.__xote_subs_id__)];
          if (signalId !== undefined) result.push(signalId);
        }
        link = link.nextDep;
      }
      return result;
    })()
  `)
}

// Build the complete dependency graph
let buildGraph = (): array<graphNode> => {
  let nodes: array<graphNode> = []
  let signalSubscriberMap: Dict.t<array<int>> = Dict.make()

  // Process signals
  let signals = getSignals()
  signals->Array.forEach(entry => {
    let subscriberIds = getSubscriberIds(entry.signal)
    signalSubscriberMap->Dict.set(Int.toString(entry.id), subscriberIds)

    let dependsOn = if entry.kind == #Computed {
      getDependencyIds(entry.signal)
    } else {
      []
    }

    nodes->Array.push({
      id: entry.id,
      kind: (entry.kind :> [#Signal | #Computed | #Effect]),
      name: entry.name,
      value: Some(getSignalValueString(entry)),
      dependsOn,
      dependedBy: subscriberIds->Array.filter(id => id > 0),
    })
    ->ignore
  })

  // Process effects
  let effects = getEffects()
  effects->Array.forEach(entry => {
    let depIds = getEffectDependencyIds(entry)
    nodes->Array.push({
      id: -entry.id,
      kind: #Effect,
      name: entry.name,
      value: None,
      dependsOn: depIds,
      dependedBy: [],
    })->ignore
  })

  nodes
}

// ============================================================================
// Component Tree Inspection
// ============================================================================

let rec inspectComponentsHelper = (element: Dom.element, depth: int): array<componentNode> => {
  let results: array<componentNode> = []

  let owner: option<Xote__Component.Reactivity.owner> = %raw(`element["__xote_owner__"]`)

  let hasOwner = switch owner {
  | Some(_) => true
  | None => false
  }

  let childNodes: array<componentNode> = {
    let children: array<Dom.element> = %raw(`Array.from(element.children || [])`)
    children->Array.flatMap(child => inspectComponentsHelper(child, depth + 1))
  }

  if hasOwner {
    let effectCount = switch owner {
    | Some(o) => o.disposers->Array.length
    | None => 0
    }
    let computedCount = switch owner {
    | Some(o) => o.computeds->Array.length
    | None => 0
    }
    let tag: string = %raw(`element.tagName ? element.tagName.toLowerCase() : "#text"`)

    results->Array.push({
      element,
      tag,
      effectCount,
      computedCount,
      depth,
      children: childNodes,
    })->ignore
  } else {
    // No owner on this element, but pass through children
    childNodes->Array.forEach(child => {
      results->Array.push(child)->ignore
    })
  }

  results
}

let inspectComponents = (root: Dom.element): array<componentNode> => {
  inspectComponentsHelper(root, 0)
}

// ============================================================================
// DevTools UI Panel
// ============================================================================
// Built using Xote's Component API (dogfooding)

module Component = Xote__Component

// Panel state
type tab = Signals | Graph | Components

let panelMounted: ref<bool> = ref(false)
let panelVisible: ref<option<Signal.t<bool>>> = ref(None)
let activeTab: ref<option<Signal.t<tab>>> = ref(None)
let refreshCounter: ref<option<Signal.t<int>>> = ref(None)

// Trigger a refresh of the devtools panel data
let refresh = (): unit => {
  switch refreshCounter.contents {
  | Some(s) => Signal.update(s, n => n + 1)
  | None => ()
  }
}

// ============================================================================
// SVG Graph Rendering
// ============================================================================

module GraphLayout = {
  type nodePos = {
    id: int,
    x: float,
    y: float,
    kind: [#Signal | #Computed | #Effect],
    label: string,
  }

  type edge = {
    fromX: float,
    fromY: float,
    toX: float,
    toY: float,
  }

  type layout = {
    nodes: array<nodePos>,
    edges: array<edge>,
    width: float,
    height: float,
  }

  // Simple layered layout: signals top, computeds middle, effects bottom
  let computeLayout = (graph: array<graphNode>): layout => {
    let signals = graph->Array.filter(n => n.kind == #Signal)
    let computeds = graph->Array.filter(n => n.kind == #Computed)
    let effects = graph->Array.filter(n => n.kind == #Effect)

    let nodeSpacing = 120.0
    let layerSpacing = 100.0
    let padding = 60.0

    let nodePositions: Dict.t<nodePos> = Dict.make()
    let allNodes: array<nodePos> = []

    // Position signals
    signals->Array.forEachWithIndex((entry, i) => {
      let pos = {
        id: entry.id,
        x: padding +. Int.toFloat(i) *. nodeSpacing,
        y: padding,
        kind: #Signal,
        label: entry.name->Option.getOr("#" ++ Int.toString(entry.id)),
      }
      nodePositions->Dict.set(Int.toString(entry.id), pos)
      allNodes->Array.push(pos)->ignore
    })

    // Position computeds
    computeds->Array.forEachWithIndex((entry, i) => {
      let pos = {
        id: entry.id,
        x: padding +. Int.toFloat(i) *. nodeSpacing,
        y: padding +. layerSpacing,
        kind: #Computed,
        label: entry.name->Option.getOr("#" ++ Int.toString(entry.id)),
      }
      nodePositions->Dict.set(Int.toString(entry.id), pos)
      allNodes->Array.push(pos)->ignore
    })

    // Position effects
    effects->Array.forEachWithIndex((entry, i) => {
      let pos = {
        id: entry.id,
        x: padding +. Int.toFloat(i) *. nodeSpacing,
        y: padding +. layerSpacing *. 2.0,
        kind: #Effect,
        label: entry.name->Option.getOr("Effect"),
      }
      nodePositions->Dict.set(Int.toString(entry.id), pos)
      allNodes->Array.push(pos)->ignore
    })

    // Build edges
    let edges: array<edge> = []
    graph->Array.forEach(node => {
      let toPos = nodePositions->Dict.get(Int.toString(node.id))
      switch toPos {
      | Some(to) =>
        node.dependsOn->Array.forEach(depId => {
          let fromPos = nodePositions->Dict.get(Int.toString(depId))
          switch fromPos {
          | Some(from) =>
            edges->Array.push({
              fromX: from.x,
              fromY: from.y,
              toX: to.x,
              toY: to.y,
            })->ignore
          | None => ()
          }
        })
      | None => ()
      }
    })

    let maxX = allNodes->Array.reduce(0.0, (acc, n) => Math.max(acc, n.x))
    let maxY = allNodes->Array.reduce(0.0, (acc, n) => Math.max(acc, n.y))

    {
      nodes: allNodes,
      edges,
      width: maxX +. padding *. 2.0,
      height: maxY +. padding *. 2.0,
    }
  }
}

// ============================================================================
// UI Rendering Helpers (uses Component API directly to avoid circular deps)
// ============================================================================

module UI = {
  open Component

  let css = `
    .xote-devtools-panel {
      position: fixed;
      bottom: 0;
      right: 0;
      width: 480px;
      max-height: 60vh;
      background: #1a1a2e;
      color: #e0e0e0;
      font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
      font-size: 12px;
      border: 1px solid #333;
      border-radius: 8px 8px 0 0;
      box-shadow: 0 -4px 20px rgba(0,0,0,0.4);
      z-index: 999999;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    .xote-devtools-panel.hidden { display: none; }
    .xote-dt-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 8px 12px;
      background: #16213e;
      border-bottom: 1px solid #333;
      cursor: default;
      user-select: none;
    }
    .xote-dt-title {
      font-weight: 700;
      font-size: 13px;
      color: #7dd3fc;
      letter-spacing: 1px;
    }
    .xote-dt-controls { display: flex; gap: 6px; }
    .xote-dt-btn {
      background: transparent;
      border: 1px solid #444;
      color: #aaa;
      padding: 2px 8px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 11px;
      font-family: inherit;
    }
    .xote-dt-btn:hover { background: #333; color: #fff; }
    .xote-dt-tabs {
      display: flex;
      gap: 0;
      padding: 0;
      background: #1a1a2e;
      border-bottom: 1px solid #333;
    }
    .xote-dt-tab {
      padding: 6px 16px;
      background: transparent;
      border: none;
      border-bottom: 2px solid transparent;
      color: #888;
      cursor: pointer;
      font-size: 12px;
      font-family: inherit;
    }
    .xote-dt-tab:hover { color: #ccc; }
    .xote-dt-tab.active {
      color: #7dd3fc;
      border-bottom-color: #7dd3fc;
    }
    .xote-dt-content {
      flex: 1;
      overflow-y: auto;
      padding: 8px 12px;
      min-height: 150px;
      max-height: calc(60vh - 80px);
    }
    .xote-dt-signal-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 4px 8px;
      border-radius: 4px;
      margin: 2px 0;
    }
    .xote-dt-signal-row:hover { background: #222; }
    .xote-dt-signal-id { color: #666; margin-right: 8px; }
    .xote-dt-signal-name { color: #a78bfa; flex: 1; }
    .xote-dt-signal-kind {
      font-size: 10px;
      padding: 1px 6px;
      border-radius: 3px;
      margin: 0 6px;
    }
    .xote-dt-kind-signal { background: #1e3a5f; color: #60a5fa; }
    .xote-dt-kind-computed { background: #1e3f2e; color: #4ade80; }
    .xote-dt-kind-effect { background: #3f2e1e; color: #fb923c; }
    .xote-dt-signal-value { color: #fbbf24; font-size: 11px; max-width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
    .xote-dt-detail {
      padding: 8px;
      margin: 4px 0;
      background: #111;
      border-radius: 4px;
      border-left: 3px solid #7dd3fc;
    }
    .xote-dt-detail-label { color: #888; font-size: 10px; text-transform: uppercase; margin-bottom: 4px; }
    .xote-dt-detail-value { color: #e0e0e0; }
    .xote-dt-comp-row {
      padding: 4px 0;
      border-bottom: 1px solid #222;
    }
    .xote-dt-comp-tag { color: #f472b6; font-weight: 600; }
    .xote-dt-comp-info { color: #666; font-size: 11px; margin-left: 8px; }
    .xote-dt-graph-container { overflow: auto; }
    .xote-dt-empty { color: #666; text-align: center; padding: 24px; font-style: italic; }
    .xote-dt-badge { font-size: 10px; color: #888; background: #222; padding: 1px 5px; border-radius: 3px; margin-left: 4px; }
  `

  // Inject stylesheet
  let injectStyles = (): unit => {
    %raw(`
      (function() {
        if (document.getElementById('xote-devtools-styles')) return;
        var style = document.createElement('style');
        style.id = 'xote-devtools-styles';
        style.textContent = css;
        document.head.appendChild(style);
      })()
    `)
  }

  // Render signal list tab
  let renderSignalsTab = (): node => {
    let signals = getSignals()
    let effects = getEffects()

    if signals->Array.length == 0 && effects->Array.length == 0 {
      Component.div(
        ~attrs=[attr("class", "xote-dt-empty")],
        ~children=[text("No signals registered. Call DevTools.enable() before creating signals.")],
        (),
      )
    } else {
      let signalRows =
        signals
        ->Array.toSorted((a, b) => Int.toFloat(a.id - b.id))
        ->Array.map(entry => {
          let valueStr = getSignalValueString(entry)
          let kindClass = entry.kind == #Computed ? "xote-dt-kind-computed" : "xote-dt-kind-signal"
          let kindLabel = entry.kind == #Computed ? "computed" : "signal"
          let nameStr = entry.name->Option.getOr("(unnamed)")
          let subs = getSubscriberIds(entry.signal)
          let subsCount = subs->Array.length

          Component.div(
            ~attrs=[attr("class", "xote-dt-signal-row")],
            ~children=[
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-id")],
                ~children=[text("#" ++ Int.toString(entry.id))],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-name")],
                ~children=[text(nameStr)],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-kind " ++ kindClass)],
                ~children=[text(kindLabel)],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-badge")],
                ~children=[text(Int.toString(subsCount) ++ " sub" ++ (subsCount != 1 ? "s" : ""))],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-value")],
                ~children=[text(valueStr)],
                (),
              ),
            ],
            (),
          )
        })

      let effectRows =
        effects
        ->Array.toSorted((a, b) => Int.toFloat(a.id - b.id))
        ->Array.map(entry => {
          let nameStr = entry.name->Option.getOr("(unnamed)")
          let deps = getEffectDependencyIds(entry)
          let depsCount = deps->Array.length

          Component.div(
            ~attrs=[attr("class", "xote-dt-signal-row")],
            ~children=[
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-id")],
                ~children=[text("E#" ++ Int.toString(entry.id))],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-name")],
                ~children=[text(nameStr)],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-signal-kind xote-dt-kind-effect")],
                ~children=[text("effect")],
                (),
              ),
              Component.span(
                ~attrs=[attr("class", "xote-dt-badge")],
                ~children=[text(Int.toString(depsCount) ++ " dep" ++ (depsCount != 1 ? "s" : ""))],
                (),
              ),
            ],
            (),
          )
        })

      Component.div(
        ~children=Array.concat(signalRows, effectRows),
        (),
      )
    }
  }

  // Render component tree tab
  let renderComponentsTab = (): node => {
    let root: option<Dom.element> = %raw(`document.body`)
    switch root {
    | None =>
      Component.div(
        ~attrs=[attr("class", "xote-dt-empty")],
        ~children=[text("No document body found.")],
        (),
      )
    | Some(body) => {
        let components = inspectComponents(body)
        if components->Array.length == 0 {
          Component.div(
            ~attrs=[attr("class", "xote-dt-empty")],
            ~children=[text("No components with reactive state found.")],
            (),
          )
        } else {
          let rec renderNode = (node: componentNode): node => {
            let indent = String.repeat("  ", node.depth)
            let info =
              "effects:" ++
              Int.toString(node.effectCount) ++
              " computeds:" ++
              Int.toString(node.computedCount)

            Component.div(
              ~children=[
                Component.div(
                  ~attrs=[attr("class", "xote-dt-comp-row")],
                  ~children=[
                    text(indent),
                    Component.span(
                      ~attrs=[attr("class", "xote-dt-comp-tag")],
                      ~children=[text("<" ++ node.tag ++ ">")],
                      (),
                    ),
                    Component.span(
                      ~attrs=[attr("class", "xote-dt-comp-info")],
                      ~children=[text(info)],
                      (),
                    ),
                  ],
                  (),
                ),
                fragment(node.children->Array.map(renderNode)),
              ],
              (),
            )
          }

          Component.div(~children=components->Array.map(renderNode), ())
        }
      }
    }
  }

  // Helper to create an SVG element node
  let svgEl = (tag: string, ~attrs: array<(string, Component.attrValue)>=[], ~children: array<node>=[], ()): node => {
    Component.Element({tag, attrs, events: [], children})
  }

  // Render SVG graph tab using native Xote SVG elements
  let renderGraphTab = (): node => {
    let graph = buildGraph()
    if graph->Array.length == 0 {
      Component.div(
        ~attrs=[attr("class", "xote-dt-empty")],
        ~children=[text("No reactive primitives registered.")],
        (),
      )
    } else {
      let layout = GraphLayout.computeLayout(graph)
      let width = Math.max(layout.width, 400.0)
      let height = Math.max(layout.height, 200.0)

      let f = Float.toString

      // Build edge elements
      let edgeElements = layout.edges->Array.map(edge => {
        svgEl(
          "line",
          ~attrs=[
            attr("x1", f(edge.fromX)),
            attr("y1", f(edge.fromY)),
            attr("x2", f(edge.toX)),
            attr("y2", f(edge.toY)),
            attr("stroke", "#555"),
            attr("stroke-width", "1.5"),
            attr("marker-end", "url(#xdt-arrow)"),
          ],
          (),
        )
      })

      // Build node elements
      let nodeElements = layout.nodes->Array.flatMap(n => {
        let (fill, stroke) = switch n.kind {
        | #Signal => ("#1e3a5f", "#60a5fa")
        | #Computed => ("#1e3f2e", "#4ade80")
        | #Effect => ("#3f2e1e", "#fb923c")
        }

        let shape = switch n.kind {
        | #Computed => {
            let size = 18.0
            let points =
              f(n.x) ++ "," ++ f(n.y -. size) ++ " " ++
              f(n.x +. size) ++ "," ++ f(n.y) ++ " " ++
              f(n.x) ++ "," ++ f(n.y +. size) ++ " " ++
              f(n.x -. size) ++ "," ++ f(n.y)
            svgEl("polygon", ~attrs=[
              attr("points", points),
              attr("fill", fill),
              attr("stroke", stroke),
              attr("stroke-width", "2"),
            ], ())
          }
        | #Effect =>
          svgEl("rect", ~attrs=[
            attr("x", f(n.x -. 16.0)),
            attr("y", f(n.y -. 12.0)),
            attr("width", "32"),
            attr("height", "24"),
            attr("rx", "3"),
            attr("fill", fill),
            attr("stroke", stroke),
            attr("stroke-width", "2"),
          ], ())
        | #Signal =>
          svgEl("circle", ~attrs=[
            attr("cx", f(n.x)),
            attr("cy", f(n.y)),
            attr("r", "14"),
            attr("fill", fill),
            attr("stroke", stroke),
            attr("stroke-width", "2"),
          ], ())
        }

        let label = svgEl("text", ~attrs=[
          attr("x", f(n.x)),
          attr("y", f(n.y +. 28.0)),
          attr("text-anchor", "middle"),
          attr("fill", "#aaa"),
          attr("font-size", "10"),
          attr("font-family", "monospace"),
        ], ~children=[text(n.label)], ())

        [shape, label]
      })

      // Arrow marker definition
      let defs = svgEl("defs", ~children=[
        svgEl("marker", ~attrs=[
          attr("id", "xdt-arrow"),
          attr("markerWidth", "8"),
          attr("markerHeight", "6"),
          attr("refX", "8"),
          attr("refY", "3"),
          attr("orient", "auto"),
        ], ~children=[
          svgEl("polygon", ~attrs=[
            attr("points", "0 0, 8 3, 0 6"),
            attr("fill", "#555"),
          ], ())
        ], ())
      ], ())

      let allSvgChildren = Array.concat([defs], Array.concat(edgeElements, nodeElements))

      Component.div(
        ~attrs=[attr("class", "xote-dt-graph-container")],
        ~children=[
          Component.Element({
            tag: "svg",
            attrs: [
              attr("width", f(width)),
              attr("height", f(height)),
              attr("viewBox", "0 0 " ++ f(width) ++ " " ++ f(height)),
              attr("style", "background:#111;border-radius:4px"),
            ],
            events: [],
            children: allSvgChildren,
          }),
        ],
        (),
      )
    }
  }

  // Main panel component
  let renderPanel = (): node => {
    let visible = switch panelVisible.contents {
    | Some(s) => s
    | None => {
        let s = Signal.make(true)
        panelVisible := Some(s)
        s
      }
    }

    let tab = switch activeTab.contents {
    | Some(s) => s
    | None => {
        let s = Signal.make(Signals)
        activeTab := Some(s)
        s
      }
    }

    let counter = switch refreshCounter.contents {
    | Some(s) => s
    | None => {
        let s = Signal.make(0)
        refreshCounter := Some(s)
        s
      }
    }

    let handleClose = (_: Dom.event) => Signal.set(visible, false)
    let handleRefresh = (_: Dom.event) => Signal.update(counter, n => n + 1)
    let handleSignalsTab = (_: Dom.event) => Signal.set(tab, Signals)
    let handleGraphTab = (_: Dom.event) => Signal.set(tab, Graph)
    let handleComponentsTab = (_: Dom.event) => Signal.set(tab, Components)

    Component.div(
      ~attrs=[
        computedAttr("class", () =>
          "xote-devtools-panel" ++ (Signal.get(visible) ? "" : " hidden")
        ),
      ],
      ~children=[
        // Header
        Component.div(
          ~attrs=[attr("class", "xote-dt-header")],
          ~children=[
            Component.span(
              ~attrs=[attr("class", "xote-dt-title")],
              ~children=[text("XOTE DEVTOOLS")],
              (),
            ),
            Component.div(
              ~attrs=[attr("class", "xote-dt-controls")],
              ~children=[
                Component.button(
                  ~attrs=[attr("class", "xote-dt-btn")],
                  ~events=[("click", handleRefresh)],
                  ~children=[text("Refresh")],
                  (),
                ),
                Component.button(
                  ~attrs=[attr("class", "xote-dt-btn")],
                  ~events=[("click", handleClose)],
                  ~children=[text("x")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        // Tabs
        Component.div(
          ~attrs=[attr("class", "xote-dt-tabs")],
          ~children=[
            Component.button(
              ~attrs=[
                computedAttr("class", () =>
                  "xote-dt-tab" ++ (Signal.get(tab) == Signals ? " active" : "")
                ),
              ],
              ~events=[("click", handleSignalsTab)],
              ~children=[text("Signals")],
              (),
            ),
            Component.button(
              ~attrs=[
                computedAttr("class", () =>
                  "xote-dt-tab" ++ (Signal.get(tab) == Graph ? " active" : "")
                ),
              ],
              ~events=[("click", handleGraphTab)],
              ~children=[text("Graph")],
              (),
            ),
            Component.button(
              ~attrs=[
                computedAttr("class", () =>
                  "xote-dt-tab" ++ (Signal.get(tab) == Components ? " active" : "")
                ),
              ],
              ~events=[("click", handleComponentsTab)],
              ~children=[text("Components")],
              (),
            ),
          ],
          (),
        ),
        // Content area - reactive based on tab and refresh counter
        Component.signalFragment(
          Computed.make(() => {
            let _ = Signal.get(counter) // Subscribe to refresh
            let currentTab = Signal.get(tab)
            let content = switch currentTab {
            | Signals => renderSignalsTab()
            | Graph => renderGraphTab()
            | Components => renderComponentsTab()
            }
            [
              Component.div(
                ~attrs=[attr("class", "xote-dt-content")],
                ~children=[content],
                (),
              ),
            ]
          }),
        ),
      ],
      (),
    )
  }

  // Mount the SVG graph directly into a container element
  let mountGraph = (container: Dom.element): unit => {
    let graphNode = renderGraphTab()
    Component.mount(graphNode, container)
  }
}

// ============================================================================
// Public Mount / Toggle API
// ============================================================================

let mount = (): unit => {
  if !panelMounted.contents {
    panelMounted := true
    UI.injectStyles()

    let panel = UI.renderPanel()
    let container: Dom.element = %raw(`
      (function() {
        var el = document.createElement('div');
        el.id = 'xote-devtools-root';
        document.body.appendChild(el);
        return el;
      })()
    `)
    Component.mount(panel, container)

    // Register Ctrl+Shift+D keyboard shortcut
    %raw(`
      document.addEventListener('keydown', function(e) {
        if (e.ctrlKey && e.shiftKey && e.key === 'D') {
          e.preventDefault();
          var panel = document.querySelector('.xote-devtools-panel');
          if (panel) {
            panel.classList.toggle('hidden');
          }
        }
      })
    `)
  }
}

let toggle = (): unit => {
  switch panelVisible.contents {
  | Some(s) => Signal.update(s, v => !v)
  | None => mount()
  }
}

let show = (): unit => {
  if !panelMounted.contents {
    mount()
  }
  switch panelVisible.contents {
  | Some(s) => Signal.set(s, true)
  | None => ()
  }
}

let hide = (): unit => {
  switch panelVisible.contents {
  | Some(s) => Signal.set(s, false)
  | None => ()
  }
}
