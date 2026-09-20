/***
Core rendering primitives: the virtual node type, attribute helpers, the JSX
rendering components and DOM mounting.

This interface is the public surface of `Xote.View`. Anything not listed here
(the renderer, the DOM helpers, the owner system) is an implementation detail
and lives in an internal `Runtime*` module.

## Examples

```rescript
let counter = () => {
  let count = Signal.make(0)

  <div class="counter">
    <button onClick={_ => Signal.update(count, n => n + 1)}> {View.text("+1")} </button>
    <p> <View.Int value={count} /> </p>
  </div>
}

View.mountById(counter(), "root")
```
*/

/* ============================================================================
 * Type Definitions
 * ============================================================================ */

/**
Attribute value source: a literal, a signal, or a computation.

The `Optional*` variants carry an `option<string>`, where `None` removes the
attribute rather than writing an empty value — what presence-based styling
(`[data-open]`) needs.

Build these with `attr`, `signalAttr` and friends rather than by hand; the
constructors are exposed so the variant can be matched on.

## Examples

```rescript
let open_ = Signal.make(true)

let attrs: array<(string, View.attrValue)> = [
  View.attr("class", "panel"),
  View.optionalSignalAttr("data-open", Computed.make(() => Signal.get(open_) ? Some("") : None)),
]

let panel = View.element("div", ~attrs, ~children=[View.text("Body")], ())
```
*/
type attrValue = RuntimeNode.attrValue =
  | Static(string)
  | SignalValue(Signal.t<string>)
  | Compute(unit => string)
  | OptionalStatic(option<string>)
  | OptionalSignalValue(Signal.t<option<string>>)
  | OptionalCompute(unit => option<string>)

/**
A virtual node: the value every component returns and `mount` renders.

Most nodes are built through JSX, `Html.*` or the constructors below rather
than by naming a constructor directly. The reactive variants (`SignalText`,
`SignalFragment`, `KeyedList`) are what let the renderer update a subtree
without re-rendering its parent, and `LazyComponent` defers a component body so
its effects are not captured by a surrounding computed.

## Examples

```rescript
let greeting: View.node = View.text("Hello")

let list: View.node = View.fragment([View.text("a"), View.text("b")])

let element: View.node =
  View.element("p", ~attrs=[View.attr("class", "lead")], ~children=[greeting], ())
```
*/
type rec node = RuntimeNode.node =
  | Element({
      tag: string,
      attrs: array<(string, attrValue)>,
      events: array<(string, Dom.event => unit)>,
      children: array<node>,
    })
  | Text(string)
  | SignalText(Signal.t<string>)
  | Fragment(array<node>)
  | SignalFragment(Signal.t<array<node>>)
  | Keyed({key: string, identity: Obj.t, child: node})
  | LazyComponent(unit => node)
  | KeyedList({signal: Signal.t<array<Obj.t>>, keyFn: Obj.t => string, renderItem: Obj.t => node})

/* ============================================================================
 * Attributes
 * ============================================================================ */

/**
A static string attribute. Written once and never updated.

## Examples

```rescript
let node = View.element("div", ~attrs=[View.attr("class", "card")], ())
```
*/
let attr: (string, string) => (string, attrValue)

/**
An attribute backed by a signal. The DOM is patched whenever the signal
changes, without re-rendering the element.

## Examples

```rescript
let theme = Signal.make("dark")
let node = View.element("div", ~attrs=[View.signalAttr("data-theme", theme)], ())

Signal.set(theme, "light") // patches the attribute in place
```
*/
let signalAttr: (string, Signal.t<string>) => (string, attrValue)

/**
An attribute backed by a computation. Every signal read inside `compute`
becomes a dependency.

Use it when the attribute is derived from more than one signal, or needs
formatting.

## Examples

```rescript
let count = Signal.make(3)
let node = View.element(
  "li",
  ~attrs=[View.computedAttr("aria-label", () => Int.toString(Signal.get(count)) ++ " items")],
  (),
)
```
*/
let computedAttr: (string, unit => string) => (string, attrValue)

/**
A removable static attribute: `None` removes it instead of writing an empty
value.

`Some("")` and `None` are the two states presence-based CSS selectors such as
`[data-open]` distinguish.

## Examples

```rescript
let present = View.element("div", ~attrs=[View.optionalAttr("data-open", Some(""))], ())
let absent = View.element("div", ~attrs=[View.optionalAttr("data-open", None)], ())
```
*/
let optionalAttr: (string, option<string>) => (string, attrValue)

