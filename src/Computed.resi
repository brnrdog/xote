/* Derived signals that recompute when their dependencies change.

   Computeds are lazy with push-based dirty flagging: an upstream change marks
   them dirty immediately, but the value is only recomputed when read. */

/* Create a computed. `~name` is a debugging label; `~equals` decides whether a
 recomputed value propagates to downstream observers. */
let make: (unit => 'a, ~name: string=?, ~equals: ('a, 'a) => bool=?) => Signal.t<'a>

/* Manual disposal. Computeds also auto-dispose when they lose all subscribers. */
let dispose: Signal.t<'a> => unit
