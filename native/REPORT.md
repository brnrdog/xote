# Rendering Xote to native views

**What the experiment found, and what a `xote-native` package would have to be.**

This is the write-up of an exploration carried out on the branch
`claude/xote-native-mobile-apps-4dgl7n`: twelve commits that take Xote from a
web-only renderer to a ReScript app running on an iOS simulator, and the
measurements, tests and mistakes that came out of doing it.

It answers three questions, in this order:

1. **Can Xote render to native views at all, and is the architecture the right
   one?** — §1–§3. Yes, and the reason is more interesting than the result.
2. **What would `xote-native` be, as a package built on Xote's primitives and
   shipped separately from the web library?** — §4–§6. This is the design work
   that has to precede the extraction; the extraction itself is not done.
3. **What did building a real app on it actually teach?** — §7–§9. The good, the
   bad, the gaps, and the five bugs worth remembering.

The neighbouring documents are narrower on purpose and are not repeated here:
[`README.md`](./README.md) is the architecture, [`ROADMAP.md`](./ROADMAP.md) is
the ordered list of remaining work, [`ios/README.md`](./ios/README.md) is how to
run it on a simulator, and
[`example/tracker/README.md`](./example/tracker/README.md) is the demo's own
notes.

---

## 1. Where this got to

A ReScript app written against Xote — the same `View`, the same signals, the
same JSX transform, the same renderer — mounts and runs on an iOS simulator,
laying out through a flexbox engine and drawing into `UIView`s, with no
reconciler and no diff anywhere in the pipeline.

| | |
|---|---|
| Changes to `src/` | **105 insertions, 6 deletions, 6 files.** Nothing removed, nothing renamed, no export surface change |
| The bridge | **8 opcodes**, one flat array each |
| Host implementations | **4** — headless reference, DOM preview, UIKit, and the layout-only reference |
| ReScript surface added | 590 lines across 7 modules (`native/*.res`) |
| JavaScript host runtime | 2,442 lines (`native/host/*.mjs`) |
| Swift | 2,154 lines (`native/ios/`), **never compiled in this repository** |
| Tests | 2,353 lines; 1,183 layout boxes checked against Chromium, 113 conformance frames, 173 core tests |
| Demo | An issue tracker over 5,000 issues, 826 lines of app code |

Three things are worth stating plainly before anything else.

**The premise held under measurement.** §2.

**The core barely had to move.** Six files, a hundred lines, and the same code
paths the web uses. Whatever else is true, native support is not a fork of the
renderer.

**The Swift has never been compiled here.** This repository develops on Linux;
there is no Swift toolchain and `download.swift.org` is unreachable. An earlier
version of the host built and ran on a simulator and the user confirmed it; the
layout engine has since been rewritten in JavaScript, checked against Chromium,
and *transliterated* to Swift — so the algorithm is verified and the spelling is
not. Every claim below about iOS should be read with that qualifier attached.

---

## 2. The premise, measured

The argument for doing this at all is architectural. React Native's bridge has
the shape it does because React's model demands it: React re-renders component
subtrees and diffs the output, so something must own that diff, batch it, and
ship it across a thread boundary. The reconciler is not an implementation detail
of React Native — it is the reason its bridge exists in that form.

Xote has no re-render. A `Signal.set` runs its dependents synchronously and each
dependent performs exactly the mutation its own value implies: one text node's
contents, one attribute, one keyed row's position. **A renderer built on
fine-grained reactivity emits the native mutation stream directly.** There is
nothing to diff because nothing was ever recomputed wholesale.

That is a nice claim and it needed a number. `npm run native:measure` runs the
tracker — 5,000 issues, a 720pt viewport — against a headless host and counts
what crosses:

```
                                     commands   views
  mount the whole screen                  335     118
  ...then learn the viewport              459     283
  type a query matching many              336     283
  type a query matching few               931     265
  type a query matching nothing           269      31
  clear the query                         265     118
  toggle a filter chip                    884     271
  clear the filter                        904     283
  scroll within one row                     0     283
  scroll across one row                    75     289
  scroll to the middle of the list       1000     289
  scroll back to the top                  984     283
  open an issue                           423      53
  change an issue's status                  8      53
  go back                                 383     118
```

**Every number tracks what changed on screen. None tracks the dataset.** Five
thousand issues never cost five thousand of anything; the screen holds under
300 views and the largest single operation is a screenful.

- **`change an issue's status`: 8 commands.** One signal is written. Three
  buttons restyle, a status dot changes colour, a label changes text — and
  nothing is created, destroyed or reconciled. That is the entire argument in
  one gesture, and it is the row that would be several hundred commands under a
  diffing renderer.
- **`scroll within one row`: 0 commands.** A drag raises a scroll event every
  frame. The visible range lives in a `Signal.t<(int, int)>` with a structural
  comparator, and `Signal.set` does not notify when the value is unchanged, so
  the frames in between cost literally nothing.
- **`toggle a filter chip`: 884 commands.** The honest counterweight. Changing a
  filter changes which issues are visible, so a screenful of rows — about eleven
  nodes each — really is rebuilt. It is proportional to the screen rather than to
  the data behind it, which is the claim. It is not free, which was never the
  claim.

The conclusion is that the architecture earns the rest of the work. It is not
that the bridge is free; it is that its cost is bounded by the screen.

**What this does not measure:** frame time. Command counts say nothing about how
long UIKit takes to apply them, and the numbers above are the *input* to that
question, not the answer.

---

## 3. What the architecture turned out to be

### 3.1 A shim, not a seam