/**
A removable attribute backed by a signal: the attribute appears and disappears
as the signal moves between `Some` and `None`.

## Examples

```rescript
let error = Signal.make(None)
let node = View.element("input", ~attrs=[View.optionalSignalAttr("aria-invalid", error)], ())

Signal.set(error, Some("true")) // adds the attribute
Signal.set(error, None) // removes it
```
*/
let optionalSignalAttr: (string, Signal.t<option<string>>) => (string, attrValue)

/**
A removable attribute backed by a computation.

## Examples

```rescript
let open_ = Signal.make(false)
let node = View.element(
  "details",
  ~attrs=[View.optionalComputedAttr("open", () => Signal.get(open_) ? Some("") : None)],
  (),
)
```
*/
let optionalComputedAttr: (string, unit => option<string>) => (string, attrValue)

/**
Namespaced aliases of the six attribute helpers, for call sites that prefer
`Attr.signal("data-theme", theme)` to `signalAttr("data-theme", theme)`.

Each binding is the same function as its top-level counterpart: `Attr.string`
is `attr`, `Attr.signal` is `signalAttr`, `Attr.compute` is `computedAttr`,
`Attr.optional` is `optionalAttr`, `Attr.optionalSignal` is
`optionalSignalAttr` and `Attr.optionalCompute` is `optionalComputedAttr`.

## Examples

```rescript
let theme = Signal.make("dark")

let attrs = [
  View.Attr.string("class", "card"),
  View.Attr.signal("data-theme", theme),
  View.Attr.optional("data-open", Some("")),
]

let node = View.element("div", ~attrs, ())
```
*/
module Attr: {
  /** Static string attribute. Same function as `View.attr`. */
  let string: (string, string) => (string, attrValue)

  /** Signal-backed attribute. Same function as `View.signalAttr`. */
  let signal: (string, Signal.t<string>) => (string, attrValue)

  /** Computation-backed attribute. Same function as `View.computedAttr`. */
  let compute: (string, unit => string) => (string, attrValue)

  /** Removable static attribute. Same function as `View.optionalAttr`. */
  let optional: (string, option<string>) => (string, attrValue)

  /** Removable signal-backed attribute. Same function as `View.optionalSignalAttr`. */
  let optionalSignal: (string, Signal.t<option<string>>) => (string, attrValue)

  /** Removable computation-backed attribute. Same function as `View.optionalComputedAttr`. */
  let optionalCompute: (string, unit => option<string>) => (string, attrValue)
}

/* ============================================================================
 * Node constructors
 * ============================================================================ */

/**
A static text node.

This is the explicit way to put a string in child position; JSX child
interpolation goes through `child` instead.

## Examples

```rescript
let node = View.element("p", ~children=[View.text("Hello")], ())
```
*/
let text: string => node

/**
A reactive text node driven by a computation. Only the text is patched when a
dependency changes — the surrounding element is untouched.

## Examples

```rescript
let name = Signal.make("Ada")
let node = View.element("p", ~children=[View.signalText(() => "Hi " ++ Signal.get(name))], ())

Signal.set(name, "Grace") // patches the text node in place
```
*/
let signalText: (unit => string) => node

/**
A reactive text node from an int computation. Shorthand for `signalText` with
`Int.toString`.

## Examples

```rescript
let count = Signal.make(0)
let node = View.element("span", ~children=[View.signalInt(() => Signal.get(count))], ())
```
*/
let signalInt: (unit => int) => node

/**
A reactive text node from a float computation. Shorthand for `signalText` with
`Float.toString`.

## Examples

```rescript
let ratio = Signal.make(0.5)
let node = View.element("span", ~children=[View.signalFloat(() => Signal.get(ratio))], ())
```
*/
let signalFloat: (unit => float) => node

/**
A static text node from an int.

## Examples

```rescript
let node = View.element("span", ~children=[View.int(42)], ())
```
*/
let int: int => node

/**
A static text node from a float.

## Examples

```rescript
let node = View.element("span", ~children=[View.float(1.5)], ())
```
*/
let float: float => node

/**
A static text node from a bool, rendering `"true"` or `"false"`.

## Examples

```rescript
let node = View.element("span", ~children=[View.bool(true)], ())
```
*/
let bool: bool => node

/**
Groups nodes without introducing a wrapper element.

## Examples

```rescript
let node = View.fragment([View.text("a"), View.text("b")])
```
*/
let fragment: array<node> => node

/**
A fragment whose children come from a signal. The whole child list is replaced
when the signal changes — use `eachWithKey` or `For` when element identity
matters.

## Examples

```rescript
let children = Signal.make([View.text("a")])
let node = View.signalFragment(children)

Signal.set(children, [View.text("a"), View.text("b")])
```
*/
let signalFragment: Signal.t<array<node>> => node

