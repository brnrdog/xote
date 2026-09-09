/* Navigation, modelled in the app rather than by the platform.

 A stack of screens in a signal, and the top one is what renders. That is
 enough for an example and it is *not* native navigation: there are no platform
 transitions, no interactive back gesture, and no per-screen lifecycle. Those
 need a host that owns a real navigation controller, which is the open item in
 `ROADMAP.md`.

 What it does show is that a screen change is the one case where re-rendering
 wholesale is exactly right. Everything else in this app updates in place. */

type screen =
  | Issues
  | Detail(TrackerData.issue)

let stack: Signal.t<array<screen>> = Signal.make([Issues])

let push = (screen: screen) => Signal.update(stack, screens => screens->Array.concat([screen]))

let pop = () =>
  Signal.update(stack, screens => {
    let depth = Array.length(screens)
    depth > 1 ? screens->Array.slice(~start=0, ~end=depth - 1) : screens
  })

let current = Computed.make(() => {
  let screens = Signal.get(stack)
  switch screens->Array.get(Array.length(screens) - 1) {
  | Some(screen) => screen
  | None => Issues
  }
})

let canGoBack = Computed.make(() => Array.length(Signal.get(stack)) > 1)