The obvious design is a `RuntimeHost` record — create, insert, remove, setProp —
that `RuntimeRender` calls, with the DOM as one implementation and a native host
as another. That was not what got built, and the reason is worth recording.

`RuntimeRender` and `RuntimeDom` between them touch about two dozen DOM
operations, and that list is the *whole* coupling:

| Kind | What the renderer uses |
|---|---|
| Create | `createElement`, `createElementNS`, `createTextNode`, `createComment`, `createDocumentFragment`, `getElementById` |
| Tree | `appendChild`, `insertBefore`, `removeChild` / `remove` |
| Walk | `parentNode`, `firstChild`, `nextSibling`, `childNodes`, `nodeType` |
| Write | `setAttribute`, `removeAttribute`, `textContent`, `innerHTML = ""`, `value`, `checked`, `disabled` |
| Events | `addEventListener` |

`host/shadow.mjs` implements exactly that list over a plain JavaScript tree and
projects every mutation onto a command. The renderer is untouched and does not
know it is being watched.

The trade is explicit: the shim keeps the web hot path **byte-for-byte
unchanged** — `RuntimeRender.res` is full of measured optimizations and there is
a benchmark suite guarding them — at the cost of a JavaScript object graph
shadowing the native tree. A seam is cleaner and opens the door to other
backends (a canvas, a terminal, a test double) at the cost of an indirection on
every mutation in the measured path.

The right order is still shim first. What the shim produced is a precise,
executable specification of what the seam's interface would have to be, written
by a working host rather than by guesswork. That specification is now available
and the decision can be made on evidence and a benchmark.

### 3.2 Eight commands

```
create(id, type)              createText(id, text)
setProp(id, key, value)       setText(id, text)
insert(parentId, id, index)   remove(parentId, id)
destroy(id)                   listen(id, event)
```

Ids are integers; 0 is never used, so it doubles as "no node". Values are
whatever structured-cloneable thing the app passed — **a style crosses as an
object, not as a parsed string**, which is the single most important property of
the wire format and the reason §6 exists.

Two design decisions in here paid for themselves:

**`remove` and `destroy` are separate.** The keyed reconciler moves a row by
detaching and re-inserting it in the same batch. A host that released the view
on detach would throw it away in between. `destroy` is emitted at flush time for
whatever is still parentless, so a move costs nothing at all.

**`insert` carries an index, not a before-sibling.** Because of *group*
flattening (§3.3) the shadow position and the native position are different
numbers, and only the shadow document knows both. Handing the host an index
means the host never has to reason about nodes it cannot see — and it is what
lets the host do its own, separate flattening (§3.5) without the two colliding.

### 3.3 Two node kinds never reach the host

- **Comments.** The keyed-list reconciler brackets its rows with comment
  anchors. They exist only in the shadow tree.
- **Grouping boxes.** Every reactive region renders its children into a
  container that the web erases at layout time (`display: contents`). Native
  layout has no equivalent, and a stray box in a flex column is a visible bug —
  so the projection splices a group's children into its nearest rendered
  ancestor.

The end-to-end test asserts that no group and no comment ever crosses.

### 3.4 Threading and failure

The app runs on its own serial queue; only finished batches hop to the main
queue to be applied, and events hop back. Both queues are serial and every hop
is asynchronous, so batches arrive in the order they were produced and events in
the order they happened. A slow update costs a late frame instead of a frozen
one.

Failures are contained rather than propagated, because the thing being protected
is a long-lived process with a screen on it: a handler that throws does not
silence the handlers registered after it, a batch the host cannot apply is
dropped without jamming the bridge, and a command the host cannot *read* is
skipped and reported rather than discarding the batch around it. That last one
is forward-compatibility by construction — the two halves of the bridge are
versioned separately, so a bundle newer than the app around it is a thing to
survive rather than a crash.

### 3.5 Two flattenings, at two different layers

The word does two jobs here and they are worth separating, because they happen
on opposite sides of the bridge and neither knows about the other.

**Group flattening** (§3.3) is on the app side. A reactive region renders into a
grouping box that the web erases at layout time and that native has no
equivalent for, so the shadow document splices its children into the nearest
node that *is* projected, and the box never crosses.

**View flattening** is on the host side, and was the open Tier 1 item. A `view`
that paints nothing, carries no accessibility or hit-testing prop and has no
listener needing a surface keeps its layout node and gets no `UIView`; its
children become subviews of the nearest ancestor that has one. `host/flatten.mjs`
is the policy and `XoteFlatten.swift` is its transliteration.

They compose because the protocol carries an *index* rather than a sibling: the
app side has already decided what crosses, and the host side then decides what
of that gets a drawing surface, without either needing to see the other's tree.

Frames come from the layout tree, so host flattening cannot move anything. The
conformance suite compares the frames and the view tree separately, and
`test/flatten_test.mjs` replays one command stream into a flattening host and a
non-flattening one and asserts the frames come out identical. On the tracker's
list screen it removes 34 of 192 views — 42% of the plain boxes. That is a real
saving and not a dramatic one, because this app writes few wrappers; an app that
writes more would save more.

Views are pooled on the same seam: `destroy` returns one, `create` takes one
out, and the protocol's guarantee that a destroyed id is never referenced again
is exactly the guarantee a pool needs. Across a scroll sweep, a filter toggle and
a navigation, the tracker allocates 296 views instead of 881.

Neither is available to the DOM preview host, which is not an oversight: CSS has
no way to express a box with no element, so both are open only to a host whose
layout tree and view tree are separate objects.

### 3.6 Layout is the largest single piece

`host/layout.mjs` is a flexbox engine — 622 lines — checked frame-for-frame
against Chromium's own implementation: **1,183 boxes across 196 trees, all
agreeing.** `XoteLayout.swift` is a transliteration of it.

