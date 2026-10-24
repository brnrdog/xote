# Proposal: Xote Lens — devtools for humans and agents

| | |
|---|---|
| **Status** | Draft. Nothing here is built yet. Phase 1 (hooks) and Phase 2 (agent CLI/MCP) are the committed direction; Phases 3–4 are sketched so the data model is designed for them. |
| **Decisions so far** | Debug hooks live **in rescript-signals** (not a Xote-side wrapper). The **PPX emits a sidecar map** of what it rewrote. The **agent surface ships first**; the browser panel comes later and renders the same data. |
| **Related** | [`tracked-blocks.md`](./tracked-blocks.md) — the PPX and `View.probe`, whose diagnostics this generalises |

## Summary

A Xote app's behaviour is decided by three things no component tree shows:

1. the **reactive graph** — signals, computeds and effects, who reads whom, and
   in what order the scheduler runs them;
2. the **regions that own that graph** — keyed rows, `SignalFragment` passes,
   hydrated rows — and therefore what is disposed when;
3. **what `@xote.component` did to the source** — which leaves were thunked,
   which branches became `View.tracked`, which got a `View.probe`.

Xote Lens is one instrumentation layer that records all three, and several
consumers of that one data model: a `xote` CLI and an MCP server first (so an
AI agent, or CI, can ask "why did this run?" and get structured JSON), and a
browser panel later (so a human can see the same answer drawn).

The principle that keeps it coherent: **the panel never knows anything the CLI
cannot print.**

```
          ┌──────────── xote/devtools (opt-in instrumented runtime) ────────────┐
          │ graph snapshot · event stream · region tree · PPX site map · lints  │
          └──────┬──────────────────────┬──────────────────────────┬────────────┘
           `xote` CLI              MCP server                Browser panel
         (terminals, CI)    (agents, structured JSON)     (humans; Phase 3)
```

## Motivation

Fine-grained reactivity fails quietly. A missing dependency is a stale UI, not
an error; an over-broad `tracked` block is a slow UI, not an error; an
undisposed `Computed` is a leak, not an error. Today the tools for finding
these are `Console.log`, `~name` arguments nobody can read back, and the one
diagnostic that exists — `View.probe`'s first-evaluation warning.

Agents feel this harder than people. An agent writing Xote can compile and run
tests, but it cannot observe *reactive behaviour*: it has no way to check that
clicking "+1" updates one text node rather than re-rendering a list, or that a
row's effects are gone after the row is removed. It guesses, and the
`AGENTS.md` "Common Pitfalls" list is a record of the guesses that went wrong.

## Layer 1 — debug hooks in rescript-signals

### Shape

One module, `Signals.Debug`, holding a single mutable hook. Instrumentation
points call it only when it is set.

```rescript
/* rescript-signals: src/signals/Debug.res */
type nodeKind = [#Signal | #Computed | #Effect]

type event =
  | Created({id: int, kind: nodeKind, name: option<string>, stack: option<string>})
  | Linked({source: int, target: int})          /* a new dependency edge */
  | Unlinked({source: int, target: int})        /* re-tracking dropped one */
  | Written({id: int, changed: bool})           /* Signal.set; changed = passed equals */
  | Notified({id: int, observers: array<int>})  /* who was marked dirty/pending */
  | RunStart({id: int, level: int})             /* computed recompute or effect body */
  | RunEnd({id: int, threw: bool})
  | Disposed({id: int})
  | BatchStart
  | BatchEnd

type hook = {
  emit: event => unit,
  captureStacks: bool,
  /* Value reads are pull-based: the hook asks for a value when it wants one,
     rather than every write serialising it. */
}

let current: ref<option<hook>> = ref(None)
let install: hook => unit
let uninstall: unit => unit

/* Read-only graph access for snapshots, by id. */
let inspect: int => option<{
  kind: nodeKind,
  name: option<string>,
  level: int,
  value: option<Obj.t>,
  sources: array<int>,
  observers: array<int>,
  dirty: bool,
}>
```

