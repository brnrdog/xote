/* Internal: the renderer's side of the devtools hook.

   `rescript-signals` reports the reactive graph (`Signals.Debug`); this reports
   what only the renderer knows — the scopes it creates and releases, which DOM
   node each binding writes, what a keyed pass did, failures a boundary caught,
   hydration warnings and hidden-read probes. `Devtools` installs a listener
   here and merges both streams into one.

   Nothing here runs unless a listener is installed: every call site is guarded
   by one read of `enabled`. Events carry the renderer's own objects (owners,
   regions, DOM nodes) rather than ids, so this module allocates nothing to
   identify them; `Devtools` maps them to ids in WeakMaps of its own. */

type scopeKind = [#Root | #Fragment | #List | #Row | #Pass | #Boundary | #HydratedRow]

@tag("type")
type event =
  /* A scope: an owner (row, pass, boundary, hydrated row) or a region (the
     fragment or keyed list whose passes and rows those owners are). `parent`
     is the scope it was created under. */
  | ScopeCreated({scope: Obj.t, kind: scopeKind, key: option<string>, parent: option<Obj.t>})
  /* An owner released. A region is released with the owner it belongs to. */
  | ScopeDisposed({scope: Obj.t})
  /* A binding wrote to the DOM: `what` is "text" or "attr:<name>". */
  | DomWrite({target: Dom.element, what: string})
  /* One keyed reconcile pass. */
  | Reconciled({scope: Obj.t, kept: int, rebuilt: int, created: int, removed: int, moved: int})
  /* An error boundary caught a failure and rendered its fallback. */
  | Caught({error: Obj.t})
  | HydrationWarning({message: string})
  /* A `View.probe` site was evaluated; `hidden` is whether it read a signal. */
  | Probe({site: string, hidden: bool})

let enabled: ref<bool> = ref(false)
let listener: ref<option<event => unit>> = ref(None)

let emit = (event: event): unit =>
  switch listener.contents {
  | Some(listener) => listener(event)
  | None => ()
  }

/* What the next effect created will write to. A binding sets this just before
   `Effect.run`, and `Devtools` takes it when the effect's `Created` event
   arrives — which `rescript-signals` emits synchronously inside `Effect.run`.
   That pairs an effect with its DOM target without the binding knowing the
   effect's id. */
type binding = {target: Dom.element, what: string}
let pendingBinding: ref<option<binding>> = ref(None)

let bind = (target: Dom.element, what: string): unit => pendingBinding := Some({target, what})

let scopeCreated = (
  scope: 'scope,
  kind: scopeKind,
  ~key: option<string>=?,
  ~parent: option<'parent>,
) => emit(ScopeCreated({scope: Obj.magic(scope), kind, key, parent: Obj.magic(parent)}))

let scopeDisposed = (scope: 'scope) => emit(ScopeDisposed({scope: Obj.magic(scope)}))

let domWrite = (target: Dom.element, what: string) => emit(DomWrite({target, what}))
