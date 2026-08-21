module DOM = RuntimeDom

/* ============================================================================
 * Type Definitions
 *
 * The node types live in the internal `RuntimeNode` module so that the renderer
 * can be internal too; they are re-exported here with their constructors, so
 * `View.node` / `View.attrValue` stay the public spelling.
 * ============================================================================ */

/* Attribute value source.

 The `Optional*` variants carry an `option<string>`, where `None` means "remove
 this attribute" rather than "write an empty value". Presence-based styling
 (`[data-open]`, `[data-checked]`) needs that distinction: an attribute that is
 always present, even as `""`, always matches. */
type attrValue = RuntimeNode.attrValue =
  | Static(string)
  | SignalValue(Signal.t<string>)
  | Compute(unit => string)
  | OptionalStatic(option<string>)
  | OptionalSignalValue(Signal.t<option<string>>)
  | OptionalCompute(unit => option<string>)

/* Virtual node types */
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
 * Attribute Helpers
 * ============================================================================ */

module Attributes = {
  let static = (key: string, value: string): (string, attrValue) => (key, Static(value))

  let signal = (key: string, signal: Signal.t<string>): (string, attrValue) => (
    key,
    SignalValue(signal),
  )

  let computed = (key: string, compute: unit => string): (string, attrValue) => (
    key,
    Compute(compute),
  )

  let optional = (key: string, value: option<string>): (string, attrValue) => (
    key,
    OptionalStatic(value),
  )

  let optionalSignal = (key: string, signal: Signal.t<option<string>>): (string, attrValue) => (
    key,
    OptionalSignalValue(signal),
  )

  let optionalComputed = (key: string, compute: unit => option<string>): (string, attrValue) => (
    key,
    OptionalCompute(compute),
  )
}

/* Public API for attributes */
let attr = Attributes.static
let signalAttr = Attributes.signal
let computedAttr = Attributes.computed
let optionalAttr = Attributes.optional
let optionalSignalAttr = Attributes.optionalSignal
let optionalComputedAttr = Attributes.optionalComputed

module Attr = {
  let string = attr
  let signal = signalAttr
  let compute = computedAttr
  let optional = optionalAttr
  let optionalSignal = optionalSignalAttr
  let optionalCompute = optionalComputedAttr
}

/* ============================================================================
 * Public API
 * ============================================================================ */

/* Text nodes */
let text = (content: string): node => Text(content)

let signalText = (compute: unit => string): node => SignalText(
  RuntimeOwner.ownedComputed(compute),
)

let signalInt = (compute: unit => int): node => SignalText(
  RuntimeOwner.ownedComputed(() => compute()->Int.toString),
)

let signalFloat = (compute: unit => float): node => SignalText(
  RuntimeOwner.ownedComputed(() => compute()->Float.toString),
)

/* Static text nodes with type-specific helpers */
let int = (value: int): node => Text(Int.toString(value))

let float = (value: float): node => Text(Float.toString(value))

let bool = (value: bool): node => Text(value ? "true" : "false")

/* Fragments */
let fragment = (children: array<node>): node => Fragment(children)

let signalFragment = (signal: Signal.t<array<node>>): node => SignalFragment(signal)

/* Auto-tracked reactive block: every signal read while `body` runs subscribes
   the block, which re-evaluates `body` and replaces its children wholesale
   (no diffing) whenever a dependency changes. Prefer `eachWithKey`/`For` for
   lists and keep tracked blocks small. */
let tracked = (body: unit => node): node => SignalFragment(
  RuntimeOwner.ownedComputed(() => [body()]),
)

let childrenToArray = (child: option<node>): array<node> => {
  switch child {
  | Some(Fragment(children)) => children
  | Some(child) => [child]
  | None => []
  }
}

/* Lists */
let each = (signal: Signal.t<array<'a>>, renderItem: 'a => node): node => {
  let nodesSignal = RuntimeOwner.ownedComputed(() => {
    Signal.get(signal)->Array.map(renderItem)
  })
  SignalFragment(nodesSignal)
}

let eachWithKey = (
  signal: Signal.t<array<'a>>,
  keyFn: 'a => string,
  renderItem: 'a => node,
): node => {
  KeyedList({
    signal: Obj.magic(signal),
    keyFn: Obj.magic(keyFn),
    renderItem: Obj.magic(renderItem),
  })
}

/* JSX rendering primitives */
module For = {
  type props<'item> = {
    each: MaybeSignal.t<array<'item>>,
    by?: 'item => string,
    render: 'item => node,
  }

  let make = (props: props<'item>): node => {
    switch (props.each, props.by) {
    | (Static(items), Some(keyFn)) =>
      fragment(
        items->Array.map(item =>
          Keyed({key: keyFn(item), identity: Obj.magic(item), child: props.render(item)})
        ),
      )
    | (Static(items), None) => fragment(items->Array.map(props.render))
    | (Reactive(signal), Some(keyFn)) => eachWithKey(signal, keyFn, props.render)
    | (Reactive(signal), None) => each(signal, props.render)
    }
  }
}