This route was taken for a specific reason. The repository cannot verify Swift
at all, so embedding Yoga would have stacked an unverifiable C++ integration on
top of an unverifiable bridge. A JavaScript engine could be checked against the
specification *by the specification's own implementation*, and then
transliterated — leaving exactly one unknown instead of two.

Getting there took thirteen rounds of disagreement with the oracle, each one a
real bug in a plausible-looking implementation. A representative few, because
they are the reason "we implemented flexbox" should never be said casually:

- the flex base size and the hypothetical main size are different quantities;
- a definite size is not the same thing as an available size;
- `auto` width is fit-content but `auto` height is not;
- `flex-basis: 0` still occupies its own padding;
- reverse is a mirror with *physical* margins, not a re-ordering;
- with negative free space `space-between` degrades to flex-start but
  `space-around` and `space-evenly` degrade to safe centre;
- `flex: 1` means `flex-basis: 0%`, and a percentage of an indefinite size is
  `auto` — except along a row.

For a shipping host Yoga is still the right answer. Swapping it in is now a
*contained* change, because there is a reference implementation and a suite to
check the swap against. The signal to do it is reaching one of the deliberate
omissions: `flexWrap`, baseline alignment, `alignContent`, or percentage margins
and paddings.

---

## 4. Building `xote-native` on Xote's primitives

### 4.1 What it actually needs from `xote`

This is the load-bearing finding of the whole exercise. Everything in `native/`
is built from Xote's **public** API — the modules listed in `rescript.json`
`public` and guaranteed by their `.resi` files. Not one line reaches for a
`Runtime*` module:

```
$ grep -rn "Runtime" native --include=*.res --include=*.resi
(no matches)
```

The complete list of what it imports:

| From | Used | For |
|---|---|---|
| `View` | `node`, `attrValue`, `element`, `text`, `signalText`, `empty`, `fragment`, `Fragment`, `Element`, `Keyed`, `LazyComponent`, `eachWithKey`, `tracked`, `mount`, `Opaque`, `OpaqueSignal`, `OpaqueCompute` | The whole node vocabulary and the opaque prop payload |
| `XoteJSX` | `jsx`, `jsxs`, `jsxKeyed`, `jsxsKeyed`, `jsxFragment`, `fragmentProps`, `array`, `null` | Re-exported unchanged, so the component transform, keys and fragments are Xote's |
| `Signal` | `t`, `make`, `get`, `set`, `peek`, `update` | State |
| `Computed` | `make` | Derived values, including the list window |
| `Effect` | `run` | Attribute and text bindings |
| `MaybeSignal` | `t`, `ofUnknown` | Sorting out what a polymorphic JSX prop actually received |

Every one of those is in a `.resi` (or, for `XoteJSX`, has no interface file and
is fully public) and every one is already in `package.json` `exports` under both
its friendly name and its `./src/*.res.mjs` path. **A separate ReScript package
depending on `xote` can import all of it today, with no change to `xote`'s
export surface.**

That is what makes the extraction a packaging exercise rather than a
re-architecture. `xote-native` is not privileged code living inside the library;
it is an ordinary consumer of the library that happens to have been developed in
the same tree.

### 4.2 What it adds

Seven ReScript modules, 590 lines:

| Module | What it is |
|---|---|
| `NativeStyle` | A record of all-optional flexbox and paint fields. `pt`/`pct`/`auto` for dimensions, `merge` for composition, `make` as an identity that gives a record literal something to be inferred against at a polymorphic prop position |
| `NativeProp` | Untyped JSX values into `View.attrValue` **without stringifying** — the reason `Opaque*` had to exist |
| `NativeJSX` | The JSX module: `view`, `text`, `image`, `scroll`, `input`, `pressable`, plus pass-through for any tag a host adds. Re-exports Xote's transform verbatim |
| `NativeEvent` | Typed payloads for `press`, `text`, `focus`, `scroll`, `layout` |
| `Native` | The same primitives without JSX |
| `NativeList` | A list that renders a window instead of a dataset |
| `NativeApp` | `mount`, and an explicit `flush` |

Plus the JavaScript host runtime (1,805 lines): the shadow document, the
protocol, the flush scheduler, the flexbox engine, and three hosts.

### 4.3 Where the reactivity model does the work — and where it fights back

Three of Xote's primitives turned out to be doing far more than expected on
native, and it is worth being explicit about which, because they are the ones a
`xote-native` API has to keep honest.

**`View.LazyComponent` is load-bearing, not an optimization.** `XoteJSX.jsx`
wraps a component in a `LazyComponent`, whose body runs *untracked* in its own
scope. That is the only thing standing between "a component creates a signal"
and "that signal's reads belong to whatever reactive region called the
component". The consequence is a rule with teeth: **anything that creates state
must be a component, not a function** — see §7.5, where the same bug appeared
twice with dramatically different symptoms.

**`Signal.set` not notifying on an equal value is what makes scrolling free.**
The windowed list holds its visible range in a `Signal.t<(int, int)>` with a
structural comparator. Sixty scroll events a second land on it and the vast
majority set the same range, so they cost nothing. This is not an optimization
layered on top; it is the default behaviour of the primitive, used deliberately.

**`Computed`'s `~equals` does not stop dirty-flag propagation, and that costs
more here than on the web.** A computed with `~equals` suppresses the
*notification* when its value is unchanged, but the dirty flag has already
propagated, so an intermediate computed downstream still recomputes and still
notifies. On the web that re-renders a region for nothing. On a phone it tears
down and rebuilds real views. The demo works around it by materialising the
condition into a `Signal` through an `Effect`; the right fix is upstream in
`rescript-signals`, and `test/signals_pin_test.mjs` pins the current behaviour so
that the day it is fixed, a test fails and the workaround can go.

