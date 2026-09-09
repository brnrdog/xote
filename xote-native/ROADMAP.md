# What is left

> The findings behind this list — the architecture, the packaging design for a
> separate `xote-native`, the core changes, and the demo's own good/bad/gaps —
> are in [`REPORT.md`](./REPORT.md). This file is the ordered work.


The prototype renders a real app on a real simulator. That is a much smaller
claim than "production-ready", and the distance between them depends almost
entirely on which of these you mean:

| Bar | What it means | Rough size |
|---|---|---|
| **A — ship one app you control** | You write the screens, you hit the limits, you extend the host when you do | Months, one person |
| **B — other people build real apps on it** | Strangers hit edges you never thought about, on devices you do not own | A year or more, small team |
| **C — a general React Native alternative** | Feature parity, ecosystem, migration paths | Not a solo project. React Native is a decade and a large team |

Everything below is ordered for **bar A**, because bar A is the only one worth
aiming at until the premise is measured (see the last section). Most of the list
is shared with B; the things that are only B are marked.

---

## What has been done since

**Tier 1 is complete**, and the core changes in Tier 2 are in. The short version:

- Layout is a real flexbox engine, checked frame-for-frame against Chromium and
  transliterated to Swift. `UIStackView`, Auto Layout, and every approximation
  built on them are gone.
- There is a host conformance suite: a batch in, a node tree, a set of frames, a
  view tree and the text out, replayed against both the JavaScript hosts and
  UIKit.
- The app runs off the main thread, and failures are contained rather than
  propagated.
- The core changes in `xote` are in — opaque attribute values, and host hooks
  for what a tag means and what a grouping box is.
- Lists render a window rather than a dataset.
- Layout-only boxes no longer become views, and views destroyed by one screen
  are handed to the next.
- The types no longer promise more than the hosts deliver, and a test enforces
  it.

What is left is below.

---

## Tier 1 — the rendering model

**1. Layout. Done.** `xote-native/src/host/layout.mjs` is a flexbox engine checked
frame-for-frame against Chromium — 1183 boxes across 196 trees, all agreeing —
and `XoteLayout.swift` is a transliteration of it. Every box is a plain `UIView`
with a `frame`.

The roadmap said Yoga, and for a shipping host that is still the right answer.
This route was taken because the repository cannot verify Swift at all, so an
unverifiable C++ integration plus an unverifiable bridge was two unknowns
stacked; a JavaScript engine could be checked against the specification by the
specification's own implementation. Swapping in Yoga is now a contained change
with a reference to check it against — and the signal to do it is reaching one
of the deliberate omissions: `flexWrap`, baseline alignment, `alignContent`, or
percentage margins and paddings.

**2. Text measurement. Done.** A `text` node carries a measure callback into
`NSAttributedString.boundingRect`, and layout asks it how tall the text is at a
given width. Line height, letter spacing and truncation modes are expressible
from here and none of them are wired — which is why none of them are in
`NativeStyle` either (Tier 2, item 5). They change how big a string is, so
wiring one means changing the measure callback with it.

**3. View flattening. Done.** A box that only arranges its children keeps its
layout node and loses its view; its children attach to the nearest ancestor that
has one. The policy is `host/flatten.mjs` — only a `view` is ever a candidate,
and only when it paints nothing, carries no accessibility or hit-testing prop,
and has no listener that needs a surface to be delivered from. `layout` is
deliberately not such a listener: a frame comes from the layout tree, which a
flattened node is still in, so a `NativeList` measuring its own viewport costs
no view.

On the tracker's list screen that is **34 of 192 views**, or 42% of the plain
boxes. The saving is real and it is not dramatic, because this app already
writes few wrappers; an app with more would save more.

Flattening may not move anything, and `test/flatten_test.mjs` is that assertion:
the same command stream replayed into a flattening host and a non-flattening one
produces byte-identical frames, node tree and text. The conformance suite gained
a `views` expectation and a `flattening` case that materialises a box, then
dematerialises one, then does it again — the splices that are easy to get wrong
and invisible in a frame.

Not available to the DOM preview host, which is not an oversight: CSS has no way
to express a box with no element, so flattening is only open to a host whose
layout tree and view tree are separate objects.

**4. Threading. Done.** The app runs on its own serial queue; only finished
batches cross to the main queue. A slow update costs a late frame, not a frozen
one.

**5. View recycling. Done.** `destroy` returns a view to a bounded per-kind pool
and `create` takes one back out — the protocol already guarantees the id will
never be referenced again, which is exactly the guarantee a pool needs. Views are
reset on release rather than on acquire, so a parked view never holds a string,
an image, a delegate or a gesture closure belonging to the screen that put it
there.

Driving the tracker through a scroll sweep, a filter toggle and a navigation:
**881 view allocations become 296**, with 66% of acquisitions served from the
pool. The bound is per kind, so a list that destroys five thousand rows does not
hold five thousand views waiting for a sixth thousand that never comes.

