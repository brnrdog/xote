/* Navigation, owned by the platform.

 This used to be a stack of screens in a signal with the top one rendered, which
 is not navigation: no transition, no interactive back gesture, no per-screen
 lifecycle, and the screen underneath rebuilt from nothing every time. It is
 `NativeNav` now — the same array of screens, but rendered as one `screen` per
 entry inside a `stack`, which on iOS is a real `UINavigationController`.

 Two things changed for the app, and both are worth naming.

 The list screen keeps its scroll position and its search text when you come
 back to it, because it is still there — a push adds a screen on top rather
 than replacing what is on screen. That is the whole reason a stack is a stack.

 And a back swipe works, which means the platform can now change the app's
 state. `NativeNav` handles that: the host pops, reports the new depth, and the
 array catches up. Nothing in the screens below knows it happened. */

type screen =
  | Issues
  | Detail(TrackerData.issue)

let nav = NativeNav.make(Issues)

let push = screen => NativeNav.push(nav, screen)

let pop = () => NativeNav.pop(nav)

let canGoBack = nav.canGoBack
