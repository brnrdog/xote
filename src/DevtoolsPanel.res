/* Public: an in-page devtools panel, built with Xote on top of `Devtools`.

   Everything the panel creates is made under `Devtools.mute`, so it never
   shows up in what it displays. Events from the app are buffered as they
   arrive and applied once per animation frame, so the panel never writes a
   signal from inside the app's own update. It renders in a shadow root, so
   neither its styles nor the page's leak across.

   The graph is a layered dependency diagram: signals on the left, what reads
   them to the right, down to the bindings that write the DOM. Its layout is
   recomputed only when the set of nodes or edges changes; values, selection
   and the pulse of a node that just ran are per-node signals, so a busy app
   does not redraw the diagram on every frame.

   It shows no data the CLI cannot print: it reads `Devtools.snapshot`,
   `Devtools.why`, `Devtools.leaks` and the event stream, like `xote-lens`. */

type tab = Graph | Timeline | Scopes | Issues

/* One line of the timeline. `node` is what the line is about, for a link. */
type entry = {key: string, kind: string, text: string, node: option<int>}

/* A top-level write (or batch) and everything it caused. */
type transaction = {
  key: string,
  title: string,
  summary: string,
  entries: array<entry>,
  node: option<int>,
}

type picked = {path: string, writers: array<int>}

type kinds = {signals: bool, computeds: bool, effects: bool, bindings: bool}

type state = {
  expanded: Signal.t<bool>,
  tab: Signal.t<tab>,
  /* Bumped once per frame that brought events: everything that reads the
   live graph re-reads on it. */
  version: Signal.t<int>,
  selected: Signal.t<option<int>>,
  hover: Signal.t<option<int>>,
  filter: Signal.t<string>,
  kinds: Signal.t<kinds>,
  scopeFilter: Signal.t<option<int>>,
  transactions: Signal.t<array<transaction>>,
  /* Nodes that ran or were written in the last few hundred milliseconds. */
  hot: Signal.t<Set.t<int>>,
  picking: Signal.t<bool>,
  picked: Signal.t<option<picked>>,
  /* Flash DOM nodes on the page as bindings write them. */
  highlight: Signal.t<bool>,
  zoom: Signal.t<float>,
  detailOpen: Signal.t<bool>,
  size: Signal.t<(int, int)>,
}

let transactionLimit = 200
let graphLimit = 400
let hotMs = 700

/* ---- DOM glue ------------------------------------------------------------- */

