/* Untyped prop values into `View.attrValue`, without stringifying them.

 A native prop is a style object, a number, a boolean — things with no HTML
 spelling and no reason to acquire one. `View.Opaque` is the variant for exactly
 that: the renderer assigns it and never inspects it, so none of the
 HTML-attribute rules apply and nothing has to lie about the payload's type.

 This used to be `Obj.magic` into `Static`, which worked because the renderer
 never looked — but it was a cast in every direction, and it made the native
 layer depend on a representation detail of the core rather than on its API. */

let isFunction = (value: 'a): bool => {
  ignore(value)
  %raw(`typeof value === "function"`)
}

/* A value that arrived from JSX: raw, a `Signal.t`, a `unit => 'a` thunk, or a
 `MaybeSignal.t`. `Compute` reads a thunk inside the attribute's own effect, so
 a reactive prop costs no extra computed. */
let ofUnknown = (key: string, value: 'a): (string, View.attrValue) =>
  if isFunction(value) {
    /* A thunk is read inside the attribute's own effect, so a reactive prop
     costs no extra computed. */
    (key, View.OpaqueCompute(Obj.magic(value)))
  } else {
    switch MaybeSignal.ofUnknown(value) {
    | Static(value) => (key, View.Opaque(Obj.magic(value)))
    | Reactive(signal) => (key, View.OpaqueSignal(Obj.magic(signal)))
    }
  }

/* Typed constructors for the function-based API. `Obj.t` is the erased payload
 the variant carries, so these are casts of representation, not of meaning. */
let value = (key: string, v: 'a): (string, View.attrValue) => (key, View.Opaque(Obj.magic(v)))

let signal = (key: string, s: Signal.t<'a>): (string, View.attrValue) => (
  key,
  View.OpaqueSignal(Obj.magic(s)),
)

let compute = (key: string, f: unit => 'a): (string, View.attrValue) => (
  key,
  View.OpaqueCompute(Obj.magic(f)),
)

let optional = (key: string, v: option<'a>): array<(string, View.attrValue)> =>
  switch v {
  | Some(v) => [value(key, v)]
  | None => []
  }