---

## 5. Packaging it as its own thing

### 5.1 The shape

`xote-native` targets **iOS and Android**, which decides the shape more than
anything else does: a platform host cannot live inside it. What is portable —
the ReScript surface, the shadow document, the protocol, the flexbox engine, the
flattening policy, the view pool, the conformance suite — is one JavaScript
package. Each platform host is its own artifact in its own toolchain, and the
conformance suite is the contract between them.

```
xote-native/                          xote/  (unchanged, web)
├── package.json      depends on ──▶ package.json
├── rescript.json     depends on ──▶ rescript.json  (name: xote, namespace: Xote)
│     name: xote-native
│     namespace: true  → XoteNative
│     compiler-flags: ["-open Xote"]
├── src/*.res                NativeStyle, NativeProp, NativeJSX,
│                            NativeEvent, Native, NativeList, NativeApp
├── src/host/*.mjs           shadow document, protocol, layout, flatten,
│                            pool, capabilities, the JavaScript hosts
├── bundle/                  the app-thread entry point and the bundler —
│                            one bundle, byte-for-byte, for both platforms
├── conformance/             the suite every host must satisfy
└── test/

xote-native-ios/       Swift package   ─┐  each consumes the bundle and the
xote-native-android/   Gradle module  ─┘  conformance suite; neither is a
                                          dependency of the other
```

The alternative — one package with `ios/` and `android/` inside it — makes an
npm package the distribution channel for a Swift package and a Gradle module,
which is not what either ecosystem does and would make the JavaScript package
unpublishable without them.

Today those modules compile as `NativeJSX$Xote` and import `../src/View.res.mjs`
by relative path, because they live inside the `xote` ReScript package as a dev
source directory. After extraction they compile as `NativeJSX$XoteNative` and
import `xote/src/View.res.mjs` by bare specifier — which is exactly what the
`exports` entries in `xote`'s `package.json` already serve.

### 5.2 The mechanics

**`xote-native/rescript.json`** — this is the file the test actually builds
with, not a sketch:

```json
{
  "name": "xote-native",
  "namespace": true,
  "sources": [{ "dir": "src", "subdirs": false }],
  "package-specs": { "module": "esmodule", "in-source": true },
  "suffix": ".res.mjs",
  "dependencies": ["rescript-signals", "xote"],
  "compiler-flags": ["-open Xote"]
}
```

The `package-specs` and `suffix` should match `xote`'s exactly. Emitted import
paths across a package boundary are built from these, and there is no reason to
find out the hard way which mismatches ReScript tolerates.

**`xote-native/package.json`** carries `xote` as a peer dependency (one copy of
the reactivity graph, always), `files` covering `src/**/*.res`, the compiled
`*.res.mjs`, `host/`, and `rescript.json`, and an `exports` map that mirrors
`xote`'s convention — both the friendly names and the `./src/*.res.mjs` paths, so
a downstream ReScript package resolves.

**A consuming app** then looks like:

```json
{
  "dependencies": ["rescript-signals", "xote", "xote-native"],
  "jsx": { "version": 4, "module": "NativeJSX" },
  "compiler-flags": ["-open Xote", "-open XoteNative"]
}
```

or, for a project with both web pages and native screens in one tree, keeps
`XoteJSX` as the project default and switches per file — which already works
today and is the single nicest ergonomic property of the whole design:

```rescript
@@jsxConfig({version: 4, module_: "NativeJSX"})
```

**This is no longer a proposal.** `native/test/package_test.mjs` stages `xote`
and a synthetic `xote-native` into a temporary `node_modules`, compiles the
fixture app in `native/test/__fixtures__/package/` against both, and asserts
what comes out. It runs in under a second, on Linux, with no device. What it
establishes:

- A downstream app **does** compile against the two packages, JSX module switch
  and all.
- The emitted imports **are** bare specifiers — `xote/src/View.res.mjs`,
  `xote-native/src/NativeJSX.res.mjs` — and the test walks every one of them,
  asserting the subpath is served by `xote`'s published `exports` map. Six
  modules are reached: `View`, `Signal`, `Computed`, `Effect`, `XoteJSX`,
  `MaybeSignal`. All six are already exported. **Nothing in `xote` has to
  change.**
- The namespace really does move: `NativeJSX$Xote` becomes
  `NativeJSX$XoteNative`, and every import in the app follows.

And two things it found that the design above had wrong or unsaid:

**`xote-native` needs `-open Xote`.** Every one of the seven modules refers to
`View`, `Signal`, `Computed`, `Effect`, `XoteJSX` and `MaybeSignal`
unqualified, because inside `xote` the namespace puts them directly in scope.
From its own package they are `Xote.View`, and the build fails on the first line
of `NativeProp`. `"compiler-flags": ["-open Xote"]` fixes it with **no source
changes** — the same arrangement `tests/consumer` already uses. The alternative,
qualifying several hundred references, buys nothing.

**`host/` has to travel inside the source directory.** `NativeApp.res` reaches
the runtime through `@module("./host/runtime.mjs")`, a path relative to the
emitted `.res.mjs`. Stage the package as `src/*.res` plus `src/host/*.mjs` and
that external is already correct; put `host/` at the package root instead and
every one of those externals needs an extra `../`. A layout decision that looks
cosmetic and is not.