`inspect` needs an id → node table. It is filled from `Created` and cleared on
`Disposed` **inside the hook's installer**, so the uninstrumented path never
allocates it; nodes created before `install` are invisible (install first, in
the entry module).

### Where the calls go

Every point already exists in 3.1.x; the hook is one `switch Debug.current.contents`
beside it.

| Event | Location in rescript-signals |
|---|---|
| `Created` | `Signal.make`, `Computed.makeWith`, `Core.makeObserver` (effects) |
| `Linked` / `Unlinked` | `Scheduler.trackDepFromComputed` / `trackDepFromEffect` when a **new** link is made, and the stale-link sweep after `runComputedCycle` / `retrackEffect` |
| `Written` | `Signal.set`, after the `equals` check |
| `Notified` | `Scheduler.notifySubs` |
| `RunStart` / `RunEnd` | `Scheduler.runComputedCycle`, `Scheduler.runEffectBody` |
| `Disposed` | `Scheduler.disposeEffect`, `Computed.dispose` |
| `BatchStart` / `BatchEnd` | `Scheduler.batch` (outermost only) |

Re-reading an existing link emits nothing — `trackDep` on an unchanged
dependency is the hottest path in the library and stays a cursor compare.

### Cost

- Uninstalled: one load of a module-level ref and a `None` compare per
  instrumented call. The rescript-signals benchmark gates the PR: no
  regression beyond noise on its existing suite.
- `stack: option<string>` is `new Error().stack`, captured only when
  `captureStacks` is true. It is how a node without a `~name` still gets a
  `file:line` (via the `.res.mjs` source map back to `.res`).

### Ids

The existing `Id.make` counter. It is deterministic for a given program and
interaction sequence, which is exactly the headless case agents run in, so
"node 17" means the same thing across CLI calls in one session. For hot reload
(Phase 3) the panel keys nodes by `(name ?? site, kind, ordinal)` instead.

## Layer 2 — Xote runtime events

Xote adds its own hook, `RuntimeDevtools.current`, mirroring `Signals.Debug`,
for what only the renderer knows:

| Event | Emitted from | Why it matters |
|---|---|---|
| `RegionCreated({region, parent, kind: #Row \| #Pass \| #Hydrated \| #Root, key?})` | `RuntimeOwner.createOwner` call sites in `RuntimeRender` / `Hydration` | Ownership tree |
| `Owned({region, node})` | `RuntimeOwner.addDisposer` / `addComputed` | Which signals node a region will dispose |
| `RegionDisposed({region})` | `RuntimeOwner.disposeOwner` | Leak detection: anything still alive that was created under a disposed region |
| `Bound({node, dom, attr?})` | the effect that writes a `SignalText`, attribute or fragment | "This DOM write came from node 42" |
| `Reconciled({list, kept, rebuilt, moved, created, removed})` | keyed reconciler | List performance |
| `Template({shape, hit})` | `RuntimeTemplate` | Clone hit rate |
| `Suspended` / `Resumed` / `Caught` | `View.Suspense`, error boundaries | Async and failure flow |
| `HydrationMismatch({expected, found, path})` | `Hydration` walker | First divergence from server HTML |
| `Probe({site, reads})` | `View.probe` | Today's console warning, as data |

Region ids live in a `WeakMap` owned by the devtools installer, not in the
`owner` record — `RuntimeOwner` keeps its one-field shape and the
uninstrumented path is unchanged.

## Layer 3 — the PPX site map

With `"ppx-flags": [["xote/ppx/ppx", "-sitemap"]]`, the PPX writes one JSON
file per module next to the compiled output (`lib/xote-sitemap/<Module>.json`):