**6. Error containment. Done.** A handler that throws does not silence its
siblings, a batch the host cannot apply is dropped without jamming the bridge,
and a command the host cannot read is skipped rather than discarding the batch.

---

## Tier 2 — the core changes in Xote itself

**1. An opaque `attrValue` payload. Done.** `Opaque`, `OpaqueSignal` and
`OpaqueCompute` carry a payload the renderer assigns and never inspects.

**2. A host-neutral grouping node. Done.** `document.createXoteGroup()`. The
`div`-sniffing heuristic — a correctness hazard sitting on an implementation
detail of `SignalFragment` — is gone.

**3. The SVG tag table. Done.** `document.createXoteElement(tag)` lets a host
decide what its own tags mean.

**4. Dirty-flag over-propagation in `rescript-signals`. Not ours.** It is a
dependency. `xote-native/test/signals_pin_test.mjs` pins the behaviour so that the
day it is fixed upstream, a test fails and the workaround in the example can go.

**5. The type surface, enforced. Done.** `NativeStyle` declared `flexWrap`,
`alignContent`, baseline alignment, `lineHeight`, `letterSpacing`, `fontStyle`
and `textTransform`; nothing read any of them. `NativeJSX` declared ten props
and two events no native host applied. All of them are gone, except
`placeholderTextColor` and the `submit`/`focus`/`blur` events, which an app
really does need and which were three lines each of a pattern `changeText`
already proved — those were implemented rather than removed.

`host/capabilities.mjs` is now the list of what the engine and the native hosts
implement, and `test/surface_test.mjs` reads `NativeStyle.res`, `NativeJSX.res`,
`layout.mjs` and the Swift sources as text and asserts the three agree. It is
the only check this repository can run against the Swift at all, and switching
it on immediately turned up two `lineHeight` uses in the tracker that had never
done anything. Growing the surface is now a deliberate act in a fixed order:
implement it, list it, then declare it.

The three layout omissions are the ones worth restating, because removing them
from the type is what turns them into a signal: reaching for `flexWrap`,
`alignContent` or baseline alignment is now a compile error, and that is
precisely the point at which the engine should be swapped for Yoga.

**6. A `RuntimeHost` seam. Started.** The two hooks above are the seam, at the
only two points that needed one. Still open: the process-global `document` means
two Xote apps in one JavaScript realm collide, and whether the remaining
operations are worth routing through a record at all. Benchmark before
committing to that — the web hot path is measured.

---

## Tier 3 — what an app author needs before they can build anything real

Roughly in the order you will hit them.

- ~~**Lists.**~~ **Done for fixed-height rows.** `NativeList` computes the window
  instead of the list: the rows on screen are the only ones that exist, and the
  space above and below is padding on the content box. 10,000 rows cost 54
  views, and scrolling within a row costs nothing at all, because the range is
  held in a signal with a structural comparison. Hosts now raise `scroll` and
  `layout`. **Variable row heights are still open** — they need measured rows and
  a running offset table, and that is a different component.
- **Navigation.** `Xote.Router` is `history`-shaped. Native navigation is a stack
  of screens with platform transitions, back gestures and lifecycle. A different
  abstraction, not a port.
- **Gestures and animation.** Anything driven by touch has to run on the UI
  thread, which means *declaring* animations rather than stepping them from
  JavaScript. This is where React Native needed Reanimated; expect no shortcut.
- **Text input.** Keyboard avoidance, IME and autocorrect, return-key handling,
  focus management, controlled-input echo. `UITextField` with one event is a
  demo, not a text input.
- **Images.** Caching, decode off the main thread, placeholders, resizing, and an
  asset pipeline that understands `@2x`/`@3x`.
- **Safe area, appearance, dynamic type, rotation.** All of these are inputs the
  app has to be able to read reactively. None are wired.
- **Accessibility.** `accessibilityLabel` and `testID` exist. Traits, focus
  order, actions, VoiceOver navigation and reduced-motion do not. For bar B this
  is not optional.
- **Native modules.** ReScript makes this the *best* part of the story —
  externals are already how ReScript talks to a foreign runtime, so a typed
  binding is idiomatic rather than generated. Still needs an async call protocol
  and a story for who writes the platform side.

---

## Tier 4 — platform and tooling

- ~~**Android.**~~ **Written, never run.** `hosts/android/` is a Kotlin host:
  the eight commands against `android.view`, the layout engine transliterated a
  third time, the same flattening policy and view pool, text through
  `StaticLayout`, and `XoteConformanceTest` replaying the shared suite against
  real views.

  It was the test of whether the protocol is host-agnostic, and the answer is
  mostly yes: nothing in `xote-native/src/host/`, `xote-native/src/*.res` or the bundle changed to
  accommodate it, and the capability manifest and protocol handshake passed
  against the Kotlin on the first run. Four things differ and none is visible to
  an app — a box must be a `ViewGroup`, points are not pixels, a `scroll` has to
  scroll itself, and there is no JavaScript engine in the platform. See
  [`hosts/android/README.md`](./hosts/android/README.md).

  It has never been compiled. That is a weaker claim than iOS can make, and the
  conformance suite is what would close it.