One pleasant thing fell out: `NativeStyle` does not appear in the emitted code
at all. `make` and `pt` are `%identity`, so a style is an object literal at the
call site and the module vanishes at compile time — a style costs nothing at
runtime and crosses the bridge as the object the app wrote. The test asserts
that too, so it stays true.

### 5.3 What moves, what stays, and what is genuinely shared

| | |
|---|---|
| **Moves** to `xote-native` | `native/*.res`, `native/host/`, `native/conformance/`, `native/test/`, `native/example/`, and the five native npm scripts |
| **Stays** in `xote` | The two host hooks in `RuntimeDom`, the three `Opaque*` constructors in `RuntimeNode`/`View`, and `tests/OpaqueAttrs_test.mjs` — all of which are web-renderer features that native happens to be the first caller of (§6) |
| **Moves out separately** | `native/hosts/ios/` and `native/hosts/android/` each want to be their own artifact — a Swift package and a Gradle module, not directories in a JavaScript one. They are `xote-native`'s reference hosts, not part of it. `native/` is already laid out that way |
| **Genuinely shared, and a standing cost** | Three pairs are now the same thing written twice — `host/layout.mjs`/`XoteLayout.swift`, `host/flatten.mjs`/`XoteFlatten.swift`, `host/pool.mjs`/`XotePool.swift`. A change to one that is not a change to the other is a change nothing tests. `conformance/suite.json` is the artifact that makes that survivable, and it is why the suite compares the view tree and not only the frames |

### 5.4 Versioning the protocol

Three hosts exist today and two of them are in this repository, so "which
opcodes does this host speak" has never been a real question. It becomes one the
moment a host lives in someone else's app — a JavaScript bundle updates
independently of the binary around it, which is the entire point of shipping
JavaScript.

The forward-compatible half was already built: `XoteCommand.decodeBatch` checks
arity, skips an opcode it does not recognise, and reports it, rather than
discarding the batch around it. What was missing was a number. **That is now
done**, and the shape it took is worth recording because the interesting part is
which mismatch is fatal:

- `protocol.mjs` exports `PROTOCOL_VERSION`, at `1`.
- A host declares `{min, max}` — the range of bundle versions it can apply. A
  host that declares nothing is assumed to speak 1, which is what every host
  written before this did.
- `install()` performs the handshake before anything renders. A host **older**
  than the bundle is a warning through `onError`: it skips what it does not know
  and reports each one, so the app runs and the screen may be missing something.
  Refusing there would turn a partly-drawn screen into no screen at all. A host
  that has **dropped** this protocol is a refusal, because every alternative to
  throwing is a silently wrong screen.
- **Opcodes are append-only.** A new capability is a new opcode and a bump.
  Changing what an existing opcode *means*, or the arity or order of its
  arguments, is not a bump — it is a different protocol, because an old host
  will apply it silently and wrongly, and that is the one failure nothing
  downstream can detect. There is no mechanism that prevents it; the rule is the
  mechanism.

On the Swift side `XoteHost.protocolMin`/`protocolMax` are declared and injected
through the bridge, and `test/protocol_test.mjs` reads them out of the source
and fails if the binary and the bundle drift apart — which is, again, the only
kind of check this repository can run against Swift.

### 5.5 How to know the extraction worked

The repository already has the machinery, which is the happiest finding in this
section. `scripts/consumer-boundary-test.mjs` stages a copy of the publishable
package into a temporary `node_modules`, compiles a fixture ReScript package
against it, and asserts that the documented API compiles and that implementation
details do not. `tests/consumer/rescript.json` is already a downstream package
with `dependencies: ["xote"]` and `-open Xote`.

`xote-native` is the same fixture with one more dependency. Extending that
harness to stage both packages and compile a native fixture against them is the
test that proves the extraction — and it runs in seconds, on Linux, with no
device.

The rest of the guardrails carry over unchanged: `npm run test:exports` pins the
public surface, `native:test` replays the layout oracle and the conformance
suite, and `native:bundle:test` runs the shipped bundle in a bare realm with no
DOM, no `console` and no timers, which is what an embedded `JSContext` looks
like before Swift injects anything.

### 5.6 The order

1. ~~**Version the protocol.**~~ **Done** — see §5.4.
2. ~~**Extend the boundary test to two packages**, still in this repository,
   with `native/` still where it is.~~ **Done** — `native/test/package_test.mjs`,
   and it found the two problems above.
3. **Lift `native/` into `xote-native`.** The build now says what this costs:
   a `rescript.json` with `-open Xote`, a `package.json` with an `exports` map,
   and `host/` living inside `src/`. No source file changes.
4. **Split the hosts out** — `hosts/ios/` into a Swift package, `hosts/android/`
   into a Gradle module, each with the conformance suite as its acceptance test.
   `native/` is already arranged so this is a move rather than an untangling.
5. **Only then** publish anything.

Steps 1 and 2 were worth doing regardless of whether the package is ever
extracted, because they are the tests that would have caught the drift. Step 3
is now a move rather than an experiment.

---

## 6. What `xote` had to change — and what it still should

### 6.1 Landed: 105 lines, six files

The prototype was built deliberately with **zero** changes to `src/`, which
means it worked around four things instead. Three of those four turned out to be
worth fixing on the web renderer's own merits, and were.

**1. `attrValue` carries an opaque payload.** `View.attrValue` declared
`string`; native props are objects, numbers and booleans. At runtime the
renderer never inspected the value — it handed it to `setAttrOrProp` — so a cast
worked. Now there are three real constructors:

```rescript
| Opaque(Obj.t)
| OpaqueSignal(Signal.t<Obj.t>)
| OpaqueCompute(unit => Obj.t)
```