```json
{
  "module": "Counter",
  "file": "src/Counter.res",
  "sites": [
    { "site": "src/Counter.res:12:6", "kind": "thunked-attr", "attr": "class" },
    { "site": "src/Counter.res:14:8", "kind": "tracked", "reads": ["count"] },
    { "site": "src/Counter.res:15:10", "kind": "child" },
    { "site": "src/Counter.res:18:4", "kind": "probe", "reason": "unresolved call: Store.total" },
    { "site": "src/Counter.res:21:4", "kind": "one-shot-prop", "component": "Card", "prop": "label" },
    { "site": "src/Counter.res:23:4", "kind": "already-reactive" }
  ]
}
```

`site_of` already produces these strings for `View.probe`; the map reuses it.
The flag keeps the emitted JavaScript identical — the map is a side output, not
a change to what ships. The map is how `xote check` explains a component
without re-implementing the PPX's analysis, and how the panel later draws its
"expanded" view.

## `xote/devtools` — the consumer API

A separate package entry (never imported by `xote` or `xote/client`, so the
production bundle-size report is unaffected):

```rescript
Devtools.install(~captureStacks=true, ())   /* installs both hooks */
Devtools.snapshot(): snapshot               /* nodes, edges, regions, values */
Devtools.subscribe(event => ...)            /* the merged event stream */
Devtools.record(() => action): trace        /* events produced by one action */
Devtools.why(nodeId): array<cause>          /* causal chain back to a Written */
Devtools.leaks(): array<leak>               /* alive nodes whose creating region is disposed, undisposed user computeds */
```

`trace` is the unit everything else is built on: a `Signal.set` (or a
dispatched DOM event) and everything it caused, grouped by batch.

## Phase 2 — the agent surface (ships first)

### CLI

Every command prints human text by default and JSON with `--json`.

| Command | Does | Built on |
|---|---|---|
| `xote api <Module[.value]>` | Signature and doc comment from the public `.resi` — never a `Runtime*` internal | `.resi` files; the same boundary `test:exports` snapshots |
| `xote check [files]` | `rescript build` + site maps + lint rules → one diagnostics report | Layer 3, lints below |
| `xote render <Module.component> [--ssr] [--hydrate]` | Headless jsdom render; prints the DOM and a graph summary | Layers 1–2, the jsdom setup `tests/setup.mjs` already uses |
| `xote act <selector> <event> [--value v]` | Dispatches an event against the last render; prints the trace: writes, observers run, DOM writes, regions created/disposed, leaks | `Devtools.record` |
| `xote why <nodeId \| selector>` | Causal chain for a node or a DOM element's last update | `Devtools.why` |
| `xote graph [--around nodeId]` | Snapshot of the graph (or a neighbourhood) | `Devtools.snapshot` |

`render`/`act`/`why` share a session (a long-lived jsdom process) so ids stay
stable across calls.

### MCP server

`xote mcp` exposes the same commands as tools — `xote_api`, `xote_check`,
`xote_render`, `xote_act`, `xote_why`, `xote_graph` — with the `--json`
shapes as results. One implementation, two transports.

Example `xote_act` result:

```json
{
  "action": { "type": "click", "selector": "#increment" },
  "writes": [{ "node": 3, "name": "count", "site": "src/Counter.res:4:14" }],
  "ran": [{ "node": 9, "kind": "computed", "name": null, "site": "src/Counter.res:15:10" }],
  "domWrites": [{ "node": 9, "target": "p > text", "kind": "text" }],
  "regions": { "created": 0, "disposed": 0 },
  "leaks": []
}
```

### Lint rules

Each one is a pitfall already written down in `AGENTS.md`, turned into a
check with a stable id an agent can act on:

