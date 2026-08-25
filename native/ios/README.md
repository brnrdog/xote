# Running it on an iOS simulator

> **Status.** The JavaScript half is tested (`npm run native:ios:test` runs the
> shipped bundle in a realm with no DOM, no `console` and no timers — what
> JavaScriptCore looks like). The Swift half has **never been compiled**: it was
> written on Linux, where there is no Swift toolchain and no Xcode. Expect to
> fix a typo or two on first build, and please push the fix back.

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

Three pieces of Swift, none of them large:

| File | What it does |
|---|---|
| `XoteBridge.swift` | Owns the `JSContext`, injects `XoteHost.apply`, evaluates the bundle, calls `xoteStart()`, forwards events back |
| `XoteCommand.swift` | Decodes the wire format — a JSON array of arrays, opcode first |
| `XoteHost.swift` | The eight commands against `UIView`s |
| `XoteStyle.swift` | A style object read with the types UIKit wants |

Both directions are synchronous and on the main thread. `apply` is called from
inside the JavaScript call that produced the batch, so by the time
`xoteDispatchEvent` returns, the views already reflect the press. That is
deliberate for a prototype — it makes the whole thing easy to step through in a
debugger — and it is the first thing a real host would change.

`bootstrap.mjs` is the app-thread entry point, bundled to one classic script
because JavaScriptCore has no module loader. It flushes explicitly rather than
on a microtask, so "the batch is on the other side before this call returns" is
a property you can rely on from Swift.

## What is approximated, and what is missing

**Layout is `UIStackView`, not Yoga.** Every `view` becomes a stack view:
`flexDirection` is the axis, `gap` is `spacing`, `alignItems` is `alignment`,
`padding` is `directionalLayoutMargins`, `justifyContent: space-between` is
`.equalSpacing`, and `flex` is a low content-hugging priority. That covers the
example screen and will cover most simple ones, but it is an approximation with
real edges:

- `justifyContent: flex-start` — the flexbox default — has no `UIStackView`
  spelling, because a stack with `.fill` distribution must consume its axis. A
  box that needs it appends an invisible trailing view that wants space less
  than anything else (`XoteBox.slack`). It works; it is not what Yoga does.
- `position: absolute`, percentage sizes, `flexWrap`, `flexShrink`,
  `aspectRatio` and per-child `margin` are ignored.
- Nested `flex` ratios between siblings collapse to "flexible or not", since
  hugging priority is not a growth factor.

Replacing this with Yoga is the single highest-value change, and it is why
`native/README.md` lists layout as the largest piece of a real host.

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
