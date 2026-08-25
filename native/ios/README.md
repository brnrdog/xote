# Running it on an iOS simulator

> **Status.** An earlier version of this host built and ran on an iOS simulator.
> Layout has since been rewritten from `UIStackView` onto a real flexbox engine
> (see below), which is a large change to unverified Swift — expect to fix a
> compile error or two on the next build.
>
> The Swift is written without a toolchain to check it against: this
> repository's development happens on Linux, where there is no Swift compiler
> and `download.swift.org` is unreachable. The layout *algorithm* is not
> unverified — it is checked against Chromium in `native/test/` — but the Swift
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
npm run native:ios:build         # ReScript → bundle → XoteNative/Resources/xote-app.js
cd native/ios && xcodegen generate
open XoteNativeExample.xcodeproj
```

Pick an iPhone simulator and hit run. You should get the same screen as the
preview: the counter, the todo list, the conditional hint.

The bundle is a build artifact and is not committed, so `native:ios:build` has
to run **before** `xcodegen generate` — the resources phase globs the directory
at generation time. Re-running the build after that is enough; Xcode picks up
the new file on the next launch.

**Without XcodeGen:** make a new iOS App project in Xcode (Swift, Storyboard:
None), delete its `ViewController.swift` and `SceneDelegate.swift`, remove the
`UIApplicationSceneManifest` key from its `Info.plist`, then drag in
`XoteNative/Sources/*.swift`, `App/AppDelegate.swift`, and
`XoteNative/Resources/xote-app.js` (as a resource, "Copy items if needed" off).

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
| `XoteStyle.swift` | A style object read with the types layout and UIKit want |

Both directions are synchronous and on the main thread. `apply` is called from
inside the JavaScript call that produced the batch, so by the time
`xoteDispatchEvent` returns, the views already reflect the press. That is
deliberate for a prototype — it makes the whole thing easy to step through in a
debugger — and it is the first thing a real host would change.

`bootstrap.mjs` is the app-thread entry point, bundled to one classic script
because JavaScriptCore has no module loader. It flushes explicitly rather than
on a microtask, so "the batch is on the other side before this call returns" is
a property you can rely on from Swift.

## How layout works, and what is missing

> For the full picture — what it would take to make any of this
> production-ready, in what order — see [`../ROADMAP.md`](../ROADMAP.md).

**Layout is a flexbox engine, ported from a tested one.** Every box is a plain
`UIView` with a `frame`; there is no Auto Layout and no `UIStackView`. Flexbox
and Auto Layout are two constraint systems with different answers, and the first
version of this host spent its whole existence asking one to imitate the other.

`XoteLayout.swift` is a transliteration of `native/host/layout.mjs`, which is
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

**Also missing:** text measurement is `UILabel`'s own (fine, but it means the
app thread never learns any size), `onLayout` and `onScroll` are not raised,
images load with no cache, there is no view recycling on `destroy`, and the app
that gets mounted is hard-coded to `CounterApp` in `bootstrap.mjs`.

## When it does not work

- **`fatalError: xote-app.js is not in the bundle`** — the resources phase does
  not have it. Run `npm run native:ios:build`, then regenerate the project.
- **A blank black screen** — look in the Xcode console for
  `Xote: JavaScript exception`. `XoteBridge` installs a `console` shim, so
  anything the app logs shows up as `Xote JS:`.
- **Everything renders but nothing responds** — a `listen` command reached a
  view that cannot take a gesture recogniser. Check the opcode stream with
  `npm run native:preview`, which prints every batch beside the screen.
- **The layout is subtly wrong** — expected; see above. Compare against the
  preview, which is real flexbox, to tell an approximation bug from an app bug.
