/* A navigation stack an app can hold in a signal.

 `Native.stack` and `Native.screen` are the primitives; this is the thing to
 reach for. It owns an array of screens, renders one `screen` per entry, and
 handles the case the primitives leave to you — the platform popping first.

 ## Why the entries are keyed

 A push must not disturb the screens underneath it. Rendering the array
 unkeyed would rebuild every screen on every push: the list screen would lose
 its scroll position and its search field on the way *into* a detail screen,
 which is the opposite of what a navigation stack is for. So each entry gets an
 id when it is pushed and `View.eachWithKey` reconciles on that — a push is one
 `screen` created and inserted, and nothing else moves.

 The id is internal on purpose. A screen value is whatever the app wants,
 including two structurally equal values that are two different screens, so
 identity cannot be derived from it.

 ## The platform popping first

 `stackChange` arrives when someone swiped back, carrying the depth the platform
 is now at, and [truncate] is what answers it. The host has already popped by
 then; truncating emits the `REMOVE` and `DESTROY` it is waiting for. An app
 that renders through this module never has to know that happened.

 Because the handler is registered, the host also *enables* the back gesture —
 see `src/host/navigation.mjs`. A stack built by hand with no `stackChange`
 listener is one the platform will not pop, which is the safe default and not a
 very useful one. */

module Style = NativeStyle

/* An entry is a screen plus the identity the reconciler needs. */
type entry<'screen> = {id: int, screen: 'screen}

type t<'screen> = {
  entries: Signal.t<array<entry<'screen>>>,
  /* Not a signal: it is a source of fresh ids, never something to render. */
  mutable nextId: int,
  /* Built once, here, rather than on each call of an accessor — a `Computed`
   created inside a render body would be a new one on every pass. */
  depth: Signal.t<int>,
  canGoBack: Signal.t<bool>,
  current: Signal.t<'screen>,
}

let make = (initial: 'screen): t<'screen> => {
  let entries = Signal.make([{id: 0, screen: initial}])
  {
    entries,
    nextId: 1,
    depth: Computed.make(() => Signal.get(entries)->Array.length),
    canGoBack: Computed.make(() => Signal.get(entries)->Array.length > 1),
    current: Computed.make(() =>
      switch Signal.get(entries)->Array.get(Array.length(Signal.get(entries)) - 1) {
      | Some(entry) => entry.screen
      /* Unreachable: `truncate` never goes below one and `reset` refuses an
       empty stack. Answering with the screen the stack started on is still
       better than raising, because this runs inside a render. */
      | None => initial
      }
    ),
  }
}

let push = (nav: t<'screen>, screen: 'screen) => {
  let id = nav.nextId
  nav.nextId = id + 1
  Signal.update(nav.entries, entries => entries->Array.concat([{id, screen}]))
}

/* Truncate to `depth` screens. The answer to `stackChange`, and the thing
 [pop] and [popToRoot] are written in terms of.

 A stack never goes below one screen: a navigation controller with no root is a
 programming error on iOS and a blank window everywhere else. A depth at or
 above the current one is a no-op rather than an error — it is what a
 `stackChange` for a pop the app already performed looks like, and there is
 nothing wrong with being told something twice. */
let truncate = (nav: t<'screen>, depth: int) =>
  Signal.update(nav.entries, entries => {
    let wanted = depth < 1 ? 1 : depth
    Array.length(entries) <= wanted ? entries : entries->Array.slice(~start=0, ~end=wanted)
  })

let pop = (nav: t<'screen>) => truncate(nav, Array.length(Signal.peek(nav.entries)) - 1)

let popToRoot = (nav: t<'screen>) => truncate(nav, 1)

/* Replace the whole stack — a deep link, a sign-out, a tab change.

 Every screen is new, so nothing is reconciled and nothing is preserved, which
 is what "replace the stack" means. An empty array is refused: see [truncate]. */
let reset = (nav: t<'screen>, screens: array<'screen>) =>
  if Array.length(screens) > 0 {
    let first = nav.nextId
    nav.nextId = first + Array.length(screens)
    Signal.set(
      nav.entries,
      screens->Array.mapWithIndex((screen, index) => {id: first + index, screen}),
    )
  }

/* The stack, rendered.

 `render` returns a screen's *contents* — the `screen` node itself is put there
 by this function. Returning a `<screen>` from it nests one inside another,
 which draws nothing, costs a view, and is on no stack.

 It is called once per entry rather than once per pass: it is inside
 `View.eachWithKey`, so a screen that is already on the stack is left alone. */
let view = (
  nav: t<'screen>,
  ~render: 'screen => View.node,
  ~style: option<Style.t>=?,
  ~attrs: array<(string, View.attrValue)>=[],
  (),
): View.node =>
  Native.stack(
    ~style?,
    ~attrs,
    ~onStackChange=({depth}: NativeEvent.stackChange) => truncate(nav, depth),
    ~children=[
      View.eachWithKey(
        nav.entries,
        entry => Int.toString(entry.id),
        entry => Native.screen(~children=[render(entry.screen)], ()),
      ),
    ],
    (),
  )
