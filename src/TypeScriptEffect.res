@genType
type disposer = Effect.disposer = {dispose: unit => unit}

@genType
let runWithDisposer = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer => {
  Effect.runWithDisposer(fn, ~name?)
}

@genType
let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): unit => {
  Effect.run(fn, ~name?)
}
