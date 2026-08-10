/* Core rendering primitives: the virtual node type, attribute helpers, the JSX
   rendering components and DOM mounting.

   This interface is the public surface of `Xote.View`. Anything not listed here
   (the renderer, the DOM helpers, the owner system) is an implementation detail
   and lives in an internal `Runtime*` module. */

/* ============================================================================
 * Type Definitions
 * ============================================================================ */

/* Attribute value source: a literal, a signal, or a computation.

   The `Optional*` variants carry an `option<string>`, where `None` removes the
   attribute rather than writing an empty value — what presence-based styling
   (`[data-open]`) needs. */
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
 * Attributes
 * ============================================================================ */

/* Static string attribute */
let attr: (string, string) => (string, attrValue)

/* Reactive attribute backed by a signal */
let signalAttr: (string, Signal.t<string>) => (string, attrValue)

/* Reactive attribute backed by a computation */
let computedAttr: (string, unit => string) => (string, attrValue)

/* Removable attributes - `None` removes the attribute instead of writing a value */
let optionalAttr: (string, option<string>) => (string, attrValue)
let optionalSignalAttr: (string, Signal.t<option<string>>) => (string, attrValue)
let optionalComputedAttr: (string, unit => option<string>) => (string, attrValue)

module Attr: {
  let string: (string, string) => (string, attrValue)
  let signal: (string, Signal.t<string>) => (string, attrValue)
  let compute: (string, unit => string) => (string, attrValue)
  let optional: (string, option<string>) => (string, attrValue)
  let optionalSignal: (string, Signal.t<option<string>>) => (string, attrValue)
  let optionalCompute: (string, unit => option<string>) => (string, attrValue)
}

/* ============================================================================
 * Node constructors
 * ============================================================================ */

let text: string => node
let signalText: (unit => string) => node
let signalInt: (unit => int) => node
let signalFloat: (unit => float) => node
let int: int => node
let float: float => node
let bool: bool => node
let fragment: array<node> => node
let signalFragment: Signal.t<array<node>> => node

/* Auto-tracked reactive block: every signal read while `body` runs subscribes
   the block, which re-evaluates `body` and replaces its children wholesale (no
   diffing) when a dependency changes. Keep tracked blocks small; prefer
   `eachWithKey`/`For` for lists and `@xote.component` for fine-grained updates. */
let tracked: (unit => node) => node

/* Simple reactive list - re-renders every item when the signal changes */
let each: (Signal.t<array<'a>>, 'a => node) => node

/* Keyed reactive list - reconciles the DOM and preserves element identity */
let eachWithKey: (Signal.t<array<'a>>, 'a => string, 'a => node) => node

let element: (
  string,
  ~attrs: array<(string, attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<node>=?,
  unit,
) => node

/* Empty placeholder - renders an empty text node */
let null: unit => node
let empty: unit => node

/* ============================================================================
 * JSX rendering components
 * ============================================================================ */

module For: {
  type props<'item> = {
    each: MaybeSignal.t<array<'item>>,
    by?: 'item => string,
    render: 'item => node,
  }

  let make: props<'item> => node
}

module KeyedFor: {
  type props<'item> = {
    each: MaybeSignal.t<array<'item>>,
    by: 'item => string,
    render: 'item => node,
  }

  let make: props<'item> => node
}

module Show: {
  type props = {
    when_: MaybeSignal.t<bool>,
    children?: node,
    fallback?: node,
  }

  let make: props => node
}

module Maybe: {
  type props<'value> = {
    value: MaybeSignal.t<option<'value>>,
    render: 'value => node,
    fallback?: node,
  }

  let make: props<'value> => node
}

module Value: {
  type props<'value> = {
    value: MaybeSignal.t<'value>,
    render: 'value => node,
  }

  let make: props<'value> => node
}

module Text: {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make: props<'value, 'children> => node
}

module Int: {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make: props<'value, 'children> => node
}

module Float: {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make: props<'value, 'children> => node
}

module Bool: {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make: props<'value, 'children> => node
}

/* ============================================================================
 * Mounting
 * ============================================================================ */

let mount: (node, Dom.element) => unit
let mountById: (node, string) => unit

/* ============================================================================
 * Emitted by @xote.component
 *
 * These two are public because the PPX generates calls to them in consumer
 * code. They are usable by hand, but the annotation is the intended caller —
 * everything else the PPX relies on stays internal.
 * ============================================================================ */

/* Coerce an arbitrary value in child position into a node: a node passes
   through, a thunk or `Signal.t` becomes reactive, a scalar becomes text, an
   array becomes a fragment, null/undefined render nothing.

   Typed `'a => node`, so it erases type checking in child position: a record or
   variant compiles and renders "[object Object]" (with a development-only
   warning) where unannotated code would have failed to compile. */
let child: 'a => node

/* Wrap a leaf whose signal reads the PPX could not resolve statically. On first
   evaluation the leaf runs inside a throwaway computed; if that computed
   subscribed to anything the read was hidden, and a development-only warning
   names `site`. Behaviour is unchanged either way — with no dependencies this
   is the identity function. */
let probe: (string, unit => 'a) => 'a

/* ============================================================================
 * Deprecated - removed in the next major release
 * ============================================================================ */

@deprecated("Internal helper. Use MaybeSignal.ofUnknown to normalize an untyped value.")
let isReactiveProp: 'value => bool
