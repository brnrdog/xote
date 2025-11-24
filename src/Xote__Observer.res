module IntSet = Belt.Set.Int
module IntMap = Belt.Map.Int

type kind = [#Effect | #Computed(int)] /* holds the signal id it writes to */

type t = {
  id: int,
  kind: kind,
  run: unit => unit,
  /* current dependency set (signal ids) */
  mutable deps: IntSet.t,
  /* topological level for scheduling order */
  mutable level: int,
}
