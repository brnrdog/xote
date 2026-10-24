/* Public: an in-page devtools panel, built with Xote on top of `Devtools`.

   Everything the panel creates is made under `Devtools.mute`, so it never
   shows up in what it displays: its signals, effects, scopes and DOM writes
   are filtered out of snapshots, traces and the event stream. Events from the
   app are buffered as they arrive and applied once per animation frame, so the
   panel never writes a signal from inside the app's own update. It renders in
   a shadow root, so neither its styles nor the page's leak across.

   It shows no data the CLI cannot print: it reads `Devtools.snapshot`,
   `Devtools.why`, `Devtools.leaks` and the event stream, like `xote-lens`. */

type tab = Graph | Timeline | Scopes | Issues

type entry = {key: string, kind: string, text: string}

type picked = {path: string, writers: array<int>}

type state = {
  expanded: Signal.t<bool>,
  tab: Signal.t<tab>,
  version: Signal.t<int>,
  selected: Signal.t<option<int>>,
  filter: Signal.t<string>,
  log: Signal.t<array<entry>>,
  picking: Signal.t<bool>,
  picked: Signal.t<option<picked>>,
}

let logLimit = 300

/* ---- DOM glue ------------------------------------------------------------- */

/* Light and dark follow the page's colour scheme. */
let style = `
:host { all: initial; }
* { box-sizing: border-box; }
.launcher, .panel {
  --bg: #ffffff; --fg: #1d1b26; --muted: #6b6880; --line: #e4e2ee; --accent: #6a4cff;
  --row: #f5f4fa; --issue: #b42318; --write: #6a4cff; --dom: #087443; --scope: #8a5a00;
  font: 12px/1.45 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  color: var(--fg);
}
@media (prefers-color-scheme: dark) {
  .launcher, .panel {
    --bg: #17161d; --fg: #ecebf3; --muted: #9a97ad; --line: #2c2a36; --accent: #9d86ff;
    --row: #201f28; --issue: #ff8a7a; --write: #b3a1ff; --dom: #5fd49a; --scope: #f0c060;
  }
}
.launcher {
  position: fixed; right: 12px; bottom: 12px; z-index: 2147483647;
  background: var(--bg); border: 1px solid var(--line); border-radius: 999px;
  padding: 6px 12px; cursor: pointer; box-shadow: 0 4px 16px rgba(0,0,0,.15);
}
.panel {
  position: fixed; right: 12px; bottom: 12px; z-index: 2147483647;
  width: min(560px, calc(100vw - 24px)); height: min(70vh, 640px);
  display: flex; flex-direction: column; background: var(--bg);
  border: 1px solid var(--line); border-radius: 10px; overflow: hidden;
  box-shadow: 0 12px 40px rgba(0,0,0,.25);
}
header { display: flex; gap: 2px; padding: 6px; border-bottom: 1px solid var(--line); align-items: center; }
footer { padding: 4px 10px; border-top: 1px solid var(--line); color: var(--muted); }
main { flex: 1; overflow: auto; min-height: 0; }
button { font: inherit; color: inherit; background: none; border: 0; cursor: pointer; }
.tab, .icon, .small { padding: 4px 8px; border-radius: 6px; }
.tab[data-active="true"], .icon[data-active="true"] { background: var(--row); color: var(--accent); }
.spacer { flex: 1; }
.split { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1.2fr); height: 100%; }
.list { border-right: 1px solid var(--line); overflow: auto; }
.filter { width: 100%; padding: 6px 8px; border: 0; border-bottom: 1px solid var(--line); background: var(--bg); color: var(--fg); font: inherit; }
.row { display: block; width: 100%; text-align: left; padding: 3px 8px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.row[data-selected="true"] { background: var(--row); color: var(--accent); }
.detail { padding: 8px 10px; overflow: auto; }
.detail h3 { font-size: 13px; margin: 0 0 6px; word-break: break-all; }
.detail h4 { font-size: 12px; margin: 10px 0 4px; color: var(--muted); }
table { border-collapse: collapse; width: 100%; }
th { text-align: left; color: var(--muted); font-weight: normal; padding: 2px 8px 2px 0; vertical-align: top; width: 1%; white-space: nowrap; }
td { padding: 2px 0; word-break: break-all; }
.link { color: var(--accent); padding: 0 4px 0 0; text-align: left; }
.why, .why ul { list-style: none; margin: 0; padding-left: 14px; }
.why { padding-left: 0; }
.why li { position: relative; padding: 1px 0; }
.why ul li::before { content: "└ "; color: var(--muted); }
.site, .muted { color: var(--muted); }
.timeline, .scopes { padding: 4px 0; }
.timeline .small { margin: 0 6px 4px; }
.entry { padding: 1px 10px; white-space: pre-wrap; word-break: break-all; }
.entry.write { color: var(--write); }
.entry.dom { color: var(--dom); }
.entry.scope { color: var(--scope); }
.entry.issue { color: var(--issue); }
.entry.batch { color: var(--muted); }
.scope { padding: 1px 6px; }
.scope.released { color: var(--muted); text-decoration: line-through; }
p.muted { padding: 10px; margin: 0; }
`

