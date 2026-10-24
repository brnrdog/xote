/* Public: devtools for Xote applications — the data model behind the
   `xote-lens` CLI, its MCP server and the in-page panel.

   Two streams are merged here into one: the reactive graph, reported by
   `rescript-signals` through `Signals.Debug`, and what only the renderer knows,
   reported by `RuntimeDevtools` (scopes, DOM writes, keyed passes, boundaries,
   hydration and probes). Everything is named by small integer ids this module
   assigns, in creation order, so the same program and the same interactions
   give the same ids — which is what lets an agent refer to "node 17" across
   several calls.

   `rescript-signals` is found through the global registry each loaded copy
   announces itself on, never imported: Xote still compiles against releases
   that predate the hooks, and a page with two copies of the library is
   instrumented in both. Without the hooks, `install` reports
   `signals: false` and only the renderer's events arrive.

   This module is reachable only through the `xote/devtools` entry, so the
   client bundles do not carry it. */

type nodeKind = [#signal | #computed | #effect]
type scopeKind = [#root | #fragment | #list | #row | #pass | #boundary | #hydratedRow]

type binding = {target: string, what: string}

type node = {
  id: int,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  scope: option<int>,
  binding: option<binding>,
  level: int,
  value: option<string>,
  sources: array<int>,
  observers: array<int>,
  dirty: bool,
  disposed: bool,
}

type scope = {
  id: int,
  kind: scopeKind,
  key: option<string>,
  parent: option<int>,
  disposed: bool,
}

type snapshot = {nodes: array<node>, scopes: array<scope>}

@tag("type")
type event =
  | Created({
      id: int,
      kind: nodeKind,
      name: option<string>,
      scope: option<int>,
      site: option<string>,
    })
  | Linked({source: int, target: int})
  | Unlinked({source: int, target: int})
  | Written({id: int, changed: bool, site: option<string>})
  | RunStart({id: int})
  | RunEnd({id: int, changed: bool, threw: bool})
  | Disposed({id: int})
  | Collected({id: int})
  | BatchStart
  | BatchEnd
  | ScopeCreated({id: int, kind: scopeKind, key: option<string>, parent: option<int>})
  | ScopeDisposed({id: int})
  | DomWrite({node: option<int>, target: string, what: string})
  | Reconciled({scope: int, kept: int, rebuilt: int, created: int, removed: int, moved: int})
  | Caught({message: string})
  | HydrationWarning({message: string})
  | Probe({site: string, hidden: bool})
  | StateRestored({key: string, node: option<int>, found: bool, decoded: bool})

type status = {signals: bool, copies: int}

type counts = {
  writes: int,
  effects: int,
  computeds: int,
  bindings: int,
  domWrites: int,
  scopesCreated: int,
  scopesDisposed: int,
  reconciled: int,
}

type trace = {events: array<event>, counts: counts}

type action = [#written | #recomputed | #ran | #created]

type rec cause = {
  id: int,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  action: action,
  causes: array<cause>,
}

type leakReason = [#effectOutlivedScope | #computedOutlivedScope | #unownedEffect]

type leak = {
  node: int,
  reason: leakReason,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  scope: option<int>,
}

/* ---- the rescript-signals side, as the registry hands it over ------------- */

/* These mirror `Signals.Debug`'s types exactly, so values crossing between the
   two compile to the same shapes. The registry entry's `version` guards the
   contract: an entry of another version is left alone. */
module Upstream = {
  /* The events are built only by `rescript-signals`, on its side of the
   registry, so no constructor is ever applied here. */
  @@warning("-37")

  type kind = [#Signal | #Computed | #Effect]

  @tag("type")
  type event =
    | Created({id: int, kind: kind, name: option<string>, stack: option<string>})
    | Linked({source: int, target: int})
    | Unlinked({source: int, target: int})
    | Written({id: int, changed: bool})
    | RunStart({id: int})
    | RunEnd({id: int, changed: bool, threw: bool})
    | Disposed({id: int})
    | Collected({id: int})
    | BatchStart
    | BatchEnd

  type hook = {emit: event => unit, captureStacks: bool}

  type node = {
    id: int,
    kind: kind,
    name: option<string>,
    level: int,
    value: option<Obj.t>,
    sources: array<int>,
    observers: array<int>,
    dirty: bool,
    disposed: bool,
  }

  type api = {
    version: int,
    install: hook => unit,
    uninstall: unit => unit,
    nodes: unit => array<int>,
    inspect: int => option<node>,
    /* Added after the first release of the hooks, so it may be missing. */
    idOfSignal?: Obj.t => option<int>,
  }

  let copies: unit => array<api> = %raw(`function () {
    try {
      var copies = globalThis[Symbol.for("rescript-signals.debug")]
      return Array.isArray(copies) ? copies.filter(function (c) { return c && c.version === 1 }) : []
    } catch (_) { return [] }
  }`)

  let toKind = (kind: kind): nodeKind =>
    switch kind {
    | #Signal => #signal
    | #Computed => #computed
    | #Effect => #effect
    }
}

/* ---- presentation helpers ---------------------------------------------------- */

/* A short, safe rendering of any value: depth- and length-limited, cycle-safe,
 and never calling into the value beyond reading its own properties. */
let preview: 'a => string = %raw(`function (value) {
  var seen = []
  function go(v, depth) {
    if (v === undefined) return "undefined"
    if (v === null) return "null"
    var t = typeof v
    if (t === "string") return JSON.stringify(v.length > 60 ? v.slice(0, 57) + "..." : v)
    if (t === "number" || t === "boolean" || t === "bigint") return String(v)
    if (t === "symbol") return v.toString()
    if (t === "function") return "ƒ " + (v.name || "anonymous")
    if (typeof Node !== "undefined" && v instanceof Node) {
      return v.nodeType === 1 ? "<" + v.tagName.toLowerCase() + ">" : v.nodeType === 3 ? "#text" : "#node"
    }
    if (seen.indexOf(v) !== -1) return "[cycle]"
    if (depth > 2) return Array.isArray(v) ? "[…]" : "{…}"
    seen.push(v)
    var out
    if (Array.isArray(v)) {
      var items = v.slice(0, 5).map(function (x) { return go(x, depth + 1) })
      if (v.length > 5) items.push("… " + (v.length - 5) + " more")
      out = "[" + items.join(", ") + "]"
    } else if (typeof v.TAG === "string" || typeof v.TAG === "number") {
      var args = Object.keys(v).filter(function (k) { return k !== "TAG" })
        .map(function (k) { return go(v[k], depth + 1) })
      out = v.TAG + (args.length ? "(" + args.join(", ") + ")" : "")
    } else {
      var keys = Object.keys(v)
      var entries = keys.slice(0, 5).map(function (k) { return k + ": " + go(v[k], depth + 1) })
      if (keys.length > 5) entries.push("… " + (keys.length - 5) + " more")
      out = "{" + entries.join(", ") + "}"
    }
    seen.pop()
    return out.length > 120 ? out.slice(0, 117) + "..." : out
  }
  try { return go(value, 0) } catch (_) { return "[unreadable]" }
}`)

/* A CSS-like path to a DOM node, for messages and JSON output. */
/* A CSS-like path to a DOM node, for messages and JSON output: up to the
   nearest id, at most four steps, preferring a class over a position, and
   skipping the `display: contents` wrappers fragments render into. */
let pathOf: Dom.element => string = %raw(`function (node) {
  function isWrapper(n) {
    return n.nodeType === 1 && n.tagName === "DIV" && !n.id && !n.className &&
      n.getAttribute("style") === "display: contents"
  }
  function step(n) {
    if (n.nodeType === 3) return "#text"
    if (n.nodeType === 8) return "<!--" + String(n.data).trim() + "-->"
    if (n.nodeType !== 1) return "#node"
    var tag = n.tagName.toLowerCase()
    if (n.id) return tag + "#" + n.id
    var cls = typeof n.className === "string" ? n.className.trim().split(/\s+/)[0] : ""
    var label = cls ? tag + "." + cls : tag
    var parent = n.parentNode
    if (parent && parent.children) {
      var same = Array.prototype.filter.call(parent.children, function (c) {
        return c.tagName === n.tagName && (!cls || (typeof c.className === "string" && c.className.trim().split(/\s+/)[0] === cls))
      })
      if (same.length > 1) label += ":nth-child(" + (Array.prototype.indexOf.call(parent.children, n) + 1) + ")"
    }
    return label
  }
  try {
    var parts = []
    var n = node
    var truncated = false
    while (n && n.nodeType !== 9) {
      if (!isWrapper(n)) {
        if (parts.length === 4) { truncated = true; break }
        parts.unshift(step(n))
        if (n.nodeType === 1 && (n.id || n.tagName === "BODY")) break
      }
      n = n.parentNode
    }
    if (n === null && parts.length > 0) parts.unshift("(detached)")
    else if (truncated) parts.unshift("…")
    return parts.join(" > ")
  } catch (_) { return "#node" }
}`)

/* The first stack frame outside the library: where user code created a node or
   wrote a signal. Frames are reported as `file:line:col` of the compiled
   `.res.mjs`, which sits next to its `.res` source. */
let siteOf: string => option<string> = %raw(`function (stack) {
  var lines = String(stack).split("\n").slice(1)
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (/rescript-signals|[\\/]xote[\\/](src|dist)[\\/]|node:internal|Devtools/.test(line)) continue
    /* In a bundle the paths are gone, but chunk names keep the module name. */
    if (/[\\/](Signal|Computed|Effect|Scheduler|Core|Debug|View|Html|XoteJSX|MaybeSignal|Context|Resource|Hydration|SSR|SSRState|Router|Runtime\w+)\.res[-.]/.test(line)) continue
    var match = line.match(/\(?((?:file:\/\/)?[^\s()]+):(\d+):(\d+)\)?\s*$/)
    if (match) {
      /* A page's origin says nothing; keep the path. */
      var file = match[1].replace(/^file:\/\//, "").replace(/^https?:\/\/[^\/]+\//, "")
      try {
        var cwd = typeof process !== "undefined" && process.cwd ? process.cwd() + "/" : ""
        if (cwd && file.indexOf(cwd) === 0) file = file.slice(cwd.length)
      } catch (_) {}
      return file + ":" + match[2] + ":" + match[3]
    }
  }
  return undefined
}`)

let captureStack: unit => string = %raw(`function () { return new Error().stack || "" }`)

let messageOf: Obj.t => string = %raw(`function (error) {
  try {
    if (error && typeof error.message === "string") return error.message
    if (error && error.RE_EXN_ID) return String(error.RE_EXN_ID) + (error._1 !== undefined ? " " + String(error._1) : "")
    return String(error)
  } catch (_) { return "[unreadable error]" }
}`)

/* ---- state ------------------------------------------------------------------------ */

type weakRef
let makeWeakRef: Dom.element => weakRef = %raw(`function (target) {
  return typeof WeakRef === "function" ? new WeakRef(target) : { deref: function () { return target } }
}`)
@send external deref: weakRef => Nullable.t<Dom.element> = "deref"

type nodeInfo = {
  gid: int,
  copy: int,
  local: int,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  scope: option<int>,
  /* What the effect writes, if it is a binding. The node is held weakly and
   its path worked out when read: at creation it is often still detached. */
  bindingTarget: option<weakRef>,
  bindingWhat: string,
  /* An effect created while another node was running, under no scope: every
   run of the outer one makes another. */
  unownedNested: bool,
}

type scopeInfo = {
  sid: int,
  skind: scopeKind,
  skey: option<string>,
  sparent: option<int>,
  mutable sdisposed: bool,
}

type weakMap
@new external makeWeakMap: unit => weakMap = "WeakMap"
@send external weakGet: (weakMap, Obj.t) => Nullable.t<int> = "get"
@send external weakSet: (weakMap, Obj.t, int) => unit = "set"
@send external weakGetAll: (weakMap, Obj.t) => Nullable.t<array<int>> = "get"
@send external weakSetAll: (weakMap, Obj.t, array<int>) => unit = "set"

let historyLimit = 20000

type state = {
  mutable active: bool,
  mutable captureStacks: bool,
  mutable copies: array<Upstream.api>,
  mutable nextNode: int,
  mutable nextScope: int,
  /* `${copy}:${localId}` → global id */
  localToGlobal: Map.t<string, int>,
  nodes: Map.t<int, nodeInfo>,
  scopes: Map.t<int, scopeInfo>,
  mutable scopeIds: weakMap,
  mutable writers: weakMap,
  mutable history: array<event>,
  listeners: array<event => unit>,
  /* The nodes currently running, innermost last. */
  running: array<int>,
  /* Ids created while muted, and everything they lead to. */
  mutedNodes: Set.t<int>,
  mutedScopes: Set.t<int>,
  mutable muteDepth: int,
}

let state: state = {
  active: false,
  captureStacks: true,
  copies: [],
  nextNode: 0,
  nextScope: 0,
  localToGlobal: Map.make(),
  nodes: Map.make(),
  scopes: Map.make(),
  scopeIds: makeWeakMap(),
  writers: makeWeakMap(),
  history: [],
  listeners: [],
  running: [],
  mutedNodes: Set.make(),
  mutedScopes: Set.make(),
  muteDepth: 0,
}

let localKey = (copy: int, local: int) => Int.toString(copy) ++ ":" ++ Int.toString(local)

let globalOf = (copy: int, local: int): option<int> =>
  state.localToGlobal->Map.get(localKey(copy, local))

let scopeIdOf = (scope: Obj.t): option<int> =>
  if RuntimeValue.isNullish(scope) {
    None
  } else {
    state.scopeIds->weakGet(scope)->Nullable.toOption
  }

let currentScope = (): option<int> =>
  switch RuntimeOwner.currentOwner.contents {
  | Some(owner) => scopeIdOf(Obj.magic(owner))
  | None => None
  }

let isMutedNode = (id: int) => state.mutedNodes->Set.has(id)

let isMuted = (event: event): bool =>
  switch event {
  | Created({id})
  | Written({id})
  | RunStart({id})
  | RunEnd({id})
  | Disposed({id})
  | Collected({id}) =>
    isMutedNode(id)
  | Linked({source, target}) | Unlinked({source, target}) =>
    isMutedNode(source) || isMutedNode(target)
  | ScopeCreated({id}) | ScopeDisposed({id}) => state.mutedScopes->Set.has(id)
  | Reconciled({scope}) => state.mutedScopes->Set.has(scope)
  | DomWrite({node: Some(id)}) => isMutedNode(id)
  | DomWrite(_) => state.muteDepth > 0
  /* A batch names no node, so it is muted by when it happens. */
  | BatchStart | BatchEnd => state.muteDepth > 0
  | StateRestored({node: Some(id)}) => isMutedNode(id)
  | Caught(_) | HydrationWarning(_) | Probe(_) | StateRestored(_) => false
  }

let deliver = (event: event): unit =>
  if !isMuted(event) {
    state.history->Array.push(event)->ignore
    if Array.length(state.history) > historyLimit {
      state.history = state.history->Array.slice(~start=historyLimit / 2)
    }
    state.listeners->Array.forEach(listener => listener(event))
  }

/* ---- translating the upstream stream ----------------------------------------------- */

let onUpstream = (copy: int, event: Upstream.event): unit =>
  switch event {
  | Created({id: local, kind, name, stack}) => {
      state.nextNode = state.nextNode + 1
      let gid = state.nextNode
      state.localToGlobal->Map.set(localKey(copy, local), gid)
      let kind = Upstream.toKind(kind)
      let scope = currentScope()
      let binding = switch kind {
      | #effect =>
        switch RuntimeDevtools.pendingBinding.contents {
        | Some({target, what}) => {
            RuntimeDevtools.pendingBinding := None
            let key: Obj.t = Obj.magic(target)
            switch state.writers->weakGetAll(key)->Nullable.toOption {
            | Some(ids) => ids->Array.push(gid)->ignore
            | None => state.writers->weakSetAll(key, [gid])
            }
            Some((makeWeakRef(target), what))
          }
        | None => None
        }
      | _ => None
      }
      let site = stack->Option.flatMap(siteOf)
      let muted =
        state.muteDepth > 0 ||
          switch scope {
          | Some(scope) => state.mutedScopes->Set.has(scope)
          | None => false
          }
      if muted {
        state.mutedNodes->Set.add(gid)
      }
      state.nodes->Map.set(
        gid,
        {
          gid,
          copy,
          local,
          kind,
          name,
          site,
          scope,
          bindingTarget: binding->Option.map(((target, _)) => target),
          bindingWhat: binding->Option.mapOr("", ((_, what)) => what),
          unownedNested: kind == #effect && scope == None && Array.length(state.running) > 0,
        },
      )
      deliver(Created({id: gid, kind, name, scope, site}))
    }
  | Linked({source, target}) =>
    switch (globalOf(copy, source), globalOf(copy, target)) {
    | (Some(source), Some(target)) => deliver(Linked({source, target}))
    | _ => ()
    }
  | Unlinked({source, target}) =>
    switch (globalOf(copy, source), globalOf(copy, target)) {
    | (Some(source), Some(target)) => deliver(Unlinked({source, target}))
    | _ => ()
    }
  | Written({id, changed}) =>
    switch globalOf(copy, id) {
    | Some(id) =>
      let site = state.captureStacks ? siteOf(captureStack()) : None
      deliver(Written({id, changed, site}))
    | None => ()
    }
  | RunStart({id}) =>
    switch globalOf(copy, id) {
    | Some(id) => {
        state.running->Array.push(id)->ignore
        deliver(RunStart({id: id}))
      }
    | None => ()
    }
  | RunEnd({id, changed, threw}) =>
    switch globalOf(copy, id) {
    | Some(id) => {
        let _ = state.running->Array.pop
        deliver(RunEnd({id, changed, threw}))
      }
    | None => ()
    }
  | Disposed({id}) =>
    switch globalOf(copy, id) {
    | Some(id) => deliver(Disposed({id: id}))
    | None => ()
    }
  | Collected({id}) =>
    switch globalOf(copy, id) {
    | Some(id) => deliver(Collected({id: id}))
    | None => ()
    }
  | BatchStart => deliver(BatchStart)
  | BatchEnd => deliver(BatchEnd)
  }

/* ---- translating the renderer's stream ----------------------------------------------- */

let toScopeKind = (kind: RuntimeDevtools.scopeKind): scopeKind =>
  switch kind {
  | #Root => #root
  | #Fragment => #fragment
  | #List => #list
  | #Row => #row
  | #Pass => #pass
  | #Boundary => #boundary
  | #HydratedRow => #hydratedRow
  }

let onRenderer = (event: RuntimeDevtools.event): unit =>
  switch event {
  | ScopeCreated({scope, kind, key, parent}) => {
      state.nextScope = state.nextScope + 1
      let sid = state.nextScope
      state.scopeIds->weakSet(scope, sid)
      let parent = parent->Option.flatMap(scopeIdOf)
      let muted =
        state.muteDepth > 0 ||
          switch parent {
          | Some(parent) => state.mutedScopes->Set.has(parent)
          | None => false
          }
      if muted {
        state.mutedScopes->Set.add(sid)
      }
      let kind = toScopeKind(kind)
      state.scopes->Map.set(sid, {sid, skind: kind, skey: key, sparent: parent, sdisposed: false})
      deliver(ScopeCreated({id: sid, kind, key, parent}))
    }
  | ScopeDisposed({scope}) =>
    switch scopeIdOf(scope)->Option.flatMap(sid => state.scopes->Map.get(sid)) {
    | Some(info) if !info.sdisposed => {
        info.sdisposed = true
        deliver(ScopeDisposed({id: info.sid}))
      }
    | _ => ()
    }
  | DomWrite({target, what}) => {
      let node = switch state.running->Array.at(-1) {
      | Some(id) =>
        switch state.nodes->Map.get(id) {
        | Some({kind: #effect}) => Some(id)
        | _ => None
        }
      | None => None
      }
      deliver(DomWrite({node, target: pathOf(target), what}))
    }
  | Reconciled({scope, kept, rebuilt, created, removed, moved}) =>
    switch scopeIdOf(scope) {
    | Some(scope) => deliver(Reconciled({scope, kept, rebuilt, created, removed, moved}))
    | None => ()
    }
  | Caught({error}) => deliver(Caught({message: messageOf(error)}))
  | HydrationWarning({message}) => deliver(HydrationWarning({message: message}))
  | Probe({site, hidden}) => deliver(Probe({site, hidden}))
  | StateRestored({key, signal, found, decoded}) =>
    let node =
      state.copies
      ->Array.mapWithIndex((copy, index) =>
        switch copy.idOfSignal {
        | Some(idOfSignal) => idOfSignal(signal)->Option.flatMap(local => globalOf(index, local))
        | None => None
        }
      )
      ->Array.find(Option.isSome)
      ->Option.flatMap(id => id)
    deliver(StateRestored({key, node, found, decoded}))
  }

/* ---- installing ------------------------------------------------------------------ */

let status = (): status => {
  signals: Array.length(state.copies) > 0,
  copies: Array.length(state.copies),
}

let reset = () => {
  state.nextNode = 0
  state.nextScope = 0
  state.localToGlobal->Map.clear
  state.nodes->Map.clear
  state.scopes->Map.clear
  state.scopeIds = makeWeakMap()
  state.writers = makeWeakMap()
  state.history = []
  state.running->Array.splice(~start=0, ~remove=Array.length(state.running), ~insert=[])
  state.mutedNodes->Set.clear
  state.mutedScopes->Set.clear
  state.muteDepth = 0
}

let uninstall = (): unit =>
  if state.active {
    state.copies->Array.forEach(copy => copy.uninstall())
    state.copies = []
    RuntimeDevtools.enabled := false
    RuntimeDevtools.listener := None
    RuntimeDevtools.pendingBinding := None
    state.active = false
    reset()
  }

let install = (~captureStacks: bool=true, ()): status => {
  uninstall()
  state.active = true
  state.captureStacks = captureStacks
  state.copies = Upstream.copies()
  state.copies->Array.forEachWithIndex((copy, index) =>
    copy.install({emit: event => onUpstream(index, event), captureStacks})
  )
  RuntimeDevtools.listener := Some(onRenderer)
  RuntimeDevtools.enabled := true
  status()
}

let installed = (): bool => state.active

let subscribe = (listener: event => unit): (unit => unit) => {
  state.listeners->Array.push(listener)->ignore
  () => {
    switch state.listeners->Array.indexOf(listener) {
    | -1 => ()
    | index => state.listeners->Array.splice(~start=index, ~remove=1, ~insert=[])
    }
  }
}

let mute = (fn: unit => 'a): 'a => {
  state.muteDepth = state.muteDepth + 1
  try {
    let result = fn()
    state.muteDepth = state.muteDepth - 1
    result
  } catch {
  | exn =>
    state.muteDepth = state.muteDepth - 1
    throw(exn)
  }
}

let history = (): array<event> => state.history->Array.copy

let clearHistory = (): unit => state.history = []

/* ---- reading the graph -------------------------------------------------------------- */

let upstreamNode = (info: nodeInfo): option<Upstream.node> =>
  switch state.copies->Array.get(info.copy) {
  | Some(copy) => copy.inspect(info.local)
  | None => None
  }

let bindingOf = (info: nodeInfo): option<binding> =>
  info.bindingTarget->Option.map(target => {
    target: switch target->deref->Nullable.toOption {
    | Some(element) => pathOf(element)
    | None => "(collected)"
    },
    what: info.bindingWhat,
  })

let globalIds = (info: nodeInfo, locals: array<int>): array<int> =>
  locals->Array.filterMap(local => globalOf(info.copy, local))

let inspect = (id: int): option<node> =>
  switch state.nodes->Map.get(id) {
  | None => None
  | Some(info) =>
    upstreamNode(info)->Option.map(live => {
      id,
      kind: info.kind,
      name: info.name,
      site: info.site,
      scope: info.scope,
      binding: bindingOf(info),
      level: live.level,
      value: live.value->Option.map(preview),
      sources: globalIds(info, live.sources),
      observers: globalIds(info, live.observers),
      dirty: live.dirty,
      disposed: live.disposed,
    })
  }

let value = (id: int): option<unknown> =>
  switch state.nodes->Map.get(id) {
  | None => None
  | Some(info) => upstreamNode(info)->Option.flatMap(live => live.value->Option.map(Obj.magic))
  }

let rec scopeDead = (id: int, depth: int): bool =>
  depth < 64 &&
    switch state.scopes->Map.get(id) {
    | None => false
    | Some(info) =>
      info.sdisposed ||
      switch info.sparent {
      | Some(parent) => scopeDead(parent, depth + 1)
      | None => false
      }
    }

let scopeOf = (info: scopeInfo): scope => {
  id: info.sid,
  kind: info.skind,
  key: info.skey,
  parent: info.sparent,
  disposed: scopeDead(info.sid, 0),
}

let scopes = (): array<scope> =>
  state.scopes
  ->Map.values
  ->Iterator.toArray
  ->Array.filter(info => !(state.mutedScopes->Set.has(info.sid)))
  ->Array.map(scopeOf)

let snapshot = (): snapshot => {
  let nodes =
    state.nodes
    ->Map.keys
    ->Iterator.toArray
    ->Array.filter(id => !isMutedNode(id))
    ->Array.filterMap(inspect)
  {nodes, scopes: scopes()}
}

let writersOf = (element: Dom.element): array<int> =>
  state.writers->weakGetAll(Obj.magic(element))->Nullable.toOption->Option.getOr([])->Array.copy

/* ---- traces and budgets ------------------------------------------------------------ */

let countEvents = (events: array<event>): counts => {
  let writes = ref(0)
  let effects = ref(0)
  let computeds = ref(0)
  let bindings = ref(0)
  let domWrites = ref(0)
  let scopesCreated = ref(0)
  let scopesDisposed = ref(0)
  let reconciled = ref(0)
  events->Array.forEach(event =>
    switch event {
    | Written({changed: true}) => writes := writes.contents + 1
    | RunStart({id}) =>
      switch state.nodes->Map.get(id) {
      | Some({kind: #effect, bindingTarget}) => {
          effects := effects.contents + 1
          if bindingTarget->Option.isSome {
            bindings := bindings.contents + 1
          }
        }
      | Some({kind: #computed}) => computeds := computeds.contents + 1
      | _ => ()
      }
    | DomWrite(_) => domWrites := domWrites.contents + 1
    | ScopeCreated(_) => scopesCreated := scopesCreated.contents + 1
    | ScopeDisposed(_) => scopesDisposed := scopesDisposed.contents + 1
    | Reconciled(_) => reconciled := reconciled.contents + 1
    | _ => ()
    }
  )
  {
    writes: writes.contents,
    effects: effects.contents,
    computeds: computeds.contents,
    bindings: bindings.contents,
    domWrites: domWrites.contents,
    scopesCreated: scopesCreated.contents,
    scopesDisposed: scopesDisposed.contents,
    reconciled: reconciled.contents,
  }
}

let record = (fn: unit => unit): trace => {
  let events = []
  let unsubscribe = subscribe(event => events->Array.push(event)->ignore)
  try {
    fn()
  } catch {
  | exn =>
    unsubscribe()
    throw(exn)
  }
  unsubscribe()
  {events, counts: countEvents(events)}
}

module Budget = {
  let check = (
    trace: trace,
    ~writes: option<int>=?,
    ~effects: option<int>=?,
    ~computeds: option<int>=?,
    ~bindings: option<int>=?,
    ~domWrites: option<int>=?,
    ~scopesCreated: option<int>=?,
    ~scopesDisposed: option<int>=?,
  ): result<unit, string> => {
    let counts = trace.counts
    let failures = [
      ("writes", writes, counts.writes),
      ("effects", effects, counts.effects),
      ("computeds", computeds, counts.computeds),
      ("bindings", bindings, counts.bindings),
      ("domWrites", domWrites, counts.domWrites),
      ("scopesCreated", scopesCreated, counts.scopesCreated),
      ("scopesDisposed", scopesDisposed, counts.scopesDisposed),
    ]->Array.filterMap(((label, expected, actual)) =>
      switch expected {
      | Some(expected) if expected != actual =>
        Some(`${label}: expected ${Int.toString(expected)}, got ${Int.toString(actual)}`)
      | _ => None
      }
    )
    switch failures {
    | [] => Ok()
    | failures => Error(failures->Array.join("; "))
    }
  }
}

/* ---- why did this run? ---------------------------------------------------------------- */

/* Index of the last event at or before `before` that satisfies `test`. */
let findLast = (events: array<event>, ~before: int, test: event => bool): option<int> => {
  let index = ref(min(before, Array.length(events) - 1))
  let found = ref(None)
  while found.contents == None && index.contents >= 0 {
    if test(events->Array.getUnsafe(index.contents)) {
      found := Some(index.contents)
    }
    index := index.contents - 1
  }
  found.contents
}

let findNext = (events: array<event>, ~after: int, test: event => bool): option<int> => {
  let index = ref(after + 1)
  let found = ref(None)
  while found.contents == None && index.contents < Array.length(events) {
    if test(events->Array.getUnsafe(index.contents)) {
      found := Some(index.contents)
    }
    index := index.contents + 1
  }
  found.contents
}

let rec explain = (events: array<event>, id: int, ~before: int, ~depth: int): option<cause> =>
  switch state.nodes->Map.get(id) {
  | None => None
  | Some(info) =>
    let base = (action, causes) => {
      id,
      kind: info.kind,
      name: info.name,
      site: info.site,
      action,
      causes,
    }
    switch info.kind {
    | #signal =>
      findLast(events, ~before, event =>
        switch event {
        | Written({id: written, changed: true}) => written == id
        | _ => false
        }
      )->Option.map(index => {
        let site = switch events->Array.getUnsafe(index) {
        | Written({site}) => site
        | _ => None
        }
        {...base(#written, []), site: site->Option.orElse(info.site)}
      })
    | #computed | #effect =>
      let isStart = event =>
        switch event {
        | RunStart({id: started}) => started == id
        | _ => false
        }
      let isEnd = event =>
        switch event {
        | RunEnd({id: ended}) => ended == id
        | _ => false
        }
      switch findLast(events, ~before, isStart) {
      | None => None
      | Some(start) =>
        let previousEnd = findLast(events, ~before=start - 1, isEnd)->Option.getOr(-1)
        let end_ = findNext(events, ~after=start, isEnd)->Option.getOr(Array.length(events))
        let isFirstRun = switch findLast(events, ~before=start - 1, isStart) {
        | Some(_) => false
        | None =>
          /* The creation run directly follows `Created`, when the history holds it. */
          findLast(events, ~before=start, event =>
            switch event {
            | Created({id: created}) => created == id
            | _ => false
            }
          )->Option.isSome
        }
        if isFirstRun {
          Some(base(#created, []))
        } else {
          /* Every source the node read during or before this run. */
          let sources = Set.make()
          switch inspect(id) {
          | Some(live) => live.sources->Array.forEach(source => sources->Set.add(source))
          | None => ()
          }
          let index = ref(0)
          while index.contents < end_ {
            switch events->Array.getUnsafe(index.contents) {
            | Linked({source, target}) if target == id => sources->Set.add(source)
            | _ => ()
            }
            index := index.contents + 1
          }
          /* A source caused this run if it changed after the previous run
             ended: a written signal before the run started, or a computed
             that recomputed to a new value — which, computeds being lazy, can
             happen inside this very run when it pulls the computed. */
          let causes = if depth >= 16 {
            []
          } else {
            sources
            ->Set.values
            ->Iterator.toArray
            ->Array.filterMap(source => {
              let changedAt = findLast(events, ~before=end_ - 1, event =>
                switch event {
                | Written({id: written, changed: true}) => written == source
                | RunEnd({id: ended, changed: true, threw: false}) => ended == source
                | _ => false
                }
              )
              switch changedAt {
              | Some(at) if at > previousEnd =>
                explain(events, source, ~before=at, ~depth=depth + 1)
              | _ => None
              }
            })
          }
          Some(base(info.kind == #computed ? #recomputed : #ran, causes))
        }
      }
    }
  }

let why = (id: int): option<cause> => {
  let events = state.history
  explain(events, id, ~before=Array.length(events) - 1, ~depth=0)
}

/* ---- leaks -------------------------------------------------------------------------- */

let leaks = (): array<leak> =>
  state.nodes
  ->Map.values
  ->Iterator.toArray
  ->Array.filter(info => !isMutedNode(info.gid))
  ->Array.filterMap(info =>
    switch upstreamNode(info) {
    | None => None
    | Some(live) =>
      let outlived = switch info.scope {
      | Some(scope) => scopeDead(scope, 0)
      | None => false
      }
      let reason = switch info.kind {
      | #effect if live.disposed => None
      | #effect if outlived => Some(#effectOutlivedScope)
      | #effect if info.unownedNested => Some(#unownedEffect)
      | #computed if outlived && Array.length(live.observers) > 0 => Some(#computedOutlivedScope)
      | _ => None
      }
      reason->Option.map(reason => {
        node: info.gid,
        reason,
        kind: info.kind,
        name: info.name,
        site: info.site,
        scope: info.scope,
      })
    }
  )
