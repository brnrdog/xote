# Running it on Android

> **Status.** This host has **never been compiled or run.** There is no Android
> SDK in this repository and no Kotlin toolchain — development happens on Linux
> with Node and nothing else. Expect to fix compile errors on the first build.
>
> That is a weaker claim than the iOS host can make, which has at least run on a
> simulator. What is *not* unverified is the algorithm: `XoteLayout.kt` is a
> transliteration of `xote-native/src/host/layout.mjs`, which is checked frame-for-frame
> against Chromium, and `XoteConformanceTest` replays the same shared suite the
> other three hosts answer to. Only the Kotlin spelling is unknown.

## The two-minute version, with no Android at all

The browser preview is a web page, and the emulator has a browser:

```sh
npm run native:preview      # serves on :3100
# then open http://10.0.2.2:3100/preview.html in the emulator's browser
```

That runs the real app, the real renderer and the real bridge protocol under
real touch input — but the views on the other side of the bridge are DOM nodes.
It tells you the app works. It tells you nothing about this host.

## The real thing

```sh
npm run native:bundle                 # ReScript → xote-native/bundle/dist/xote-app.js
cd xote-native/hosts/android && ./gradlew installDebug
```

There is no Gradle wrapper committed, because this repository cannot generate
one it has tested. `gradle wrapper` in this directory, or open the folder in
Android Studio and let it do so.

`XOTE_APP` picks the example at build time, and only the chosen one ends up in
the bundle:

```sh
npm run native:bundle                  # tracker (default)
XOTE_APP=counter npm run native:bundle # the smaller counter example
```

The bundle is a build artifact and is not committed. Gradle reads it straight
out of `xote-native/bundle/dist/` — the same file the iOS host uses — rather than
keeping a copy, so there is nothing to forget to update.

### The conformance suite

```sh
./gradlew connectedAndroidTest
```

`XoteConformanceTest` replays `xote-native/conformance/suite.json` against real
`View`s and compares the node tree, every frame, the text, and the view tree.
Gradle points the test assets at `xote-native/conformance/` directly, so the file is
shared with the JavaScript hosts and with iOS and cannot drift.

It is an instrumented test rather than a JVM one because it needs real views,
exactly as the iOS suite needs a simulator. **It is the only thing that can tell
you this Kotlin is right**, and it is worth running before anything else.

## How it fits together

```
xote-app.js  ──evaluated in──▶  a JS engine     (XoteJsRuntime)
                                    │
                XoteHost.apply(json)│  batches of commands
                                    ▼
                                XoteHost        (the eight opcodes → android.view)
                                    │
                     xoteDispatchEvent(id, …)   events back
```

| File | What it does |
|---|---|
| `XoteBridge.kt` | Owns the engine, injects the host object, evaluates the bundle, forwards events back |
| `XoteCommand.kt` | Decodes the wire format — a JSON array of arrays, opcode first |
| `XoteHost.kt` | The eight commands against `View`s, and one layout pass per batch |
| `XoteLayout.kt` | Flexbox, transliterated from the reference engine |
| `XoteFlatten.kt` | Which nodes get a `View`, transliterated from `host/flatten.mjs` |
| `XotePool.kt` | The view pool, transliterated from `host/pool.mjs` |
| `XoteStyle.kt` | A style object read with the types layout and Android want |
| `XoteViews.kt` | `XoteBox`, `XoteScrollView`, and the text-watcher bookkeeping |

## What is different from iOS, and why

Four things, and none of them is a difference the app can see.

**A box has to be a `ViewGroup`.** `UIView` holds subviews and `View` does not,
so every box is an `XoteBox`, a `ViewGroup` whose `onLayout` is deliberately
empty: `XoteHost.applyFrames` has already measured and positioned every child,
and re-arranging them would undo it. This is the Android spelling of "no Auto
Layout anywhere".

**Points are not pixels.** The app writes one set of numbers and they mean the
same thing on both platforms — density-independent points. On iOS that is free,
because a `UIView` frame is already in points. Here `View.layout` takes pixels,
so `applyFrames` multiplies by the display density on the way out and text
measurement divides by it on the way back in. The layout tree stays in points,
which is what keeps the conformance suite comparable across a device and a
simulator with different densities.

**A `scroll` scrolls itself.** `ScrollView` is vertical-only and takes exactly
one child, while a `scroll` here mirrors `UIScrollView`: one view, either axis,
whichever the content overflows. So `XoteScrollView` is a `ViewGroup` that
handles a drag and clamps to the content. **It is the least-tested code in
either host** — no fling, no over-scroll, no scrollbars, no nested-scrolling
participation. It is enough to drive a windowed list and report `scroll`, which
is what the protocol asks of it; a shipping host would want `NestedScrollView`
or `RecyclerView` machinery underneath.

**There is no JavaScript engine in the platform.** JavaScriptCore ships with
iOS; Android has nothing equivalent in its API. So `XoteBridge` talks to an
`XoteJsRuntime` interface — expose one object, evaluate a string, and that is
the whole of it — and ships `WebViewRuntime`, which needs no dependency at all.
Read its caveats before shipping it: no bytecode cache, a `WebView` is a large
object to carry for an engine, and startup pays to parse the bundle every
launch. QuickJS or Hermes is the answer, and swapping one in is this interface
and about twenty lines.

The threading discipline survives the substitution: `evaluateJavascript` is
posted to the main thread but script *execution* is not on it, and
`@JavascriptInterface` methods arrive on a private binder thread — so the app
really does run off the main thread, and only finished batches are posted to it.

## Colour, and one bug worth not writing again

`XoteStyle.colorFromHex` is hand-rolled rather than `Color.parseColor`, for one
reason: `parseColor` reads the leading pair of an eight-digit string as
**alpha**, and the wire format — like CSS, like the iOS host — puts alpha last.
Using the platform parser would make `#00000080` opaque here and half
transparent there, and it would look like a theme bug rather than a parsing one.

## When it does not work

- **A blank black screen** — look in `logcat` for `Xote`. The bridge installs a
  `console` shim, so anything the app logs shows up as `Xote JS`.
- **`FileNotFoundException: xote-app.js`** — the assets directory is empty. Run
  `npm run native:bundle`.
- **Everything renders but nothing responds** — a `listen` reached a view that
  is not clickable. Check the opcode stream with `npm run native:preview`, which
  prints every batch beside the screen.
- **The layout is wrong** — run `connectedAndroidTest` first. If the conformance
  suite passes and the screen is still wrong, the bug is in painting rather than
  in layout, which is the class of bug the suite structurally cannot see: see
  the three iOS cases in [`../ios/README.md`](../ios/README.md), all of which
  were clipping, insets or theme rather than a wrong frame.