/* Light and dark follow the page's colour scheme. */
let style = `
:host { all: initial; }
* { box-sizing: border-box; }
.launcher, .panel {
  --bg: #fbfbfd; --bg2: #ffffff; --fg: #1b1a22; --muted: #6f6d80; --line: #e6e5ef; --row: #f2f1f8;
  --accent: #6a4cff; --signal: #7c5cff; --computed: #2f7df6; --effect: #d9861a; --binding: #159a66;
  --issue: #d13c2a; --warn: #b7791f; --hot: #ff6b3d; --edge: #c9c7d6; --shadow: 0 16px 48px rgba(20,16,50,.22);
  font: 12px/1.45 "DM Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; color: var(--fg);
  position: fixed; right: 12px; bottom: 12px; z-index: 2147483647; display: flex;
  background: var(--bg); border: 1px solid var(--line); box-shadow: var(--shadow);
}
@media (prefers-color-scheme: dark) {
  .launcher, .panel {
    --bg: #141319; --bg2: #1a1921; --fg: #ecebf3; --muted: #9a97ad; --line: #2a2834; --row: #1f1e28;
    --accent: #a08cff; --signal: #a994ff; --computed: #6ea8ff; --effect: #f0b25a; --binding: #5fd49a;
    --issue: #ff8a7a; --warn: #f0c060; --hot: #ff8a5c; --edge: #3b394a; --shadow: 0 16px 48px rgba(0,0,0,.5);
  }
}
.launcher { align-items: center; gap: 6px; border-radius: 999px; padding: 6px 12px 6px 10px; cursor: pointer; }
.panel { flex-direction: column; border-radius: 12px; overflow: hidden; max-width: calc(100vw - 24px); max-height: calc(100vh - 24px); }
.dot { width: 8px; height: 8px; border-radius: 50%; background: var(--binding); } .dot.off { background: var(--muted); }
.badge, .tab .count { background: var(--issue); color: #fff; border-radius: 999px; padding: 0 6px; font-size: 10px; }
.resize { position: absolute; left: 0; top: 0; width: 14px; height: 14px; cursor: nwse-resize; z-index: 2; }
.resize::after { content: ""; position: absolute; left: 3px; top: 3px; width: 6px; height: 6px; border-left: 2px solid var(--muted); border-top: 2px solid var(--muted); opacity: .6; }
header, footer { display: flex; background: var(--bg2); }
header { gap: 2px; padding: 6px 8px 6px 18px; border-bottom: 1px solid var(--line); align-items: center; }
footer { gap: 12px; padding: 4px 12px; border-top: 1px solid var(--line); color: var(--muted); white-space: nowrap; overflow: hidden; }
main { flex: 1; overflow: hidden; min-height: 0; display: flex; flex-direction: column; }
button { font: inherit; color: inherit; background: none; border: 0; cursor: pointer; }
input { font: inherit; color: var(--fg); }
.brand { display: flex; align-items: center; gap: 6px; margin-right: 10px; font-weight: 600; }
.tabs { display: flex; gap: 2px; background: var(--row); border-radius: 8px; padding: 2px; }
.tab { padding: 3px 10px; border-radius: 6px; color: var(--muted); display: flex; gap: 6px; align-items: center; }
.tab[data-active="true"] { background: var(--bg2); color: var(--fg); box-shadow: 0 1px 2px rgba(0,0,0,.12); }
.tab .count { padding: 0 5px; line-height: 15px; }
.spacer { flex: 1; }
.icon { width: 26px; height: 26px; border-radius: 6px; display: inline-flex; align-items: center; justify-content: center; color: var(--muted); font-size: 14px; }
.icon:hover { background: var(--row); color: var(--fg); } .icon[data-active="true"] { background: var(--accent); color: #fff; }
.toolbar { display: flex; gap: 6px; align-items: center; padding: 6px 8px; border-bottom: 1px solid var(--line); flex-wrap: wrap; }
.toolbar input { flex: 1; min-width: 120px; padding: 4px 8px; border: 1px solid var(--line); border-radius: 6px; background: var(--bg2); }
.chip { display: inline-flex; align-items: center; gap: 5px; padding: 2px 8px; border-radius: 999px; border: 1px solid var(--line); color: var(--muted); }
.chip .sw { width: 8px; height: 8px; border-radius: 50%; background: var(--c); }
.chip[data-on="true"] { color: var(--fg); border-color: var(--c); background: color-mix(in srgb, var(--c) 10%, transparent); }
.chip.x { color: var(--fg); border-color: var(--accent); }
.zoom { display: inline-flex; border: 1px solid var(--line); border-radius: 6px; overflow: hidden; }
.zoom button { padding: 2px 7px; } .zoom button + button { border-left: 1px solid var(--line); }
.body { flex: 1; min-height: 0; display: grid; grid-template-columns: minmax(0, 1fr); }
.body[data-detail="true"] { grid-template-columns: minmax(0, 1fr) minmax(0, 300px); }
.graph { display: flex; flex-direction: column; min-height: 0; min-width: 0; }
.canvas { overflow: auto; position: relative; background: radial-gradient(var(--line) 1px, transparent 1px) 0 0 / 18px 18px; }
.canvas svg { display: block; }
.empty { padding: 16px; color: var(--muted); }
[data-kind="signal"] { --c: var(--signal); } [data-kind="computed"] { --c: var(--computed); }
[data-kind="effect"] { --c: var(--effect); } [data-kind="binding"] { --c: var(--binding); }
.gedge { fill: none; stroke: var(--edge); stroke-width: 1.2; transition: stroke .15s, opacity .15s; }
.gedge.lit { stroke: var(--accent); stroke-width: 1.8; } .gedge.dim { opacity: .25; }
.gnode { cursor: pointer; transition: opacity .15s; } .gnode.dim { opacity: .3; }
.gnode rect.box { fill: var(--bg2); stroke: var(--c); stroke-width: 1.2; rx: 6; transition: stroke-width .15s; }
.gnode.hot rect.box { stroke: var(--hot); stroke-width: 2.4; fill: color-mix(in srgb, var(--hot) 14%, var(--bg2)); }
.gnode.selected rect.box { stroke-width: 2.4; fill: color-mix(in srgb, var(--c) 12%, var(--bg2)); }
.gnode.lit rect.box { stroke-width: 2; }
.gnode .glyph { fill: var(--c); font-size: 11px; font-weight: 700; }
.gnode .label { fill: var(--fg); font-size: 11px; }
.gnode .value { fill: var(--muted); font-size: 10px; }
.detail { border-left: 1px solid var(--line); overflow: auto; padding: 10px 12px; background: var(--bg2); }
.detail h3 { font-size: 12px; margin: 0 0 8px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; word-break: break-all; }
.detail h4 { font-size: 11px; margin: 12px 0 4px; color: var(--muted); text-transform: uppercase; letter-spacing: .04em; }
.pill { display: inline-block; padding: 0 7px; border-radius: 999px; font-size: 10px; line-height: 16px; color: #fff; background: var(--c); }
table { border-collapse: collapse; width: 100%; }
th { text-align: left; color: var(--muted); font-weight: normal; padding: 2px 8px 2px 0; vertical-align: top; width: 1%; white-space: nowrap; }
td { padding: 2px 0; word-break: break-all; }
.link { color: var(--accent); padding: 0; text-align: left; } .link:hover { text-decoration: underline; }
.small { padding: 2px 8px; border: 1px solid var(--line); border-radius: 6px; color: var(--muted); }
.small:hover { color: var(--fg); background: var(--row); } .value { font-weight: 500; }
.why, .why ul { list-style: none; margin: 0; padding-left: 14px; } .why { padding-left: 0; }
.why li { padding: 1px 0; } .why ul li::before { content: "└ "; color: var(--muted); }
.site, .muted { color: var(--muted); }
.timeline, .scopes, .issues { overflow: auto; flex: 1; }
.timeline { padding: 6px 8px; } .scopes { padding: 6px 0; } .issues { padding: 8px; }
.timeline-head { display: flex; gap: 8px; align-items: center; margin-bottom: 6px; }
.tx { border: 1px solid var(--line); border-radius: 8px; margin-bottom: 6px; background: var(--bg2); }
.tx summary { cursor: pointer; padding: 5px 8px; display: flex; gap: 8px; align-items: baseline; list-style: none; }
.tx summary::-webkit-details-marker { display: none; }
.tx summary .title { color: var(--signal); font-weight: 500; flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tx summary .sum { color: var(--muted); white-space: nowrap; }
.tx[data-issue="true"] summary .title { color: var(--issue); }
.tx .entries { padding: 2px 8px 6px; border-top: 1px solid var(--line); }
.entry { padding: 1px 0; white-space: pre-wrap; word-break: break-all; }
.entry.write { color: var(--signal); } .entry.dom { color: var(--binding); } .entry.keyed { color: var(--computed); }
.entry.scope { color: var(--warn); } .entry.issue { color: var(--issue); } .entry.batch, .entry.run { color: var(--muted); }
.entry .link { color: inherit; }
.scope { display: flex; gap: 8px; width: 100%; text-align: left; padding: 2px 10px; }
.scope:hover { background: var(--row); } .scope .k { color: var(--warn); }
.scope .n, .scope.released, .scope.released .k { color: var(--muted); }
.scope.released .k { text-decoration: line-through; }
.issue-card { border-left: 3px solid var(--issue); background: var(--bg2); border-radius: 6px; padding: 6px 10px; margin-bottom: 6px; }
.issue-card .what { color: var(--issue); font-weight: 500; }
p.muted { padding: 12px; margin: 0; }
`

/* The shadow host, appended to `target` (default: the body), and the element
 to render into. */
let createHost: (
  string,
  option<Dom.element>,
) => (Dom.element, Dom.element) = %raw(`function (css, target) {
  var host = document.createElement("div");
  host.id = "xote-devtools";
  var root = host.attachShadow ? host.attachShadow({ mode: "open" }) : host;
  var style = document.createElement("style");
  style.textContent = css;
  var container = document.createElement("div");
  root.appendChild(style);
  root.appendChild(container);
  (target || document.body).appendChild(host);
  return [host, container];
}`)

let removeNode: Dom.element => unit = %raw(`function (node) { if (node.parentNode) node.parentNode.removeChild(node) }`)

let nextFrame: (unit => unit) => unit = %raw(`function (fn) {
  typeof requestAnimationFrame === "function" ? requestAnimationFrame(function () { fn() }) : setTimeout(fn, 16)
}`)

let inputValue: Dom.event => string = %raw(`function (event) { return event.target.value }`)

/* One overlay for the page: the picker's hover and a binding's target under
 the pointer. */
let showOutline: (Dom.element, string) => unit = %raw(`function (el, color) {
  if (!el || !el.getBoundingClientRect) return
  var box = document.getElementById("xote-devtools-outline")
  if (!box) {
    box = document.createElement("div")
    box.id = "xote-devtools-outline"
    box.style.cssText = "position:fixed;pointer-events:none;z-index:2147483646;border-radius:3px;transition:opacity .12s"
    document.body.appendChild(box)
  }
  var r = el.getBoundingClientRect()
  Object.assign(box.style, {
    display: "block", opacity: "1", border: "2px solid " + color,
    background: color.replace("rgb(", "rgba(").replace(")", ",.12)"),
    left: r.left - 2 + "px", top: r.top - 2 + "px", width: r.width + 4 + "px", height: r.height + 4 + "px"
  })
}`)

let hideOutline: unit => unit = %raw(`function () {
  var box = document.getElementById("xote-devtools-outline"); if (box) box.style.display = "none"
}`)

