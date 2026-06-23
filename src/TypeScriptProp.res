@genType
type t<'a>

@genType
let get = (value: t<'a>): 'a => Prop.get(Obj.magic(value))

@genType
let static = (value: 'a): t<'a> => Obj.magic(Prop.static(value))

@genType
let reactive = (signal: TypeScriptSignal.t<'a>): t<'a> =>
  Obj.magic(Prop.reactive(Obj.magic(signal)))

@genType
let signal = reactive
