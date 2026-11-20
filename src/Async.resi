/***
Async values: signals whose value comes from a promise.

`Async.make(fetch)` is a computed whose function returns a promise. What
`fetch` reads before its first `await` is its dependencies, and a change to
one fetches again. Only the latest fetch settles the value.

Until the first fetch settles there is no value, and a read throws
`NotReady`. Read the value where Xote can wait for it — a JSX child or
attribute, a `View.tracked` block, a `Computed`, an `Effect` — and nothing
more is needed: a computed holds `NotReady` and recomputes when the value
arrives, and a reactive leaf or block renders once it is there. Under a
`View.Suspense`, the fallback shows meanwhile.

A read in a component body is not one of those places: a body runs once and
untracked, so it would never learn that the value arrived. Reading a value
that is not ready there is an error that says so.

## Examples

```rescript
let userId = Signal.make("1")
let user = Async.make(() => Api.getUser(Signal.get(userId)))

module UserName = {
  @xote.component
  let make = () => <h2> {Signal.get(user).name} </h2>
}

<View.Suspense fallback={<p> {"Loading..."} </p>}> <UserName /> </View.Suspense>
```
*/

/**
Thrown by a read of an async value that has no value yet, and by a read of
anything computed from one. Xote never shows it as a failure: a reactive leaf
or block that runs into it waits for the value, and an error boundary lets it
pass.
*/
exception NotReady

/**
Creates an async value. `fetch` runs at once, and again when a signal it read
before its first `await` changes. While a later fetch is in flight, a read
returns the previous value. A fetch that rejects is a failure: reads throw it,
so a reactive leaf hands it to the nearest `View.ErrorBoundary`, until a
dependency changes and a fetch succeeds.

During a server render no fetch starts, and the value is never ready: the
server renders what does not depend on it, or a `View.Suspense` fallback.

## Examples

```rescript
let query = Signal.make("xote")
let results = Async.make(() => Api.search(Signal.get(query)))
```
*/
let make: (unit => promise<'a>, ~name: string=?) => Signal.t<'a>

/**
Whether `fn` read anything still loading: a value with no fetch settled yet,
or one fetching again. Reads in `fn` are tracked as usual, so a reactive leaf
or effect that asks is told again when the answer changes. A failure other
than `NotReady` is thrown.

## Examples

```rescript
module Toolbar = {
  @xote.component
  let make = () =>
    <div class={Async.isPending(() => Signal.get(results)) ? "toolbar dimmed" : "toolbar"}>
      {"Search"}
    </div>
}
```
*/
let isPending: (unit => 'a) => bool