The renderer assigns these and never inspects them, so none of the HTML rules
apply: no boolean presence, no `"true"`/`"false"`, no stringification. **This is
a web feature too** — it is how the DOM renderer can hand an object to a custom
element's property, which it could not do before. SSR emits one only when it is
a scalar; an object is left out of the markup rather than rendered as
`[object Object]`, and hydration writes it on the client.

**2. A host-neutral grouping node.** `SignalFragment` and hydration both
hard-coded `<div style="display: contents">`, and the shadow document recognised
that `div` and erased it — a correctness heuristic sitting on an implementation
detail of the renderer. `RuntimeDom.createGroup()` now consults
`document.createXoteGroup()` and falls back to the div. A host is *told* which
boxes are grouping boxes instead of having to guess.

**3. The SVG tag table belongs to the DOM host.** `RuntimeDom.isSvgTag` routes
`text`, `image`, `line`, `mask`, `filter`, `use` and a dozen others through
`createElementNS`. Half of those are perfectly ordinary native view names.
`createElementForTag` now consults `document.createXoteElement(tag)` first.

Both hooks cost **one `typeof` per element created**, which is nothing next to
creating one, and a document implementing neither behaves exactly as it did
before.

**4. Dirty-flag over-propagation** is in `rescript-signals`, not here. It is
pinned by a test rather than worked around in the library (§4.3).

### 6.2 The one visible cost to web users

Adding constructors to `View.attrValue` — a type exported from a `.resi` — makes
an exhaustive `switch` over it in downstream code non-exhaustive. It is an
additive change that leaves the export surface unchanged and breaks no call
site, but it is not invisible, and it is the single place where the native work
reaches web consumers. It belongs in a release note.

Everything else is genuinely inert: `native/` is a dev source directory in
`rescript.json`, absent from `package.json` `files`, so nothing native has ever
shipped in the `xote` tarball.

### 6.3 Still open

**A `RuntimeHost` seam.** The two hooks are a seam at the only two points that
needed one. Whether the remaining two dozen operations are worth routing through
a record is a benchmark question, not a design question, and the benchmark suite
exists. The answer is not obviously yes: the shim costs a shadow tree, the seam
costs an indirection in the measured path.

**`document` is process-global.** `host/runtime.mjs` holds a module-level
`installed` singleton and assigns `globalThis.document`. One Xote app per
JavaScript realm. That is fine on a phone — a realm per app is the deployment
model — and it is *not* fine for a test harness that wants two, or for an app
embedding a second Xote surface. This is the strongest argument for the seam,
and it is the one that should decide it.

**Server-side rendering of opaque values is a stub.** Scalars stringify, objects
are omitted. For the web that is right. For a future native SSR-equivalent — a
pre-rendered first screen — it is not obviously enough, and nobody has needed it
yet.

---

## 7. The demo

### 7.1 What it is

[`example/tracker/`](./example/tracker/) is an issue tracker over five thousand
issues: a live search, three filter chips, a windowed list, an empty state, a
detail screen, and a status control that writes one signal. 826 lines of app
code across six modules, plus the counter and panel examples that came before
it.

It was built for one reason. `ROADMAP.md` ended on a measurement, and the only
evidence for the premise at that point was a counter. A counter proves a bridge
exists; it proves nothing about whether the bridge stays cheap when the screen
is real. So: something with enough data to be embarrassing, enough interaction
to be representative, and a second screen.

| | |
|---|---|
| `TrackerData.res` | 5,000 issues, generated deterministically. Per-issue state in its own signal |
| `TrackerTheme.res` | The palette and the shapes that repeat. Styles are values; a variation is a merge |
| `TrackerNav.res` | A stack of screens in a signal |
| `TrackerIssues.res` | Search, filters, the windowed list, the empty state, an absolutely positioned badge |
| `TrackerDetail.res` | Wrapping text the host measures, a scroll view, the status control |
| `TrackerApp.res` | One `View.tracked` over the navigation stack |

### 7.2 The good

**The app code is unremarkable, and that is the result.** It is ReScript with
JSX, signals, and records. There is no bridge in it, no serialisation, no
`useNativeDriver`, no threading. `@@jsxConfig` switches the JSX module per file,
so a project could hold web pages and native screens side by side sharing every
type, every signal and every helper between them. Nothing about writing the
tracker felt like writing against a prototype.

**Styles are values.** `NativeStyle.t` is a record of optional fields;
`TrackerTheme` defines the shapes that repeat, and a variation is
`Style.merge(base, {backgroundColor: "..."})`. No stylesheet registry, no string
parsing, no cascade. A style crosses the bridge as an object because the
protocol carries objects, so there is no serialisation step to be slow or wrong.

**The reactivity model paid off exactly where predicted.** Eight commands to
change an issue's status. Zero to scroll within a row. The per-issue `status`
signal means a status button restyles itself and nothing above it in the tree
even learns that something happened.

**The windowed list is 108 lines** and gets 10,000 rows down to 54 views, with
the space above and below expressed as padding on the content box. It is a
component, not a host feature — which is the right layer, and it is only
possible because `Computed` and a structural comparator do the work.

**The layout engine was right.** After the Chromium oracle agreed on 1,183
boxes, every layout complaint from the simulator turned out to be a *host* bug —
clipping, insets, a missing plist key. Not one was a wrong frame. That is a
strong result for a from-scratch flexbox implementation and it is entirely
attributable to having an oracle.

**Errors are contained.** The tracker was, at various points, running with a
handler that threw on every keystroke and with a bundle emitting opcodes the
host did not know. Neither killed the app.

### 7.3 The bad