| Id | Finds | Source |
|---|---|---|
| `effect-returns-unit` | An `Effect.run` body that doesn't return `option<unit => unit>` (caught by the compiler; the rule rewrites the error into the fix) | compiler output |
| `get-in-effect` | `Signal.get` of a signal the effect also writes | site map + graph |
| `one-shot-prop` | `<Card label={Signal.get(x)} />` | site map |
| `unresolved-read` | A `probe` site that reported reads at runtime | site map + `Probe` events |
| `undisposed-computed` | A user `Computed.make` / `MaybeSignal.map` result alive after its creating region was disposed | `leaks()` |
| `router-before-init` | Router read before `Router.init` / `initSSR` | runtime |
| `ssr-state-bleed` | `SSRState` ids registered by a previous render | runtime |
| `raw-captures-binding` | `%raw` referring to a surrounding ReScript binding | source scan |

### Reactive budgets

The feature nothing else in the ecosystem offers, and the one that lets an
agent refactor without silently coarsening a component. A zekr helper over
`Devtools.record`:

```rescript
test("increment touches one text node", () => {
  let trace = Devtools.record(() => click("#increment"))
  trace->Budget.expect(~effects=0, ~computeds=1, ~domWrites=1, ~regionsCreated=0)
})
```

Asserting *how much* updated, not only what the DOM ends up as, is what makes
fine-grained reactivity a tested property instead of an aspiration.

### Agent docs

`xote api --dump` writes an `llms.txt`-style digest of the public surface from
the `.resi` files, so the docs an agent loads cannot drift from the boundary
the guardrails enforce.

## Phase 3 — browser panel

A panel (itself written in Xote) over the same event stream via a
`postMessage` bridge: graph view with live highlight, region tree overlaid on
the DOM, timeline/flame chart of traces, "why did this update?" on any element,
leak list. No data the CLI lacks.

## Phase 4 — SSR, hydration and PPX lenses

- Server HTML with markers beside the client node tree; jump to the first
  `HydrationMismatch`.
- `SSRState` payload decoded through its codecs, with the signal each id
  restored into.
- Per-component expanded view from the site map, with probe sites marked.

## Plan

| Phase | Lands in | Exit criterion |
|---|---|---|
| 1a | rescript-signals | `Signals.Debug` with the events above; benchmark unchanged uninstalled; tests for every event |
| 1b | xote | `RuntimeDevtools` events; `xote/devtools` with `snapshot`/`record`/`why`/`leaks`; bundle-size report unchanged for `xote` and `xote/client` |
| 1c | xote (ppx) | `-sitemap` flag; `ppx:test` asserts the map for `ppx/example/` |
| 2 | xote (new `cli/` package or `bin/`) | CLI + MCP; lints; `Budget` helper; one budget test per keyed-list operation in this repo's own suite |
| 3 | separate package | Panel |
| 4 | separate package | SSR/hydration/PPX lenses |

## Rejected alternatives

- **Wrap the primitives in Xote's `Signal`/`Computed`/`Effect` shims.** Sees
  creation and writes, but not scheduling order, re-tracking, or the computeds
  rescript-signals runs internally — the exact things "why did this run?"
  needs. (Also: the shims are deliberately thin re-exports.)
- **Patch the compiled JavaScript at load time.** Fragile across compiler
  versions and invisible to `.res`-level reasoning.
- **Browser panel first.** More visible, but it fixes the data model around a
  UI. Agents force the model to be complete and textual; the panel then gets
  it for free.

## Open questions

1. **Hook granularity.** One `emit: event => unit` (simple, allocates an event
   per call when installed) versus one function per event kind (no allocation,
   wider API). Proposed: start with `emit`; installed cost doesn't matter much.
2. **Should generated computeds carry a site name?** With `-sitemap`, the PPX
   could also pass `~name=site` to the computeds it emits, so runtime nodes
   map to source without stack capture. It changes emitted code (dev only?).
3. **Where the CLI lives.** A `bin` in the `xote` package keeps install simple;
   a separate `xote-lens` package keeps jsdom and the MCP SDK out of
   consumers' dependency trees. Proposed: separate package.
4. **Value serialisation.** `inspect` returns `Obj.t`; JSON output needs a
   safe, depth-limited serialiser that handles cycles, DOM nodes and functions.