- **A real JavaScript engine.** Bytecode precompilation, much better startup and
  memory. JavaScriptCore was the right call for the iOS prototype because it
  ships with iOS; `WebView` is the equivalent shortcut on Android and a worse
  one. Hermes or QuickJS is the answer on both, and the Android host already has
  the seam for it — `XoteJsRuntime` is two methods.
- **Bundler.** Today: Vite to one IIFE, no source maps, no code splitting, no
  asset resolution, and the mounted app is hard-coded in `bootstrap.mjs`. Needs
  at minimum an entry-point API, source maps that survive into the JSC console,
  and lazily-loaded screens.
- **Fast refresh.** Genuinely hard here, and worth saying so: Xote has no
  component boundaries to swap, and signal state has no serialisable identity.
  A realistic first step is reload-preserving-nothing, which is still a large
  improvement over rebuild-and-relaunch.
- **Debugging.** The bridge traffic panel in the web preview is already most of
  a devtool. Pointing it at a device over a socket would be a small change with
  a large payoff — the mutation stream *is* the app's behaviour.
- **Crash reporting and symbolication.** Bar B.

---

## Tier 5 — shipping it as a thing other people install

- **Extract `xote-native` into its own package.** It depends on `xote`; it does
  not belong inside it. No longer blocked and no longer a guess:
  `xote-native/test/package_test.mjs` stages both packages into a temporary
  `node_modules` and compiles a downstream app against them, so the cost is
  known — a `rescript.json` carrying `-open Xote`, a `package.json` with an
  `exports` map, and `host/` living inside `src/` so `@module("./host/…")`
  stays correct. **No source file changes**, and nothing in `xote` has to move:
  the six modules `xote-native` reaches for are all already in the published
  `exports` map. What is left is the move itself.
- ~~**Version the protocol.**~~ **Done.** `PROTOCOL_VERSION` is 1, a host
  declares the range of bundle versions it can apply, and `install()` compares
  them before anything renders. A host *older* than the bundle is a warning —
  it skips opcodes it does not know and reports each one, so the app runs and
  the screen may be missing something. A host that has dropped this protocol
  entirely is a refusal, because every alternative to throwing is a silently
  wrong screen. The rule that makes the first case survivable is written down
  where the opcodes are: **opcodes are append-only**, and changing what one
  means is a different protocol rather than a new version.
- ~~**A host conformance suite.**~~ **Done.** Host-agnostic: a fixed batch, and
  the node tree, frames, text and view tree a correct host ends up with.
  Replayed against the reference host in JavaScript and against UIKit in Xcode.
- **Snapshot tests against the preview.** The DOM preview host is *real*
  flexbox. Rendering the same screen in both and diffing is a layout-regression
  test that needs no device, and it would have caught the label bug.
- **CI on both platforms, templates, a CLI, docs, an upgrade path.**

---

## The order from here

1. **Extract the package.** The protocol is versioned and the seams are in
   place; what is left is the packaging itself — see
   [`REPORT.md` §5.6](./REPORT.md).
2. **Navigation.** The next thing an app cannot be built without.
3. **Text input, safe area, appearance.** Small individually, and between them
   the difference between a demo and a screen.
4. **Run the Android host.** It is written; nothing here can build it. One
   afternoon with an SDK and the conformance suite would settle it.
5. **Gestures and animation.** The hardest remaining design problem.

Flattening and recycling used to sit at position 4 on this list, waiting for a
real screen to measure against. The tracker is that screen, so they are done —
and the measurement says flattening saves less here than it would in an app with
more wrappers, while recycling cuts allocations by two thirds.

---

## The premise, measured

This section used to say the premise had only been demonstrated on a counter,
and that a real screen should be built before investing further. That screen
exists: [`xote-native/example/tracker/`](./example/tracker/) is an issue tracker over
five thousand issues with a live search, filters, a windowed list and a second
screen, and `npm run native:measure` prints what every interaction costs.

**It holds.** Every number tracks what changed on screen, and none of them
tracks the dataset: the screen holds under 300 views, the largest single
operation is a screenful, and changing one issue's status is 8 commands with
nothing created or destroyed. Scrolling within a row is free.

The honest counterweight is in the same table: changing a filter costs ~880
commands, because changing a filter changes which issues are visible and a
screenful of rows really is rebuilt. That is proportional to the screen rather
than to the data behind it, which is the claim — it is not free, which was never
the claim.

So the architecture is worth the rest of the work. What the exercise also
produced was two bugs worth keeping in mind, both written up in the example's
README: a component that creates state has to *be* a component, or its effects
belong to whatever reactive region called it; and `int` multiplication in
ReScript is `Math.imul`, which wraps.

What is worth measuring next is a device, not a headless host — command counts
say nothing about frame time, and the numbers above are the input to that
question rather than the answer.
