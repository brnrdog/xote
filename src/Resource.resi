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

Resources derive from one another: `map`, `map2`, `map3` and `all` combine
the values of resources into a resource, and `chain` fetches with another
resource's value. A derived resource is loading while what it derives from
is, so a view reads one state instead of matching on several.

Created in a component, a resource belongs to it: removing the component drops
whatever is in flight. A resource created under a `View.Suspense` makes that
suspense show its fallback until the first fetch settles; `hold` does the same
for a resource created elsewhere. During a server
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

On a derived resource (`map`, `map2`, `map3`, `all`), it fetches again every
resource it derives from, each once even when it is reached two ways. On a
`chain`, it runs the chain's own fetch again with the source's current value,
and leaves the source alone.

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

On a `chain`, it sets the chain's own value. On a derived resource (`map`,
`map2`, `map3`, `all`) it does nothing: a derived value has nothing of its own
to set, so mutate the resources it derives from.

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

/**
Makes the nearest `View.Suspense` of the calling component wait for a resource
created somewhere else — at module level, in a shared store, or in a component
above the suspense.

The wait follows the same rule as for a resource created below the suspense:
the fallback shows until the resource first has a value or fails, and a later
fetch never brings it back. A resource that already has a value or has failed
holds nothing. While the hold lasts, the resource's fetches also count toward
`View.Suspense.pending`.

Call it in a component body. The hold is released with the component, which
ends any wait it still holds. Outside any `Suspense`, and during a server
render, it does nothing. Call it once per resource to wait for several.

## Examples

```rescript
let currentUser = Resource.make(() => fetchCurrentUser())

module Greeting = {
  @xote.component
  let make = () => {
    Resource.hold(currentUser)
    <h1> {Signal.get(currentUser)->Resource.value->Option.mapOr("", user => user.name)} </h1>
  }
}

<View.Suspense fallback={<p> {"Loading..."} </p>}> <Greeting /> </View.Suspense>
```
*/
let hold: t<'a> => unit

/**
A resource whose value is `fn` of another's.

The derived resource follows its source: `Pending` and `Failed` as the source
is, and `fn` of the value otherwise, `Refreshing` while the source refreshes.
`fn` runs again only when the source's value changes, so a source that only
starts or stops refreshing keeps the derived value as it was. An `fn` that
throws makes the derived resource `Failed`. Keep `fn` pure.

A derived resource has no fetch of its own, so it does not make a
`View.Suspense` wait by being created; its source does that where *it* was
created. To make a suspense wait for it, `hold` it. It is read like any
resource, and stays attached to its source only while something reads it.

## Examples

```rescript
let user = Resource.make(() => Api.getUser("1"))
let name = Resource.map(user, user => user.name)
```
*/
let map: (t<'a>, 'a => 'b) => t<'b>

/**
A resource derived from two others: `fn` of both values once both have one.

It is `Failed` as soon as either has failed (the first, if both have),
otherwise `Pending` while either has no value yet, otherwise `fn` of both
values — `Refreshing` while either refreshes, `Ready` once neither does. The
rest is as for `map`.

## Examples

```rescript
let user = Resource.make(() => Api.getUser("1"))
let settings = Resource.make(() => Api.getSettings())

let greeting = Resource.map2(user, settings, (user, settings) =>
  settings.formal ? "Good day, " ++ user.name : "Hi " ++ user.name
)
```
*/
let map2: (t<'a>, t<'b>, ('a, 'b) => 'c) => t<'c>

/**
`map2` for three resources.

## Examples

```rescript
let page = Resource.map3(user, settings, feed, (user, settings, feed) =>
  {user, settings, feed}
)
```
*/
let map3: (t<'a>, t<'b>, t<'c>, ('a, 'b, 'c) => 'd) => t<'d>

/**
A resource of every value of `resources`, in order, combined as `map2`
combines two: `Failed` as soon as one has failed, `Pending` while one has no
value yet, and the array of values otherwise. The array is the same one until
a value in it changes.

## Examples

```rescript
let users = ["1", "2", "3"]->Array.map(id => Resource.make(() => Api.getUser(id)))
let team = Resource.all(users)
```
*/
let all: array<t<'a>> => t<array<'a>>

/**
A resource whose fetch needs another resource's value.

`fetch` runs with the source's value each time the source settles with one,
and not while the source has none or is only refreshing. Like the fetch of
`make`, the signals it reads before its first `await` are dependencies too,
and only its latest call can settle the chain.

Seen from outside, the chain is loading while either fetch is: `Pending` or
`Failed` while the source is, its own state otherwise, shown as `Refreshing`
while the source refreshes. Created under a `View.Suspense`, it makes that
suspense wait until it first has a value or fails — which, since it cannot
fetch before its source loads, waits for the source as well.

## Examples

```rescript
let user = Resource.make(() => Api.getUser("1"))
let posts = user->Resource.chain(user => Api.getPosts(user.id))
```
*/
let chain: (t<'a>, 'a => promise<'b>) => t<'b>