let createHost: string => (Dom.element, Dom.element) = %raw(`function (css) {
  var host = document.createElement("div")
  host.id = "xote-devtools"
  var root = host.attachShadow ? host.attachShadow({ mode: "open" }) : host
  var style = document.createElement("style")
  style.textContent = css
  root.appendChild(style)
  var container = document.createElement("div")
  root.appendChild(container)
  return [host, container]
}`)

let appendTo: (
  Dom.element,
  Dom.element,
) => unit = %raw(`function (parent, child) { parent.appendChild(child) }`)
let removeNode: Dom.element => unit = %raw(`function (node) { if (node.parentNode) node.parentNode.removeChild(node) }`)
let body: unit => Dom.element = %raw(`function () { return document.body }`)

let nextFrame: (unit => unit) => unit = %raw(`function (fn) {
  if (typeof requestAnimationFrame === "function") requestAnimationFrame(function () { fn() })
  else setTimeout(fn, 16)
}`)

let inputValue: Dom.event => string = %raw(`function (event) { return event.target.value }`)

/* The element picker: highlight what the pointer is over, and hand the first
   click outside the panel to `onPick` instead of the page. Returns the
   function that stops picking. */
let startPicking: (
  Dom.element,
  Dom.element => unit,
) => unit => unit = %raw(`function (host, onPick) {
  var outline = document.createElement("div")
  outline.style.cssText = "position:fixed;pointer-events:none;z-index:2147483646;border:2px solid #7c5cff;background:rgba(124,92,255,.12);border-radius:2px;display:none"
  document.body.appendChild(outline)
  function inPanel(node) { return node === host || host.contains(node) }
  function move(event) {
    var target = event.target
    if (!target || inPanel(target) || !target.getBoundingClientRect) { outline.style.display = "none"; return }
    var r = target.getBoundingClientRect()
    outline.style.display = "block"
    outline.style.left = r.left + "px"; outline.style.top = r.top + "px"
    outline.style.width = r.width + "px"; outline.style.height = r.height + "px"
  }
  function click(event) {
    if (inPanel(event.target)) return
    event.preventDefault(); event.stopPropagation()
    stop()
    onPick(event.target)
  }
  function stop() {
    document.removeEventListener("mousemove", move, true)
    document.removeEventListener("click", click, true)
    if (outline.parentNode) outline.parentNode.removeChild(outline)
  }
  document.addEventListener("mousemove", move, true)
  document.addEventListener("click", click, true)
  return stop
}`)

/* Ctrl+Shift+X toggles the panel. */
let listenForToggle: (unit => unit) => unit => unit = %raw(`function (toggle) {
  function key(event) {
    if (event.ctrlKey && event.shiftKey && (event.key === "X" || event.key === "x")) { event.preventDefault(); toggle() }
  }
  document.addEventListener("keydown", key)
  return function () { document.removeEventListener("keydown", key) }
}`)

/* The element and its children: a binding writes either a text node or the
 element itself, when that text is its only child. */