/**
Auto-tracked reactive block: every signal read while `body` runs subscribes the
block, which re-evaluates `body` and replaces its children wholesale (no
diffing) when a dependency changes.

Keep tracked blocks small; prefer `eachWithKey`/`For` for lists and
`@xote.component` for fine-grained updates.

## Examples

```rescript
let loggedIn = Signal.make(false)

let node = View.tracked(() =>
  if Signal.get(loggedIn) {
    View.element("p", ~children=[View.text("Welcome back")], ())
  } else {
    View.element("a", ~attrs=[View.attr("href", "/login")], ~children=[View.text("Sign in")], ())
  }
)
```
*/
let tracked: (unit => node) => node

/**
A reactive list that re-renders every item when the signal changes.

Simple but unkeyed: DOM nodes are not reused, so element state (focus, input
values, transitions) is lost on every update. Prefer `eachWithKey` for anything
the user interacts with.

## Examples

```rescript
let items = Signal.make(["a", "b"])

let node = View.element(
  "ul",
  ~children=[View.each(items, item => View.element("li", ~children=[View.text(item)], ()))],
  (),
)
```
*/
let each: (Signal.t<array<'a>>, 'a => node) => node

/**
A keyed reactive list that reconciles the DOM and preserves element identity.

The second argument extracts a stable key per item; nodes whose key survives an
update are moved rather than recreated, so focus and input state are kept.

## Examples

```rescript
type todo = {id: string, label: string}

let todos = Signal.make([{id: "1", label: "Write docs"}])

let node = View.element(
  "ul",
  ~children=[
    View.eachWithKey(
      todos,
      todo => todo.id,
      todo => View.element("li", ~children=[View.text(todo.label)], ()),
    ),
  ],
  (),
)

// Reordering moves the existing <li> instead of rebuilding it.
Signal.set(todos, [{id: "2", label: "Ship"}, {id: "1", label: "Write docs"}])
```
*/
let eachWithKey: (Signal.t<array<'a>>, 'a => string, 'a => node) => node

/**
Renders a static-or-reactive value into a node.

A `Static` value renders once; a `Reactive` one re-renders whenever the source
signal changes. `View.Show`, `View.Maybe` and `View.Value` are built on it.

A `Fragment` returned by `renderItem` is flattened into the reactive pass
rather than nested, so keyed children stay reconcilable.

## Examples

```rescript
let count = Signal.make(1)

// Reactive: re-renders on every change.
let live = View.render(MaybeSignal.reactive(count), n =>
  View.element("p", ~children=[View.text("Count: " ++ Int.toString(n))], ())
)

// Static: rendered once.
let once = View.render(MaybeSignal.static("Ada"), name =>
  View.element("p", ~children=[View.text(name)], ())
)
```
*/
let render: (MaybeSignal.t<'a>, 'a => node) => node

/**
Creates an element node for any tag.

The general constructor behind `Html.*` and JSX. Reach for it when a tag has no
`Html` helper, or when attributes are assembled programmatically. The trailing
`unit` is required because every other argument is optional.

## Examples

```rescript
// A tag with no Html helper.
let section = View.element(
  "section",
  ~attrs=[View.attr("class", "hero")],
  ~children=[View.text("Welcome")],
  (),
)

// With an event handler.
let onSubmit = View.element(
  "form",
  ~events=[("submit", _evt => Console.log("submitted"))],
  ~children=[section],
  (),
)
```
*/
let element: (
  string,
  ~attrs: array<(string, attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<node>=?,
  unit,
) => node

/**
An empty placeholder, rendering an empty text node.

The node still occupies a position in the DOM, so a reactive block can later
replace it in place. Use it as the "render nothing" branch of a conditional.

## Examples

```rescript
let visible = Signal.make(false)

let node = View.tracked(() =>
  Signal.get(visible) ? View.element("p", ~children=[View.text("Hi")], ()) : View.null()
)
```
*/
let null: unit => node

/** Alias of `null`: an empty placeholder node. */
let empty: unit => node

/* ============================================================================
 * JSX rendering components
 * ============================================================================ */

/**
Renders a list, keyed when `by` is supplied.

Without `by` this behaves like `each` (re-render everything); with `by` it
behaves like `eachWithKey` (reconcile and preserve identity). `each` accepts a
`MaybeSignal`, so the same component renders static and reactive lists.

## Examples

```rescript
// Static list.
let staticList =
  <ul>
    <View.For
      each={MaybeSignal.static(["One", "Two"])}
      render={label => <li> {View.text(label)} </li>}
    />
  </ul>

// Reactive and keyed.
let items = Signal.make([("1", "One")])
let keyedList =
  <ul>
    <View.For
      each={MaybeSignal.reactive(items)}
      by={((id, _label)) => id}
      render={((_id, label)) => <li> {View.text(label)} </li>}
    />
  </ul>
```
*/
module For: {
  /**
  Props of `View.For`.

  - `each` — the items, static or reactive.
  - `by` — optional stable key per item; supplying it makes the list keyed.
  - `render` — builds a node for one item.
  */
  type props<'item> = {
    each: MaybeSignal.t<array<'item>>,
    by?: 'item => string,
    render: 'item => node,
  }

  /** Renders the list. Called for you by `<View.For />`; see the module doc for usage. */
  let make: props<'item> => node
}

/**
`For` with `by` required: a keyed list where forgetting the key is a compile
error rather than a silent loss of element identity.

## Examples

```rescript
type row = {id: string, label: string}

let rows = Signal.make([{id: "1", label: "One"}])

let table =
  <ul>
    <View.KeyedFor
      each={MaybeSignal.reactive(rows)}
      by={row => row.id}
      render={row => <li> {View.text(row.label)} </li>}
    />
  </ul>
```
*/
module KeyedFor: {
  /**
  Props of `View.KeyedFor`. Same as `View.For.props`, except `by` is mandatory.
  */
  type props<'item> = {
    each: MaybeSignal.t<array<'item>>,
    by: 'item => string,
    render: 'item => node,
  }

  /** Renders the keyed list. Called for you by `<View.KeyedFor />`; see the module doc for usage. */
  let make: props<'item> => node
}

