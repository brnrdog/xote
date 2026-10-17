/***
Values a component makes available to everything it renders, without passing
them through the components in between.

A context is declared once with `make`, which also sets the value a component
gets when nothing above it provides one. A component provides a value for its
subtree with `<Context.Provider>` (or `provide` in its own body), and any
component below reads the nearest one with `use`.

A provision is scoped to the providing component: siblings and everything
rendered outside it never see it, and two instances of the same component can
provide different values to their own subtrees. That makes context the tool
for state that belongs to *one instance* of something — a `Tabs` and its
`Tab`s, a `Form` and its `Field`s — and for values that must not outlive a
render, such as per-request data during SSR. For one value shared by the whole
app on the client, a module-level `Signal` is simpler and works as well.

Read a context in the component body, while it renders. Reads inside effects
the body set up, and inside the reactive blocks it renders (`View.tracked`,
`View.Show`, `View.For`), see the same value on every later run. Event
handlers, timers and other code that runs outside a render do not: read the
value in the body and close over it.

Providing a value does not make it reactive. To let the subtree follow a value
that changes, provide a `Signal.t` and read it with `Signal.get` where it is
used.

## Examples

```rescript
let theme = Context.make("light")

module Badge = {
  @xote.component
  let make = () => {
    let current = Context.use(theme)
    <span class={current}> {"New"} </span>
  }
}

let app =
  <div>
    <Badge /> // "light"
    <Context.Provider context=theme value="dark">
      <Badge /> // "dark"
    </Context.Provider>
  </div>
```
*/

/** A context carrying values of type `'a`. */
type t<'a>

/**
Declares a context. `default` is what `use` returns when no component above
provides a value.

## Examples

```rescript
let currentUser: Context.t<option<string>> = Context.make(None)
let selection: Context.t<Signal.t<int>> = Context.make(Signal.make(0))
```
*/
let make: 'a => t<'a>

/**
The value the nearest provider above provides, or the context's default when
there is none.

Call it in a component body. Outside a render — in an event handler, a timer,
at module level — there is no provider above, and it returns the default.

## Examples

```rescript
let selection = Context.make(Signal.make(0))

module Tab = {
  @xote.component
  let make = (~index: int, ~label: string) => {
    let selected = Context.use(selection)
    <button
      class={Signal.get(selected) == index ? "tab active" : "tab"}
      onClick={_ => Signal.set(selected, index)}>
      {label}
    </button>
  }
}
```
*/
let use: t<'a> => 'a

/**
Provides `value` to everything the calling component renders.

Call it in a component body; it raises when called anywhere else, since there
would be no render to scope it to. The value is in place for the component's
result only, so siblings and the component's own parent never see it. Most
code uses `Provider` instead, which does this for its children.

## Examples

```rescript
let selection = Context.make(Signal.make(0))

module Tabs = {
  @xote.component
  let make = (~children: View.node) => {
    // Each Tabs instance gets its own selection.
    Context.provide(selection, Signal.make(0))
    <div class="tabs"> {children} </div>
  }
}
```
*/
let provide: (t<'a>, 'a) => unit

/**
Function form of `Provider`: renders `children` with `value` provided.

## Examples

```rescript
let theme = Context.make("light")

let node = Context.provider(theme, "dark", View.text("Rendered under the dark theme"))
```
*/
let provider: (t<'a>, 'a, View.node) => View.node

/**
Renders its children with `value` provided for `context`.

## Examples

```rescript
let theme = Context.make("light")

module Dark = {
  @xote.component
  let make = () =>
    <Context.Provider context=theme value="dark">
      <p> {"Rendered under the dark theme"} </p>
    </Context.Provider>
}
```
*/
module Provider: {
  /**
  Props of `Context.Provider`.

  - `context` — the context to provide.
  - `value` — the value its subtree reads.
  - `children` — the subtree.
  */
  type props<'value> = {
    context: t<'value>,
    value: 'value,
    children?: View.node,
  }

  /** Provides the value and renders the children. Called for you by `<Context.Provider />`; see the module doc for usage. */
  let make: props<'value> => View.node
}