let withChildren: Dom.element => array<Dom.element> = %raw(`function (element) {
  return [element].concat(Array.prototype.slice.call(element.childNodes))
}`)

/* ---- describing ---------------------------------------------------------------- */

let label = (id: int): string =>
  switch Devtools.inspect(id) {
  | Some({name: Some(name), kind}) => `${(kind :> string)} "${name}"`
  | Some({kind, binding: Some({what, target})}) =>
    `${(kind :> string)} #${Int.toString(id)} (${what} → ${target})`
  | Some({kind}) => `${(kind :> string)} #${Int.toString(id)}`
  | None => `#${Int.toString(id)}`
  }

let siteSuffix = (site: option<string>) =>
  switch site {
  | Some(site) => "  " ++ site
  | None => ""
  }

let describe = (event: Devtools.event): option<(string, string)> =>
  switch event {
  | Written({id, changed: true, site}) =>
    let value =
      Devtools.inspect(id)
      ->Option.flatMap(node => node.value)
      ->Option.mapOr("", value => " = " ++ value)
    Some(("write", `write ${label(id)}${value}${siteSuffix(site)}`))
  | RunStart({id}) => Some(("run", `run ${label(id)}`))
  | DomWrite({what, target}) => Some(("dom", `dom ${what} ${target}`))
  | Reconciled({kept, created, removed, moved, rebuilt}) =>
    Some((
      "keyed",
      `keyed pass: kept ${Int.toString(kept)}, created ${Int.toString(
          created,
        )}, removed ${Int.toString(removed)}, moved ${Int.toString(moved)}, rebuilt ${Int.toString(
          rebuilt,
        )}`,
    ))
  | ScopeCreated({kind, key}) =>
    Some(("scope", `scope + ${(kind :> string)}${key->Option.mapOr("", key => ` "${key}"`)}`))
  | ScopeDisposed({id}) => Some(("scope", `scope - ${Int.toString(id)}`))
  | BatchStart => Some(("batch", "batch {"))
  | BatchEnd => Some(("batch", "}"))
  | Caught({message}) => Some(("issue", `caught: ${message}`))
  | HydrationWarning({message}) => Some(("issue", `hydration: ${message}`))
  | Probe({site, hidden: true}) => Some(("issue", `hidden read: ${site}`))
  | StateRestored({key, found: false}) =>
    Some(("issue", `ssr state: "${key}" was restored on the client, but the server never sent it`))
  | StateRestored({key, decoded: false}) =>
    Some(("issue", `ssr state: "${key}" could not be decoded; the signal kept its initial value`))
  | StateRestored({key, node}) =>
    Some((
      "state",
      `ssr state: "${key}" restored${node->Option.mapOr("", id => " into " ++ label(id))}`,
    ))
  | _ => None
  }

/* ---- view helpers ---------------------------------------------------------------- */

let el = (tag, ~cls="", ~attrs=[], ~events=[], children) =>
  View.element(
    tag,
    ~attrs=cls == "" ? attrs : Array.concat([View.attr("class", cls)], attrs),
    ~events,
    ~children,
    (),
  )

let txt = View.text

let rec causeView = (cause: Devtools.cause): View.node => {
  let verb = switch cause.action {
  | #written => "written"
  | #recomputed => "recomputed"
  | #ran => "ran"
  | #created => "ran for the first time"
  }
  el(
    "li",
    [
      el("span", ~cls="cause", [txt(`${label(cause.id)} ${verb}`)]),
      el("span", ~cls="site", [txt(siteSuffix(cause.site))]),
      cause.causes->Array.length > 0 ? el("ul", cause.causes->Array.map(causeView)) : View.null(),
    ],
  )
}

let whyView = (id: int): View.node =>
  switch Devtools.why(id) {
  | Some(cause) => el("ul", ~cls="why", [causeView(cause)])
  | None => el("p", ~cls="muted", [txt("No run of this node is in the history yet.")])
  }

let nodeLink = (state: state, id: int) =>
  el(
    "button",
    ~cls="link",
    ~events=[
      (
        "click",
        _ => {
          Signal.set(state.selected, Some(id))
          Signal.set(state.tab, Graph)
        },
      ),
    ],
    [txt(label(id))],
  )