/**
Renders `children` while `when_` is true, and `fallback` otherwise.

With no `fallback`, the false branch renders nothing.

## Examples

```rescript
let visible = Signal.make(true)

let node =
  <View.Show when_={MaybeSignal.reactive(visible)} fallback={<p> {View.text("Hidden")} </p>}>
    <p> {View.text("Visible")} </p>
  </View.Show>

Signal.set(visible, false) // swaps in the fallback
```
*/
module Show: {
  /**
  Props of `View.Show`.

  - `when_` — the condition, static or reactive.
  - `children` — rendered while the condition is true.
  - `fallback` — rendered while it is false; nothing, if omitted.
  */
  type props = {
    when_: MaybeSignal.t<bool>,
    children?: node,
    fallback?: node,
  }

  /** Renders one of the two branches. Called for you by `<View.Show />`; see the module doc for usage. */
  let make: props => node
}

/**
Renders an `option` value: `render` on `Some`, `fallback` on `None`.

The unwrapping counterpart of `Show` — `render` receives the value, so there is
no need to match on the option by hand.

## Examples

```rescript
let selected = Signal.make(None)

let node =
  <View.Maybe
    value={MaybeSignal.reactive(selected)}
    fallback={<p> {View.text("Nothing selected")} </p>}
    render={name => <p> {View.text("Selected: " ++ name)} </p>}
  />

Signal.set(selected, Some("Ada")) // renders "Selected: Ada"
```
*/
module Maybe: {
  /**
  Props of `View.Maybe`.

  - `value` — an optional value, static or reactive.
  - `render` — builds a node from the unwrapped value.
  - `fallback` — rendered on `None`; nothing, if omitted.
  */
  type props<'value> = {
    value: MaybeSignal.t<option<'value>>,
    render: 'value => node,
    fallback?: node,
  }

  /** Renders the value or the fallback. Called for you by `<View.Maybe />`; see the module doc for usage. */
  let make: props<'value> => node
}

/**
Renders an arbitrary value through `render`, re-rendering when it changes.

The general case of `Show` and `Maybe`, for values with no natural empty state.

## Examples

```rescript
let count = Signal.make(1)

let node =
  <View.Value
    value={MaybeSignal.reactive(count)}
    render={n => <p> {View.text("Count: " ++ Int.toString(n))} </p>}
  />

Signal.set(count, 2) // re-renders with "Count: 2"
```
*/
module Value: {
  /**
  Props of `View.Value`.

  - `value` — the value, static or reactive.
  - `render` — builds a node from it.
  */
  type props<'value> = {
    value: MaybeSignal.t<'value>,
    render: 'value => node,
  }

  /** Renders the value through `render`. Called for you by `<View.Value />`; see the module doc for usage. */
  let make: props<'value> => node
}

