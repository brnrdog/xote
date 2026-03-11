type kind = [#Effect | #Computed(int)] // int = backing signal ID

type t = {
  id: int,
  kind: kind,
  run: unit => unit,
  mutable deps: Set.t<int>,
  mutable level: int,
  mutable dirty: bool,
  name: option<string>,
}

let make = (id: int, kind: kind, run: unit => unit, ~name: option<string>=?): t => {
  id,
  kind,
  run,
  deps: Set.make(),
  dirty: true,
  level: 0,
  name,
}
