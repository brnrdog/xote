# Conditionals and lists

Every construct here answers the same question: how big a piece of DOM gets
rebuilt when something changes. Smaller is better.

## Conditionals

### Under `@xote.component`

Write the `if` or `switch` directly in child position. The PPX wraps it in
`View.tracked` and subscribes it to the **condition only** — leaves inside the
branches stay fine-grained.

```rescript
<div>
  {switch Signal.get(status) {
  | Loading => <span> {"Loading…"} </span>
  | Ready(msg) => <strong class={Signal.get(theme)}> {msg} </strong>
  }}
</div>
```

Changing `theme` rewrites one attribute and leaves the `<strong>` in place.
Only a change to `status` re-runs the switch. Signal reads in `when` guards
count as part of the scrutinee.

### `View.Show`

For a plain boolean, with an optional fallback:

```rescript
<View.Show when_={MaybeSignal.reactive(isReady)} fallback={<p> {"Loading"} </p>}>
  <Dashboard />
</View.Show>
```

### `View.Maybe`

For `option` values — renders `render(value)` when `Some`, the fallback when
`None`:

```rescript
<View.Maybe
  value={MaybeSignal.reactive(selected)}
  fallback={<p> {"Nothing selected"} </p>}
  render={todo => <p> {todo.title} </p>}
/>
```

### `View.tracked`

The manual form, and what the PPX emits. Every signal read while the body runs
subscribes the block; dependencies are re-discovered on each run.

```rescript
View.tracked(() =>
  if Signal.get(loggedIn) {
    <p> {`Hello, ${Signal.get(name)}`} </p>
  } else {
    <p> {"Please log in"} </p>
  }
)
```

**A tracked block replaces its children wholesale — no diffing.** DOM state
inside it (input focus, scroll position, media playback) does not survive an
update. Keep tracked blocks small, and never wrap a list in one.

## Lists

### `View.For`

The JSX list component. Add `by` whenever items have stable identity:

```rescript
<View.For
  each={MaybeSignal.reactive(todos)}
  by={todo => todo.id}
  render={todo => <li class={todo.done ? "done" : ""}> {todo.title} </li>}
/>
```

Without `by`, a change to the array rebuilds every row. With `by`, xote
reconciles: rows keep their DOM identity, their event listeners, and any
reactive state inside them.

`each` accepts a `MaybeSignal.t<array<'item>>` — use `MaybeSignal.static` for a
list that never changes, `MaybeSignal.reactive` for a signal.

The `render` callback's body is node position, so leaves inside it stay
fine-grained under the PPX.

### Function-based equivalents

```rescript
View.each(items, item => Html.li(~children=[View.text(item)], ()))
View.eachWithKey(todos, todo => todo.id, todo => Html.li(~children=[View.text(todo.title)], ()))
```

`each` is `<View.For>` without `by`; `eachWithKey` is `<View.For by=…>`.

### Choosing a key

The key function returns a `string` and must be **stable and unique** within the
list. An array index is not a key — it changes when items move, which defeats
the reconciler. Use a database id, a slug, or a generated uuid stored on the
item.

### Cost model

The keyed reconciler is a three-phase algorithm (remove, build new order,
reconcile DOM). It preserves element identity across moves, but it does **not**
compute a minimal move set: one early position mismatch cascades, so swapping
two rows in a long list moves most of the list. Updating and appending are
cheap; heavy reordering is not. If a view reorders large lists constantly,
consider sorting the data behind a computed and accepting the rebuild, or
paginating.

## Nesting rule

Reactive scopes nest, and the outermost one wins. A list inside a tracked block
is rebuilt wholesale whenever the block's condition changes, throwing away the
reconciliation you asked for. Put the conditional *inside* the row, or use
`View.Show` around the smallest possible subtree.

```rescript
/* ✗ every status change rebuilds all rows */
{View.tracked(() => Signal.get(filter) === All ? <View.For … /> : <View.For … />)}

/* ✓ one list, a computed feeding it */
<View.For each={MaybeSignal.computed(() => visibleRows())} by={r => r.id} render={…} />
```
