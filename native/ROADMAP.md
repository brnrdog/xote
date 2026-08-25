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

## The thing you already hit

Text sizing was not a random rough edge. Two real bugs, both now fixed:

1. **Every non-flex view was pushed to `.defaultLow` (250) hugging priority.** A
   `UILabel` defaults to **251** — one point higher — and that single point is
   how a label says "I am exactly as big as my text". Overriding it made every
   label the most stretchable thing in its row, so labels got handed space they
   should have refused. Non-flex views now keep UIKit's own defaults.
2. **Multi-line labels had no `preferredMaxLayoutWidth`.** A wrapping `UILabel`
   has no intrinsic height until it knows its width, and inside a stack view it
   learns its width only after layout — so the first pass measured one line.
   `XoteLabel` feeds the resolved width back.

Both are worth understanding as a category, not as two bugs: they are what it
costs to express flexbox in a layout system that is not flexbox. Which is item
one below.

---

## Tier 1 — the rendering model

The foundation. Nothing above this matters if this is wrong.

**1. Replace `UIStackView` with Yoga.** The single highest-value change, by a
wide margin. Everything currently approximated becomes exact: `position:
absolute`, percentages, `flexWrap`, `flexShrink`, real per-sibling grow ratios,
`aspectRatio`, per-child `margin`. It also deletes `XoteBox.slack` and the
hugging-priority reasoning above, which exist only to talk UIStackView into
flexbox semantics. Every "minor rendering detail" you will hit from here is the
same root cause, and this is the fix for all of them at once.

**2. Text measurement through Yoga's measure callback.** Once Yoga owns layout,
a text node is a leaf with a measure function into `NSAttributedString` (and
`StaticLayout` on Android). That is also where line height, letter spacing,
truncation modes and nested text runs with mixed styling become expressible —
none of which the current label path can represent.

**3. View flattening.** Every node currently becomes a `UIView`. React Native
flattens layout-only views away, because a screen with 400 nodes and 150 real
drawing surfaces scrolls very differently from one with 400. Xote's projection
already flattens grouping nodes on the JavaScript side; this is the same idea
one level down, and it needs Yoga first (the Yoga tree keeps the node, the view
tree does not).

**4. Threading.** `apply` currently runs synchronously on the main thread from
inside the JavaScript call that produced the batch. That is a deliberate
prototype choice — it makes the whole thing steppable in a debugger — and it
means a slow update blocks the UI. Production is: app thread produces batches,
UI thread applies them and runs one layout pass per batch. The protocol is
already ordered and self-contained, which is what makes that safe.

**5. View recycling.** `destroy` is the natural place to return a view to a
pool. Nothing in the protocol prevents it; nothing currently does it.

**6. Error containment.** A JavaScript exception today logs and leaves a frozen
screen. Real apps need the equivalent of an error boundary — a failed batch that
does not corrupt the view tree, and a way to report it.

---

## Tier 2 — the five core changes in Xote itself

Four were in `README.md` before the iOS host existed. The host raises the
priority of two of them and adds a fifth.

**1. `attrValue` should carry an opaque payload.** Unchanged, and now proven
harmless in practice — style objects cross the bridge and arrive as objects.
Still a cast that should not have to exist.

**2. A host-neutral grouping node.** This is now a **correctness hazard**, not a
tidiness one. The shadow document identifies Xote's reactive-region wrapper by
its tag being `div`. If `SignalFragment` ever renders something else, every
native app silently grows stray boxes in its layout. A prototype can live with
a heuristic on an implementation detail; a released package cannot.

**3. The SVG tag table in `RuntimeDom`.** Unchanged: `text`, `image`, `line`,
`mask`, `filter` and `use` are ordinary native view names being routed through
`createElementNS`. Harmless today because the shadow document ignores the
namespace, still wrong in shared code.

**4. Dirty-flag over-propagation in `rescript-signals`.** A computed's `~equals`
stops the notification but not the flag that already propagated, so a downstream
computed recomputes and notifies anyway. On the web that re-renders a region for
nothing. On a phone it destroys and rebuilds `UIView`s — with Yoga, a layout
pass too. The workaround (materialise the condition into a `Signal`) is a thing
app authors have to know, which is the definition of a leak.

**5. A `RuntimeHost` seam.** Previously "only if a real host proves it is
needed". A real host now exists, and it proved the shim's implicit interface is
exactly the two dozen operations already documented — so the seam can be
designed from evidence rather than guessed. Two things push it over the line:
the shadow document has to own the process-global `document`, so two Xote apps
in one JavaScript realm collide; and the DOM path pays for a shim it does not
need. Benchmark it before committing — the web hot path is measured, and an
indirection per mutation is not free.

---

## Tier 3 — what an app author needs before they can build anything real

Roughly in the order you will hit them.

- **Lists.** `eachWithKey` reconciles the whole list; native lists recycle a
  window of rows. This is the first wall any real app hits, and it needs
  `onScroll` from the host plus a windowing component. Largest item in this tier.
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

## The order I would actually do it in

1. **Yoga + text measurement.** Everything visual is downstream. Until this
   lands, every layout bug report is the same bug.
2. **The host conformance suite.** Cheap, and it makes step 4 and the Android
   host tractable.
3. **Threading and error containment.** Small, and they change the shape of the
   host — better before there is more host.
4. **The Tier 2 changes in `xote` and `rescript-signals`.** Especially the
   grouping node, which is a live correctness hazard.
5. **Lists.** The first wall a real app hits.
6. **Extract the package, version the protocol.**
7. **Navigation, then everything else in Tier 3.**

---

## What to measure before investing further

The premise of the whole thing is that fine-grained reactivity makes the bridge
cheap: no diff, so a signal change costs the mutations it implies and nothing
else. On the example screen that is 91 commands to mount, 1 to tap, 3 to toggle
a row.

That is a counter. **Build one screen at the scale of a real app** — a few
hundred nodes, a scrolling list, a form — and measure the same three numbers,
plus time-to-first-paint and the cost of a scroll frame. If the stream stays
proportional to what actually changed, the architecture is worth the year. If it
does not, the finding is more valuable than any of the work above, and it is a
week to get it.
