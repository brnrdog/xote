@genType
let makeWithoutEquals = (compute: unit => 'a, ~name: option<string>=?): TypeScriptSignal.t<'a> => {
  Obj.magic(Computed.makeWithoutEquals(compute, ~name?))
}

@genType
let makeWithEquals = (
  compute: unit => 'a,
  equalsFn: ('a, 'a) => bool,
  ~name: option<string>=?,
): TypeScriptSignal.t<'a> => {
  Obj.magic(Computed.makeWithEquals(compute, equalsFn, ~name?))
}

@genType
let make = (
  compute: unit => 'a,
  ~name: option<string>=?,
  ~equals: option<('a, 'a) => bool>=?,
): TypeScriptSignal.t<'a> => {
  Obj.magic(Computed.make(compute, ~name?, ~equals?))
}

@genType
let dispose = (signal: TypeScriptSignal.t<'a>): unit => {
  Computed.dispose(Obj.magic(signal))
}