**The type surface promised more than any host delivered — fixed, and now
enforced.** This was the worst thing in the directory, because it failed
*silently*. `NativeStyle.t` declared `flexWrap`, `alignContent` and `baseline`
alignment, which the layout engine does not implement; `letterSpacing`,
`textTransform`, `fontStyle` and `lineHeight`, which nothing read anywhere.
`NativeJSX` declared ten props and two events no native host applied.

All of them are gone, except `placeholderTextColor` and the `submit`, `focus`
and `blur` events — those an app really does need, and each was three lines of a
pattern `changeText` had already proved, so they were implemented instead.

The part worth keeping is the guardrail rather than the edit.
`host/capabilities.mjs` lists what the engine and the native hosts implement,
and `test/surface_test.mjs` reads `NativeStyle.res`, `NativeJSX.res`,
`layout.mjs` and the Swift sources **as text** and asserts the three agree.
Nothing that renders can catch this class of bug: a style key nobody reads
produces a correct screen for every app that does not use it. Switching the test
on immediately found two `lineHeight` uses in the tracker itself that had never
done anything.

It also happens to be the only check this repository can run against the Swift
at all — a name in the manifest that is not a `case` in `XoteHost.swift` now
fails here instead of on a device. And removing the three layout omissions from
the type turns them into a signal: reaching for `flexWrap` is a compile error,
and that is precisely when the engine should become Yoga.

**`toggle a filter chip` is 884 commands.** Proportional to the screen and not
to the data, which is the claim, and still the number that would show up first
in a profile. Recycling now absorbs the allocation cost of that rebuild — the
views come back from a pool — but the 884 commands themselves are unchanged,
because they are what the reactivity graph computed. Making that number smaller
means changing what the filter invalidates, not how the host applies it.

**The layout engine exists twice.** 622 lines of JavaScript and 574 lines of
Swift computing the same thing. The conformance suite is what makes that
survivable rather than reckless, but it is a standing tax on every change, and
it is the strongest argument for eventually swapping both for Yoga.

**Navigation is a stack in a signal.** It renders the top screen and that is
all: no platform transition, no interactive back gesture, no per-screen
lifecycle, no state preservation. It is honest about being a placeholder, and it
is also the one place in the app where re-rendering wholesale is exactly right —
which is why the seam sits there and not somewhere more expensive.

**Text input is `UITextField` with one event.** No keyboard avoidance, no IME
handling, no return-key semantics, no focus management, and the controlled-input
echo problem is unaddressed.

### 7.4 The gaps

Two entries that used to be in this table are gone. **View flattening** and
**view recycling** — Tier 1 items 3 and 5 — are implemented: a box that only
arranges its children keeps its layout node and loses its view, and a destroyed
view goes back to a bounded pool instead of to the allocator. On the tracker's
list screen that is 34 of 192 views flattened away, and 881 view allocations
across a scroll sweep become 296. Neither may move anything, which is asserted
rather than assumed: the same command stream is replayed into a flattening host
and a non-flattening one and the frames must come out identical. See
[`ROADMAP.md`](./ROADMAP.md) Tier 1.

What is left, roughly in the order an app author would hit it:

| Gap | State |
|---|---|
| Variable-height list rows | Open. Needs measured rows and a running offset table — a different component from `NativeList` |
| Navigation | A signal, not a navigation controller |
| Gestures and animation | Nothing. Touch-driven animation has to run on the UI thread, which means *declaring* animations rather than stepping them from JavaScript. This is where React Native needed Reanimated |
| Safe area, appearance, dynamic type, rotation | None are readable by the app. All of them need to be reactive inputs |
| Accessibility | `accessibilityLabel` and `testID` exist. Traits, focus order, actions, VoiceOver navigation and reduced-motion do not |
| Images | Load with no cache, no decode off the main thread, no placeholder, no `@2x`/`@3x` pipeline |
| Native modules | The *best* part of the story on paper — externals are already how ReScript talks to a foreign runtime, so a binding is idiomatic rather than generated — and entirely undesigned. Needs an async call protocol |
| Android | The protocol has four independent implementations, which is decent evidence it is host-agnostic. A Kotlin host is the test of that claim |
| Hermes | JavaScriptCore was right for a prototype because it ships with iOS. Bytecode precompilation and startup say it is not right for an app |
| Bundler | Vite to one IIFE. No source maps into the JSC console, no code splitting, no asset resolution, and the entry point is a list in `bootstrap.mjs` rather than something an app declares |
| Fast refresh | Genuinely hard, and worth saying so: Xote has no component boundaries to swap and signal state has no serialisable identity. Reload-preserving-nothing is the realistic first step |
| Devtools | The bridge traffic panel in the web preview is already most of one. Pointing it at a device over a socket is a small change with a large payoff — the mutation stream *is* the app's behaviour |

### 7.5 The challenges — five bugs worth keeping

Every one of these cost real time, and every one is a lesson that generalises.

**1. A component that creates state must be a component. (174,782 commands.)**
`NativeList` was built inside a `View.tracked` block. Its `Effect.run` reads
leaked into that block's dependency set, so the region rebuilt the list, the new
list reported its layout, and the two drove each other in a loop — 174,782
commands where there are now 335. The same bug wore a completely different
costume the second time: `TrackerIssues` was a plain function called from inside
the navigation's tracked block, and the symptom was *the search field resetting
on every keystroke*. Both fixes are the same one word: make it a component, so
`XoteJSX.jsx` wraps it in `View.LazyComponent` and its body runs untracked in
its own scope. `NativeList` now wraps its own body defensively.