/**
Renders a string as text, from either `value` or `children`.

Accepts a raw string, a `Signal.t<string>` or a `unit => string` thunk — the
prop is normalized with `MaybeSignal.ofUnknown`, so a signal renders reactively
and a plain string renders once.

## Examples

```rescript
let name = Signal.make("Ada")

let reactive = <View.Text value={name} />
let static = <View.Text value="Ada" />
let asChild = <View.Text> {"Ada"} </View.Text>
```
*/
module Text: {
  /**
  Props of `View.Text`. Supply the string as `value` or as `children`;
  deliberately untyped so a raw value, a signal or a thunk are all accepted.
  */
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  /** Renders the string as text. Called for you by `<View.Text />`; see the module doc for usage. */
  let make: props<'value, 'children> => node
}

/**
Renders an int as text. Like `View.Text`, but formats with `Int.toString`.

## Examples

```rescript
let count = Signal.make(0)

let reactive = <View.Int value={count} />
let static = <View.Int value={42} />
```
*/
module Int: {
  /** Props of `View.Int`. See `View.Text.props`. */
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  /** Renders the int as text. Called for you by `<View.Int />`; see the module doc for usage. */
  let make: props<'value, 'children> => node
}

/**
Renders a float as text. Like `View.Text`, but formats with `Float.toString`.

## Examples

```rescript
let ratio = Signal.make(0.5)

let reactive = <View.Float value={ratio} />
let static = <View.Float value={1.5} />
```
*/
module Float: {
  /** Props of `View.Float`. See `View.Text.props`. */
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  /** Renders the float as text. Called for you by `<View.Float />`; see the module doc for usage. */
  let make: props<'value, 'children> => node
}

/**
Renders a bool as `"true"` or `"false"`. Like `View.Text`, for booleans.

## Examples

```rescript
let ready = Signal.make(false)

let reactive = <View.Bool value={ready} />
let static = <View.Bool value={true} />
```
*/
module Bool: {
  /** Props of `View.Bool`. See `View.Text.props`. */
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  /** Renders the bool as text. Called for you by `<View.Bool />`; see the module doc for usage. */
  let make: props<'value, 'children> => node
}

/* ============================================================================
 * Mounting
 * ============================================================================ */

/**
Renders a node into a container element, replacing its contents.

The entry point for a client-rendered app. To attach to server-rendered markup
instead, use `Hydration.hydrate`, which reuses the existing DOM.

## Examples

```rescript
@val external document: {..} = "document"

let container: Dom.element = document["getElementById"]("root")
View.mount(<p> {View.text("Hello")} </p>, container)
```
*/
let mount: (node, Dom.element) => unit

/**
`mount` by element id. Does nothing when no element has that id.

## Examples

```rescript
View.mountById(<p> {View.text("Hello")} </p>, "root")
```
*/
let mountById: (node, string) => unit

/* ============================================================================
 * Emitted by @xote.component
 *
 * These two are public because the PPX generates calls to them in consumer
 * code. They are usable by hand, but the annotation is the intended caller —
 * everything else the PPX relies on stays internal.
 * ============================================================================ */

/**
Coerces an arbitrary value in child position into a node.

A node passes through, a thunk or `Signal.t` becomes reactive, a scalar becomes
text, an array becomes a fragment, null/undefined render nothing.

Typed `'a => node`, so it erases type checking in child position: a record or
variant compiles and renders `"[object Object]"` (with a development-only
warning) where unannotated code would have failed to compile. Prefer `text`,
`int` or `View.Value` in hand-written code.

## Examples

```rescript
let count = Signal.make(1)

let fromString = View.child("Hello")
let fromInt = View.child(7)
let fromSignal = View.child(count) // reactive
let fromThunk = View.child(() => Signal.get(count) * 2) // reactive
let fromArray = View.child([View.text("a"), View.text("b")]) // a fragment
```
*/
let child: 'a => node

/**
Wraps a leaf whose signal reads the PPX could not resolve statically.

On first evaluation the leaf runs inside a throwaway computed; if that computed
subscribed to anything, the read was hidden, and a development-only warning
names `site`. Behaviour is unchanged either way — with no dependencies this is
the identity function.

Emitted by `@xote.component`; there is rarely a reason to call it by hand.

## Examples

```rescript
let count = Signal.make(1)

// Returns the value, and warns in development if the read was hidden.
let value = View.probe("Counter.label", () => Signal.get(count))
value == 1
```
*/
let probe: (string, unit => 'a) => 'a

/* ============================================================================
 * Deprecated - removed in the next major release
 * ============================================================================ */

/** Deprecated: internal helper. Use `MaybeSignal.ofUnknown` to normalize an untyped value. */
@deprecated("Internal helper. Use MaybeSignal.ofUnknown to normalize an untyped value.")
let isReactiveProp: 'value => bool
