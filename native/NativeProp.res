/* Untyped prop values into `View.attrValue`, without stringifying them.

 This is the one place the native layer leans on a representation detail of the
 core. `View.attrValue` declares its payload as `string` because the DOM writes
 strings; at runtime the renderer only ever hands the value straight to
 `setAttrOrProp`, so a style object, a number or a boolean survives the trip
 untouched and arrives at the shadow document as itself.

 Nothing about that is accidental — it is exactly `Obj.magic` doing what
 `AGENTS.md` says it does, contained to four functions and hidden behind typed
 props. It is also the strongest argument for the core change this prototype
 wants: an `attrValue` that carries an opaque payload would make every line
 below unnecessary, and would let the web renderer pass objects to custom
 elements for the same reason. */

let isFunction = (value: 'a): bool => {
  ignore(value)
  %raw(`typeof value === "function"`)
}

/* A value that arrived from JSX: raw, a `Signal.t`, a `unit => 'a` thunk, or a
 `MaybeSignal.t`. `Compute` reads a thunk inside the attribute's own effect, so
 a reactive prop costs no extra computed. */
let ofUnknown = (key: string, value: 'a): (string, View.attrValue) =>
  if isFunction(value) {
    (key, View.Compute(Obj.magic(value)))
  } else {
    switch MaybeSignal.ofUnknown(value) {
    | Static(value) => (key, View.Static(Obj.magic(value)))
    | Reactive(signal) => (key, View.SignalValue(Obj.magic(signal)))
    }
  }

/* Typed constructors for the function-based API. */
let value = (key: string, v: 'a): (string, View.attrValue) => (key, View.Static(Obj.magic(v)))

let signal = (key: string, s: Signal.t<'a>): (string, View.attrValue) => (
  key,
  View.SignalValue(Obj.magic(s)),
)

let compute = (key: string, f: unit => 'a): (string, View.attrValue) => (
  key,
  View.Compute(Obj.magic(f)),
)

let optional = (key: string, v: option<'a>): array<(string, View.attrValue)> =>
  switch v {
  | Some(v) => [value(key, v)]
  | None => []
  }