**2. `int` multiplication in ReScript is `Math.imul`.** The dataset generator
was a Lehmer RNG in integers. It wrapped to 32 bits, went negative, indexed
arrays out of range, and produced `undefined` for every generated field —
surfacing as an issue with `-17 comments`. It is a float now. Nothing about this
is specific to Xote and it will bite anyone doing arithmetic in ReScript that
leaves the 32-bit range.

**3. `console` does not exist in JavaScriptCore.** The shadow document's error
containment had a fallback that logged to `console`, inside the `catch` that was
containing the error. In JSC, before Swift injects a shim, that fallback threw
*during* containment. It is a nested `try`/`catch` now. The general rule: the
last line of an error path may not assume anything about its environment.
`native:bundle:test` exists precisely to catch this class — it runs the shipped
bundle in a realm with no `console`, no timers, no `document` and no module
loader.

**4. Three bugs that look like layout and are not.** All three were found the
first time the tracker ran on a simulator, and the user reported them as layout
problems, which is exactly what they looked like:

- *Text rendering on top of other text*, and *content scrolling up over the
  header*. One bug. `UIScrollView` clips by default and must keep doing so — its
  content is larger than its frame by definition — and the host was applying
  `overflow: visible`, the correct flexbox default for a box, to scroll views as
  well. A list drawn across the header looks precisely like two versions of a
  label at once.
- *The app running in a letterboxed band with black above and below*. A missing
  `UILaunchScreen`. Without it, iOS runs an app at a legacy screen size and
  scales it. The trap: XcodeGen **writes** `Info.plist` from `project.yml`
  rather than reading the one in the repository, so a key that exists only in
  the file is a key the build does not have.

The lesson is the one the conformance suite is built around and does not fully
deliver on: **frames being right is not the same as the screen being right.**

**5. An unbounded leak in the host.** Gesture targets were appended to an array
that was never emptied, so every `listen` grew it forever. Now keyed by node id
and released on `destroy`. Trivial once seen, invisible until the app ran long
enough to matter.

### 7.6 The limitations — what is not tested, precisely

This matters more than the list of missing features, because a gap you know
about is a plan and a blind spot is a bug you have not met yet.

**The Swift has never been compiled in this repository.** Linux, no toolchain,
no network route to one. The layout *algorithm* is verified against Chromium;
the Swift spelling of it is not. Expect compile errors on the next real build.

**The conformance suite compares four things and only four things:** the node
tree (parent → child ids), the frames in root coordinates, the text, and — since
flattening landed — the *view* tree, which is not the same as the node tree.
That is a deliberate and defensible choice: it is what two hosts in two
languages can agree on, with text measured by a stub because `UILabel`,
`StaticLayout` and Chromium will never agree on font metrics.

It is also, structurally, why every one of the bugs in §7.5(4) got through.
**Nothing in the suite can catch:**

| Not covered | Why it is invisible to the suite |
|---|---|
| Clipping and overflow | Both hosts compute the same frame; only one of them draws outside it |
| Z-order and paint order | Both trees are compared as parent → children maps, not as a painting order |
| Colours, fonts, opacity, corner radius | Never compared — the suite is geometry |
| Safe-area and content insets | The suite supplies a viewport, not a device |
| Anything in the app shell | Launch screens, `Info.plist`, orientation, the view controller |
| Threading, event delivery, error containment | Tested separately in JavaScript, not against UIKit |
| Whether the Swift *compiles* | Nothing here can check that. `test/surface_test.mjs` reads it as text and checks the names line up, which is a real check and not a substitute for one |
| Frame time | Not measured at all, on any host |

Two cheap things would close most of that: snapshot-diffing the same screen
between the DOM preview host and the device, and adding paint properties to the
conformance comparison. Neither is built.

**The measurements are from a headless host.** Command counts are a proxy for
work, not a measure of it. The next thing worth measuring is a device.

---

## 8. What is still unknown

Stated as questions, because they have not been answered and should not be
presented as though they have:

1. **Does it hold at 60fps?** 884 commands for a filter toggle is a bounded
   number. Whether UIKit applies it inside a frame budget is unmeasured.
2. **Is the shim or the seam right?** The shim keeps the web hot path untouched
   and costs a shadow tree. The seam costs an indirection per mutation in a path
   that is benchmarked. This is decidable by benchmark and has not been decided.
3. **Does the protocol survive a second platform?** Four host implementations is
   evidence. A Kotlin host written by someone who did not design the protocol is
   proof.
4. **Can animation be declarative enough?** Every framework that got here needed
   a second system for it. There is no reason to expect Xote to be the exception,
   and no design yet.
5. **What does fast refresh even mean without component boundaries?** Xote has
   none to swap and signal state has no serialisable identity.

---

## 9. If this goes further

The near-term order, unchanged from [`ROADMAP.md`](./ROADMAP.md) and restated
here so this document stands alone:

1. **Version the protocol and extract the package** (§5.6). The seams are in
   place and there are four implementations to keep honest.
2. **Narrow the type surface to what is implemented** (§7.3). This is a
   half-day and it is the difference between a library and a trap.
3. **Navigation.** The next thing an app cannot be built without.
4. **Text input, safe area, appearance.** Small individually; between them, the
   difference between a demo and a screen.
5. **An Android host.** The conformance suite makes this a transliteration and a
   day of plumbing rather than a week of guessing — and it is the real test of
   the protocol.
6. **Gestures and animation.** The hardest remaining design problem, and the one
   to do last because everything above it constrains the answer.

The honest summary is that the architectural bet paid off and the product work
has barely started. Fine-grained reactivity does make the bridge cheap; that
question is settled by §2. What is not settled is any of the two dozen things
that make a UI framework usable by someone who did not write it — and none of
those are made easier or harder by the reactivity model. They are just work.
