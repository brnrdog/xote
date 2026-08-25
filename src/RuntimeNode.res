/* Internal: the virtual node representation.

   These types live outside `View` so that the renderer (`RuntimeRender`) can be
   an internal module while `View`, `SSR` and `Hydration` still agree on a single
   node type. `View` re-exports both types with their constructors, so
   `Xote.View.node` and `Xote.View.attrValue` remain the public spelling. */

/* Attribute value source.

 The `Optional*` variants carry an `option<string>`, where `None` means "remove
 this attribute" rather than "write an empty value". Presence-based styling
 (`[data-open]`, `[data-checked]`) needs that distinction: an attribute that is
 always present, even as `""`, always matches. */
type attrValue =
  | Static(string)
  | SignalValue(Signal.t<string>)
  | Compute(unit => string)
  | OptionalStatic(option<string>)
  | OptionalSignalValue(Signal.t<option<string>>)
  | OptionalCompute(unit => option<string>)
  /* A value that is not a string and is not meant to become one: a style
   object for a native host, a number, a record handed to a custom element's
   property. The renderer assigns it and never inspects it, so none of the
   HTML-attribute rules — boolean presence, `"true"`/`"false"` — apply. */
  | Opaque(Obj.t)
  | OpaqueSignal(Signal.t<Obj.t>)
  | OpaqueCompute(unit => Obj.t)

/* Virtual node types */
type rec node =
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

/* An `attrValue` reduced to how it has to be applied: a value that is known up
 front, or a read that must run inside an effect. Both are nullable because a
 missing value removes the attribute. */
type attrRead =
  | ReadStatic(Nullable.t<string>)
  | ReadReactive(unit => Nullable.t<string>)
  | ReadOpaque(Nullable.t<Obj.t>)
  | ReadOpaqueReactive(unit => Nullable.t<Obj.t>)

let resolveAttr = (value: attrValue): attrRead =>
  switch value {
  | Static(value) => ReadStatic(Nullable.make(value))
  | OptionalStatic(value) => ReadStatic(Nullable.fromOption(value))
  | SignalValue(signal) => ReadReactive(() => Nullable.make(Signal.get(signal)))
  | OptionalSignalValue(signal) => ReadReactive(() => Nullable.fromOption(Signal.get(signal)))
  | Compute(compute) => ReadReactive(() => Nullable.make(compute()))
  | OptionalCompute(compute) => ReadReactive(() => Nullable.fromOption(compute()))
  | Opaque(value) => ReadOpaque(Nullable.make(value))
  | OpaqueSignal(signal) => ReadOpaqueReactive(() => Nullable.make(Signal.get(signal)))
  | OpaqueCompute(compute) => ReadOpaqueReactive(() => Nullable.make(compute()))
  }

/* An opaque value has no HTML spelling. A scalar has an obvious one and is
 rendered; anything else is left out of the markup, because guessing at
 `[object Object]` is worse than omitting an attribute the client will set
 anyway. */
let opaqueToMarkup: Nullable.t<Obj.t> => Nullable.t<string> = %raw(`function (value) {
  if (value === null || value === undefined) return null
  const kind = typeof value
  if (kind === "string" || kind === "number" || kind === "boolean") return String(value)
  return null
}`)

/* Current value of an attribute without subscribing to it — SSR renders a
 snapshot, so it must not register dependencies. */
let peekAttr = (value: attrValue): Nullable.t<string> =>
  switch resolveAttr(value) {
  | ReadStatic(value) => value
  | ReadReactive(read) => Signal.untrack(read)
  | ReadOpaque(value) => opaqueToMarkup(value)
  | ReadOpaqueReactive(read) => opaqueToMarkup(Signal.untrack(read))
  }
