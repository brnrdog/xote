# Reactivity

Xote's primitives come from `rescript-signals`, re-exported as `Signal`,
`Computed` and `Effect`. Three concepts, and an ownership rule that decides
when things get cleaned up.

## Signal

```rescript
let count = Signal.make(0)

Signal.get(count)          /* read AND subscribe the current observer */
Signal.peek(count)         /* read without subscribing */
Signal.set(count, 5)
Signal.update(count, n => n + 1)
```

`Signal.set` compares with JavaScript strict equality (`===`) and only notifies
when the value actually differs. That is what keeps records and arrays from
looping: a new record with identical fields is a *different* value and does
notify. Pass `~equals` when you need something else:

```rescript
type point = {x: int, y: int}
let position = Signal.make({x: 0, y: 0}, ~equals=(a, b) => a.x === b.x && a.y === b.y)
```

`~name` is a debugging label, surfaced to tooling. Worth setting on long-lived
or cross-module signals.

## Computed

```rescript
let doubled = Computed.make(() => Signal.get(count) * 2)
Signal.get(doubled)   /* a Computed IS a Signal.t — read it the same way */
```

Computeds are lazy with push-based dirty flagging: an upstream change marks
them dirty immediately, the value recomputes on the next read. `~equals`
decides whether a recomputed value propagates downstream.

**Disposal.** A computed *you* create is not disposed automatically at scope
exit — call `Computed.dispose(c)` when you are done with one you created and
kept, for instance in a component body that gets unmounted. (Computeds also
auto-dispose when they lose all their subscribers, and the computeds xote
allocates internally to back a node are owned by that node and released with
it. The ones to watch are the long-lived ones you hold yourself.)

## Effect

```rescript
Effect.run(() => {
  Console.log(Signal.get(count))
  None                       /* no cleanup */
})

Effect.run(() => {
  let id = setInterval(() => tick(), 1000)
  Some(() => clearInterval(id))   /* runs before each re-run and on disposal */
})
```

The body returns `option<unit => unit>`. Returning `unit` is a type error — a
very common one. Return `None` explicitly.

`Effect.runWithDisposer` returns `{dispose: unit => unit}` for manual teardown.

### Ownership decides lifetime

- An effect created **while a component renders** is registered with that
  component. Unmounting the component stops it.
- An effect created **anywhere else** — at module level, inside an event
  handler, in a callback — has no scope to belong to. It lives until its
  disposer runs. If you create one there, use `runWithDisposer` and keep the
  disposer.

The same owner system disposes the computeds and effects attached to a DOM
element when that element is removed, which is why unmounting a subtree does
not leak.

## Batching

```rescript
Signal.batch(() => {
  Signal.set(firstName, "Ada")
  Signal.set(lastName, "Lovelace")
})
```

Each dependent effect runs at most once for the whole batch instead of once per
write. Batches nest safely and return the value the body produced:

```rescript
let total = Signal.batch(() => {
  Signal.update(items, arr => Array.concat(arr, [item]))
  Signal.peek(items)->Array.length
})
```

Scheduling is **synchronous** throughout — there is no microtask or
animation-frame integration. When a batch ends, its effects run inline before
`batch` returns.

## Untracked reads

```rescript
Effect.run(() => {
  let current = Signal.get(source)                     /* tracked */
  let config = Signal.untrack(() => Signal.get(cfg))   /* not tracked */
  render(current, config)
  None
})
```

`Signal.peek` for one read, `Signal.untrack` for a block. Use them when a value
is an input to the work but should not cause the work to re-run.

## Re-tracking

Every time an observer runs, its dependencies are cleared and re-tracked from
scratch. Conditional reads therefore work correctly: a signal read only on one
branch is unsubscribed as soon as that branch stops being taken. You never have
to declare a dependency array, and you cannot get a stale one.

## Where state should live

- **Local to a component**: `Signal.make` in the component body. It is created
  once, on the single run of that body.
- **Shared across components**: a module-level signal, or a record of signals
  returned by a factory function. There is no context API; passing a signal as
  a prop or importing a module-level one is the idiom.
- **Synced with the server**: `SSRState.signal(id, initial, codec)` — see
  `ssr.md`.

A store is just a module:

```rescript
/* Store.res */
let todos = Signal.make([])
let remaining = Computed.make(() => Signal.get(todos)->Array.filter(t => !t.done)->Array.length)
let add = todo => Signal.update(todos, ts => Array.concat(ts, [todo]))
```

Remember that a component reading `Store.remaining` **through a helper function
in another module** is a read the PPX cannot see. Read the signal directly in
JSX position, or wrap the call in a thunk.
