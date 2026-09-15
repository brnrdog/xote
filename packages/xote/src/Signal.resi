/* Reactive state cells.

   `t<'a>` is abstract: values are only ever read through `get`/`peek` and
   written through `set`/`update`, so every mutation goes through the scheduler
   and notifies dependents. */

type t<'a>

/* Create a signal. `~name` is a debugging label; `~equals` replaces the default
 JavaScript strict equality used to decide whether `set` notifies dependents. */
let make: ('a, ~name: string=?, ~equals: ('a, 'a) => bool=?) => t<'a>

/* Read the value and subscribe the current observer to it */
let get: t<'a> => 'a

/* Read the value without subscribing the current observer */
let peek: t<'a> => 'a

/* Write the value, notifying dependents when it differs from the current one */
let set: (t<'a>, 'a) => unit

/* Write a value derived from the current one */
let update: (t<'a>, 'a => 'a) => unit

/* Defer scheduler flushing until `fn` returns, so a burst of writes runs each
 dependent effect at most once */
let batch: (unit => 'a) => 'a

/* Disable dependency capture inside `fn` */
let untrack: (unit => 'a) => 'a