module KeyedFor = {
  type props<'item> = {
    each: MaybeSignal.t<array<'item>>,
    by: 'item => string,
    render: 'item => node,
  }

  let make = (props: props<'item>): node => {
    switch props.each {
    | Static(items) =>
      fragment(
        items->Array.map(item =>
          Keyed({key: props.by(item), identity: Obj.magic(item), child: props.render(item)})
        ),
      )
    | Reactive(signal) => eachWithKey(signal, props.by, props.render)
    }
  }
}

module Show = {
  type props = {
    when_: MaybeSignal.t<bool>,
    children?: node,
    fallback?: node,
  }

  let make = (props: props): node => {
    switch props.when_ {
    | Static(true) => fragment(childrenToArray(props.children))
    | Static(false) => fragment(childrenToArray(props.fallback))
    | Reactive(signal) =>
      signalFragment(
        RuntimeOwner.ownedComputed(() =>
          if Signal.get(signal) {
            childrenToArray(props.children)
          } else {
            childrenToArray(props.fallback)
          }
        ),
      )
    }
  }
}

module Maybe = {
  type props<'value> = {
    value: MaybeSignal.t<option<'value>>,
    render: 'value => node,
    fallback?: node,
  }

  let renderValue = (props: props<'value>, value: option<'value>): array<node> => {
    switch value {
    | Some(value) => [props.render(value)]
    | None => childrenToArray(props.fallback)
    }
  }

  let make = (props: props<'value>): node => {
    switch props.value {
    | Static(value) => fragment(renderValue(props, value))
    | Reactive(signal) =>
      signalFragment(RuntimeOwner.ownedComputed(() => renderValue(props, Signal.get(signal))))
    }
  }
}

module Value = {
  type props<'value> = {
    value: MaybeSignal.t<'value>,
    render: 'value => node,
  }

  let make = (props: props<'value>): node => {
    switch props.value {
    | Static(value) => props.render(value)
    | Reactive(signal) =>
      signalFragment(RuntimeOwner.ownedComputed(() => [props.render(Signal.get(signal))]))
    }
  }
}

/* Element constructor */
let element = (
  tag: string,
  ~attrs: array<(string, attrValue)>=[],
  ~events: array<(string, Dom.event => unit)>=[],
  ~children: array<node>=[],
  (),
): node => Element({tag, attrs, events, children})

/* Null representation */
let null = () => text("")
let empty = null

/* Mounting */
let mount = (node: node, container: Dom.element): unit => {
  let el = RuntimeRender.render(node)
  container->DOM.appendChild(el)
}

let mountById = (node: node, containerId: string): unit => {
  switch DOM.getElementById(containerId)->Nullable.toOption {
  | Some(container) => mount(node, container)
  | None => Console.error("Container element not found: " ++ containerId)
  }
}

@deprecated("Internal helper. Use MaybeSignal.ofUnknown to normalize an untyped value.")
let isReactiveProp = RuntimeValue.isMaybeSignal

let valuePrimitive = (value: 'input, stringify: 'value => string): node =>
  if RuntimeValue.isNullish(value) {
    null()
  } else {
    /* `map` always allocates a fresh computed over the source, so the result is
       the library's to release even when the source signal is the consumer's. */
    switch MaybeSignal.ofUnknown(value)->MaybeSignal.map(stringify) {
    | Static(value) => text(value)
    | Reactive(signal) => SignalText(RuntimeOwner.markOwned(signal))
    }
  }

let renderValuePrimitiveProps = (props: 'props, stringify: 'scalar => string): node => {
  switch (props->RuntimeValue.getField("children"), props->RuntimeValue.getField("value")) {
  | (Some(children), _) => valuePrimitive(children, stringify)
  | (None, Some(value)) => valuePrimitive(value, stringify)
  | (None, None) => null()
  }
}

/* Is this runtime value already a `node`? Nodes are ReScript variants compiled
   to objects carrying a string `TAG` in the set below; Signals, Props, scalars
   and functions are not, so a value already built into a node passes straight
   through `child`. */
