# Components

A component is a function that returns a `View.node`. It runs **once**, when
the node is first built, and never again. Everything that changes afterwards is
a reactive leaf the builder left behind.

## The `@xote.component` style (recommended)

Requires `"ppx-flags": ["xote/ppx/ppx"]` in `rescript.json`.

```rescript
/* Counter.res — one component per module, named `make` */
@xote.component
let make = (~start: int=0) => {
  let count = Signal.make(start)

  <div class="counter">
    <p> {"Count: "} {Signal.get(count)} </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}> {"+"} </button>
  </div>
}
```

Used from another file as `<Counter start=3 />` — the file name is the
component name.

The annotation does two things:

1. Derives the props record from the labeled arguments, exactly like
   ReScript's `@jsx.component` (which it emits underneath, so the
   one-component-per-module rule applies).
2. Decomposes the returned JSX into fine-grained leaves, so an inline
   `Signal.get` in an attribute or a child becomes a subscription instead of a
   one-shot read.

### What the annotation reaches

`@xote.component` marks the **whole file** as fine-grained, not just the
annotated binding. In a file with at least one annotated component, JSX is
decomposed wherever it appears: in the component, in JSX bound to a `let`, in
arrays and options of JSX, and in plain helper functions that return markup.

```rescript
/* no annotation needed — helpers returning markup are decomposed too */
let filterButton = (label, value, current) =>
  <button
    class={value === current ? "active" : "idle"}
    onClick={_ => Signal.set(filter, value)}>
    {label}
  </button>
```

A file with no `@xote.component` anywhere is left completely untouched. That is
the opt-in boundary: per file, by annotation.

### Bare children

Under the annotation any `{…}` in child position works, coerced at runtime by
`View.child`:

```rescript
<div>
  {"Count: "}           /* static text */
  {Signal.get(count)}   /* reactive text leaf */
  {View.text("node")}   /* already a node — passes through */
  {maybeNode}           /* None renders nothing */
  {items}               /* array — coerced element-wise */
</div>
```

`View.child` is typed `'a => node`, so it erases type checking in child
position: a record or variant compiles and renders `[object Object]` with a
development warning. If a child renders as `[object Object]`, that is why.

## The non-PPX style

Without `ppx-flags`, use `@jsx.component` and be explicit. Every reactive value
needs a thunk, and a scalar in child position needs a value primitive.

```rescript
@jsx.component
let make = (~start: int=0) => {
  let count = Signal.make(start)

  <div class="counter">
    <p>
      <View.Text> "Count: " </View.Text>
      <View.Int> {() => Signal.get(count)} </View.Int>
    </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      <View.Text> "+" </View.Text>
    </button>
  </div>
}
```

`View.Text`, `View.Int`, `View.Float` and `View.Bool` each take a `value` prop
or a child. They also stay useful under the PPX when you want the stronger
`int`/`float` typing.

## The function-based style

No JSX at all. `Html` covers `div span button input h1 h2 h3 p ul li a`; every
other tag goes through `View.element(tag, …)`.

```rescript
Html.div(
  ~attrs=[View.attr("class", "counter")],
  ~children=[
    Html.p(~children=[
      View.text("Count: "),
      View.signalText(() => Signal.get(count)->Int.toString),
    ], ()),
    Html.button(
      ~events=[("click", _ => Signal.update(count, n => n + 1))],
      ~children=[View.text("+")],
      (),
    ),
  ],
  (),
)
```

Note the trailing `()` — these take optional labeled arguments and need the
unit terminator.

## Props

Two categories, and the distinction decides whether you need a wrapper.

### Built-in element attributes: no wrapper

Every attribute on `<div>`, `<button>`, … is untyped by design. It accepts a
raw value, a `Signal.t`, a `unit => 'a` thunk, or a `MaybeSignal.t`, and the
runtime coerces it.

```rescript
<div class="static" />
<div class={classSignal} />
<div class={() => Signal.get(active) ? "on" : "off"} />
```

The trade for that convenience: `class={42}` compiles and renders `class="42"`.
The compiler will not catch a wrong type here.

### Typed props: `MaybeSignal.t`

`View.Show`, `View.For`, `View.Maybe`, `View.Value` and **every component you
write** have declared prop types. A prop that should accept both a plain value
and a reactive one is typed `MaybeSignal.t<'a>`, and the caller says which:

```rescript
@xote.component
let make = (~className: MaybeSignal.t<string>=MaybeSignal.static("badge"), ~children) =>
  <span class={className}> {children} </span>
```

```rescript
<Badge className={MaybeSignal.reactive(tone)}> {"Live"} </Badge>
<Badge> {"Static"} </Badge>
```

`MaybeSignal.t<'a>` is `Reactive(Signal.t<'a>) | Static('a)`. Build with
`static`, `reactive`, or `computed(fn)`; read with `get` (tracked) or `peek`
(untracked); transform with `map`, which preserves staticness.

> `Prop` is a deprecated alias of `MaybeSignal` — `Prop.t` is a type alias, so
> migrating is a rename. `Prop.static` → `MaybeSignal.static`, `Prop.signal`
> and `Prop.reactive` → `MaybeSignal.reactive`, `Prop.get` → `MaybeSignal.get`.

### User-component props are never thunked

This is the sharpest edge in the whole library.

```rescript
<Card label={Signal.get(name)} />   /* one-shot read — Card never updates */
```

A prop lands in the component's typed props record, so the PPX leaves it
exactly as written. A scalar prop *cannot* be reactive: the component function
runs once. To make it react, pass the reactive thing itself and read it inside:

```rescript
<Card name={name} />                          /* Signal.t prop */
<Card tone={MaybeSignal.reactive(tone)} />    /* MaybeSignal prop */
```

Props that are node-shaped are still decomposed: `children`, any prop whose
value is JSX, and any prop that is a function returning JSX (a `render`
callback). Function props whose body is not JSX — `by={row => row.id}`,
`onClick` — are left alone.

One consequence worth remembering: a prop is evaluated **where it is written**.
A one-shot read written inside a tracked branch subscribes that branch, so
changing it rebuilds the branch wholesale instead of updating a leaf. Pass the
signal down and the branch stays subscribed to its condition alone.

## Children

```rescript
@xote.component
let make = (~children) => <section class="card"> {children} </section>
```

`children` is a `View.node`. To accept several, take a `View.node` and let the
caller pass a fragment, or take an explicit array prop.

## Event handlers

```rescript
let onSubmit = (evt: Dom.event) => {
  ignore(evt)
  let value = Signal.peek(draft)   /* peek: a handler is not a reactive scope */
  submit(value)
}
```

Handlers run outside any tracking scope. `Signal.get` there creates no
subscription, but `peek` says so explicitly and survives a later refactor that
moves the code into an effect.

Available JSX handlers: `onClick`, `onInput`, `onChange`, `onSubmit`, `onFocus`,
`onBlur`, `onKeyDown`, `onKeyUp`, `onMouseEnter`, `onMouseLeave`, `onMouseDown`,
`onMouseMove`, `onMouseUp`, `onContextMenu`, `onDrag`, `onDragStart`,
`onDragEnd`, `onDragOver`, `onDragEnter`, `onDragLeave`, `onDrop`. Anything else
goes through the function-based `~events=[("eventname", handler)]`.
