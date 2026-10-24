/* Internal: the renderer's side of the devtools hook. `rescript-signals`
   reports the reactive graph; this reports what only the renderer knows, and
   `Devtools` merges both streams.

   Every call site is guarded by one read of `enabled`. Events carry the
   renderer's own objects (owners, regions, DOM nodes), which `Devtools` maps
   to ids, so nothing here allocates to identify them. */

/* The same as `Devtools.scopeKind`. */
type scopeKind = [#root | #fragment | #list | #row | #pass | #boundary | #hydratedRow]

@tag("type")
type event =
  /* An owner (row, pass, boundary, hydrated row) or a region (the fragment or
   keyed list those owners belong to), created under `parent`. */
  | ScopeCreated({scope: Obj.t, kind: scopeKind, key: option<string>, parent: option<Obj.t>})
  /* An owner released; a region goes with the owner it belongs to. */
  | ScopeDisposed({scope: Obj.t})
  /* `what` is "text" or "attr:<name>". */
  | DomWrite({target: Dom.element, what: string})
  | Reconciled({scope: Obj.t, kept: int, rebuilt: int, created: int, removed: int, moved: int})
  | Caught({error: Obj.t})
  | HydrationWarning({message: string})
  /* `hidden` is whether the `View.probe` site read a signal. */
  | Probe({site: string, hidden: bool})
  | StateRestored({key: string, signal: Obj.t, found: bool, decoded: bool})

let enabled: ref<bool> = ref(false)
let listener: ref<option<event => unit>> = ref(None)

let emit = (event: event): unit => listener.contents->Option.forEach(listener => listener(event))

/* What the next effect created will write to. A binding sets this just before
   `Effect.run`, whose `Created` event `rescript-signals` emits synchronously,
   and `Devtools` takes it there: that pairs an effect with its DOM target
   without the binding knowing the effect's id. */
type binding = {target: Dom.element, what: string}
let pendingBinding: ref<option<binding>> = ref(None)

let bind = (target: Dom.element, what: string): unit => pendingBinding := Some({target, what})

let scopeCreated = (scope: 'scope, kind, ~key=?, ~parent: option<'parent>) =>
  emit(ScopeCreated({scope: Obj.magic(scope), kind, key, parent: Obj.magic(parent)}))

let scopeDisposed = (scope: 'scope) => emit(ScopeDisposed({scope: Obj.magic(scope)}))

let domWrite = (target: Dom.element, what: string) => emit(DomWrite({target, what}))