let isNode: 'a => bool = %raw(`function (v) {
  if (v === null || typeof v !== "object" || typeof v.TAG !== "string") { return false }
  switch (v.TAG) {
    case "Element":
    case "Text":
    case "SignalText":
    case "Fragment":
    case "SignalFragment":
    case "Keyed":
    case "LazyComponent":
    case "KeyedList":
      return true
    default:
      return false
  }
}`)

/* Stringify any scalar child (int/float/string/bool) without knowing its type
   at compile time; null/undefined render as empty. */
let stringifyChild: 'a => string = %raw(`function (v) { return v == null ? "" : String(v) }`)

/* Is this runtime value a rescript-signals signal/computed? Positive shape
   check against `Signal.t` ({id: int, value, equals: fn, subs: object}) —
   detecting by shape rather than assuming any non-node object is a signal
   keeps records/dicts that land in `child` from reaching `Signal.get`. */
let isSignal: 'a => bool = %raw(`function (v) {
  return v !== null && typeof v === "object"
    && typeof v.id === "number"
    && typeof v.equals === "function"
    && typeof v.subs === "object" && v.subs !== null
    && "value" in v
}`)

let isArray: 'a => bool = %raw(`function (v) { return Array.isArray(v) }`)

/* A value that renders as text on its own (string, number, boolean), as
   opposed to a node, a signal, a collection, or nothing. */
let isScalar: 'a => bool = %raw(`function (v) {
  const t = typeof v
  return t === "string" || t === "number" || t === "boolean"
}`)

/* ============================================================================
 * Development-only diagnostics
 * ============================================================================ */

/* Both diagnostics below cost something in production — the probe allocates a
   throwaway computed per unresolved leaf, and `warnUnrenderable` formats a
   console argument on every coerced child — so both are skipped there.
   `globalThis.__XOTE_DEV__` wins when set; otherwise `process.env.NODE_ENV`
   (which bundlers inline) decides. When neither is available they stay on: a
   silently stale UI is worse than an allocation. */
let readDevFlag: unit => bool = %raw(`function () {
  try {
    if (typeof globalThis !== "undefined" && globalThis.__XOTE_DEV__ !== undefined) {
      return !!globalThis.__XOTE_DEV__
    }
    if (typeof process !== "undefined" && process.env && process.env.NODE_ENV) {
      return process.env.NODE_ENV !== "production"
    }
  } catch (_) {}
  return true
}`)

let devMode: ref<option<bool>> = ref(None)

let isDevMode = (): bool =>
  switch devMode.contents {
  | Some(enabled) => enabled
  | None => {
      let enabled = readDevFlag()
      devMode := Some(enabled)
      enabled
    }
  }

let logUnrenderable: 'a => unit = %raw(`function (v) {
  console.warn(
    "[Xote] View.child: this value is not a node, signal, array, function or scalar and cannot be rendered; it was stringified. Build a node from it (View.text, JSX, ...) instead:",
    v
  )
}`)

/* Reaching here means the child is already rendering wrong, so the warning is
   worth an allocation in development — but in production the render is what it
   is, and the message helps nobody. */
let warnUnrenderable = (value: 'a): unit =>
  if isDevMode() {
    logUnrenderable(value)
  }

/* Coerce an arbitrary JSX child into a node. This is what `@xote.component`
   emits for a *bare* child in element position — `<div>{Signal.get(count)}</div>`
   — so a value primitive (`<View.Int>`) is no longer required:

     - an already-built node passes through untouched;
     - a reactive thunk (what the ppx emits for an eager signal read) re-runs on
       change — a scalar result becomes reactive text, a node result a tracked
       fragment;
     - a bare `Signal.t` (detected by shape) becomes reactive text; a plain
       scalar, static text;
     - an array is coerced element-wise into a `Fragment`;
     - null/undefined render nothing;
     - any other object cannot be rendered: it is stringified with a console
       warning rather than treated as a signal.

   A thunk whose first evaluation is a *scalar* locks into reactive-text mode
   (safe: ReScript typing keeps scalar thunks scalar). Any other first value —
   node, array, option<node>, null — gets a tracked fragment that re-coerces
   the result on every run, so shape changes like `None -> Some(node)` render
   correctly. The one unsupported shape change is scalar-first-then-node from
   an untyped hand-written thunk.

   The explicit `View.Text`/`Int`/`Float`/`Bool` value primitives still work for
   non-ppx code and for stronger typing; this is the ergonomic default under the
   annotation. */
let rec child = (value: 'a): node => {
  if isNode(value) {
    (Obj.magic(value): node)
  } else {
    /* Nullish first: `null` is itself an object, so it has to be ruled out
       before the object branch. */
    if RuntimeValue.isNullish(value) {
      null()
    } else if RuntimeValue.isFunction(value) {
      let compute: unit => 'b = Obj.magic(value)
      /* The thunk's first result decides the shape. That probe read is
         untracked and thrown away — it asks what the leaf *is*, and must not
         subscribe anything on its own. */
      if isScalar(Signal.untrack(compute)) {
        /* scalar-first thunk: a reactive text node. ReScript typing keeps a
           scalar thunk scalar, so locking text mode here is safe. */
        SignalText(RuntimeOwner.ownedComputed(() => stringifyChild(compute())))
      } else {
        /* node-, array-, option- or otherwise object-first thunk: a tracked
           fragment that re-coerces the result on *every* run, so thunks over
           `option<node>` (None first, Some(node) later) and array-returning
           thunks stay correct instead of being locked into text mode by
           their first value. */
        SignalFragment(RuntimeOwner.ownedComputed(() => [child(Obj.magic(compute()))]))
      }
    } else if RuntimeValue.isObject(value) {
      if isSignal(value) {
        let signal: Signal.t<'b> = Obj.magic(value)
        SignalText(RuntimeOwner.ownedComputed(() => stringifyChild(Signal.get(signal))))
      } else if isArray(value) {
        let items: array<'b> = Obj.magic(value)
        Fragment(items->Array.map(item => child(item)))
      } else {
        warnUnrenderable(value)
        text(stringifyChild(value))
      }
    } else {
      text(stringifyChild(value))
    }
  }
}

/* ============================================================================
 * Hidden signal reads (@xote.component)
 * ============================================================================ */

/* The ppx detects signal reads *syntactically*. A read it cannot see the
   definition of — an imported helper (`Store.waitingCount(store)`), a read
   pulled out of a data structure — is compiled as a plain value: the leaf is
   evaluated once and never updates, and no error or warning is produced. Inside
   an enclosing `tracked` block the same read silently widens that block's
   dependencies, so one broadcast re-renders the whole region.

   `probe` is what `@xote.component` emits around a leaf whose expression
   contains a call it could not resolve. The first time that leaf is evaluated
   it runs inside a throwaway computed, and what that computed subscribed to
   settles the question:

     - nothing subscribed: the leaf really is static. The computed is disposed
       and the value returned, so `probe` is exactly the identity function.
     - something subscribed: the read was hidden from the ppx. The value is read
       back *through* the computed, so an enclosing tracked block subscribes
       exactly as it would have without the probe (behaviour is unchanged), and
       a one-time warning naming the source location tells the developer to
       thunk it.

   The warning is only emitted for a *scalar* result — the shape that silently
   renders a stale number or class name. A reactive result (a signal, a thunk, a
   `MaybeSignal`) is already handled by the runtime, and a node-shaped result is
   built fresh by whatever renders it. */

/* Does this computed subscribe to any signal? Reads `subs.firstDep` on the
   `rescript-signals` computed. If the internal shape is not recognised, report
   `false`: no warning and no behaviour change is the safe direction. */
let hasDependencies: 'a => bool = %raw(`function (c) {
  var subs = c == null ? null : c.subs
  if (subs === null || typeof subs !== "object" || !("firstDep" in subs)) { return false }
  return subs.firstDep != null
}`)

let warnHiddenRead = (site: string): unit =>
  Console.warn(
    "[Xote] " ++
    site ++
    ": this value reads a signal through a call @xote.component cannot see " ++
    "(a helper from another module, MaybeSignal.get, a read stored in a data structure), " ++
    "so it compiled to a one-shot value that will never update — and inside a tracked " ++
    "block it widens that block and re-renders it wholesale. Wrap it in a thunk " ++
    "(`{() => ...}`) or inline the Signal.get. " ++
    "See https://github.com/brnrdog/xote/blob/main/ppx/README.md#hidden-reads",
  )

/* Each site is probed once. The answer is a property of the source expression,
   not of this render, so re-probing would only repeat the same finding — and
   the leaked-read branch has to keep its computed alive to stay subscribed.
   Every later evaluation of a probed leaf is therefore a plain call, and the
   report is emitted once however often the component renders. */
let probedSites: Dict.t<bool> = Dict.make()

let probe = (site: string, compute: unit => 'a): 'a =>
  if !isDevMode() || probedSites->Dict.get(site)->Option.isSome {
    compute()
  } else {
    probedSites->Dict.set(site, true)
    let signal = Computed.make(compute)
    if hasDependencies(signal) {
      if isScalar(Signal.peek(signal)) {
        warnHiddenRead(site)
      }
      /* Read back through the computed so an enclosing tracked block captures
         the same dependencies it would have captured without the probe. The
         computed is deliberately not disposed: it is what carries them. */
      Signal.get(signal)
    } else {
      let value = Signal.peek(signal)
      Computed.dispose(signal)
      value
    }
  }

module Text = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, value => value)
  }
}

module Int = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, value => value->Int.toString)
  }
}

module Float = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, value => value->Float.toString)
  }
}

module Bool = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let toString = value => value ? "true" : "false"

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, toString)
  }
}