/* A short-lived highlight over a node a binding just wrote. */
let flashElement: Dom.element => unit = %raw(`function (el) {
  var node = el && el.nodeType === 3 ? el.parentNode : el
  if (!node || !node.getBoundingClientRect) return
  var r = node.getBoundingClientRect()
  if (r.width === 0 && r.height === 0) return
  var box = document.createElement("div")
  box.style.cssText = "position:fixed;pointer-events:none;z-index:2147483645;border:2px solid rgb(255,107,61);background:rgba(255,107,61,.18);border-radius:3px;transition:opacity .5s ease-out"
  Object.assign(box.style, { left: r.left - 1 + "px", top: r.top - 1 + "px", width: r.width + 2 + "px", height: r.height + 2 + "px" })
  document.body.appendChild(box)
  setTimeout(function () { box.style.opacity = "0" }, 80)
  setTimeout(function () { if (box.parentNode) box.parentNode.removeChild(box) }, 650)
}`)

let revealElement: Dom.element => unit = %raw(`function (el) {
  var node = el && el.nodeType === 3 ? el.parentNode : el
  if (node && node.scrollIntoView) node.scrollIntoView({ block: "center", inline: "nearest" })
}`)

/* The element picker: `show` what the pointer is over, and hand the first
   click outside the panel to `onPick` instead of the page. Returns the
   function that stops picking. */
let startPicking: (
  Dom.element,
  Dom.element => unit,
  Dom.element => unit,
  unit => unit,
) => unit => unit = %raw(`function (host, onPick, show, hide) {
  function inPanel(node) { return node === host || host.contains(node) }
  function move(event) {
    var target = event.target
    if (target && !inPanel(target) && target.getBoundingClientRect) show(target); else hide()
  }
  function click(event) {
    if (inPanel(event.target)) return
    event.preventDefault(); event.stopPropagation()
    stop()
    onPick(event.target)
  }
  function key(event) { if (event.key === "Escape") stop() }
  var listeners = { mousemove: move, click: click, keydown: key }
  function stop() {
    for (var type in listeners) document.removeEventListener(type, listeners[type], true)
    hide()
  }
  for (var type in listeners) document.addEventListener(type, listeners[type], true)
  return stop
}`)

/* Ctrl+Shift+X toggles the panel. */
let listenForToggle: (unit => unit) => unit => unit = %raw(`function (toggle) {
  function key(e) { if (e.ctrlKey && e.shiftKey && (e.key === "X" || e.key === "x")) { e.preventDefault(); toggle() } }
  document.addEventListener("keydown", key)
  return function () { document.removeEventListener("keydown", key) }
}`)

/* Drag the panel's top-left corner to resize it. */
let startResize: (Dom.event, ((int, int)) => unit) => unit = %raw(`function (event, onSize) {
  event.preventDefault()
  var panel = event.target.parentNode
  var startX = event.clientX, startY = event.clientY
  var startW = panel.offsetWidth, startH = panel.offsetHeight
  function move(e) { onSize([Math.max(420, startW + startX - e.clientX), Math.max(260, startH + startY - e.clientY)]) }
  function up() { document.removeEventListener("mousemove", move); document.removeEventListener("mouseup", up) }
  document.addEventListener("mousemove", move)
  document.addEventListener("mouseup", up)
}`)

let loadSize: unit => option<(int, int)> = %raw(`function () {
  try { var size = JSON.parse(localStorage.getItem("xote-devtools.size")) } catch (_) {}
  return Array.isArray(size) && size.length === 2 ? size : undefined
}`)

let saveSize: ((int, int)) => unit = %raw(`function (size) {
  try { localStorage.setItem("xote-devtools.size", JSON.stringify(size)) } catch (_) {}
}`)

/* The element and its children: a binding writes either a text node or the
 element itself, when that text is its only child. */
let withChildren: Dom.element => array<Dom.element> = %raw(`function (element) {
  return [element].concat(Array.from(element.childNodes))
}`)

/* ---- describing ----------------------------------------------------------- */

/* A binding is an effect the renderer made to write the DOM; it is shown as
 its own kind. */
let kindOf = (node: Devtools.node): string =>
  switch node {
  | {binding: Some(_)} => "binding"
  | {kind} => (kind :> string)
  }

let glyphOf = (kind: string): string =>
  switch kind {
  | "signal" => "◆"
  | "computed" => "ƒ"
  | "effect" => "↯"
  | _ => "▣"
  }

let hash = (id: int) => "#" ++ Int.toString(id)
let quotedKey = (key: option<string>) => key->Option.mapOr("", key => ` "${key}"`)
let plural = (n: int, word: string) => `${Int.toString(n)} ${word}${n == 1 ? "" : "s"}`
let currentValue = (id: int) => Devtools.inspect(id)->Option.flatMap(node => node.value)

/* The last step of a DOM path: `div.counter-demo-value`. */
let lastStep = (path: string): string => path->String.split(" > ")->Array.at(-1)->Option.getOr(path)

/* `src/demos/CounterDemo.res.mjs:3:14` → `CounterDemo:3`. */
let shortSite = (site: string): string => {
  let parts = site->String.split(":")
  let file = parts->Array.getUnsafe(0)
  let base = file->String.split("/")->Array.at(-1)->Option.getOr(file)
  let base =
    base->String.replace(".res.mjs", "")->String.replace(".mjs", "")->String.replace(".js", "")
  switch parts[1] {
  | Some(line) if line != "" => `${base}:${line}`
  | _ => base
  }
}

/* A name when there is one; else where the node was made; else its id. */
let shortLabel = (node: Devtools.node): string =>
  switch node {
  | {name: Some(name)} => name
  | {binding: Some({what, target})} => `${what} → ${lastStep(target)}`
  | {site: Some(site)} => shortSite(site)
  | {id} => hash(id)
  }