/* ---- tabs ---------------------------------------------------------------------- */

let detailView = (state: state) =>
  View.tracked(() => {
    let _ = Signal.get(state.version)
    switch (Signal.get(state.picked), Signal.get(state.selected)) {
    | (Some({path, writers}), None) =>
      el(
        "div",
        ~cls="detail",
        [
          el("h3", [txt(path)]),
          writers->Array.length == 0
            ? el(
                "p",
                ~cls="muted",
                [
                  txt(
                    "No binding writes this element: it never updates in place. If it should follow a signal, look for a one-shot prop or a hidden read.",
                  ),
                ],
              )
            : el(
                "div",
                writers->Array.map(writer => el("div", [nodeLink(state, writer), whyView(writer)])),
              ),
        ],
      )
    | (_, Some(id)) =>
      switch Devtools.inspect(id) {
      | None => el("div", ~cls="detail muted", [txt(`#${Int.toString(id)} is gone.`)])
      | Some(node) =>
        let row = (key, value) => el("tr", [el("th", [txt(key)]), el("td", [value])])
        el(
          "div",
          ~cls="detail",
          [
            el("h3", [txt(label(id))]),
            el(
              "table",
              [
                row("value", txt(node.value->Option.getOr("—"))),
                row("site", txt(node.site->Option.getOr("—"))),
                row(
                  "scope",
                  txt(
                    node.scope->Option.mapOr("none (created outside a render)", scope =>
                      Int.toString(scope)
                    ),
                  ),
                ),
                row("level", txt(Int.toString(node.level))),
                row(
                  "reads",
                  el("span", node.sources->Array.map(source => nodeLink(state, source))),
                ),
                row(
                  "read by",
                  el("span", node.observers->Array.map(observer => nodeLink(state, observer))),
                ),
              ]->Array.concat(node.disposed ? [row("state", txt("disposed"))] : []),
            ),
            el("h4", [txt("Why did it last run?")]),
            whyView(id),
          ],
        )
      }
    | (None, None) =>
      el(
        "p",
        ~cls="muted",
        [txt("Select a node, or pick an element on the page (⌖) to see why it updated.")],
      )
    }
  })

let graphTab = (state: state) => {
  let ids = Computed.make(() => {
    let _ = Signal.get(state.version)
    let filter = Signal.get(state.filter)->String.toLowerCase
    Devtools.snapshot().nodes
    ->Array.filter(node =>
      filter == "" ||
      String.includes(node.name->Option.getOr("")->String.toLowerCase, filter) ||
      String.includes((node.kind :> string), filter) ||
      Int.toString(node.id) == filter
    )
    ->Array.map(node => node.id)
  })
  el(
    "div",
    ~cls="split",
    [
      el(
        "div",
        ~cls="list",
        [
          el(
            "input",
            ~cls="filter",
            ~attrs=[View.attr("placeholder", "filter by name, kind or id")],
            ~events=[("input", event => Signal.set(state.filter, inputValue(event)))],
            [],
          ),
          View.eachWithKey(
            ids,
            id => Int.toString(id),
            id =>
              el(
                "button",
                ~cls="row",
                ~attrs=[
                  View.computedAttr("data-selected", () =>
                    Signal.get(state.selected) == Some(id) ? "true" : "false"
                  ),
                ],
                ~events=[
                  (
                    "click",
                    _ => {
                      Signal.set(state.picked, None)
                      Signal.set(state.selected, Some(id))
                    },
                  ),
                ],
                [
                  View.signalText(() => {
                    let _ = Signal.get(state.version)
                    let value =
                      Devtools.inspect(id)
                      ->Option.flatMap(node => node.value)
                      ->Option.mapOr("", value => " = " ++ value)
                    label(id) ++ value
                  }),
                ],
              ),
          ),
        ],
      ),
      detailView(state),
    ],
  )
}

