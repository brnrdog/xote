/* Devtools for Xote applications, reachable through the `xote/devtools` entry.

   `install` instruments the running app: the reactive graph through the debug
   hooks of `rescript-signals` (when the loaded copy has them — see `status`)
   and the renderer's scopes, DOM writes and keyed passes. Install from the
   entry module, before anything reactive is created: nodes created earlier
   are not reported.

   Every node and scope is named by an id assigned in creation order, so the
   same program driven the same way yields the same ids. */

type nodeKind = [#signal | #computed | #effect]

/* `#fragment` and `#list` are the regions a `SignalFragment` and a keyed list
   render into; `#pass`, `#row`, `#boundary` and `#hydratedRow` are the owners
   whose release disposes what they rendered. */
type scopeKind = [#root | #fragment | #list | #row | #pass | #boundary | #hydratedRow]

/* What a library-created effect writes: `target` is a CSS-like path to the DOM
 node, `what` one of "text", "attr:<name>", "fragment" or "list". */
type binding = {target: string, what: string}

type node = {
  id: int,
  kind: nodeKind,
  name: option<string>,
  /* `file:line:col` of the code that created the node, when stacks are
   captured (the compiled `.res.mjs`, next to its `.res`). */
  site: option<string>,
  /* The scope the node was created under; `None` outside any render. */
  scope: option<int>,
  binding: option<binding>,
  level: int,
  /* A short preview of the current value; `None` for an effect. */
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
  /* Released, itself or through an ancestor. */
  disposed: bool,
}

type snapshot = {nodes: array<node>, scopes: array<scope>}

/* The merged event stream. In JavaScript every event is an object whose
   `type` field names it, except `BatchStart` and `BatchEnd`, which are those
   strings. */
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

/* `signals` is whether the reactive graph is visible: false when the loaded
   `rescript-signals` predates its debug hooks, in which case only the
   renderer's events arrive. `copies` counts the instrumented copies. */
type status = {signals: bool, copies: int}

let install: (~captureStacks: bool=?, unit) => status
let uninstall: unit => unit
let installed: unit => bool
let status: unit => status

/* Returns the function that unsubscribes. */
let subscribe: (event => unit) => unit => unit

/* Run `fn` with everything it creates hidden from devtools, now and on every
 later run — for a tool's own UI built with Xote. */
let mute: (unit => 'a) => 'a

/* The most recent events, oldest first (bounded). */
let history: unit => array<event>
let clearHistory: unit => unit

let inspect: int => option<node>
/* The live value of a signal or computed, for tools that render it. */
let value: int => option<unknown>
let scopes: unit => array<scope>
let snapshot: unit => snapshot
/* The effects that write to a DOM node: one per binding (its text, each
   reactive attribute), oldest first. */
let writersOf: Dom.element => array<int>

type counts = {
  /* Writes that changed a value. */
  writes: int,
  /* Effect runs, bindings included. */
  effects: int,
  computeds: int,
  /* Runs of library-created effects that write the DOM. */
  bindings: int,
  domWrites: int,
  scopesCreated: int,
  scopesDisposed: int,
  reconciled: int,
}

type trace = {events: array<event>, counts: counts}

/* Everything `fn` caused, synchronously. */
let record: (unit => unit) => trace

module Budget: {
  /* Compare a trace against expected counts; each count left out is not
   checked. `Error` lists every mismatch. */
  let check: (
    trace,
    ~writes: int=?,
    ~effects: int=?,
    ~computeds: int=?,
    ~bindings: int=?,
    ~domWrites: int=?,
    ~scopesCreated: int=?,
    ~scopesDisposed: int=?,
  ) => result<unit, string>
}

type action = [#written | #recomputed | #ran | #created]

/* Why a node last ran: the sources that changed since its previous run, each
 explained in turn, down to the signal writes that started it. */
type rec cause = {
  id: int,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  action: action,
  causes: array<cause>,
}

let why: int => option<cause>

type leakReason = [
  | /* An effect still live after the scope it was created under was released. */
  #effectOutlivedScope
  | /* A computed still subscribed after its scope was released. */
  #computedOutlivedScope
  | /* An effect created inside another node's run under no scope: every run of
   the outer node creates another. */
  #unownedEffect
]

type leak = {
  node: int,
  reason: leakReason,
  kind: nodeKind,
  name: option<string>,
  site: option<string>,
  scope: option<int>,
}

let leaks: unit => array<leak>

/* A short, cycle-safe rendering of any value. */
let preview: 'a => string
/* A CSS-like path to a DOM node. */
let pathOf: Dom.element => string
