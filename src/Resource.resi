/***
Asynchronous values as signals.

A resource is a signal of its loading `state`, kept up to date by a fetch you
provide. Read it with `Signal.get` like any other signal, in a reactive leaf,
a `View.tracked` block, a computed or an effect, and it updates as the fetch
settles.

The fetch runs in an effect. The signals it reads *before its first `await`*
are its dependencies, and a change to any of them fetches again. Only the
latest fetch can settle the state: an earlier one that finishes late is
ignored. A fetch that throws or rejects settles as `Failed`.

Created in a component, a resource belongs to it: removing the component drops
whatever is in flight. A resource created under a `View.Suspense` makes that
suspense show its fallback until the first fetch settles. During a server
render (`SSR.renderToString`) no fetch starts, and a resource stays `Pending`;
one created outside a render, at module level in a server process, does fetch.

## Examples

```rescript
let userId = Signal.make("1")

let user = Resource.make(async () => {
  let id = Signal.get(userId) // a dependency: read before the first await
  let response = await fetch(`/api/users/${id}`)
  await response->json
})

module UserName = {
  @xote.component
  let make = () =>
    <p>
      {switch Signal.get(user) {
      | Pending => "Loading..."
      | Ready(user) | Refreshing(user) => user.name
      | Failed(_) => "Could not load the user"
      }}
    </p>
}

Signal.set(userId, "2") // fetches again; shows `Refreshing` until it settles
```
*/

/**
Where a resource stands.

- `Pending` — fetching with no value yet: the first fetch, or a fetch again
  after a failure.
- `Ready(value)` — the latest fetch settled with `value`.
- `Refreshing(value)` — fetching again; `value` is what the previous fetch got.
- `Failed(exn)` — the latest fetch threw or rejected with `exn`.

To send a failure to a `View.ErrorBoundary`, throw it where the state is read:
`| Failed(exn) => throw(exn)`.
*/
type state<'a> =
  | Pending
  | Ready('a)
  | Refreshing('a)
  | Failed(exn)

/** A resource: a signal of its state. Read it with `Signal.get` or `Signal.peek`. */
type t<'a> = Signal.t<state<'a>>

/**
Creates a resource and starts its first fetch.

## Examples

```rescript
let query = Signal.make("xote")

let results = Resource.make(() => search(Signal.get(query)))
```
*/
let make: (unit => promise<'a>) => t<'a>

/**
Fetches again with the same dependencies, keeping the current value as
`Refreshing` meanwhile (`Pending` after a failure). Does nothing for a
resource created during a server render.

## Examples

```rescript
let todos = Resource.make(() => loadTodos())

module Reload = {
  @xote.component
  let make = () => <button onClick={_ => Resource.refetch(todos)}> {"Reload"} </button>
}
```
*/
let refetch: t<'a> => unit

/**
Sets the value directly, as `Ready(value)`, and drops any fetch in flight. For
optimistic updates; the next dependency change or `refetch` fetches again.

## Examples

```rescript
let todos = Resource.make(() => loadTodos())

let add = todo => {
  Signal.peek(todos)->Resource.value->Option.forEach(list => Resource.mutate(todos, [...list, todo]))
  saveTodo(todo)->ignore
}
```
*/
let mutate: (t<'a>, 'a) => unit

/**
The value a state carries, if any: `Ready` and `Refreshing` have one.

## Examples

```rescript
Resource.value(Resource.Ready(1)) == Some(1)
Resource.value(Resource.Pending) == None
```
*/
let value: state<'a> => option<'a>

/**
Whether a fetch is in flight: `Pending` or `Refreshing`.

## Examples

```rescript
Resource.isLoading(Resource.Refreshing(1)) == true
Resource.isLoading(Resource.Ready(1)) == false
```
*/
let isLoading: state<'a> => bool
