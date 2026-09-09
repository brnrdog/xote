# Running it on an iOS simulator

> **Status.** An earlier version of this host built and ran on an iOS simulator.
> Layout has since been rewritten from `UIStackView` onto a real flexbox engine
> (see below), which is a large change to unverified Swift — expect to fix a
> compile error or two on the next build.
>
> The Swift is written without a toolchain to check it against: this
> repository's development happens on Linux, where there is no Swift compiler
> and `download.swift.org` is unreachable. The layout *algorithm* is not
> unverified — it is checked against Chromium in `xote-native/test/` — but the Swift
> spelling of it is.

## The two-minute version, with no Swift at all

The browser preview is a web page, and the simulator has Safari:

```sh
npm run native:preview          # serves on :3100
xcrun simctl boot "iPhone 16"   # or open Xcode → Open Developer Tool → Simulator
xcrun simctl openurl booted http://localhost:3100/preview.html
```

That runs the real app, the real renderer and the real bridge protocol, under
real iOS touch input — but the views on the other side of the bridge are DOM
nodes, not `UIView`s. It tells you the app works. It tells you nothing about the
native host.

## The real thing

### What you need

- Xcode 15 or newer, with an iOS 15+ simulator
- Node 20+ for the bundle
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) —
  only so this repository does not have to carry a generated `.xcodeproj`

### Steps

```sh
npm install
npm run native:bundle            # ReScript → xote-native/bundle/dist/xote-app.js
cd xote-native/hosts/ios && xcodegen generate
open XoteNativeExample.xcodeproj
```

Pick an iPhone simulator and hit run. You get [the tracker](../../example/tracker/):
five thousand issues, a live search, filters, and a detail screen.

**Choosing which example to run.** `XOTE_APP` picks it at build time, and only
the chosen one ends up in the bundle:

```sh
npm run native:bundle                  # tracker (default)
XOTE_APP=counter npm run native:bundle # the smaller counter example
```

Re-running the build is enough — Xcode picks up the new resource on the next
launch, with no need to regenerate the project.

The bundle is a build artifact and is not committed, so `native:bundle` has to
run **before** `xcodegen generate`. It is shared with the Android host and lives
in `xote-native/bundle/dist/`; the resources phase references the file directly, so
re-running the build after generation is enough and Xcode picks it up on the
next launch.

**Without XcodeGen:** make a new iOS App project in Xcode (Swift, Storyboard:
None), delete its `ViewController.swift` and `SceneDelegate.swift`, remove the
`UIApplicationSceneManifest` key from its `Info.plist`, then drag in
`XoteNative/Sources/*.swift`, `App/AppDelegate.swift`, and
`../../bundle/dist/xote-app.js` (as a resource, "Copy items if needed" off).

## How it fits together

```
xote-app.js  ──evaluated in──▶  JSContext        (XoteBridge)
                                    │
                XoteHost.apply(json)│  batches of commands
                                    ▼
                                XoteHost         (the eight opcodes → UIKit)
                                    │
                     xoteDispatchEvent(id, …)    events back
```

Five pieces of Swift:

| File | What it does |
|---|---|
| `XoteBridge.swift` | Owns the `JSContext`, injects `XoteHost.apply`, evaluates the bundle, calls `xoteStart()`, forwards events back |
| `XoteCommand.swift` | Decodes the wire format — a JSON array of arrays, opcode first |
| `XoteHost.swift` | The eight commands against `UIView`s, and one layout pass per batch |
| `XoteLayout.swift` | Flexbox, transliterated from the reference engine |
| `XoteFlatten.swift` | Which nodes get a `UIView`, transliterated from `host/flatten.mjs` |
| `XotePool.swift` | The view pool, transliterated from `host/pool.mjs` |
| `XoteStyle.swift` | A style object read with the types layout and UIKit want |

The app runs on its own serial queue, not the main one. A `Signal.set` and
everything it sets off — the effects, the renderer, the batch — happens there,
and only the finished batch crosses to the main queue to be applied. A slow
update costs a late frame instead of a frozen one. Both queues are serial and
every hop is `async`, so batches arrive in the order they were produced and
events in the order they happened. The `JSContext` is touched only from
`jsQueue`, and the two hops in `XoteBridge` are the whole of that discipline.

Failures are contained rather than propagated, because the thing being
protected is a long-lived process with a screen on it. A handler that throws
does not silence the handlers registered after it; a batch the host cannot
apply is dropped and the next one still gets through; a command this host
cannot read is skipped and reported rather than discarding the batch around it
— the two halves of the bridge are versioned separately, so a bundle newer than
the app is a thing to survive. Everything contained goes to `XoteBridge.onError`,
which an app can point at whatever it shows people.

