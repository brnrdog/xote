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
