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

let resolveAttr = (value: attrValue): attrRead =>
  switch value {
  | Static(value) => ReadStatic(Nullable.make(value))
  | OptionalStatic(value) => ReadStatic(Nullable.fromOption(value))
  | SignalValue(signal) => ReadReactive(() => Nullable.make(Signal.get(signal)))
  | OptionalSignalValue(signal) => ReadReactive(() => Nullable.fromOption(Signal.get(signal)))
  | Compute(compute) => ReadReactive(() => Nullable.make(compute()))
  | OptionalCompute(compute) => ReadReactive(() => Nullable.fromOption(compute()))
  }

/* Current value of an attribute without subscribing to it — SSR renders a
 snapshot, so it must not register dependencies. */
let peekAttr = (value: attrValue): Nullable.t<string> =>
  switch resolveAttr(value) {
  | ReadStatic(value) => value
  | ReadReactive(read) => Signal.untrack(read)
  }