/* What a signal or computed holds, short enough for the diagram. */
let inlineValue = (node: Devtools.node): string =>
  switch node {
  | {kind: #signal | #computed, value: Some(value)} => " = " ++ value
  | _ => ""
  }

/* How a node is named in text: its kind, then its name, else its creation
 site, else its id. */
let label = (id: int): string =>
  switch Devtools.inspect(id) {
  | Some({name: Some(name), kind}) => `${(kind :> string)} "${name}"`
  | Some({kind, binding: Some({what, target})}) =>
    `${(kind :> string)} ${hash(id)} (${what} → ${target})`
  | Some({kind, site: Some(site)}) => `${(kind :> string)} ${shortSite(site)}`
  | Some({kind}) => `${(kind :> string)} ${hash(id)}`
  | None => hash(id)
  }

let siteSuffix = (site: option<string>) => site->Option.mapOr("", site => "  " ++ site)

let scopeLabel = (scope: Devtools.scope) =>
  `${(scope.kind :> string)}${quotedKey(scope.key)} ${hash(scope.id)}`

/* An event as a timeline line: its kind, its text and the node it is about. */
let describe = (event: Devtools.event): option<(string, string, option<int>)> =>
  switch event {
  | Written({id, changed: true, site}) =>
    let value = currentValue(id)->Option.mapOr("", value => " = " ++ value)
    Some(("write", `write ${label(id)}${value}${siteSuffix(site)}`, Some(id)))
  | RunStart({id}) => Some(("run", `run ${label(id)}`, Some(id)))
  | DomWrite({what, target, node}) => Some(("dom", `dom ${what} ${target}`, node))
  | Reconciled({kept, created, removed, moved, rebuilt}) =>
    let n = Int.toString
    let counts = `kept ${n(kept)}, created ${n(created)}, removed ${n(removed)}`
    Some(("keyed", `keyed pass: ${counts}, moved ${n(moved)}, rebuilt ${n(rebuilt)}`, None))
  | ScopeCreated({kind, key}) =>
    Some(("scope", `scope + ${(kind :> string)}${quotedKey(key)}`, None))
  | ScopeDisposed({id}) => Some(("scope", `scope - ${Int.toString(id)}`, None))
  | BatchStart => Some(("batch", "batch {", None))
  | BatchEnd => Some(("batch", "}", None))
  | Caught({message}) => Some(("issue", `caught: ${message}`, None))
  | HydrationWarning({message}) => Some(("issue", `hydration: ${message}`, None))
  | Probe({site, hidden: true}) => Some(("issue", `hidden read: ${site}`, None))
  | StateRestored({key, found, decoded, node}) =>
    let (kind, text) = switch (found, decoded) {
    | (false, _) => ("issue", "was restored on the client, but the server never sent it")
    | (_, false) => ("issue", "could not be decoded; the signal kept its initial value")
    | _ => ("state", "restored" ++ node->Option.mapOr("", id => " into " ++ label(id)))
    }
    Some((kind, `ssr state: "${key}" ${text}`, node))
  | _ => None
  }

/* ---- the graph layout ----------------------------------------------------- */

type gnode = {
  id: int,
  kind: string,
  text: string,
  /* How many characters of the value fit after the label. */
  valueChars: int,
  x: int,
  y: int,
  w: int,
  sources: array<int>,
}

type gedge = {ekey: string, from: int, to: int}

type layout = {
  /* Changes exactly when the diagram must be redrawn. */
  signature: string,
  nodes: array<gnode>,
  edges: array<gedge>,
  width: int,
  height: int,
  total: int,
}

let rowH = 34
let colW = 262
let nodeH = 24
let margin = 18
let labelMax = 20
let totalMax = 30

/* 11px monospace runs close to 7px a character, plus the glyph and padding. */
let textWidth = (chars: int): int => Math.Int.max(70, 32 + chars * 7)

let clip = (text: string, max: int): string =>
  if max < 4 {
    ""
  } else if String.length(text) > max {
    String.slice(text, ~start=0, ~end=max - 1) ++ "…"
  } else {
    text
  }

/* Columns by dependency depth (ids are assigned in creation order, and a
   node is created after what it reads, so one pass in id order is enough);
   rows by the average row of a node's sources, which keeps edges short. */
let computeLayout = (nodes: array<Devtools.node>, ~shows: Devtools.node => bool): layout => {
  let shown = nodes->Array.filter(shows)->Array.slice(~start=0, ~end=graphLimit)
  let ids = Set.fromArray(shown->Array.map(node => node.id))
  let column = Map.make()
  let columns: array<array<Devtools.node>> = []
  shown
  ->Array.toSorted((a, b) => Int.toFloat(a.id - b.id))
  ->Array.forEach(node => {
    let c =
      node.sources->Array.reduce(-1, (deepest, source) =>
        Math.Int.max(deepest, column->Map.get(source)->Option.getOr(-1))
      ) + 1
    column->Map.set(node.id, c)
    while Array.length(columns) <= c {
      columns->Array.push([])
    }
    columns->Array.getUnsafe(c)->Array.push(node)
  })
  let row = Map.make()
  let gnodes = []
  columns->Array.forEachWithIndex((members, c) =>
    members
    ->Array.map(node => {
      let rows = node.sources->Array.filterMap(source => row->Map.get(source))
      let center = switch rows {
      | [] => Int.toFloat(node.id)
      | rows =>
        rows->Array.reduce(0., (a, b) => a +. Int.toFloat(b)) /. Int.toFloat(Array.length(rows))
      }
      (center, node)
    })
    ->Array.toSorted(((a, na), (b, nb)) => a == b ? Int.toFloat(na.id - nb.id) : a -. b)
    ->Array.forEachWithIndex(((_, node), r) => {
      row->Map.set(node.id, r)
      let text = clip(shortLabel(node), labelMax)
      let valueChars = totalMax - String.length(text)
      let value = clip(inlineValue(node), valueChars)
      gnodes->Array.push({
        id: node.id,
        kind: kindOf(node),
        text,
        valueChars: value == "" ? 0 : valueChars,
        x: margin + c * colW,
        y: margin + r * rowH,
        w: textWidth(String.length(text) + String.length(value)),
        sources: node.sources->Array.filter(source => ids->Set.has(source)),
      })
    })
  )
  let edges = gnodes->Array.flatMap(node =>
    node.sources->Array.map(source => {
      ekey: `${Int.toString(source)}-${Int.toString(node.id)}`,
      from: source,
      to: node.id,
    })
  )
  let maxRows =
    columns->Array.reduce(0, (most, members) => Math.Int.max(most, Array.length(members)))
  {
    signature: gnodes->Array.map(n => Int.toString(n.id) ++ n.text)->Array.join(",") ++
    "|" ++
    edges->Array.map(e => e.ekey)->Array.join(","),
    nodes: gnodes,
    edges,
    width: margin * 2 + Array.length(columns) * colW,
    height: margin * 2 + maxRows * rowH,
    total: Array.length(nodes),
  }
}

/* ---- view helpers --------------------------------------------------------- */

let txt = View.text
let flag = (on: bool) => on ? "true" : "false"
let note = (~cls="muted", text) => <p class={cls}> {txt(text)} </p>
let spacer = () => <span class="spacer" />
let kindPill = (kind: string) => <span class="pill" attrs=[("data-kind", kind)]> {txt(kind)} </span>

let iconButton = (glyph, ~title, ~active=?, onClick) =>
  <button
    class="icon"
    title
    attrs={active->Option.mapOr([], active => [("data-active", () => flag(active()))])}
    onClick
  >
    {txt(glyph)}
  </button>

/* A count, shown only when it is above zero. */
let countBadge = (cls, count: Signal.t<int>) =>
  View.tracked(() => {
    let n = Signal.get(count)
    n > 0 ? <span class={cls}> {txt(Int.toString(n))} </span> : View.null()
  })

/* `read`, re-run on every frame that brought events. */
let live = (state: state, read) =>
  () => {
    let _ = Signal.get(state.version)
    read()
  }
let liveView = (state: state, view) => View.tracked(live(state, view))

/* Scope `child` is `ancestor` or sits under it. */
let rec underScope = (scopes: Map.t<int, Devtools.scope>, child: int, ancestor: int, depth: int) =>
  child == ancestor ||
    (depth < 64 &&
      switch scopes->Map.get(child)->Option.flatMap(scope => scope.parent) {
      | Some(parent) => underScope(scopes, parent, ancestor, depth + 1)
      | None => false
      })

let selectNode = (state: state, id: int) =>
  Signal.batch(() => {
    Signal.set(state.picked, None)
    Signal.set(state.selected, Some(id))
    Signal.set(state.detailOpen, true)
    Signal.set(state.tab, Graph)
  })

let filterScope = (state: state, id: int) =>
  Signal.batch(() => {
    Signal.set(state.scopeFilter, Some(id))
    Signal.set(state.tab, Graph)
  })

/* `text` as a link that selects node `id`. */
let link = (state: state, ~cls="link", id: int, text: string) =>
  <button class={cls} onClick={_ => selectNode(state, id)}> {txt(text)} </button>

let nodeLink = (state: state, id: int) => link(state, id, label(id))

let textOrLink = (state: state, text: string, node: option<int>) =>
  node->Option.mapOr(txt(text), id => link(state, id, text))

let rec causeView = (state: state, cause: Devtools.cause): View.node => {
  let verb = switch cause.action {
  | #written => "written"
  | #recomputed => "recomputed"
  | #ran => "ran"
  | #created => "ran for the first time"
  }
  <li>
    {link(state, ~cls="link cause", cause.id, `${label(cause.id)} ${verb}`)}
    <span class="site"> {txt(siteSuffix(cause.site))} </span>
    {cause.causes == []
      ? View.null()
      : <ul> {cause.causes->Array.map(causeView(state, ...))->View.fragment} </ul>}
  </li>
}

let whyView = (state: state, id: int): View.node =>
  switch Devtools.why(id) {
  | Some(cause) => <ul class="why"> {causeView(state, cause)} </ul>
  | None => note("No run of this node is in the history yet.")
  }

let reveal = (id: int) =>
  Devtools.targetOf(id)->Option.forEach(element => {
    revealElement(element)
    flashElement(element)
  })

/* ---- detail pane ---------------------------------------------------------- */

let detailHeader = (state: state, kind: string, title: string) =>
  <h3>
    {kindPill(kind)}
    {txt(title)}
    {spacer()}
    {iconButton("×", ~title="Close", _ => Signal.set(state.detailOpen, false))}
  </h3>

let nodeDetail = (state: state, id: int) =>
  switch Devtools.inspect(id) {
  | None => <div class="muted"> {txt(`${hash(id)} is gone.`)} </div>
  | Some(node) =>
    let row = (key, value) =>
      <tr>
        <th> {txt(key)} </th>
        <td> {value} </td>
      </tr>
    let links = ids =>
      ids == []
        ? txt("—")
        : <span>
            {ids->Array.flatMap(other => [nodeLink(state, other), txt("  ")])->View.fragment}
          </span>
    let writes = switch node.binding {
    | Some({what, target}) => [
        row(
          "writes",
          <span>
            {txt(`${what} of `)}
            <span class="value"> {txt(target)} </span>
            {txt("  ")}
            <button
              class="small" title="Scroll the page to it and flash it" onClick={_ => reveal(id)}
            >
              {txt("reveal")}
            </button>
          </span>,
        ),
      ]
    | None => []
    }
    let scope = switch node.scope {
    | Some(scope) =>
      let name =
        Devtools.scopes()->Array.find(s => s.id == scope)->Option.mapOr(hash(scope), scopeLabel)
      <button
        class="link"
        title="Show only this scope in the graph"
        onClick={_ => filterScope(state, scope)}
      >
        {txt(name)}
      </button>
    | None => txt("none (created outside a render)")
    }
    let title = switch node {
    | {name: Some(name)} => name
    | {site: Some(site)} => `${shortSite(site)}  ${hash(id)}`
    | _ => hash(id)
    }
    <div>
      {detailHeader(state, kindOf(node), title)}
      <table>
        {[
          ...writes,
          row("value", <span class="value"> {txt(node.value->Option.getOr("—"))} </span>),
          row("site", txt(node.site->Option.getOr("—"))),
          row("scope", scope),
          row("level", txt(Int.toString(node.level))),
          row("reads", links(node.sources)),
          row("read by", links(node.observers)),
          ...node.disposed ? [row("state", txt("disposed"))] : [],
        ]->View.fragment}
      </table>
      <h4> {txt("Why did it last run?")} </h4>
      {whyView(state, id)}
    </div>
  }

let pickedDetail = (state: state, {path, writers}: picked) =>
  <div>
    {detailHeader(state, "binding", path)}
    {writers == []
      ? note(
          "No binding writes this element, so it never updates in place. If it should follow a signal, look for a one-shot prop or a hidden read.",
        )
      : <div>
          {writers
          ->Array.map(writer =>
            <div>
              <h4> {nodeLink(state, writer)} </h4>
              {whyView(state, writer)}
            </div>
          )
          ->View.fragment}
        </div>}
  </div>

let detailPane = (state: state) =>
  liveView(state, () =>
    switch (Signal.get(state.picked), Signal.get(state.selected)) {
    | (Some(picked), None) => pickedDetail(state, picked)
    | (_, Some(id)) => nodeDetail(state, id)
    | (None, None) =>
      note(
        "Select a node to see its value, what it reads, what reads it, and why it last ran. Pick an element on the page (⌖) to find the bindings that write it.",
      )
    }
  )

/* ---- graph tab ------------------------------------------------------------ */

let graphView = (state: state, layout: Signal.t<layout>) => {
  let nodes = Computed.make(() => Signal.get(layout).nodes)
  let edges = Computed.make(() => Signal.get(layout).edges)
  let positions = Computed.make(() =>
    Map.fromArray(Signal.get(layout).nodes->Array.map(node => (node.id, node)))
  )
  /* What is lit: the hovered node (or the selection) and its neighbours. */
  let focus = Computed.make(() => {
    let around = switch Signal.get(state.hover) {
    | Some(id) => Some(id)
    | None => Signal.get(state.selected)
    }
    around->Option.map(id => {
      let neighbours =
        Signal.get(edges)->Array.flatMap(e => e.from == id ? [e.to] : e.to == id ? [e.from] : [])
      (id, Set.fromArray([id, ...neighbours]))
    })
  })
  let edgeClass = (edge: gedge) =>
    switch Signal.get(focus) {
    | Some((id, _)) if edge.from == id || edge.to == id => "gedge lit"
    | Some(_) => "gedge dim"
    | None => "gedge"
    }
  let nodeClass = (node: gnode) => {
    let focused = switch Signal.get(focus) {
    | Some((id, set)) => id == node.id ? " selected" : set->Set.has(node.id) ? " lit" : " dim"
    | None => ""
    }
    let selected = Signal.get(state.selected) == Some(node.id) && focused != " selected"
    let hot = Signal.get(state.hot)->Set.has(node.id)
    "gnode" ++ focused ++ (selected ? " selected" : "") ++ (hot ? " hot" : "")
  }
  let path = (edge: gedge) =>
    switch (Signal.get(positions)->Map.get(edge.from), Signal.get(positions)->Map.get(edge.to)) {
    | (Some(a), Some(b)) =>
      let (x1, y1, x2, y2) = (a.x + a.w, a.y + nodeH / 2, b.x, b.y + nodeH / 2)
      let dx = (x2 - x1) / 2
      let p = (x, y) => `${Int.toString(x)},${Int.toString(y)}`
      `M${p(x1, y1)} C${p(x1 + dx, y1)} ${p(x2 - dx, y2)} ${p(x2, y2)}`
    | _ => ""
    }
  /* Hovering a node outlines the element its binding writes. */
  let hover = (id: int, on: bool) => {
    Signal.set(state.hover, on ? Some(id) : None)
    if on {
      Devtools.targetOf(id)->Option.forEach(element => showOutline(element, "rgb(21,154,102)"))
    } else {
      hideOutline()
    }
  }
  let scaled = size =>
    () => Float.toString(Int.toFloat(size(Signal.get(layout))) *. Signal.get(state.zoom))
  let nodeView = (node: gnode) => {
    let tooltip = () => label(node.id) ++ currentValue(node.id)->Option.mapOr("", v => "\n= " ++ v)
    let value = () =>
      Devtools.inspect(node.id)->Option.mapOr("", v => clip(inlineValue(v), node.valueChars))
    <g
      class={() => nodeClass(node)}
      attrs=[("data-kind", node.kind), ("data-id", Int.toString(node.id))]
      transform={`translate(${Int.toString(node.x)},${Int.toString(node.y)})`}
      onClick={_ => selectNode(state, node.id)}
      onMouseEnter={_ => hover(node.id, true)}
      onMouseLeave={_ => hover(node.id, false)}
    >
      <title> {View.signalText(live(state, tooltip))} </title>
      <rect class="box" width={Int.toString(node.w)} height={Int.toString(nodeH)} />
      <text class="glyph" x="9" y="16"> {txt(glyphOf(node.kind))} </text>
      <text class="label" x="24" y="16">
        {txt(node.text)}
        <tspan class="value"> {View.signalText(live(state, value))} </tspan>
      </text>
    </g>
  }
  <svg
    xmlns="http://www.w3.org/2000/svg" width={scaled(l => l.width)} height={scaled(l => l.height)}
  >
    <g transform={() => `scale(${Float.toString(Signal.get(state.zoom))})`}>
      <g>
        {View.eachWithKey(
          edges,
          edge => edge.ekey,
          edge => <path class={() => edgeClass(edge)} d={() => path(edge)} />,
        )}
      </g>
      <g> {View.eachWithKey(nodes, node => Int.toString(node.id), nodeView)} </g>
    </g>
  </svg>
}

let kindChip = (state: state, name: string, get: kinds => bool, set: (kinds, bool) => kinds) =>
  <button
    class="chip"
    title={`Show or hide ${name}s`}
    style={`--c: var(--${name})`}
    attrs=[("data-on", () => flag(get(Signal.get(state.kinds))))]
    onClick={_ => Signal.update(state.kinds, kinds => set(kinds, !get(kinds)))}
  >
    <span class="sw" />
    {txt(name ++ "s")}
  </button>

let graphTab = (state: state) => {
  let scopesById = Computed.make(() => {
    let _ = Signal.get(state.version)
    Map.fromArray(Devtools.scopes()->Array.map(scope => (scope.id, scope)))
  })
  let layout = Computed.make(
    () => {
      let _ = Signal.get(state.version)
      let kinds = Signal.get(state.kinds)
      let filter = Signal.get(state.filter)->String.toLowerCase
      let scopeFilter = Signal.get(state.scopeFilter)
      let scopes = Signal.get(scopesById)
      let has = (text, part) => String.includes(text->String.toLowerCase, part)
      computeLayout(Devtools.snapshot().nodes, ~shows=node => {
        let kind = kindOf(node)
        let inScope = switch (scopeFilter, node.scope) {
        | (None, _) => true
        | (Some(wanted), Some(scope)) => underScope(scopes, scope, wanted, 0)
        | (Some(_), None) => false
        }
        let kindShown = switch kind {
        | "signal" => kinds.signals
        | "computed" => kinds.computeds
        | "effect" => kinds.effects
        | _ => kinds.bindings
        }
        inScope &&
        kindShown &&
        (filter == "" ||
        has(shortLabel(node), filter) ||
        has(node.name->Option.getOr(""), filter) ||
        String.includes(kind, filter) ||
        Int.toString(node.id) == filter)
      })
    },
    ~equals=(a, b) => a.signature == b.signature,
  )
  let setZoom = factor =>
    Signal.update(state.zoom, zoom => Math.max(0.4, Math.min(2.5, zoom *. factor)))
  let scopeChip = () =>
    switch Signal.get(state.scopeFilter) {
    | Some(scope) =>
      let name =
        Signal.get(scopesById)->Map.get(scope)->Option.mapOr(`scope ${hash(scope)}`, scopeLabel)
      <button
        class="chip x"
        title="Stop filtering by scope"
        onClick={_ => Signal.set(state.scopeFilter, None)}
      >
        {txt(`in ${name}  ×`)}
      </button>
    | None => View.null()
    }
  let canvas = () => {
    let {nodes, total} = Signal.get(layout)
    switch Array.length(nodes) {
    | 0 if total > 0 => note(~cls="empty", "Nothing matches the filters.")
    | 0 if Devtools.status().signals => note(~cls="empty", "Nothing reactive yet.")
    | 0 =>
      note(
        ~cls="empty",
        "The reactive graph is not visible: the loaded rescript-signals has no debug hooks.",
      )
    | shown =>
      let limit = `Showing ${Int.toString(graphLimit)} of ${Int.toString(total)} nodes`
      <div>
        {graphView(state, layout)}
        {shown == graphLimit ? note(~cls="empty", limit ++ "; filter to narrow.") : View.null()}
      </div>
    }
  }
  let zoomText = () => `${Int.toString(Float.toInt(Signal.get(state.zoom) *. 100.))}%`
  <div class="body" attrs=[("data-detail", () => flag(Signal.get(state.detailOpen)))]>
    <div class="graph">
      <div class="toolbar">
        <input
          placeholder="filter by name, kind or id"
          value={state.filter}
          onInput={event => Signal.set(state.filter, inputValue(event))}
        />
        {kindChip(state, "signal", k => k.signals, (k, v) => {...k, signals: v})}
        {kindChip(state, "computed", k => k.computeds, (k, v) => {...k, computeds: v})}
        {kindChip(state, "effect", k => k.effects, (k, v) => {...k, effects: v})}
        {kindChip(state, "binding", k => k.bindings, (k, v) => {...k, bindings: v})}
        {View.tracked(scopeChip)}
        <span class="zoom">
          <button title="Zoom out" onClick={_ => setZoom(0.8)}> {txt("−")} </button>
          <button title="Reset zoom" onClick={_ => Signal.set(state.zoom, 1.)}>
            {View.signalText(zoomText)}
          </button>
          <button title="Zoom in" onClick={_ => setZoom(1.25)}> {txt("+")} </button>
        </span>
        {iconButton(
          "▤",
          ~title="Details",
          ~active=() => Signal.get(state.detailOpen),
          _ => Signal.update(state.detailOpen, open_ => !open_),
        )}
      </div>
      <div class="canvas"> {View.tracked(canvas)} </div>
    </div>
    {View.tracked(() =>
      Signal.get(state.detailOpen) ? <div class="detail"> {detailPane(state)} </div> : View.null()
    )}
  </div>
}

/* ---- timeline ------------------------------------------------------------- */

let entryView = (state: state, entry: entry) =>
  <div class={"entry " ++ entry.kind}> {textOrLink(state, entry.text, entry.node)} </div>

let timelineTab = (state: state) => {
  let clear = _ => {
    Devtools.clearHistory()
    Signal.set(state.transactions, [])
  }
  let count = () => `${plural(Array.length(Signal.get(state.transactions)), "update")}; newest last`
  let txView = tx =>
    <details
      class="tx" attrs=[("data-issue", flag(tx.entries->Array.some(e => e.kind == "issue")))]
    >
      <summary>
        <span class="title"> {textOrLink(state, tx.title, tx.node)} </span>
        <span class="sum"> {txt(tx.summary)} </span>
      </summary>
      <div class="entries"> {tx.entries->Array.map(entryView(state, ...))->View.fragment} </div>
    </details>
  <div class="timeline">
    <div class="timeline-head">
      <button class="small" onClick={clear}> {txt("Clear")} </button>
      <span class="muted"> {View.signalText(count)} </span>
    </div>
    {View.eachWithKey(state.transactions, tx => tx.key, txView)}
  </div>
}

/* ---- scopes --------------------------------------------------------------- */

let scopesTab = (state: state) =>
  liveView(state, () => {
    let snapshot = Devtools.snapshot()
    let counts = Map.make()
    let count = scope => counts->Map.get(scope)->Option.getOr(0)
    snapshot.nodes->Array.forEach(node =>
      node.scope->Option.forEach(s => counts->Map.set(s, count(s) + 1))
    )
    let children = Map.make()
    snapshot.scopes->Array.forEach(scope => {
      let parent = scope.parent->Option.getOr(0)
      switch children->Map.get(parent) {
      | Some(list) => list->Array.push(scope)
      | None => children->Map.set(parent, [scope])
      }
    })
    let rows = []
    let rec walk = (parent, depth) =>
      children
      ->Map.get(parent)
      ->Option.getOr([])
      ->Array.forEach(scope =>
        if Array.length(rows) < transactionLimit * 2 {
          let n = count(scope.id)
          rows->Array.push(
            <button
              class={scope.disposed ? "scope released" : "scope"}
              title="Show only this scope in the graph"
              style={`padding-left: ${Int.toString(depth * 14 + 10)}px`}
              onClick={_ => filterScope(state, scope.id)}
            >
              <span class="k"> {txt(scopeLabel(scope))} </span>
              <span class="n">
                {txt(scope.disposed ? "released" : n == 0 ? "" : plural(n, "node"))}
              </span>
            </button>,
          )
          walk(scope.id, depth + 1)
        }
      )
    walk(0, 0)
    rows == []
      ? note(
          "No scopes yet: keyed rows, fragment passes and boundaries appear here as the app renders them.",
        )
      : <div class="scopes"> {View.fragment(rows)} </div>
  })

/* ---- issues --------------------------------------------------------------- */

let issueEntries = (state: state) =>
  Signal.get(state.transactions)->Array.flatMap(tx =>
    tx.entries->Array.filter(e => e.kind == "issue")
  )

let issuesTab = (state: state) =>
  liveView(state, () => {
    let card = (what, body) =>
      <div class="issue-card">
        <div class="what"> {txt(what)} </div>
        {body}
      </div>
    let leaks = Devtools.leaks()->Array.map(leak => {
      let reason = switch leak.reason {
      | #effectOutlivedScope => "still running after the scope that created it was released"
      | #computedOutlivedScope => "still subscribed after the scope that created it was released"
      | #unownedEffect => "created inside another node's run with no scope to own it: every run of that node creates another"
      }
      card(
        "leak",
        <>
          <div>
            {nodeLink(state, leak.node)}
            {txt(" " ++ reason)}
          </div>
          <div class="site"> {txt(leak.site->Option.getOr(""))} </div>
        </>,
      )
    })
    let issues =
      issueEntries(state)->Array.map(entry =>
        card(
          entry.text->String.split(":")->Array.getUnsafe(0),
          <div> {entryView(state, {...entry, kind: ""})} </div>,
        )
      )
    switch Array.concat(leaks, issues) {
    | [] => note("No leaks, hidden reads, caught failures or hydration warnings.")
    | all => <div class="issues"> {View.fragment(all)} </div>
    }
  })

/* ---- the panel ------------------------------------------------------------ */

let tabButton = (state: state, tab: tab, name: string, ~count=?) =>
  <button
    class="tab"
    attrs=[("data-active", () => flag(Signal.get(state.tab) == tab))]
    onClick={_ => Signal.set(state.tab, tab)}
  >
    {txt(name)}
    {count->Option.mapOr(View.null(), count => countBadge("count", count))}
  </button>

let panel = (state: state, ~host: Dom.element, ~issueCount: Signal.t<int>) => {
  let stopPicking = ref(() => ())
  let onPick = target =>
    Signal.batch(() => {
      let writers = withChildren(target)->Array.flatMap(Devtools.writersOf)
      Signal.set(state.picking, false)
      Signal.set(state.picked, Some({path: Devtools.pathOf(target), writers}))
      /* Select the first writer, so the graph lights up around it. */
      Signal.set(state.selected, writers[0])
      Signal.set(state.detailOpen, true)
      Signal.set(state.tab, Graph)
    })
  let togglePicking = _ =>
    if Signal.peek(state.picking) {
      stopPicking.contents()
      Signal.set(state.picking, false)
    } else {
      Signal.set(state.picking, true)
      let show = element => showOutline(element, "rgb(106,76,255)")
      stopPicking := startPicking(host, onPick, show, hideOutline)
    }
  let statusDot = () => {
    let cls = () => {
      let _ = Signal.get(state.version)
      Devtools.status().signals ? "dot" : "dot off"
    }
    <span class={cls} title="Green: the reactive graph is visible" />
  }
  let footerText = () =>
    if Devtools.status().signals {
      let nodes = Devtools.snapshot().nodes
      ["signal", "computed", "effect", "binding"]
      ->Array.map(kind => plural(nodes->Array.filter(n => kindOf(n) == kind)->Array.length, kind))
      ->Array.join(" · ")
    } else {
      "graph not visible: rescript-signals has no debug hooks"
    }
  let size = () => {
    let (w, h) = Signal.get(state.size)
    `width: ${Int.toString(w)}px; height: ${Int.toString(h)}px`
  }
  let resize = event =>
    startResize(event, size => {
      Signal.set(state.size, size)
      saveSize(size)
    })
  View.tracked(() =>
    if !Signal.get(state.expanded) {
      <button
        class="launcher"
        title="Xote devtools (Ctrl+Shift+X)"
        onClick={_ => Signal.set(state.expanded, true)}
      >
        {statusDot()}
        {txt("xote")}
        {countBadge("badge", issueCount)}
      </button>
    } else {
      <div class="panel" style={size}>
        <div class="resize" title="Drag to resize" onMouseDown={resize} />
        <header>
          <span class="brand">
            {statusDot()}
            {txt("xote")}
          </span>
          <span class="tabs">
            {tabButton(state, Graph, "Graph")}
            {tabButton(state, Timeline, "Timeline")}
            {tabButton(state, Scopes, "Scopes")}
            {tabButton(state, Issues, "Issues", ~count=issueCount)}
          </span>
          {spacer()}
          {iconButton(
            "✦",
            ~title="Flash elements on the page as they update",
            ~active=() => Signal.get(state.highlight),
            _ => Signal.update(state.highlight, on => !on),
          )}
          {iconButton(
            "⌖",
            ~title="Pick an element on the page",
            ~active=() => Signal.get(state.picking),
            togglePicking,
          )}
          {iconButton("×", ~title="Close (Ctrl+Shift+X)", _ => Signal.set(state.expanded, false))}
        </header>
        <main>
          {View.tracked(() =>
            switch Signal.get(state.tab) {
            | Graph => graphTab(state)
            | Timeline => timelineTab(state)
            | Scopes => scopesTab(state)
            | Issues => issuesTab(state)
            }
          )}
        </main>
        <footer>
          <span> {View.signalText(live(state, footerText))} </span>
          {spacer()}
          <span> {txt("Ctrl+Shift+X")} </span>
        </footer>
      </div>
    }
  )
}

/* ---- grouping events into updates ----------------------------------------- */

let summarize = (entries: array<entry>): string => {
  let (computeds, effects, dom, created, disposed) = (ref(0), ref(0), ref(0), ref(0), ref(0))
  let bump = count => count := count.contents + 1
  entries->Array.forEach(entry =>
    switch entry.kind {
    | "run" =>
      switch entry.node->Option.flatMap(Devtools.inspect) {
      | Some({kind: #computed}) => bump(computeds)
      | Some(_) => bump(effects)
      | None => ()
      }
    | "dom" => bump(dom)
    | "scope" => bump(entry.text->String.startsWith("scope +") ? created : disposed)
    | _ => ()
    }
  )
  let counted = (count, word) => count.contents > 0 ? [plural(count.contents, word)] : []
  [
    ...counted(computeds, "computed"),
    ...counted(effects, "effect"),
    ...counted(dom, "DOM write"),
    ...created.contents + disposed.contents > 0
      ? [`scopes +${Int.toString(created.contents)}/−${Int.toString(disposed.contents)}`]
      : [],
  ]->Array.join(" · ")
}

/* Events are delivered synchronously, so a top-level write (or batch) and
 everything until the next one is what that write caused. */
let groupEvents = (events: array<Devtools.event>, counter: ref<int>): array<transaction> => {
  let out = []
  let current: ref<option<(string, option<int>, array<entry>)>> = ref(None)
  let depth = ref(0)
  let inBatch = ref(false)
  let nextKey = () => {
    counter := counter.contents + 1
    Int.toString(counter.contents)
  }
  /* A write's title is its text without the creation site. */
  let titleOf = text => text->String.split("  ")->Array.getUnsafe(0)
  let close = () => {
    switch current.contents {
    /* An empty batch says nothing. */
    | Some((_, _, entries)) if entries->Array.every(entry => entry.kind == "batch") => ()
    | Some((title, node, entries)) =>
      out->Array.push({key: nextKey(), title, summary: summarize(entries), entries, node})
    | None => ()
    }
    current := None
  }
  events->Array.forEach(event => {
    switch event {
    | Written({changed: true}) if depth.contents == 0 && !inBatch.contents => close()
    | BatchStart =>
      close()
      inBatch := true
    | BatchEnd => inBatch := false
    | RunStart(_) => depth := depth.contents + 1
    | RunEnd(_) => depth := Math.Int.max(0, depth.contents - 1)
    | _ => ()
    }
    describe(event)->Option.forEach(((kind, text, node)) => {
      let entry = {key: nextKey(), kind, text, node}
      switch current.contents {
      | Some((title, _, entries)) =>
        entries->Array.push(entry)

        /* A batch is titled by its first write. */
        if title == "batch" && kind == "write" {
          current := Some((titleOf(text), node, entries))
        }
      | None =>
        let title = switch kind {
        | "write" => titleOf(text)
        | "batch" => "batch"
        | _ => "render"
        }
        current := Some((title, kind == "write" ? node : None, [entry]))
      }
    })
  })
  close()
  out
}

let setItems = (set: Set.t<int>) => set->Set.values->Iterator.toArray
let keepLast = log => log->Array.slice(~start=Math.Int.max(0, Array.length(log) - transactionLimit))

let mount = (~target: option<Dom.element>=?, ~expanded: bool=false, ()): (unit => unit) => {
  if !Devtools.installed() {
    let _ = Devtools.install()
  }
  let (host, container) = createHost(style, target)
  let buffer = ref([])
  let scheduled = ref(false)
  let counter = ref(0)

  let (state, mounted, issueCount) = Devtools.mute(() => (
    {
      expanded: Signal.make(expanded),
      tab: Signal.make(Graph),
      version: Signal.make(0),
      selected: Signal.make(None),
      hover: Signal.make(None),
      filter: Signal.make(""),
      kinds: Signal.make({signals: true, computeds: true, effects: true, bindings: true}),
      scopeFilter: Signal.make(None),
      transactions: Signal.make([]),
      hot: Signal.make(Set.make()),
      picking: Signal.make(false),
      picked: Signal.make(None),
      highlight: Signal.make(false),
      zoom: Signal.make(1.),
      detailOpen: Signal.make(true),
      size: Signal.make(loadSize()->Option.getOr((720, 560))),
    },
    Signal.make(true),
    Signal.make(0),
  ))

  /* Muted as a whole: the batch below names no node, and would otherwise
   reach the subscriber and schedule this again, every frame. */
  let flush = () =>
    Devtools.mute(() => {
      scheduled := false
      let events = buffer.contents
      buffer := []
      let transactions = groupEvents(events, counter)
      let ran = Set.make()
      events->Array.forEach(event =>
        switch event {
        | RunStart({id}) | Written({id, changed: true}) => ran->Set.add(id)
        | DomWrite({node: Some(id)}) if Signal.peek(state.highlight) =>
          Devtools.targetOf(id)->Option.forEach(flashElement)
        | _ => ()
        }
      )
      let updateHot = f => Signal.update(state.hot, hot => Set.fromArray(f(setItems(hot))))
      let cool = () => Devtools.mute(() => updateHot(Array.filter(_, id => !(ran->Set.has(id)))))
      Signal.batch(() => {
        if transactions != [] {
          Signal.update(state.transactions, log => keepLast(Array.concat(log, transactions)))
        }
        if ran->Set.size > 0 {
          updateHot(Array.concat(_, setItems(ran)))
          setTimeout(cool, hotMs)->ignore
        }
        Signal.update(state.version, v => v + 1)
        Signal.set(issueCount, Array.length(Devtools.leaks()) + Array.length(issueEntries(state)))
      })
    })

  let unsubscribe = Devtools.subscribe(event => {
    buffer.contents->Array.push(event)
    if !scheduled.contents {
      scheduled := true
      nextFrame(flush)
    }
  })
  let stopToggle = listenForToggle(() => Signal.update(state.expanded, open_ => !open_))

  Devtools.mute(() =>
    View.mount(
      View.tracked(() => Signal.get(mounted) ? panel(state, ~host, ~issueCount) : View.null()),
      container,
    )
  )

  () => {
    unsubscribe()
    stopToggle()
    hideOutline()
    /* Releases the panel's reactive state with the pass that rendered it. */
    Signal.set(mounted, false)
    removeNode(host)
  }
}