let timelineTab = (state: state) =>
  el(
    "div",
    ~cls="timeline",
    [
      el(
        "button",
        ~cls="small",
        ~events=[
          (
            "click",
            _ => {
              Devtools.clearHistory()
              Signal.set(state.log, [])
            },
          ),
        ],
        [txt("Clear")],
      ),
      View.eachWithKey(
        state.log,
        entry => entry.key,
        entry => el("div", ~cls="entry " ++ entry.kind, [txt(entry.text)]),
      ),
    ],
  )

let scopesTab = (state: state) =>
  View.tracked(() => {
    let _ = Signal.get(state.version)
    let scopes = Devtools.scopes()
    let children = Map.make()
    scopes->Array.forEach(scope => {
      let parent = scope.parent->Option.getOr(0)
      switch children->Map.get(parent) {
      | Some(list) => list->Array.push(scope)->ignore
      | None => children->Map.set(parent, [scope])
      }
    })
    let rows = []
    let rec walk = (parent, depth) =>
      children
      ->Map.get(parent)
      ->Option.getOr([])
      ->Array.forEach(scope =>
        if Array.length(rows) < logLimit {
          rows
          ->Array.push(
            el(
              "div",
              ~cls=scope.disposed ? "scope released" : "scope",
              ~attrs=[View.attr("style", `padding-left: ${Int.toString(depth * 14 + 6)}px`)],
              [
                txt(
                  `${(scope.kind :> string)}${scope.key->Option.mapOr(
                      "",
                      key => ` "${key}"`,
                    )}  ${Int.toString(scope.id)}${scope.disposed ? " (released)" : ""}`,
                ),
              ],
            ),
          )
          ->ignore
          walk(scope.id, depth + 1)
        }
      )
    walk(0, 0)
    Array.length(rows) == 0
      ? el("p", ~cls="muted", [txt("No scopes yet.")])
      : el("div", ~cls="scopes", rows)
  })

let issuesTab = (state: state) =>
  View.tracked(() => {
    let _ = Signal.get(state.version)
    let leaks = Devtools.leaks()->Array.map(leak => {
      let reason = switch leak.reason {
      | #effectOutlivedScope => "still running after its scope was released"
      | #computedOutlivedScope => "still subscribed after its scope was released"
      | #unownedEffect => "created inside another run with no scope to own it"
      }
      el(
        "div",
        ~cls="entry issue",
        [nodeLink(state, leak.node), txt(` ${reason}${siteSuffix(leak.site)}`)],
      )
    })
    let issues =
      Signal.get(state.log)
      ->Array.filter(entry => entry.kind == "issue")
      ->Array.map(entry => el("div", ~cls="entry issue", [txt(entry.text)]))
    let all = Array.concat(leaks, issues)
    Array.length(all) == 0
      ? el(
          "p",
          ~cls="muted",
          [txt("No leaks, hidden reads, caught failures or hydration warnings.")],
        )
      : el("div", all)
  })

/* ---- the panel ---------------------------------------------------------------------- */

let tabButton = (state: state, tab: tab, name: string) =>
  el(
    "button",
    ~cls="tab",
    ~attrs=[
      View.computedAttr("data-active", () => Signal.get(state.tab) == tab ? "true" : "false"),
    ],
    ~events=[("click", _ => Signal.set(state.tab, tab))],
    [txt(name)],
  )

