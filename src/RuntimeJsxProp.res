/* Attribute values arrive untyped from JSX. `MaybeSignal.ofUnknown` owns the
 raw / signal / thunk / `MaybeSignal.t` classification; the only case handled
 here is the thunk, because `attrValue` can carry it lazily as `Compute` and
 avoid allocating a `Computed`. */

let toStringAttr = (key: string, value: 'a): (string, View.attrValue) =>
  if RuntimeValue.isFunction(value) {
    let compute: unit => string = Obj.magic(value)
    View.computedAttr(key, compute)
  } else {
    switch MaybeSignal.ofUnknown(value) {
    | Static(value) => View.attr(key, value)
    | Reactive(signal) => View.signalAttr(key, signal)
    }
  }

let toBoolAttr = (key: string, value: 'a): (string, View.attrValue) =>
  if RuntimeValue.isFunction(value) {
    let compute: unit => bool = Obj.magic(value)
    View.computedAttr(key, () => RuntimeAttr.boolToString(compute()))
  } else {
    switch MaybeSignal.ofUnknown(value)->MaybeSignal.map(RuntimeAttr.boolToString) {
    | Static(value) => View.attr(key, value)
    | Reactive(signal) => View.signalAttr(key, signal)
    }
  }

/* Tags of `View.attrValue`, so an `attrs` escape-hatch entry already built with
 `View.attr` & friends passes straight through instead of being coerced again.
 `Static` is left out on purpose: it is also `MaybeSignal.Static`, and both mean
 the same thing here — a plain value for `key` — so it takes the shared path. */
let attrValueTags = [
  "SignalValue",
  "Compute",
  "OptionalStatic",
  "OptionalSignalValue",
  "OptionalCompute",
]

/* One entry of the untyped `attrs` escape hatch. The value may be a
 `View.attrValue`, or the same shapes every other JSX attribute accepts: a raw
 value, a `Signal.t`, a `unit => 'a` thunk, a `MaybeSignal.t`, or nothing at all
 (`None`/null, which removes the attribute). */
let toAttrEntry = (key: string, value: 'a): (string, View.attrValue) =>
  switch RuntimeValue.getTag(value) {
  | Some(tag) if attrValueTags->Array.includes(tag) => (key, Obj.magic(value))
  | _ => toStringAttr(key, value)
  }

/* Escape-hatch entries are merged after the typed props and the last entry for
 a key wins. Keeping both would render the attribute twice, which is invalid
 HTML on the server and, in the browser, leaves whichever effect ran last in
 charge of a value the other one keeps overwriting. */
let mergeAttrs = (
  base: array<(string, View.attrValue)>,
  extra: array<(string, View.attrValue)>,
): array<(string, View.attrValue)> =>
  if extra->Array.length == 0 {
    base
  } else {
    let combined = base->Array.concat(extra)
    let lastIndex = Dict.make()
    combined->Array.forEachWithIndex(((key, _), index) => lastIndex->Dict.set(key, index))
    combined->Array.filterWithIndex(((key, _), index) => lastIndex->Dict.get(key) == Some(index))
  }
