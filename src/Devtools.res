/* Public: devtools for Xote applications — the data model behind the
   `xote-lens` CLI, its MCP server and the in-page panel. It merges the
   reactive graph, from `Signals.Debug`, with what only the renderer knows,
   from `RuntimeDevtools`, naming everything by ids in creation order.

   Each loaded copy of `rescript-signals` is found at runtime through the
   global registry it announces itself on, so a page with two copies is
   instrumented in both. */

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

/* A registry entry of `version` 1; entries of other versions are left alone. */
type upstream = {
  install: Signals.Debug.hook => unit,
  uninstall: unit => unit,
  inspect: int => option<Signals.Debug.node>,
  /* Added after the first release of the hooks, so it may be missing. */
  idOfSignal?: Obj.t => option<int>,
}

let upstreamCopies: unit => array<upstream> = %raw(`function () {
  try {
    var copies = globalThis[Symbol.for("rescript-signals.debug")]
    return Array.isArray(copies) ? copies.filter(function (c) { return c && c.version === 1 }) : []
  } catch (_) { return [] }
}`)

let toNodeKind = (kind: Signals.Debug.nodeKind): nodeKind =>
  switch kind {
  | #Signal => #signal
  | #Computed => #computed
  | #Effect => #effect
  }

/* Depth- and length-limited, and never calling into the value beyond reading
 its own properties. */
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
    function list(all, show, open, close) {
      var items = all.slice(0, 5).map(show)
      if (all.length > 5) items.push("… " + (all.length - 5) + " more")
      return open + items.join(", ") + close
    }
    seen.push(v)
    var out
    if (Array.isArray(v)) out = list(v, function (x) { return go(x, depth + 1) }, "[", "]")
    else if (typeof v.TAG === "string" || typeof v.TAG === "number") {
      var args = Object.keys(v).filter(function (k) { return k !== "TAG" }).map(function (k) { return go(v[k], depth + 1) })
      out = v.TAG + (args.length ? "(" + args.join(", ") + ")" : "")
    } else out = list(Object.keys(v), function (k) { return k + ": " + go(v[k], depth + 1) }, "{", "}")
    seen.pop()
    return out.length > 120 ? out.slice(0, 117) + "..." : out
  }
  try { return go(value, 0) } catch (_) { return "[unreadable]" }
}`)

/* Up to the nearest id, at most four steps, preferring a class over a
   position, and skipping the `display: contents` wrappers fragments render
   into. */
let pathOf: Dom.element => string = %raw(`function (node) {
  function isWrapper(n) {
    return n.nodeType === 1 && n.tagName === "DIV" && !n.id && !n.className &&
      n.getAttribute("style") === "display: contents"
  }
  function firstClass(n) {
    return typeof n.className === "string" ? n.className.trim().split(/\s+/)[0] : ""
  }
  function step(n) {
    if (n.nodeType === 3) return "#text"
    if (n.nodeType === 8) return "<!--" + String(n.data).trim() + "-->"
    if (n.nodeType !== 1) return "#node"
    var tag = n.tagName.toLowerCase()
    if (n.id) return tag + "#" + n.id
    var cls = firstClass(n)
    var label = cls ? tag + "." + cls : tag
    var parent = n.parentNode
    if (parent && parent.children) {
      var same = Array.prototype.filter.call(parent.children, function (c) {
        return c.tagName === n.tagName && (!cls || firstClass(c) === cls)
      })
      if (same.length > 1) label += ":nth-child(" + (Array.prototype.indexOf.call(parent.children, n) + 1) + ")"
    }
    return label
  }
  try {
    var parts = [], n = node, truncated = false
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

/* The first stack frame outside the library, as `file:line:col` of the
 compiled `.res.mjs` (which sits next to its `.res`). */
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
      var file = match[1].replace(/^file:\/\//, "").replace(/^https?:\/\/[^\/]+\//, "").replace(/\?.*$/, "")
      try { var cwd = typeof process !== "undefined" && process.cwd ? process.cwd() + "/" : "" } catch (_) {}
      if (cwd && file.indexOf(cwd) === 0) file = file.slice(cwd.length)
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

type weakRef
let makeWeakRef: Dom.element => weakRef = %raw(`function (target) {
  return typeof WeakRef === "function" ? new WeakRef(target) : { deref: function () { return target } }
}`)
@send @return(nullable) external deref: weakRef => option<Dom.element> = "deref"

type weakMap<'v>
@new external makeWeakMap: unit => weakMap<'v> = "WeakMap"
/* A non-object key reads as missing. */
@send @return(nullable) external weakGet: (weakMap<'v>, Obj.t) => option<'v> = "get"
@send external weakSet: (weakMap<'v>, Obj.t, 'v) => unit = "set"

type nodeInfo = {
  id: int,
  copy: int,
  local: int,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  scope: option<int>,
  /* A binding's DOM node, held weakly (its path is worked out when read: at
   creation it is often detached), and what it writes. */
  binding: option<(weakRef, string)>,
  /* An effect created while another node was running, under no scope: every
   run of the outer one makes another. */
  unownedNested: bool,
}

let historyLimit = 20000

let active = ref(false)
let captureStacks = ref(true)
let copies: ref<array<upstream>> = ref([])
let listeners: array<event => unit> = []
let log: ref<array<event>> = ref([])
let nextNode = ref(0)
let nextScope = ref(0)
/* `${copy}:${localId}` → id */
let localToGlobal: Map.t<string, int> = Map.make()
let nodes: Map.t<int, nodeInfo> = Map.make()
/* `disposed` here is whether the scope itself was released. */
let scopeInfos: Map.t<int, scope> = Map.make()
let scopeIds: ref<weakMap<int>> = ref(makeWeakMap())
let writers: ref<weakMap<array<int>>> = ref(makeWeakMap())
/* The nodes currently running, innermost last. */
let running: array<int> = []
/* Ids created while muted, and everything created under them. */
let mutedNodes: Set.t<int> = Set.make()
let mutedScopes: Set.t<int> = Set.make()
let muteDepth = ref(0)

let localKey = (copy, local) => `${Int.toString(copy)}:${Int.toString(local)}`
let globalOf = (copy, local) => localToGlobal->Map.get(localKey(copy, local))
let scopeIdOf = (scope: Obj.t) => scopeIds.contents->weakGet(scope)
let currentScope = () =>
  RuntimeOwner.currentOwner.contents->Option.flatMap(owner => scopeIdOf(Obj.magic(owner)))

let nodeMuted = id => mutedNodes->Set.has(id)
let scopeMuted = id => mutedScopes->Set.has(id)
/* Whether something created now, under `scope`, is muted. */
let underMute = scope => muteDepth.contents > 0 || scope->Option.mapOr(false, scopeMuted)

let isMuted = (event: event): bool =>
  switch event {
  | Created({id})
  | Written({id})
  | RunStart({id})
  | RunEnd({id})
  | Disposed({id})
  | Collected({id})
  | DomWrite({node: Some(id)})
  | StateRestored({node: Some(id)}) =>
    nodeMuted(id)
  | Linked({source, target}) | Unlinked({source, target}) => nodeMuted(source) || nodeMuted(target)
  | ScopeCreated({id}) | ScopeDisposed({id}) | Reconciled({scope: id}) => scopeMuted(id)
  /* Naming no node, these are muted by when they happen. */
  | DomWrite(_) | BatchStart | BatchEnd => muteDepth.contents > 0
  | Caught(_) | HydrationWarning(_) | Probe(_) | StateRestored(_) => false
  }

let deliver = (event: event): unit =>
  if !isMuted(event) {
    log.contents->Array.push(event)
    if Array.length(log.contents) > historyLimit {
      log := log.contents->Array.slice(~start=historyLimit / 2)
    }
    listeners->Array.forEach(listener => listener(event))
  }

let onUpstream = (copy: int, event: Signals.Debug.event): unit => {
  let withId = (local, f) => globalOf(copy, local)->Option.forEach(f)
  let withEdge = (source, target, f) =>
    switch (globalOf(copy, source), globalOf(copy, target)) {
    | (Some(source), Some(target)) => f(source, target)
    | _ => ()
    }
  switch event {
  | Created({id: local, kind, name, stack}) =>
    nextNode := nextNode.contents + 1
    let id = nextNode.contents
    localToGlobal->Map.set(localKey(copy, local), id)
    let kind = toNodeKind(kind)
    let scope = currentScope()
    let site = stack->Option.flatMap(siteOf)
    /* A binding announces its target just before creating its effect. */
    let binding = switch (kind, RuntimeDevtools.pendingBinding.contents) {
    | (#effect, Some({target, what})) =>
      RuntimeDevtools.pendingBinding := None
      switch writers.contents->weakGet(Obj.magic(target)) {
      | Some(ids) => ids->Array.push(id)
      | None => writers.contents->weakSet(Obj.magic(target), [id])
      }
      Some((makeWeakRef(target), what))
    | _ => None
    }
    if underMute(scope) {
      mutedNodes->Set.add(id)
    }
    let unownedNested = kind == #effect && scope == None && Array.length(running) > 0
    nodes->Map.set(id, {id, copy, local, kind, name, site, scope, binding, unownedNested})
    deliver(Created({id, kind, name, scope, site}))
  | Linked({source, target}) =>
    withEdge(source, target, (source, target) => deliver(Linked({source, target})))
  | Unlinked({source, target}) =>
    withEdge(source, target, (source, target) => deliver(Unlinked({source, target})))
  | Written({id, changed}) =>
    /* Not through `withId`: its Stdlib frame would read as the write's site. */
    switch globalOf(copy, id) {
    | Some(id) =>
      let site = captureStacks.contents ? siteOf(captureStack()) : None
      deliver(Written({id, changed, site}))
    | None => ()
    }
  | RunStart({id}) =>
    withId(id, id => {
      running->Array.push(id)
      deliver(RunStart({id: id}))
    })
  | RunEnd({id, changed, threw}) =>
    withId(id, id => {
      running->Array.pop->ignore
      deliver(RunEnd({id, changed, threw}))
    })
  | Disposed({id}) => withId(id, id => deliver(Disposed({id: id})))
  | Collected({id}) => withId(id, id => deliver(Collected({id: id})))
  | BatchStart => deliver(BatchStart)
  | BatchEnd => deliver(BatchEnd)
  }
}

let onRenderer = (event: RuntimeDevtools.event): unit =>
  switch event {
  | ScopeCreated({scope, kind, key, parent}) =>
    nextScope := nextScope.contents + 1
    let id = nextScope.contents
    scopeIds.contents->weakSet(scope, id)
    let parent = parent->Option.flatMap(scopeIdOf)
    if underMute(parent) {
      mutedScopes->Set.add(id)
    }
    scopeInfos->Map.set(id, {id, kind, key, parent, disposed: false})
    deliver(ScopeCreated({id, kind, key, parent}))
  | ScopeDisposed({scope}) =>
    switch scopeIdOf(scope)->Option.flatMap(id => scopeInfos->Map.get(id)) {
    | Some(info) if !info.disposed =>
      scopeInfos->Map.set(info.id, {...info, disposed: true})
      deliver(ScopeDisposed({id: info.id}))
    | _ => ()
    }
  | DomWrite({target, what}) =>
    /* Written by the running effect: the binding. */
    let node =
      running
      ->Array.at(-1)
      ->Option.filter(id => nodes->Map.get(id)->Option.mapOr(false, info => info.kind == #effect))
    deliver(DomWrite({node, target: pathOf(target), what}))
  | Reconciled({scope, kept, rebuilt, created, removed, moved}) =>
    scopeIdOf(scope)->Option.forEach(scope =>
      deliver(Reconciled({scope, kept, rebuilt, created, removed, moved}))
    )
  | Caught({error}) => deliver(Caught({message: messageOf(error)}))
  | HydrationWarning({message}) => deliver(HydrationWarning({message: message}))
  | Probe({site, hidden}) => deliver(Probe({site, hidden}))
  | StateRestored({key, signal, found, decoded}) =>
    let node =
      copies.contents
      ->Array.mapWithIndex((copy, index) =>
        copy.idOfSignal
        ->Option.flatMap(idOfSignal => idOfSignal(signal))
        ->Option.flatMap(local => globalOf(index, local))
      )
      ->Array.findMap(id => id)
    deliver(StateRestored({key, node, found, decoded}))
  }

let status = (): status => {
  signals: Array.length(copies.contents) > 0,
  copies: Array.length(copies.contents),
}

let uninstall = (): unit =>
  if active.contents {
    copies.contents->Array.forEach(copy => copy.uninstall())
    copies := []
    RuntimeDevtools.enabled := false
    RuntimeDevtools.listener := None
    RuntimeDevtools.pendingBinding := None
    active := false
    nextNode := 0
    nextScope := 0
    localToGlobal->Map.clear
    nodes->Map.clear
    scopeInfos->Map.clear
    scopeIds := makeWeakMap()
    writers := makeWeakMap()
    log := []
    running->Array.splice(~start=0, ~remove=Array.length(running), ~insert=[])
    mutedNodes->Set.clear
    mutedScopes->Set.clear
    muteDepth := 0
  }

let install = (~captureStacks as capture: bool=true, ()): status => {
  uninstall()
  active := true
  captureStacks := capture
  copies := upstreamCopies()
  copies.contents->Array.forEachWithIndex((copy, index) =>
    copy.install({emit: event => onUpstream(index, event), captureStacks: capture})
  )
  RuntimeDevtools.listener := Some(onRenderer)
  RuntimeDevtools.enabled := true
  status()
}

let installed = (): bool => active.contents

let subscribe = (listener: event => unit): (unit => unit) => {
  listeners->Array.push(listener)
  () =>
    switch listeners->Array.indexOf(listener) {
    | -1 => ()
    | index => listeners->Array.splice(~start=index, ~remove=1, ~insert=[])
    }
}

/* Run `fn`, then `cleanup` whether or not it threw. */
let withCleanup = (fn, cleanup) =>
  switch fn() {
  | result =>
    cleanup()
    result
  | exception exn =>
    cleanup()
    throw(exn)
  }

let mute = (fn: unit => 'a): 'a => {
  muteDepth := muteDepth.contents + 1
  withCleanup(fn, () => muteDepth := muteDepth.contents - 1)
}

let history = (): array<event> => log.contents->Array.copy
let clearHistory = (): unit => log := []

let live = (info: nodeInfo): option<Signals.Debug.node> =>
  copies.contents->Array.get(info.copy)->Option.flatMap(copy => copy.inspect(info.local))

let inspect = (id: int): option<node> =>
  nodes
  ->Map.get(id)
  ->Option.flatMap(info =>
    live(info)->Option.map((live): node => {
      id,
      kind: info.kind,
      name: info.name,
      site: info.site,
      scope: info.scope,
      binding: info.binding->Option.map(
        ((target, what)): binding => {
          target: target->deref->Option.mapOr("(collected)", pathOf),
          what,
        },
      ),
      level: live.level,
      value: live.value->Option.map(preview),
      sources: live.sources->Array.filterMap(local => globalOf(info.copy, local)),
      observers: live.observers->Array.filterMap(local => globalOf(info.copy, local)),
      dirty: live.dirty,
      disposed: live.disposed,
    })
  )

let value = (id: int): option<unknown> =>
  nodes
  ->Map.get(id)
  ->Option.flatMap(live)
  ->Option.flatMap(live => live.value)
  ->Option.map(Obj.magic)

/* Released, itself or through an ancestor. */
let rec scopeReleased = (id: int): bool =>
  switch scopeInfos->Map.get(id) {
  | None => false
  | Some(info) => info.disposed || info.parent->Option.mapOr(false, scopeReleased)
  }

let scopes = (): array<scope> =>
  scopeInfos
  ->Map.values
  ->Iterator.toArray
  ->Array.filterMap(info =>
    scopeMuted(info.id) ? None : Some({...info, disposed: scopeReleased(info.id)})
  )

let snapshot = (): snapshot => {
  nodes: nodes
  ->Map.keys
  ->Iterator.toArray
  ->Array.filterMap(id => nodeMuted(id) ? None : inspect(id)),
  scopes: scopes(),
}

let targetOf = (id: int): option<Dom.element> =>
  nodes
  ->Map.get(id)
  ->Option.flatMap(info => info.binding)
  ->Option.flatMap(((target, _)) => target->deref)

let writersOf = (element: Dom.element): array<int> =>
  writers.contents->weakGet(Obj.magic(element))->Option.mapOr([], Array.copy)

let countEvents = (events: array<event>): counts =>
  events->Array.reduce(
    {
      writes: 0,
      effects: 0,
      computeds: 0,
      bindings: 0,
      domWrites: 0,
      scopesCreated: 0,
      scopesDisposed: 0,
      reconciled: 0,
    },
    (c, event) =>
      switch event {
      | Written({changed: true}) => {...c, writes: c.writes + 1}
      | RunStart({id}) =>
        switch nodes->Map.get(id) {
        | Some({kind: #effect, binding}) => {
            ...c,
            effects: c.effects + 1,
            bindings: c.bindings + (Option.isSome(binding) ? 1 : 0),
          }
        | Some({kind: #computed}) => {...c, computeds: c.computeds + 1}
        | _ => c
        }
      | DomWrite(_) => {...c, domWrites: c.domWrites + 1}
      | ScopeCreated(_) => {...c, scopesCreated: c.scopesCreated + 1}
      | ScopeDisposed(_) => {...c, scopesDisposed: c.scopesDisposed + 1}
      | Reconciled(_) => {...c, reconciled: c.reconciled + 1}
      | _ => c
      },
  )

let record = (fn: unit => unit): trace => {
  let events = []
  withCleanup(fn, subscribe(event => events->Array.push(event)))
  {events, counts: countEvents(events)}
}

module Budget = {
  let check = (
    trace: trace,
    ~writes=?,
    ~effects=?,
    ~computeds=?,
    ~bindings=?,
    ~domWrites=?,
    ~scopesCreated=?,
    ~scopesDisposed=?,
  ): result<unit, string> => {
    let c = trace.counts
    let failures = [
      ("writes", writes, c.writes),
      ("effects", effects, c.effects),
      ("computeds", computeds, c.computeds),
      ("bindings", bindings, c.bindings),
      ("domWrites", domWrites, c.domWrites),
      ("scopesCreated", scopesCreated, c.scopesCreated),
      ("scopesDisposed", scopesDisposed, c.scopesDisposed),
    ]->Array.filterMap(((label, expected, actual)) =>
      switch expected {
      | Some(expected) if expected != actual =>
        Some(`${label}: expected ${Int.toString(expected)}, got ${Int.toString(actual)}`)
      | _ => None
      }
    )
    failures == [] ? Ok() : Error(failures->Array.join("; "))
  }
}

/* The first index from `from`, moving by `step`, whose event passes `test`. */
let findFrom = (events: array<event>, from: int, ~step: int, test: event => bool): option<int> => {
  let inRange = index => index >= 0 && index < Array.length(events)
  let index = ref(from)
  while inRange(index.contents) && !test(events->Array.getUnsafe(index.contents)) {
    index := index.contents + step
  }
  inRange(index.contents) ? Some(index.contents) : None
}

/* A signal written, or a computed recomputed to a new value. */
let changed = (id, event: event) =>
  switch event {
  | Written({id: node, changed: true}) | RunEnd({id: node, changed: true, threw: false}) =>
    node == id
  | _ => false
  }

/* The node a creation or run event is about. */
let phaseOf = (event: event) =>
  switch event {
  | Created({id}) => Some((#created, id))
  | RunStart({id}) => Some((#start, id))
  | RunEnd({id}) => Some((#end, id))
  | _ => None
  }

let rec explain = (events: array<event>, id: int, ~before: int, ~depth: int): option<cause> =>
  nodes
  ->Map.get(id)
  ->Option.flatMap(info => {
    let cause = (action, causes): cause => {
      id,
      kind: info.kind,
      name: info.name,
      site: info.site,
      action,
      causes,
    }
    let back = (from, test) => findFrom(events, from, ~step=-1, test)
    switch info.kind {
    | #signal =>
      back(before, event => changed(id, event))->Option.map(index => {
        let site = switch events->Array.getUnsafe(index) {
        | Written({site}) => site
        | _ => None
        }
        {...cause(#written, []), site: site->Option.orElse(info.site)}
      })
    | #computed | #effect =>
      let is = (what, event) =>
        switch phaseOf(event) {
        | Some((phase, node)) => phase == what && node == id
        | None => false
        }
      let started = event => is(#start, event)
      let ended = event => is(#end, event)
      back(before, started)->Option.map(start =>
        /* The creation run directly follows `Created`, when the history holds it. */
        if (
          back(start - 1, started)->Option.isNone &&
            back(start, event => is(#created, event))->Option.isSome
        ) {
          cause(#created, [])
        } else {
          let previousEnd = back(start - 1, ended)->Option.getOr(-1)
          let end_ = findFrom(events, start + 1, ~step=1, ended)->Option.getOr(Array.length(events))
          /* Every source the node reads now or read up to the end of this run. */
          let sources = Set.fromArray(inspect(id)->Option.mapOr([], live => live.sources))
          for index in 0 to end_ - 1 {
            switch events->Array.getUnsafe(index) {
            | Linked({source, target}) if target == id => sources->Set.add(source)
            | _ => ()
            }
          }
          /* A source caused this run if it changed after the previous run
             ended — computeds being lazy, possibly inside this very run, when
             it pulled them. */
          let causes =
            depth >= 16
              ? []
              : sources
                ->Set.toArray
                ->Array.filterMap(
                  source =>
                    switch back(end_ - 1, event => changed(source, event)) {
                    | Some(at) if at > previousEnd =>
                      explain(events, source, ~before=at, ~depth=depth + 1)
                    | _ => None
                    },
                )
          cause(info.kind == #computed ? #recomputed : #ran, causes)
        }
      )
    }
  })

let why = (id: int): option<cause> =>
  explain(log.contents, id, ~before=Array.length(log.contents) - 1, ~depth=0)

let leaks = (): array<leak> =>
  nodes
  ->Map.values
  ->Iterator.toArray
  ->Array.filterMap(info =>
    nodeMuted(info.id)
      ? None
      : live(info)->Option.flatMap(live => {
          let outlived = info.scope->Option.mapOr(false, scopeReleased)
          let reason = switch info.kind {
          | #effect if live.disposed => None
          | #effect if outlived => Some(#effectOutlivedScope)
          | #effect if info.unownedNested => Some(#unownedEffect)
          | #computed if outlived && Array.length(live.observers) > 0 =>
            Some(#computedOutlivedScope)
          | _ => None
          }
          reason->Option.map(
            (reason): leak => {
              node: info.id,
              reason,
              kind: info.kind,
              name: info.name,
              site: info.site,
              scope: info.scope,
            },
          )
        })
  )