let panel = (state: state, ~host: Dom.element) => {
  let stopPicking = ref(() => ())
  let togglePicking = _ =>
    if Signal.peek(state.picking) {
      stopPicking.contents()
      Signal.set(state.picking, false)
    } else {
      Signal.set(state.picking, true)
      stopPicking :=
        startPicking(host, target =>
          Signal.batch(() => {
            let writers = withChildren(target)->Array.flatMap(Devtools.writersOf)
            Signal.set(state.picking, false)
            Signal.set(state.selected, None)
            Signal.set(state.picked, Some({path: Devtools.pathOf(target), writers}))
            Signal.set(state.tab, Graph)
          })
        )
    }
  View.tracked(() =>
    if !Signal.get(state.expanded) {
      el(
        "button",
        ~cls="launcher",
        ~attrs=[View.attr("title", "Xote devtools (Ctrl+Shift+X)")],
        ~events=[("click", _ => Signal.set(state.expanded, true))],
        [txt("◎ xote")],
      )
    } else {
      el(
        "div",
        ~cls="panel",
        [
          el(
            "header",
            [
              tabButton(state, Graph, "Graph"),
              tabButton(state, Timeline, "Timeline"),
              tabButton(state, Scopes, "Scopes"),
              tabButton(state, Issues, "Issues"),
              el("span", ~cls="spacer", []),
              el(
                "button",
                ~cls="icon",
                ~attrs=[
                  View.attr("title", "Pick an element"),
                  View.computedAttr("data-active", () =>
                    Signal.get(state.picking) ? "true" : "false"
                  ),
                ],
                ~events=[("click", togglePicking)],
                [txt("⌖")],
              ),
              el(
                "button",
                ~cls="icon",
                ~attrs=[View.attr("title", "Close (Ctrl+Shift+X)")],
                ~events=[("click", _ => Signal.set(state.expanded, false))],
                [txt("×")],
              ),
            ],
          ),
          el(
            "main",
            [
              View.tracked(() =>
                switch Signal.get(state.tab) {
                | Graph => graphTab(state)
                | Timeline => timelineTab(state)
                | Scopes => scopesTab(state)
                | Issues => issuesTab(state)
                }
              ),
            ],
          ),
          el(
            "footer",
            [
              View.signalText(() => {
                let _ = Signal.get(state.version)
                let status = Devtools.status()
                status.signals
                  ? `${Int.toString(Array.length(Devtools.snapshot().nodes))} nodes`
                  : "graph not visible: rescript-signals has no debug hooks"
              }),
            ],
          ),
        ],
      )
    }
  )
}

let mount = (~target: option<Dom.element>=?, ~expanded: bool=false, ()): (unit => unit) => {
  if !Devtools.installed() {
    let _ = Devtools.install()
  }
  let (host, container) = createHost(style)
  appendTo(target->Option.getOr(body()), host)
  let buffer = []
  let scheduled = ref(false)
  let counter = ref(0)

  let (state, mounted) = Devtools.mute(() => (
    {
      expanded: Signal.make(expanded),
      tab: Signal.make(Graph),
      version: Signal.make(0),
      selected: Signal.make(None),
      filter: Signal.make(""),
      log: Signal.make([]),
      picking: Signal.make(false),
      picked: Signal.make(None),
    },
    Signal.make(true),
  ))

  /* Muted as a whole: the batch below names no node, and would otherwise
   reach the subscriber and schedule this again, every frame. */
  let flush = () =>
    Devtools.mute(() => {
      scheduled := false
      let events = buffer->Array.copy
      buffer->Array.splice(~start=0, ~remove=Array.length(buffer), ~insert=[])
      let entries = []
      events->Array.forEach(event =>
        switch describe(event) {
        /* An empty batch says nothing. */
        | Some(("batch", "}"))
          if entries->Array.at(-1)->Option.map(entry => entry.text) == Some("batch {") =>
          let _ = entries->Array.pop
        | Some((kind, text)) => {
            counter := counter.contents + 1
            entries->Array.push({key: Int.toString(counter.contents), kind, text})->ignore
          }
        | None => ()
        }
      )
      Signal.batch(() => {
        if Array.length(entries) > 0 {
          Signal.update(
            state.log,
            log => {
              let next = Array.concat(log, entries)
              let excess = Array.length(next) - logLimit
              excess > 0 ? next->Array.slice(~start=excess) : next
            },
          )
        }
        Signal.update(state.version, v => v + 1)
      })
    })

  let unsubscribe = Devtools.subscribe(event => {
    buffer->Array.push(event)->ignore
    if !scheduled.contents {
      scheduled := true
      nextFrame(flush)
    }
  })
  let stopToggle = listenForToggle(() => Signal.update(state.expanded, open_ => !open_))

  Devtools.mute(() =>
    View.mount(
      View.tracked(() => Signal.get(mounted) ? panel(state, ~host) : View.null()),
      container,
    )
  )

  () => {
    unsubscribe()
    stopToggle()
    /* Releases the panel's reactive state with the pass that rendered it. */
    Signal.set(mounted, false)
    removeNode(host)
  }
}
