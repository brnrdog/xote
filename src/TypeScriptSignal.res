@genType
type t<'a>

@genType
let defaultEquals = Signal.defaultEquals

@genType
let neverEquals = Signal.neverEquals

@genType
let make = (initialValue: 'a, ~name: option<string>=?, ~equals: option<('a, 'a) => bool>=?): t<
  'a,
> => {
  Obj.magic(Signal.make(initialValue, ~name?, ~equals?))
}

@genType
let makeForComputed = (initialValue: 'a, ~name: option<string>=?): t<'a> => {
  Obj.magic(Signal.makeForComputed(initialValue, ~name?))
}

@genType
let get = (signal: t<'a>): 'a => Signal.get(Obj.magic(signal))

@genType
let peek = (signal: t<'a>): 'a => Signal.peek(Obj.magic(signal))

@genType
let set = (signal: t<'a>, newValue: 'a): unit => {
  Signal.set(Obj.magic(signal), newValue)
}

@genType
let update = (signal: t<'a>, fn: 'a => 'a): unit => {
  Signal.update(Obj.magic(signal), fn)
}

@genType
let batch = Signal.batch

@genType
let untrack = Signal.untrack
