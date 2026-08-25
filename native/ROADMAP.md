# What is left

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

Items 1–5 of the plan below are largely done, and the sections are marked
accordingly. The short version:

- Layout is a real flexbox engine, checked frame-for-frame against Chromium and
  transliterated to Swift. `UIStackView`, Auto Layout, and every approximation
  built on them are gone.
- There is a host conformance suite: a batch in, a tree and a set of frames out,
  replayed against both the JavaScript hosts and UIKit.
- The app runs off the main thread, and failures are contained rather than
  propagated.
- The core changes in `xote` are in — opaque attribute values, and host hooks
  for what a tag means and what a grouping box is.
- Lists render a window rather than a dataset.

What is left is below.

---

## Tier 1 — the rendering model

**1. Layout. Done.** `native/host/layout.mjs` is a flexbox engine checked
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
from here; none of them are wired yet.

**3. View flattening. Open.** Every node still becomes a `UIView`. React Native
flattens layout-only views away, because a screen with 400 nodes and 150 real
drawing surfaces scrolls very differently from one with 400. The layout tree and
the view tree are already separate objects, which is what this needs — a node
can stay in one and vanish from the other.

**4. Threading. Done.** The app runs on its own serial queue; only finished
batches cross to the main queue. A slow update costs a late frame, not a frozen
one.

**5. View recycling. Open.** `destroy` is the natural place to return a view to
a pool, and with a windowed list there is now something that would use one.

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
dependency. `native/test/signals_pin_test.mjs` pins the behaviour so that the
day it is fixed upstream, a test fails and the workaround in the example can go.

**5. A `RuntimeHost` seam. Started.** The two hooks above are the seam, at the
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

- **Android.** The protocol has three independent implementations already
  (headless, DOM preview, UIKit), which is decent evidence it is genuinely
  host-agnostic. A Kotlin host is the fourth, and it is the test of that claim.
- **Hermes instead of JavaScriptCore.** Bytecode precompilation, much better
  startup and memory. JSC was the right call for a prototype because it ships
  with iOS; it is not the right call for an app.
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
  not belong inside it. Blocked on the Tier 2 seams.
- **Version the protocol.** Three hosts today, two of them in this repository. As
  soon as one lives in someone else's app, "which opcodes does this host speak"
  becomes a real question with a real answer.
- **A host conformance suite.** Host-agnostic: a fixed batch, an expected tree, a
  set of events. Cheap to write, and it is what makes an Android host — or
  someone else's host — a day of work instead of a week of guessing. Do this
  early; it pays for itself immediately.
- **Snapshot tests against the preview.** The DOM preview host is *real*
  flexbox. Rendering the same screen in both and diffing is a layout-regression
  test that needs no device, and it would have caught the label bug.
- **CI on both platforms, templates, a CLI, docs, an upgrade path.**

---

## The order from here

1. **Extract the package and version the protocol.** The seams are in place and
   there are now four implementations of the protocol to keep honest.
2. **Navigation.** The next thing an app cannot be built without.
3. **Text input, safe area, appearance.** Small individually, and between them
   the difference between a demo and a screen.
4. **View flattening and recycling.** Both are performance work, and both want a
   real screen to measure against first.
5. **An Android host.** The conformance suite makes this a transliteration and a
   day of plumbing rather than a week of guessing.
6. **Gestures and animation.** The hardest remaining design problem.

---

## The premise, measured

This section used to say the premise had only been demonstrated on a counter,
and that a real screen should be built before investing further. That screen
exists: [`native/example/tracker/`](./example/tracker/) is an issue tracker over
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
