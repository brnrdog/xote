/* Public: an in-page devtools panel, built with Xote on top of `Devtools`.

   Everything the panel creates is made under `Devtools.mute`, so it never
   shows up in what it displays: its signals, effects, scopes and DOM writes
   are filtered out of snapshots, traces and the event stream. Events from the
   app are buffered as they arrive and applied once per animation frame, so the
   panel never writes a signal from inside the app's own update. It renders in
   a shadow root, so neither its styles nor the page's leak across.

   The graph is drawn as a layered dependency diagram: signals on the left,
   what reads them to the right, down to the bindings that write the DOM. Its
   layout is recomputed only when the set of nodes or edges changes; values,
   selection and the pulse of a node that just ran are per-node signals, so a
   busy app does not redraw the diagram on every frame.

   It shows no data the CLI cannot print: it reads `Devtools.snapshot`,
   `Devtools.why`, `Devtools.leaks` and the event stream, like `xote-lens`. */

type tab = Graph | Timeline | Scopes | Issues

/* One line of the timeline. `node` is what the line is about, for a link. */
type entry = {key: string, kind: string, text: string, node: option<int>}

/* A top-level write (or batch) and everything it caused, as the timeline
 groups them. */
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
  font: 12px/1.45 "DM Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  color: var(--fg);
}
@media (prefers-color-scheme: dark) {
  .launcher, .panel {
    --bg: #141319; --bg2: #1a1921; --fg: #ecebf3; --muted: #9a97ad; --line: #2a2834; --row: #1f1e28;
    --accent: #a08cff; --signal: #a994ff; --computed: #6ea8ff; --effect: #f0b25a; --binding: #5fd49a;
    --issue: #ff8a7a; --warn: #f0c060; --hot: #ff8a5c; --edge: #3b394a; --shadow: 0 16px 48px rgba(0,0,0,.5);
  }
}
.launcher {
  position: fixed; right: 12px; bottom: 12px; z-index: 2147483647;
  display: flex; align-items: center; gap: 6px;
  background: var(--bg); border: 1px solid var(--line); border-radius: 999px;
  padding: 6px 12px 6px 10px; cursor: pointer; box-shadow: var(--shadow);
}
.launcher .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--binding); }
.launcher .dot.off { background: var(--muted); }
.launcher .badge { background: var(--issue); color: #fff; border-radius: 999px; padding: 0 6px; font-size: 10px; }
.panel {
  position: fixed; right: 12px; bottom: 12px; z-index: 2147483647;
  display: flex; flex-direction: column; background: var(--bg);
  border: 1px solid var(--line); border-radius: 12px; overflow: hidden; box-shadow: var(--shadow);
  max-width: calc(100vw - 24px); max-height: calc(100vh - 24px);
}
.resize { position: absolute; left: 0; top: 0; width: 14px; height: 14px; cursor: nwse-resize; z-index: 2; }
.resize::after { content: ""; position: absolute; left: 3px; top: 3px; width: 6px; height: 6px; border-left: 2px solid var(--muted); border-top: 2px solid var(--muted); opacity: .6; }
header { display: flex; gap: 2px; padding: 6px 8px 6px 18px; border-bottom: 1px solid var(--line); align-items: center; background: var(--bg2); }
footer { display: flex; gap: 12px; padding: 4px 12px; border-top: 1px solid var(--line); color: var(--muted); background: var(--bg2); white-space: nowrap; overflow: hidden; }
main { flex: 1; overflow: hidden; min-height: 0; display: flex; flex-direction: column; }
button { font: inherit; color: inherit; background: none; border: 0; cursor: pointer; }
input { font: inherit; color: var(--fg); }
.brand { display: flex; align-items: center; gap: 6px; margin-right: 10px; font-weight: 600; }
.brand .dot { width: 8px; height: 8px; border-radius: 50%; background: var(--binding); }
.brand .dot.off { background: var(--muted); }
.tabs { display: flex; gap: 2px; background: var(--row); border-radius: 8px; padding: 2px; }
.tab { padding: 3px 10px; border-radius: 6px; color: var(--muted); display: flex; gap: 6px; align-items: center; }
.tab[data-active="true"] { background: var(--bg2); color: var(--fg); box-shadow: 0 1px 2px rgba(0,0,0,.12); }
.tab .count { background: var(--issue); color: #fff; border-radius: 999px; padding: 0 5px; font-size: 10px; line-height: 15px; }
.spacer { flex: 1; }
.icon { width: 26px; height: 26px; border-radius: 6px; display: inline-flex; align-items: center; justify-content: center; color: var(--muted); font-size: 14px; }
.icon:hover { background: var(--row); color: var(--fg); }
.icon[data-active="true"] { background: var(--accent); color: #fff; }
.toolbar { display: flex; gap: 6px; align-items: center; padding: 6px 8px; border-bottom: 1px solid var(--line); flex-wrap: wrap; }
.toolbar input { flex: 1; min-width: 120px; padding: 4px 8px; border: 1px solid var(--line); border-radius: 6px; background: var(--bg2); }
.chip { display: inline-flex; align-items: center; gap: 5px; padding: 2px 8px; border-radius: 999px; border: 1px solid var(--line); color: var(--muted); }
.chip .sw { width: 8px; height: 8px; border-radius: 50%; background: var(--c); }
.chip[data-on="true"] { color: var(--fg); border-color: var(--c); background: color-mix(in srgb, var(--c) 10%, transparent); }
.chip.x { color: var(--fg); border-color: var(--accent); }
.zoom { display: inline-flex; border: 1px solid var(--line); border-radius: 6px; overflow: hidden; }
.zoom button { padding: 2px 7px; }
.zoom button + button { border-left: 1px solid var(--line); }
.body { flex: 1; min-height: 0; display: grid; grid-template-columns: minmax(0, 1fr); }
.body[data-detail="true"] { grid-template-columns: minmax(0, 1fr) minmax(0, 300px); }
.canvas { overflow: auto; position: relative; background:
  radial-gradient(var(--line) 1px, transparent 1px) 0 0 / 18px 18px; }
.canvas svg { display: block; }
.empty { padding: 16px; color: var(--muted); }
.gedge { fill: none; stroke: var(--edge); stroke-width: 1.2; transition: stroke .15s, opacity .15s; }
.gedge.lit { stroke: var(--accent); stroke-width: 1.8; }
.gedge.dim { opacity: .25; }
.gnode { cursor: pointer; transition: opacity .15s; }
.gnode.dim { opacity: .3; }
.gnode rect.box { fill: var(--bg2); stroke: var(--c); stroke-width: 1.2; rx: 6; transition: stroke-width .15s; }
.gnode.hot rect.box { stroke: var(--hot); stroke-width: 2.4; fill: color-mix(in srgb, var(--hot) 14%, var(--bg2)); }
.gnode.selected rect.box { stroke-width: 2.4; fill: color-mix(in srgb, var(--c) 12%, var(--bg2)); }
.gnode.lit rect.box { stroke-width: 2; }
.gnode .glyph { fill: var(--c); font-size: 11px; font-weight: 700; }
.gnode .label { fill: var(--fg); font-size: 11px; }
.gnode .value { fill: var(--muted); font-size: 10px; font-weight: 500; }
.gnode[data-kind="signal"] { --c: var(--signal); }
.gnode[data-kind="computed"] { --c: var(--computed); }
.gnode[data-kind="effect"] { --c: var(--effect); }
.gnode[data-kind="binding"] { --c: var(--binding); }
.detail { border-left: 1px solid var(--line); overflow: auto; padding: 10px 12px; background: var(--bg2); }
.detail h3 { font-size: 12px; margin: 0 0 8px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; word-break: break-all; }
.detail h4 { font-size: 11px; margin: 12px 0 4px; color: var(--muted); text-transform: uppercase; letter-spacing: .04em; }
.pill { display: inline-block; padding: 0 7px; border-radius: 999px; font-size: 10px; line-height: 16px; color: #fff; background: var(--c); }
.pill[data-kind="signal"] { --c: var(--signal); }
.pill[data-kind="computed"] { --c: var(--computed); }
.pill[data-kind="effect"] { --c: var(--effect); }
.pill[data-kind="binding"] { --c: var(--binding); }
table { border-collapse: collapse; width: 100%; }
th { text-align: left; color: var(--muted); font-weight: normal; padding: 2px 8px 2px 0; vertical-align: top; width: 1%; white-space: nowrap; }
td { padding: 2px 0; word-break: break-all; }
.link { color: var(--accent); padding: 0; text-align: left; }
.link:hover { text-decoration: underline; }
.small { padding: 2px 8px; border: 1px solid var(--line); border-radius: 6px; color: var(--muted); }
.small:hover { color: var(--fg); background: var(--row); }
.value { font-weight: 500; }
.why, .why ul { list-style: none; margin: 0; padding-left: 14px; }
.why { padding-left: 0; }
.why li { position: relative; padding: 1px 0; }
.why ul li::before { content: "└ "; color: var(--muted); }
.site, .muted { color: var(--muted); }
.timeline { overflow: auto; flex: 1; padding: 6px 8px; }
.tx { border: 1px solid var(--line); border-radius: 8px; margin-bottom: 6px; background: var(--bg2); }
.tx summary { cursor: pointer; padding: 5px 8px; display: flex; gap: 8px; align-items: baseline; list-style: none; }
.tx summary::-webkit-details-marker { display: none; }
.tx summary .title { color: var(--signal); font-weight: 500; flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.tx summary .sum { color: var(--muted); white-space: nowrap; }
.tx[data-issue="true"] summary .title { color: var(--issue); }
.tx .entries { padding: 2px 8px 6px; border-top: 1px solid var(--line); }
.entry { padding: 1px 0; white-space: pre-wrap; word-break: break-all; }
.entry.write { color: var(--signal); }
.entry.dom { color: var(--binding); }
.entry.keyed { color: var(--computed); }
.entry.scope { color: var(--warn); }
.entry.issue { color: var(--issue); }
.entry.batch, .entry.run { color: var(--muted); }
.entry .link { color: inherit; }
.scopes { overflow: auto; flex: 1; padding: 6px 0; }
.scope { display: flex; gap: 8px; width: 100%; text-align: left; padding: 2px 10px; }
.scope:hover { background: var(--row); }
.scope .k { color: var(--warn); }
.scope .n { color: var(--muted); }
.scope.released { color: var(--muted); }
.scope.released .k { color: var(--muted); text-decoration: line-through; }
.issues { overflow: auto; flex: 1; padding: 8px; }
.issue-card { border-left: 3px solid var(--issue); background: var(--bg2); border-radius: 6px; padding: 6px 10px; margin-bottom: 6px; }
.issue-card .what { color: var(--issue); font-weight: 500; }
p.muted { padding: 12px; margin: 0; }
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

/* One overlay for the page: the picker's hover, a binding's target under the
 pointer, and the flash of a node a binding just wrote. */
let showOutline: (Dom.element, string) => unit = %raw(`function (el, color) {
  if (!el || !el.getBoundingClientRect) return
  var box = document.getElementById("xote-devtools-outline")
  if (!box) {
    box = document.createElement("div")
    box.id = "xote-devtools-outline"
    box.style.cssText = "position:fixed;pointer-events:none;z-index:2147483646;border-radius:3px;transition:opacity .12s"
    document.body.appendChild(box)
  }
  var node = el.nodeType === 3 ? el.parentNode : el
  var r = node.getBoundingClientRect()
  box.style.display = "block"; box.style.opacity = "1"
  box.style.border = "2px solid " + color
  box.style.background = color.replace(")", ",.12)").replace("rgb(", "rgba(")
  box.style.left = (r.left - 2) + "px"; box.style.top = (r.top - 2) + "px"
  box.style.width = (r.width + 4) + "px"; box.style.height = (r.height + 4) + "px"
}`)

let hideOutline: unit => unit = %raw(`function () {
  var box = document.getElementById("xote-devtools-outline")
  if (box) box.style.display = "none"
}`)

/* A short-lived highlight over a node a binding just wrote. */
let flashElement: Dom.element => unit = %raw(`function (el) {
  if (!el) return
  var node = el.nodeType === 3 ? el.parentNode : el
  if (!node || !node.getBoundingClientRect) return
  var r = node.getBoundingClientRect()
  if (r.width === 0 && r.height === 0) return
  var box = document.createElement("div")
  box.style.cssText = "position:fixed;pointer-events:none;z-index:2147483645;border:2px solid rgb(255,107,61);background:rgba(255,107,61,.18);border-radius:3px;transition:opacity .5s ease-out"
  box.style.left = (r.left - 1) + "px"; box.style.top = (r.top - 1) + "px"
  box.style.width = (r.width + 2) + "px"; box.style.height = (r.height + 2) + "px"
  document.body.appendChild(box)
  setTimeout(function () { box.style.opacity = "0" }, 80)
  setTimeout(function () { if (box.parentNode) box.parentNode.removeChild(box) }, 650)
}`)

let revealElement: Dom.element => unit = %raw(`function (el) {
  if (!el) return
  var node = el.nodeType === 3 ? el.parentNode : el
  if (node && node.scrollIntoView) node.scrollIntoView({ block: "center", inline: "nearest" })
}`)

/* The element picker: highlight what the pointer is over, and hand the first
   click outside the panel to `onPick` instead of the page. Returns the
   function that stops picking. */
let startPicking: (
  Dom.element,
  Dom.element => unit,
) => unit => unit = %raw(`function (host, onPick) {
  function inPanel(node) { return node === host || host.contains(node) }
  function move(event) {
    var target = event.target
    if (!target || inPanel(target) || !target.getBoundingClientRect) { hide(); return }
    var r = target.getBoundingClientRect()
    show(target)
  }
  function show(target) {
    var box = document.getElementById("xote-devtools-outline")
    if (!box) {
      box = document.createElement("div")
      box.id = "xote-devtools-outline"
      box.style.cssText = "position:fixed;pointer-events:none;z-index:2147483646;border-radius:3px"
      document.body.appendChild(box)
    }
    var r = target.getBoundingClientRect()
    box.style.display = "block"; box.style.opacity = "1"
    box.style.border = "2px solid rgb(106,76,255)"; box.style.background = "rgba(106,76,255,.12)"
    box.style.left = (r.left - 2) + "px"; box.style.top = (r.top - 2) + "px"
    box.style.width = (r.width + 4) + "px"; box.style.height = (r.height + 4) + "px"
  }
  function hide() {
    var box = document.getElementById("xote-devtools-outline")
    if (box) box.style.display = "none"
  }
  function click(event) {
    if (inPanel(event.target)) return
    event.preventDefault(); event.stopPropagation()
    stop()
    onPick(event.target)
  }
  function key(event) { if (event.key === "Escape") stop() }
  function stop() {
    document.removeEventListener("mousemove", move, true)
    document.removeEventListener("click", click, true)
    document.removeEventListener("keydown", key, true)
    hide()
  }
  document.addEventListener("mousemove", move, true)
  document.addEventListener("click", click, true)
  document.addEventListener("keydown", key, true)
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

/* Drag the panel's top-left corner to resize it. */
let startResize: (Dom.event, ((int, int)) => unit) => unit = %raw(`function (event, onSize) {
  event.preventDefault()
  var panel = event.target.parentNode
  var startX = event.clientX, startY = event.clientY
  var startW = panel.offsetWidth, startH = panel.offsetHeight
  function move(e) {
    onSize([Math.max(420, startW + (startX - e.clientX)), Math.max(260, startH + (startY - e.clientY))])
  }
  function up() {
    document.removeEventListener("mousemove", move)
    document.removeEventListener("mouseup", up)
  }
  document.addEventListener("mousemove", move)
  document.addEventListener("mouseup", up)
}`)

let defaultSize = (720, 560)

let loadSize: unit => option<(int, int)> = %raw(`function () {
  try {
    var raw = localStorage.getItem("xote-devtools.size")
    if (!raw) return undefined
    var parsed = JSON.parse(raw)
    return Array.isArray(parsed) && parsed.length === 2 ? parsed : undefined
  } catch (_) { return undefined }
}`)

let saveSize: ((int, int)) => unit = %raw(`function (size) {
  try { localStorage.setItem("xote-devtools.size", JSON.stringify(size)) } catch (_) {}
}`)

/* The element and its children: a binding writes either a text node or the
 element itself, when that text is its only child. */
let withChildren: Dom.element => array<Dom.element> = %raw(`function (element) {
  return [element].concat(Array.prototype.slice.call(element.childNodes))
}`)

let setTimeout_: (unit => unit, int) => unit = %raw(`function (fn, ms) { setTimeout(fn, ms) }`)

/* ---- describing ---------------------------------------------------------------- */

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

/* The last step of a DOM path: `div.counter-demo-value`. */
let lastStep = (path: string): string => path->String.split(" > ")->Array.at(-1)->Option.getOr(path)

/* `src/demos/CounterDemo.res.mjs:3:14` → `CounterDemo:3`. */
let shortSite = (site: string): string => {
  let file = site->String.split(":")->Array.getUnsafe(0)
  let line = site->String.split(":")->Array.get(1)->Option.getOr("")
  let base = file->String.split("/")->Array.at(-1)->Option.getOr(file)
  let base =
    base->String.replace(".res.mjs", "")->String.replace(".mjs", "")->String.replace(".js", "")
  line == "" ? base : `${base}:${line}`
}

/* A name when there is one; else where the node was made; else its id. */
let shortLabel = (node: Devtools.node): string =>
  switch node {
  | {name: Some(name)} => name
  | {binding: Some({what, target})} => `${what} → ${lastStep(target)}`
  | {site: Some(site)} => shortSite(site)
  | {id} => `#${Int.toString(id)}`
  }

/* What a signal or computed holds, short enough for the diagram. */
let inlineValue = (node: Devtools.node): string =>
  switch node {
  | {kind: #signal | #computed, value: Some(value)} => " = " ++ value
  | _ => ""
  }

/* How a node is named in text: its name, else its creation site, else its id. */
let label = (id: int): string =>
  switch Devtools.inspect(id) {
  | Some({name: Some(name), kind}) => `${(kind :> string)} "${name}"`
  | Some({kind, binding: Some({what, target})}) =>
    `${(kind :> string)} #${Int.toString(id)} (${what} → ${target})`
  | Some({kind, site: Some(site)}) => `${(kind :> string)} ${shortSite(site)}`
  | Some({kind}) => `${(kind :> string)} #${Int.toString(id)}`
  | None => `#${Int.toString(id)}`
  }

let siteSuffix = (site: option<string>) =>
  switch site {
  | Some(site) => "  " ++ site
  | None => ""
  }

let describe = (event: Devtools.event): option<(string, string, option<int>)> =>
  switch event {
  | Written({id, changed: true, site}) =>
    let value =
      Devtools.inspect(id)
      ->Option.flatMap(node => node.value)
      ->Option.mapOr("", value => " = " ++ value)
    Some(("write", `write ${label(id)}${value}${siteSuffix(site)}`, Some(id)))
  | RunStart({id}) => Some(("run", `run ${label(id)}`, Some(id)))
  | DomWrite({what, target, node}) => Some(("dom", `dom ${what} ${target}`, node))
  | Reconciled({kept, created, removed, moved, rebuilt}) =>
    Some((
      "keyed",
      `keyed pass: kept ${Int.toString(kept)}, created ${Int.toString(
          created,
        )}, removed ${Int.toString(removed)}, moved ${Int.toString(moved)}, rebuilt ${Int.toString(
          rebuilt,
        )}`,
      None,
    ))
  | ScopeCreated({kind, key}) =>
    Some(("scope", `scope + ${(kind :> string)}${key->Option.mapOr("", key => ` "${key}"`)}`, None))
  | ScopeDisposed({id}) => Some(("scope", `scope - ${Int.toString(id)}`, None))
  | BatchStart => Some(("batch", "batch {", None))
  | BatchEnd => Some(("batch", "}", None))
  | Caught({message}) => Some(("issue", `caught: ${message}`, None))
  | HydrationWarning({message}) => Some(("issue", `hydration: ${message}`, None))
  | Probe({site, hidden: true}) => Some(("issue", `hidden read: ${site}`, None))
  | StateRestored({key, found: false, node}) =>
    Some((
      "issue",
      `ssr state: "${key}" was restored on the client, but the server never sent it`,
      node,
    ))
  | StateRestored({key, decoded: false, node}) =>
    Some((
      "issue",
      `ssr state: "${key}" could not be decoded; the signal kept its initial value`,
      node,
    ))
  | StateRestored({key, node}) =>
    Some((
      "state",
      `ssr state: "${key}" restored${node->Option.mapOr("", id => " into " ++ label(id))}`,
      node,
    ))
  | _ => None
  }

let plural = (n: int, word: string) => `${Int.toString(n)} ${word}${n == 1 ? "" : "s"}`

/* ---- the graph layout ---------------------------------------------------------- */

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
let textWidth = (chars: int): int => {
  let w = 32 + chars * 7
  w < 70 ? 70 : w
}

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
let computeLayout = (
  nodes: array<Devtools.node>,
  ~inScope: Devtools.node => bool,
  ~matches: Devtools.node => bool,
): layout => {
  let total = Array.length(nodes)
  let shown = nodes->Array.filter(node => inScope(node) && matches(node))
  let shown =
    Array.length(shown) > graphLimit ? shown->Array.slice(~start=0, ~end=graphLimit) : shown
  let ids = Set.make()
  shown->Array.forEach(node => ids->Set.add(node.id))
  let column = Map.make()
  let sorted = shown->Array.toSorted((a, b) => Int.toFloat(a.id - b.id))
  sorted->Array.forEach(node => {
    let depth = node.sources->Array.reduce(-1, (deepest, source) =>
      switch column->Map.get(source) {
      | Some(c) if c > deepest => c
      | _ => deepest
      }
    )
    column->Map.set(node.id, depth + 1)
  })
  let columns: array<array<Devtools.node>> = []
  sorted->Array.forEach(node => {
    let c = column->Map.get(node.id)->Option.getOr(0)
    while Array.length(columns) <= c {
      columns->Array.push([])->ignore
    }
    columns->Array.getUnsafe(c)->Array.push(node)->ignore
  })
  let row = Map.make()
  let gnodes = []
  let maxRows = ref(0)
  columns->Array.forEachWithIndex((members, c) => {
    let keyed = members->Array.map(node => {
      let rows = node.sources->Array.filterMap(source => row->Map.get(source))
      let center = switch rows {
      | [] => Int.toFloat(node.id)
      | rows =>
        rows->Array.reduce(0., (a, b) => a +. Int.toFloat(b)) /. Int.toFloat(Array.length(rows))
      }
      (center, node)
    })
    keyed
    ->Array.toSorted(((a, na), (b, nb)) => a == b ? Int.toFloat(na.id - nb.id) : a -. b)
    ->Array.forEachWithIndex(((_, node), r) => {
      row->Map.set(node.id, r)
      if r + 1 > maxRows.contents {
        maxRows := r + 1
      }
      let kind = kindOf(node)
      let text = clip(shortLabel(node), labelMax)
      let valueChars = totalMax - String.length(text)
      let value = clip(inlineValue(node), valueChars)
      gnodes
      ->Array.push({
        id: node.id,
        kind,
        text,
        valueChars: String.length(value) == 0 ? 0 : valueChars,
        x: margin + c * colW,
        y: margin + r * rowH,
        w: textWidth(String.length(text) + String.length(value)),
        sources: node.sources->Array.filter(source => ids->Set.has(source)),
      })
      ->ignore
    })
  })
  let edges = gnodes->Array.flatMap(node =>
    node.sources->Array.map(source => {
      ekey: Int.toString(source) ++ "-" ++ Int.toString(node.id),
      from: source,
      to: node.id,
    })
  )
  {
    signature: gnodes->Array.map(n => Int.toString(n.id) ++ n.text)->Array.join(",") ++
    "|" ++
    edges->Array.map(e => e.ekey)->Array.join(","),
    nodes: gnodes,
    edges,
    width: margin * 2 + Array.length(columns) * colW,
    height: margin * 2 + maxRows.contents * rowH,
    total,
  }
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

let kindPill = (kind: string) =>
  el("span", ~cls="pill", ~attrs=[View.attr("data-kind", kind)], [txt(kind)])

/* Scope `child` is `ancestor` or sits under it. */
let rec underScope = (scopes: Map.t<int, Devtools.scope>, child: int, ancestor: int, depth: int) =>
  child == ancestor ||
    (depth < 64 &&
      switch scopes->Map.get(child)->Option.flatMap(scope => scope.parent) {
      | Some(parent) => underScope(scopes, parent, ancestor, depth + 1)
      | None => false
      })

let scopeLabel = (scope: Devtools.scope) =>
  `${(scope.kind :> string)}${scope.key->Option.mapOr("", key => ` "${key}"`)} #${Int.toString(
      scope.id,
    )}`

let selectNode = (state: state, id: int) =>
  Signal.batch(() => {
    Signal.set(state.picked, None)
    Signal.set(state.selected, Some(id))
    Signal.set(state.detailOpen, true)
    Signal.set(state.tab, Graph)
  })

let nodeLink = (state: state, id: int) =>
  el("button", ~cls="link", ~events=[("click", _ => selectNode(state, id))], [txt(label(id))])

let rec causeView = (state: state, cause: Devtools.cause): View.node => {
  let verb = switch cause.action {
  | #written => "written"
  | #recomputed => "recomputed"
  | #ran => "ran"
  | #created => "ran for the first time"
  }
  el(
    "li",
    [
      el(
        "button",
        ~cls="link cause",
        ~events=[("click", _ => selectNode(state, cause.id))],
        [txt(`${label(cause.id)} ${verb}`)],
      ),
      el("span", ~cls="site", [txt(siteSuffix(cause.site))]),
      cause.causes->Array.length > 0
        ? el("ul", cause.causes->Array.map(causeView(state, ...)))
        : View.null(),
    ],
  )
}

let whyView = (state: state, id: int): View.node =>
  switch Devtools.why(id) {
  | Some(cause) => el("ul", ~cls="why", [causeView(state, cause)])
  | None => el("p", ~cls="muted", [txt("No run of this node is in the history yet.")])
  }

let reveal = (id: int) =>
  switch Devtools.targetOf(id) {
  | Some(element) => {
      revealElement(element)
      flashElement(element)
    }
  | None => ()
  }

/* ---- detail pane ------------------------------------------------------------------ */

let nodeDetail = (state: state, id: int) =>
  switch Devtools.inspect(id) {
  | None => el("div", ~cls="muted", [txt(`#${Int.toString(id)} is gone.`)])
  | Some(node) =>
    let kind = kindOf(node)
    let row = (key, value) => el("tr", [el("th", [txt(key)]), el("td", [value])])
    let links = ids =>
      ids->Array.length == 0
        ? txt("—")
        : el("span", ids->Array.flatMap(other => [nodeLink(state, other), txt("  ")]))
    el(
      "div",
      [
        el(
          "h3",
          [
            kindPill(kind),
            txt(
              switch node {
              | {name: Some(name)} => name
              | {site: Some(site)} => `${shortSite(site)}  #${Int.toString(id)}`
              | _ => `#${Int.toString(id)}`
              },
            ),
            el("span", ~cls="spacer", []),
            el(
              "button",
              ~cls="icon",
              ~attrs=[View.attr("title", "Close")],
              ~events=[("click", _ => Signal.set(state.detailOpen, false))],
              [txt("×")],
            ),
          ],
        ),
        el(
          "table",
          Array.concatMany(
            switch node.binding {
            | Some({what, target}) => [
                row(
                  "writes",
                  el(
                    "span",
                    [
                      txt(`${what} of `),
                      el("span", ~cls="value", [txt(target)]),
                      txt("  "),
                      el(
                        "button",
                        ~cls="small",
                        ~attrs=[View.attr("title", "Scroll the page to it and flash it")],
                        ~events=[("click", _ => reveal(id))],
                        [txt("reveal")],
                      ),
                    ],
                  ),
                ),
              ]
            | None => []
            },
            [
              [
                row("value", el("span", ~cls="value", [txt(node.value->Option.getOr("—"))])),
                row("site", txt(node.site->Option.getOr("—"))),
                row(
                  "scope",
                  switch node.scope {
                  | Some(scope) =>
                    el(
                      "button",
                      ~cls="link",
                      ~attrs=[View.attr("title", "Show only this scope in the graph")],
                      ~events=[("click", _ => Signal.set(state.scopeFilter, Some(scope)))],
                      [
                        txt(
                          Devtools.scopes()
                          ->Array.find(s => s.id == scope)
                          ->Option.mapOr(`#${Int.toString(scope)}`, scopeLabel),
                        ),
                      ],
                    )
                  | None => txt("none (created outside a render)")
                  },
                ),
                row("level", txt(Int.toString(node.level))),
                row("reads", links(node.sources)),
                row("read by", links(node.observers)),
              ],
              node.disposed ? [row("state", txt("disposed"))] : [],
            ],
          ),
        ),
        el("h4", [txt("Why did it last run?")]),
        whyView(state, id),
      ],
    )
  }

let pickedDetail = (state: state, {path, writers}: picked) =>
  el(
    "div",
    [
      el(
        "h3",
        [
          kindPill("binding"),
          txt(path),
          el("span", ~cls="spacer", []),
          el(
            "button",
            ~cls="icon",
            ~events=[("click", _ => Signal.set(state.detailOpen, false))],
            [txt("×")],
          ),
        ],
      ),
      writers->Array.length == 0
        ? el(
            "p",
            ~cls="muted",
            [
              txt(
                "No binding writes this element, so it never updates in place. If it should follow a signal, look for a one-shot prop or a hidden read.",
              ),
            ],
          )
        : el(
            "div",
            writers->Array.map(writer =>
              el("div", [el("h4", [nodeLink(state, writer)]), whyView(state, writer)])
            ),
          ),
    ],
  )

let detailPane = (state: state) =>
  View.tracked(() => {
    let _ = Signal.get(state.version)
    switch (Signal.get(state.picked), Signal.get(state.selected)) {
    | (Some(picked), None) => pickedDetail(state, picked)
    | (_, Some(id)) => nodeDetail(state, id)
    | (None, None) =>
      el(
        "p",
        ~cls="muted",
        [
          txt(
            "Select a node to see its value, what it reads, what reads it, and why it last ran. Pick an element on the page (⌖) to find the bindings that write it.",
          ),
        ],
      )
    }
  })

/* ---- graph tab -------------------------------------------------------------------- */

let graphView = (state: state, layout: Signal.t<layout>) => {
  let nodes = Computed.make(() => Signal.get(layout).nodes)
  let edges = Computed.make(() => Signal.get(layout).edges)
  let positions = Computed.make(() => {
    let map = Map.make()
    Signal.get(layout).nodes->Array.forEach(node => map->Map.set(node.id, node))
    map
  })
  /* What is lit: the hovered node (or the selection) and its neighbours. */
  let focus = Computed.make(() => {
    let around = switch Signal.get(state.hover) {
    | Some(id) => Some(id)
    | None => Signal.get(state.selected)
    }
    around->Option.map(id => {
      let set = Set.make()
      set->Set.add(id)
      Signal.get(edges)->Array.forEach(
        edge => {
          if edge.from == id {
            set->Set.add(edge.to)
          }
          if edge.to == id {
            set->Set.add(edge.from)
          }
        },
      )
      (id, set)
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
    let selected =
      Signal.get(state.selected) == Some(node.id) && !String.includes(focused, "selected")
        ? " selected"
        : ""
    let hot = Signal.get(state.hot)->Set.has(node.id) ? " hot" : ""
    "gnode" ++ focused ++ selected ++ hot
  }
  let path = (edge: gedge) =>
    switch (Signal.get(positions)->Map.get(edge.from), Signal.get(positions)->Map.get(edge.to)) {
    | (Some(a), Some(b)) => {
        let x1 = a.x + a.w
        let y1 = a.y + nodeH / 2
        let x2 = b.x
        let y2 = b.y + nodeH / 2
        let dx = (x2 - x1) / 2
        `M${Int.toString(x1)},${Int.toString(y1)} C${Int.toString(x1 + dx)},${Int.toString(
            y1,
          )} ${Int.toString(x2 - dx)},${Int.toString(y2)} ${Int.toString(x2)},${Int.toString(y2)}`
      }
    | _ => ""
    }
  let hoverTarget = (id: int, on: bool) =>
    if on {
      switch Devtools.targetOf(id) {
      | Some(element) => showOutline(element, "rgb(21,154,102)")
      | None => ()
      }
    } else {
      hideOutline()
    }
  el(
    "svg",
    ~attrs=[
      View.attr("xmlns", "http://www.w3.org/2000/svg"),
      View.computedAttr("width", () =>
        Float.toString(Int.toFloat(Signal.get(layout).width) *. Signal.get(state.zoom))
      ),
      View.computedAttr("height", () =>
        Float.toString(Int.toFloat(Signal.get(layout).height) *. Signal.get(state.zoom))
      ),
    ],
    [
      el(
        "g",
        ~attrs=[
          View.computedAttr("transform", () => `scale(${Float.toString(Signal.get(state.zoom))})`),
        ],
        [
          el(
            "g",
            [
              View.eachWithKey(
                edges,
                edge => edge.ekey,
                edge =>
                  el(
                    "path",
                    ~attrs=[
                      View.computedAttr("class", () => edgeClass(edge)),
                      View.computedAttr("d", () => path(edge)),
                    ],
                    [],
                  ),
              ),
            ],
          ),
          el(
            "g",
            [
              View.eachWithKey(
                nodes,
                node => Int.toString(node.id),
                node =>
                  el(
                    "g",
                    ~attrs=[
                      View.computedAttr("class", () => nodeClass(node)),
                      View.attr("data-kind", node.kind),
                      View.attr("data-id", Int.toString(node.id)),
                      View.attr(
                        "transform",
                        `translate(${Int.toString(node.x)},${Int.toString(node.y)})`,
                      ),
                    ],
                    ~events=[
                      ("click", _ => selectNode(state, node.id)),
                      (
                        "mouseenter",
                        _ => {
                          Signal.set(state.hover, Some(node.id))
                          hoverTarget(node.id, true)
                        },
                      ),
                      (
                        "mouseleave",
                        _ => {
                          Signal.set(state.hover, None)
                          hoverTarget(node.id, false)
                        },
                      ),
                    ],
                    [
                      el(
                        "title",
                        [
                          View.signalText(() => {
                            let _ = Signal.get(state.version)
                            let value =
                              Devtools.inspect(node.id)
                              ->Option.flatMap(n => n.value)
                              ->Option.mapOr("", v => "\n= " ++ v)
                            label(node.id) ++ value
                          }),
                        ],
                      ),
                      el(
                        "rect",
                        ~cls="box",
                        ~attrs=[
                          View.attr("width", Int.toString(node.w)),
                          View.attr("height", Int.toString(nodeH)),
                        ],
                        [],
                      ),
                      el(
                        "text",
                        ~cls="glyph",
                        ~attrs=[View.attr("x", "9"), View.attr("y", "16")],
                        [txt(glyphOf(node.kind))],
                      ),
                      el(
                        "text",
                        ~cls="label",
                        ~attrs=[View.attr("x", "24"), View.attr("y", "16")],
                        [
                          txt(node.text),
                          el(
                            "tspan",
                            ~cls="value",
                            [
                              View.signalText(() => {
                                let _ = Signal.get(state.version)
                                Devtools.inspect(node.id)->Option.mapOr("", v =>
                                  clip(inlineValue(v), node.valueChars)
                                )
                              }),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
              ),
            ],
          ),
        ],
      ),
    ],
  )
}

let kindChip = (state: state, name: string, get: kinds => bool, set: (kinds, bool) => kinds) =>
  el(
    "button",
    ~cls="chip",
    ~attrs=[
      View.attr("style", `--c: var(--${name})`),
      View.computedAttr("data-on", () => get(Signal.get(state.kinds)) ? "true" : "false"),
      View.attr("title", `Show or hide ${name}s`),
    ],
    ~events=[("click", _ => Signal.update(state.kinds, kinds => set(kinds, !get(kinds))))],
    [el("span", ~cls="sw", []), txt(name ++ "s")],
  )

let graphTab = (state: state) => {
  let scopesById = Computed.make(() => {
    let _ = Signal.get(state.version)
    let map = Map.make()
    Devtools.scopes()->Array.forEach(scope => map->Map.set(scope.id, scope))
    map
  })
  let layout = Computed.make(
    () => {
      let _ = Signal.get(state.version)
      let kinds = Signal.get(state.kinds)
      let filter = Signal.get(state.filter)->String.toLowerCase
      let scopeFilter = Signal.get(state.scopeFilter)
      let scopes = Signal.get(scopesById)
      computeLayout(
        Devtools.snapshot().nodes,
        ~inScope=node =>
          switch scopeFilter {
          | None => true
          | Some(wanted) =>
            switch node.scope {
            | Some(scope) => underScope(scopes, scope, wanted, 0)
            | None => false
            }
          },
        ~matches=node => {
          let kind = kindOf(node)
          let shownKind = switch kind {
          | "signal" => kinds.signals
          | "computed" => kinds.computeds
          | "effect" => kinds.effects
          | _ => kinds.bindings
          }
          shownKind &&
          (filter == "" ||
          String.includes(shortLabel(node)->String.toLowerCase, filter) ||
          String.includes(node.name->Option.getOr("")->String.toLowerCase, filter) ||
          String.includes(kind, filter) ||
          Int.toString(node.id) == filter)
        },
      )
    },
    ~equals=(a, b) => a.signature == b.signature,
  )
  let setZoom = factor =>
    Signal.update(state.zoom, zoom => {
      let next = zoom *. factor
      next < 0.4 ? 0.4 : next > 2.5 ? 2.5 : next
    })
  el(
    "div",
    ~cls="body",
    ~attrs=[
      View.computedAttr("data-detail", () => Signal.get(state.detailOpen) ? "true" : "false"),
    ],
    [
      el(
        "div",
        ~attrs=[
          View.attr("style", "display: flex; flex-direction: column; min-height: 0; min-width: 0"),
        ],
        [
          el(
            "div",
            ~cls="toolbar",
            [
              el(
                "input",
                ~attrs=[
                  View.attr("placeholder", "filter by name, kind or id"),
                  View.signalAttr("value", state.filter),
                ],
                ~events=[("input", event => Signal.set(state.filter, inputValue(event)))],
                [],
              ),
              kindChip(state, "signal", k => k.signals, (k, v) => {...k, signals: v}),
              kindChip(state, "computed", k => k.computeds, (k, v) => {...k, computeds: v}),
              kindChip(state, "effect", k => k.effects, (k, v) => {...k, effects: v}),
              kindChip(state, "binding", k => k.bindings, (k, v) => {...k, bindings: v}),
              View.tracked(() =>
                switch Signal.get(state.scopeFilter) {
                | Some(scope) =>
                  el(
                    "button",
                    ~cls="chip x",
                    ~attrs=[View.attr("title", "Stop filtering by scope")],
                    ~events=[("click", _ => Signal.set(state.scopeFilter, None))],
                    [
                      txt(
                        "in " ++
                        Signal.get(scopesById)
                        ->Map.get(scope)
                        ->Option.mapOr(`scope #${Int.toString(scope)}`, scopeLabel) ++ "  ×",
                      ),
                    ],
                  )
                | None => View.null()
                }
              ),
              el(
                "span",
                ~cls="zoom",
                [
                  el(
                    "button",
                    ~attrs=[View.attr("title", "Zoom out")],
                    ~events=[("click", _ => setZoom(0.8))],
                    [txt("−")],
                  ),
                  el(
                    "button",
                    ~attrs=[View.attr("title", "Reset zoom")],
                    ~events=[("click", _ => Signal.set(state.zoom, 1.))],
                    [
                      View.signalText(() =>
                        Int.toString(Float.toInt(Signal.get(state.zoom) *. 100.)) ++ "%"
                      ),
                    ],
                  ),
                  el(
                    "button",
                    ~attrs=[View.attr("title", "Zoom in")],
                    ~events=[("click", _ => setZoom(1.25))],
                    [txt("+")],
                  ),
                ],
              ),
              el(
                "button",
                ~cls="icon",
                ~attrs=[
                  View.attr("title", "Details"),
                  View.computedAttr("data-active", () =>
                    Signal.get(state.detailOpen) ? "true" : "false"
                  ),
                ],
                ~events=[("click", _ => Signal.update(state.detailOpen, open_ => !open_))],
                [txt("▤")],
              ),
            ],
          ),
          el(
            "div",
            ~cls="canvas",
            [
              View.tracked(() => {
                let current = Signal.get(layout)
                if Array.length(current.nodes) == 0 {
                  el(
                    "p",
                    ~cls="empty",
                    [
                      txt(
                        current.total == 0
                          ? Devtools.status().signals
                              ? "Nothing reactive yet."
                              : "The reactive graph is not visible: the loaded rescript-signals has no debug hooks."
                          : "Nothing matches the filters.",
                      ),
                    ],
                  )
                } else {
                  el(
                    "div",
                    [
                      graphView(state, layout),
                      Array.length(current.nodes) == graphLimit
                        ? el(
                            "p",
                            ~cls="empty",
                            [
                              txt(
                                `Showing ${Int.toString(graphLimit)} of ${Int.toString(
                                    current.total,
                                  )} nodes; filter to narrow.`,
                              ),
                            ],
                          )
                        : View.null(),
                    ],
                  )
                }
              }),
            ],
          ),
        ],
      ),
      View.tracked(() =>
        Signal.get(state.detailOpen) ? el("div", ~cls="detail", [detailPane(state)]) : View.null()
      ),
    ],
  )
}

/* ---- timeline ----------------------------------------------------------------------- */

let entryView = (state: state, entry: entry) =>
  el(
    "div",
    ~cls="entry " ++ entry.kind,
    switch entry.node {
    | Some(id) => [
        el(
          "button",
          ~cls="link",
          ~events=[("click", _ => selectNode(state, id))],
          [txt(entry.text)],
        ),
      ]
    | None => [txt(entry.text)]
    },
  )

let timelineTab = (state: state) =>
  el(
    "div",
    ~cls="timeline",
    [
      el(
        "div",
        ~attrs=[
          View.attr("style", "display: flex; gap: 8px; align-items: center; margin-bottom: 6px"),
        ],
        [
          el(
            "button",
            ~cls="small",
            ~events=[
              (
                "click",
                _ => {
                  Devtools.clearHistory()
                  Signal.set(state.transactions, [])
                },
              ),
            ],
            [txt("Clear")],
          ),
          el(
            "span",
            ~cls="muted",
            [
              View.signalText(() =>
                `${plural(Array.length(Signal.get(state.transactions)), "update")}; newest last`
              ),
            ],
          ),
        ],
      ),
      View.eachWithKey(
        state.transactions,
        tx => tx.key,
        tx =>
          el(
            "details",
            ~cls="tx",
            ~attrs=[
              View.attr(
                "data-issue",
                tx.entries->Array.some(e => e.kind == "issue") ? "true" : "false",
              ),
            ],
            [
              el(
                "summary",
                [
                  el(
                    "span",
                    ~cls="title",
                    switch tx.node {
                    | Some(id) => [
                        el(
                          "button",
                          ~cls="link",
                          ~events=[("click", _ => selectNode(state, id))],
                          [txt(tx.title)],
                        ),
                      ]
                    | None => [txt(tx.title)]
                    },
                  ),
                  el("span", ~cls="sum", [txt(tx.summary)]),
                ],
              ),
              el("div", ~cls="entries", tx.entries->Array.map(entryView(state, ...))),
            ],
          ),
      ),
    ],
  )

/* ---- scopes ------------------------------------------------------------------------ */

let scopesTab = (state: state) =>
  View.tracked(() => {
    let _ = Signal.get(state.version)
    let snapshot = Devtools.snapshot()
    let counts = Map.make()
    snapshot.nodes->Array.forEach(node =>
      switch node.scope {
      | Some(scope) => counts->Map.set(scope, counts->Map.get(scope)->Option.getOr(0) + 1)
      | None => ()
      }
    )
    let children = Map.make()
    snapshot.scopes->Array.forEach(scope => {
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
        if Array.length(rows) < transactionLimit * 2 {
          let n = counts->Map.get(scope.id)->Option.getOr(0)
          rows
          ->Array.push(
            el(
              "button",
              ~cls=scope.disposed ? "scope released" : "scope",
              ~attrs=[
                View.attr("style", `padding-left: ${Int.toString(depth * 14 + 10)}px`),
                View.attr("title", "Show only this scope in the graph"),
              ],
              ~events=[
                (
                  "click",
                  _ =>
                    Signal.batch(
                      () => {
                        Signal.set(state.scopeFilter, Some(scope.id))
                        Signal.set(state.tab, Graph)
                      },
                    ),
                ),
              ],
              [
                el("span", ~cls="k", [txt(scopeLabel(scope))]),
                el(
                  "span",
                  ~cls="n",
                  [txt(scope.disposed ? "released" : n == 0 ? "" : plural(n, "node"))],
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
      ? el(
          "p",
          ~cls="muted",
          [
            txt(
              "No scopes yet: keyed rows, fragment passes and boundaries appear here as the app renders them.",
            ),
          ],
        )
      : el("div", ~cls="scopes", rows)
  })

/* ---- issues ------------------------------------------------------------------------ */

let issueEntries = (state: state) =>
  Signal.get(state.transactions)->Array.flatMap(tx =>
    tx.entries->Array.filter(e => e.kind == "issue")
  )

let issuesTab = (state: state) =>
  View.tracked(() => {
    let _ = Signal.get(state.version)
    let leaks = Devtools.leaks()->Array.map(leak => {
      let reason = switch leak.reason {
      | #effectOutlivedScope => "still running after the scope that created it was released"
      | #computedOutlivedScope => "still subscribed after the scope that created it was released"
      | #unownedEffect => "created inside another node's run with no scope to own it: every run of that node creates another"
      }
      el(
        "div",
        ~cls="issue-card",
        [
          el("div", ~cls="what", [txt("leak")]),
          el("div", [nodeLink(state, leak.node), txt(" " ++ reason)]),
          el("div", ~cls="site", [txt(leak.site->Option.getOr(""))]),
        ],
      )
    })
    let issues =
      issueEntries(state)->Array.map(entry =>
        el(
          "div",
          ~cls="issue-card",
          [
            el("div", ~cls="what", [txt(entry.text->String.split(":")->Array.getUnsafe(0))]),
            el("div", [entryView(state, {...entry, kind: ""})]),
          ],
        )
      )
    let all = Array.concat(leaks, issues)
    Array.length(all) == 0
      ? el(
          "p",
          ~cls="muted",
          [txt("No leaks, hidden reads, caught failures or hydration warnings.")],
        )
      : el("div", ~cls="issues", all)
  })

/* ---- the panel ---------------------------------------------------------------------- */

let tabButton = (state: state, tab: tab, name: string, ~count: option<Signal.t<int>>=?) =>
  el(
    "button",
    ~cls="tab",
    ~attrs=[
      View.computedAttr("data-active", () => Signal.get(state.tab) == tab ? "true" : "false"),
    ],
    ~events=[("click", _ => Signal.set(state.tab, tab))],
    Array.concat(
      [txt(name)],
      switch count {
      | Some(count) => [
          View.tracked(() =>
            Signal.get(count) > 0
              ? el("span", ~cls="count", [txt(Int.toString(Signal.get(count)))])
              : View.null()
          ),
        ]
      | None => []
      },
    ),
  )

let panel = (state: state, ~host: Dom.element, ~issueCount: Signal.t<int>) => {
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
            Signal.set(state.detailOpen, true)
            Signal.set(state.tab, Graph)
            /* Select the first writer, so the graph lights up around it. */
            switch writers->Array.get(0) {
            | Some(first) => Signal.set(state.selected, Some(first))
            | None => ()
            }
          })
        )
    }
  let statusDot = () =>
    el(
      "span",
      ~attrs=[
        View.computedAttr("class", () => {
          let _ = Signal.get(state.version)
          Devtools.status().signals ? "dot" : "dot off"
        }),
        View.attr("title", "Green: the reactive graph is visible"),
      ],
      [],
    )
  View.tracked(() =>
    if !Signal.get(state.expanded) {
      el(
        "button",
        ~cls="launcher",
        ~attrs=[View.attr("title", "Xote devtools (Ctrl+Shift+X)")],
        ~events=[("click", _ => Signal.set(state.expanded, true))],
        [
          statusDot(),
          txt("xote"),
          View.tracked(() =>
            Signal.get(issueCount) > 0
              ? el("span", ~cls="badge", [txt(Int.toString(Signal.get(issueCount)))])
              : View.null()
          ),
        ],
      )
    } else {
      el(
        "div",
        ~cls="panel",
        ~attrs=[
          View.computedAttr("style", () => {
            let (w, h) = Signal.get(state.size)
            `width: ${Int.toString(w)}px; height: ${Int.toString(h)}px`
          }),
        ],
        [
          el(
            "div",
            ~cls="resize",
            ~attrs=[View.attr("title", "Drag to resize")],
            ~events=[
              (
                "mousedown",
                event =>
                  startResize(event, size => {
                    Signal.set(state.size, size)
                    saveSize(size)
                  }),
              ),
            ],
            [],
          ),
          el(
            "header",
            [
              el("span", ~cls="brand", [statusDot(), txt("xote")]),
              el(
                "span",
                ~cls="tabs",
                [
                  tabButton(state, Graph, "Graph"),
                  tabButton(state, Timeline, "Timeline"),
                  tabButton(state, Scopes, "Scopes"),
                  tabButton(state, Issues, "Issues", ~count=issueCount),
                ],
              ),
              el("span", ~cls="spacer", []),
              el(
                "button",
                ~cls="icon",
                ~attrs=[
                  View.attr("title", "Flash elements on the page as they update"),
                  View.computedAttr("data-active", () =>
                    Signal.get(state.highlight) ? "true" : "false"
                  ),
                ],
                ~events=[("click", _ => Signal.update(state.highlight, on => !on))],
                [txt("✦")],
              ),
              el(
                "button",
                ~cls="icon",
                ~attrs=[
                  View.attr("title", "Pick an element on the page"),
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
              el(
                "span",
                [
                  View.signalText(() => {
                    let _ = Signal.get(state.version)
                    let status = Devtools.status()
                    if status.signals {
                      let nodes = Devtools.snapshot().nodes
                      let count = kind => nodes->Array.filter(n => kindOf(n) == kind)->Array.length
                      `${plural(count("signal"), "signal")} · ${plural(
                          count("computed"),
                          "computed",
                        )} · ${plural(count("effect"), "effect")} · ${plural(
                          count("binding"),
                          "binding",
                        )}`
                    } else {
                      "graph not visible: rescript-signals has no debug hooks"
                    }
                  }),
                ],
              ),
              el("span", ~cls="spacer", []),
              el("span", [txt("Ctrl+Shift+X")]),
            ],
          ),
        ],
      )
    }
  )
}

/* ---- grouping events into updates ------------------------------------------------------ */

let summarize = (entries: array<entry>): string => {
  let computeds = ref(0)
  let effects = ref(0)
  let dom = ref(0)
  let created = ref(0)
  let disposed = ref(0)
  entries->Array.forEach(entry =>
    switch entry.kind {
    | "run" =>
      switch entry.node->Option.flatMap(Devtools.inspect) {
      | Some({kind: #computed}) => computeds := computeds.contents + 1
      | Some(_) => effects := effects.contents + 1
      | None => ()
      }
    | "dom" => dom := dom.contents + 1
    | "scope" =>
      if entry.text->String.startsWith("scope +") {
        created := created.contents + 1
      } else {
        disposed := disposed.contents + 1
      }
    | _ => ()
    }
  )
  [
    computeds.contents > 0 ? [plural(computeds.contents, "computed")] : [],
    effects.contents > 0 ? [plural(effects.contents, "effect")] : [],
    dom.contents > 0 ? [plural(dom.contents, "DOM write")] : [],
    created.contents + disposed.contents > 0
      ? [`scopes +${Int.toString(created.contents)}/−${Int.toString(disposed.contents)}`]
      : [],
  ]
  ->Array.flat
  ->Array.join(" · ")
}

/* Events are delivered synchronously, so a top-level write (or batch) and
 everything until the next one is what that write caused. */
let groupEvents = (events: array<Devtools.event>, counter: ref<int>): array<transaction> => {
  let out = []
  let current: ref<option<(string, option<int>, array<entry>)>> = ref(None)
  let depth = ref(0)
  let inBatch = ref(false)
  let close = () =>
    switch current.contents {
    /* An empty batch says nothing. */
    | Some((_, _, entries)) if entries->Array.every(entry => entry.kind == "batch") =>
      current := None
    | Some((title, node, entries)) => {
        counter := counter.contents + 1
        out
        ->Array.push({
          key: Int.toString(counter.contents),
          title,
          summary: summarize(entries),
          entries,
          node,
        })
        ->ignore
        current := None
      }
    | None => ()
    }
  events->Array.forEach(event => {
    let starts = switch event {
    | Written({changed: true}) => depth.contents == 0 && !inBatch.contents
    | BatchStart => true
    | _ => false
    }
    if starts {
      close()
    }
    switch event {
    | RunStart(_) => depth := depth.contents + 1
    | RunEnd(_) => depth := (depth.contents > 0 ? depth.contents - 1 : 0)
    | BatchStart => inBatch := true
    | BatchEnd => inBatch := false
    | _ => ()
    }
    switch describe(event) {
    | Some((kind, text, node)) => {
        counter := counter.contents + 1
        let entry = {key: Int.toString(counter.contents), kind, text, node}
        switch current.contents {
        | Some((title, txNode, entries)) => {
            entries->Array.push(entry)->ignore

            /* A batch is titled by its first write. */
            if title == "batch" && kind == "write" {
              current := Some((text->String.split("  ")->Array.getUnsafe(0), node, entries))
            } else {
              current := Some((title, txNode, entries))
            }
          }
        | None =>
          current :=
            Some((
              switch kind {
              | "write" => text->String.split("  ")->Array.getUnsafe(0)
              | "batch" => "batch"
              | _ => "render"
              },
              kind == "write" ? node : None,
              [entry],
            ))
        }
      }
    | None => ()
    }
  })
  close()
  out
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

  let (state, mounted, issueCount) = Devtools.mute(() => {
    let transactions = Signal.make([])
    (
      {
        expanded: Signal.make(expanded),
        tab: Signal.make(Graph),
        version: Signal.make(0),
        selected: Signal.make(None),
        hover: Signal.make(None),
        filter: Signal.make(""),
        kinds: Signal.make({signals: true, computeds: true, effects: true, bindings: true}),
        scopeFilter: Signal.make(None),
        transactions,
        hot: Signal.make(Set.make()),
        picking: Signal.make(false),
        picked: Signal.make(None),
        highlight: Signal.make(false),
        zoom: Signal.make(1.),
        detailOpen: Signal.make(true),
        size: Signal.make(loadSize()->Option.getOr(defaultSize)),
      },
      Signal.make(true),
      Signal.make(0),
    )
  })

  /* Muted as a whole: the batch below names no node, and would otherwise
   reach the subscriber and schedule this again, every frame. */
  let flush = () =>
    Devtools.mute(() => {
      scheduled := false
      let events = buffer->Array.copy
      buffer->Array.splice(~start=0, ~remove=Array.length(buffer), ~insert=[])
      let transactions = groupEvents(events, counter)
      let ran = Set.make()
      events->Array.forEach(event =>
        switch event {
        | RunStart({id}) | Written({id, changed: true}) => ran->Set.add(id)
        | DomWrite({node: Some(id)}) if Signal.peek(state.highlight) =>
          switch Devtools.targetOf(id) {
          | Some(element) => flashElement(element)
          | None => ()
          }
        | _ => ()
        }
      )
      Signal.batch(() => {
        if Array.length(transactions) > 0 {
          Signal.update(
            state.transactions,
            log => {
              let next = Array.concat(log, transactions)
              let excess = Array.length(next) - transactionLimit
              excess > 0 ? next->Array.slice(~start=excess) : next
            },
          )
        }
        if ran->Set.size > 0 {
          Signal.update(
            state.hot,
            hot => {
              let next = Set.make()
              hot->Set.forEach(id => next->Set.add(id))
              ran->Set.forEach(id => next->Set.add(id))
              next
            },
          )
          setTimeout_(
            () =>
              Devtools.mute(
                () =>
                  Signal.update(
                    state.hot,
                    hot => {
                      let next = Set.make()
                      hot->Set.forEach(
                        id =>
                          if !(ran->Set.has(id)) {
                            next->Set.add(id)
                          },
                      )
                      next
                    },
                  ),
              ),
            hotMs,
          )
        }
        Signal.update(state.version, v => v + 1)
        Signal.set(issueCount, Array.length(Devtools.leaks()) + Array.length(issueEntries(state)))
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