`../../bundle/bootstrap.mjs` is the app-thread entry point — shared with the
Android host, because nothing in it is platform-specific — bundled to one classic script
because JavaScriptCore has no module loader. It flushes explicitly rather than
on a microtask, so "the batch is on the other side before this call returns" is
a property you can rely on from Swift.

## How layout works, and what is missing

> For the full picture — what it would take to make any of this
> production-ready, in what order — see [`../../ROADMAP.md`](../../ROADMAP.md).

**Layout is a flexbox engine, ported from a tested one.** Every box is a plain
`UIView` with a `frame`; there is no Auto Layout and no `UIStackView`. Flexbox
and Auto Layout are two constraint systems with different answers, and the first
version of this host spent its whole existence asking one to imitate the other.

`XoteLayout.swift` is a transliteration of `xote-native/src/host/layout.mjs`, which is
checked frame-for-frame against Chromium's own flexbox — 1183 boxes across 196
trees, all agreeing. **Keep the two in step**: a change here that is not also a
change there is a change nothing tests.

It covers the subset `NativeStyle` can express: direction including reverse,
`justifyContent`, `alignItems`/`alignSelf`, grow/shrink/basis, min and max,
points and percentages, margin, padding, border width, gaps, `aspectRatio`,
absolute positioning, and measured text. It does not cover `flexWrap` (every
container is one line), baseline alignment, `alignContent`, or percentage
margins and paddings. Reaching one of those is the signal to swap the engine for
Yoga — which is now a contained change, because there is a reference
implementation to check the swap against.

Text is the one thing the engine cannot do itself: a `text` node carries a
measure callback into `NSAttributedString.boundingRect`, so the host answers
"how tall is this at this width" and layout does the rest.

A `scroll` is two boxes — the frame its parent positions, and a content box free
to be longer than it — and the style is split between them.

## Two trees, and why there are two

`XoteHost` keeps a `XoteLayoutNode` for every node the app made and a `UIView`
only for the ones that need one. `XoteFlatten` decides: a `view` that paints
nothing, carries no accessibility or hit-testing prop, and has no listener
needing a surface is *flattened* — it stays in the layout tree and never becomes
a `UIView`. Its children become subviews of the nearest ancestor that did, at
the index they would have occupied, and `applyFrames` adds its offset to theirs
on the way past. On the tracker's list screen that is 34 of 192 views.

Views come from `XoteViewPool` and go back on `destroy`, reset on the way in so
a parked view holds no text, image, delegate or gesture closure belonging to the
screen that put it there. Across a scroll sweep the tracker allocates 296 views
instead of 881.

The parts that are easy to get wrong are the transitions — a box that starts
painting halfway through its life has to take whatever was standing in for it
and move it inside a new view, and one that stops has to put its children back
where it was. Both directions, and the round trip, are in the `flattening` case
of the conformance suite, which compares the **view tree** as well as the frames
precisely because a flattening mistake leaves every frame correct.

**Also missing:** `XOTE_APP` is a list in `bundle/bootstrap.mjs` rather than an entry
point an app declares, text measurement is `UILabel`'s own (fine, but it means
the app thread never learns any size), and images load with no cache.

## Three things that look like layout bugs and are not

All three were found the first time the tracker ran on a simulator, and all
three are host bugs rather than anything the layout engine computed wrong.
Worth knowing, because each one *presents* as "flexbox is broken".

**The app runs in a letterboxed band with black above and below.** A missing
launch screen. Without `UILaunchScreen`, iOS runs an app at a legacy screen size
and scales it, so the window never fills the device. The trap here is that
XcodeGen **writes** `App/Info.plist` from `project.yml` rather than reading the
one in the repository — so a key that is only in the file is a key the build
does not have. It is declared in `info.properties` now.

**Content scrolls up over the header.** `UIScrollView` clips by default and must
keep doing so: its content is larger than its frame by definition, and the parts
scrolled out of view are still drawn — over whatever is above it. The host was
applying `overflow: visible` (the flexbox default, and the right default for a
box) to scroll views as well.

**Text renders on top of other text.** The same bug. A list drawn across the
header looks exactly like two versions of a label at once.

## When it does not work

- **`fatalError: xote-app.js is not in the bundle`** — the resources phase does
  not have it. Run `npm run native:bundle`, then regenerate the project.
- **A blank black screen** — look in the Xcode console for
  `Xote: JavaScript exception`. `XoteBridge` installs a `console` shim, so
  anything the app logs shows up as `Xote JS:`.
- **Everything renders but nothing responds** — a `listen` command reached a
  view that cannot take a gesture recogniser. Check the opcode stream with
  `npm run native:preview`, which prints every batch beside the screen.
- **The layout is wrong** — check the three cases above first. Otherwise compare
  against `npm run native:preview`, which lays the same app out with real
  browser flexbox: if the preview is right and the device is not, the bug is in
  `XoteLayout.swift` or the host, and `XoteConformanceTests` is where to pin it.
