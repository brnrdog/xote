## Xote Technical Overview

This document describes the current architecture and public API of Xote, a lightweight ReScript UI library for building components with fine-grained signal reactivity.

Xote uses [rescript-signals](https://brnrdog.github.io/rescript-signals) for reactive primitives and layers a small DOM renderer, JSX support, routing, server-side rendering, hydration, and SSR state transfer on top.

### Module Boundary

The ReScript compiler is configured with `"namespace": true`, so every source file in `src/` is namespaced under `Xote`. The public modules are listed in `rescript.json` under `sources.public`:

- **`Xote.View`**: Official UI node API for constructors, attributes, rendering, and mounting.
- **`Xote.Node`**: Deprecated compatibility alias for `View`.
- **`Xote.Html`**: Convenience constructors for common HTML tags.
- **`Xote.XoteJSX`**: JSX v4 transform support and lowercase HTML element definitions.
- **`Xote.Prop`**: Official static-or-reactive prop wrapper for JSX-friendly APIs.
- **`Xote.ReactiveProp`**: Deprecated compatibility alias for `Prop`.
- **`Xote.Route`**: Pure route pattern parsing and matching.
- **`Xote.Router`**: Signal-based client and SSR routing helpers.
- **`Xote.SSR`**: Server-side rendering to HTML strings.
- **`Xote.SSRContext`**: Runtime server/client environment checks.
- **`Xote.SSRState`**: Server-to-client state serialization and restoration.
- **`Xote.Hydration`**: Client-side hydration for server-rendered DOM.
- **`Xote.Signal`**, **`Xote.Computed`**, **`Xote.Effect`**: Re-export shims for `rescript-signals`.

There is no central `Xote.res` barrel and no `Xote__` prefixed source module naming. Consumers access modules through the generated namespace, for example `Xote.View`, `Xote.Router`, or unqualified `View` after `-open Xote`. `Node` remains available as a deprecated compatibility alias.

Some implementation modules are currently nested inside public modules, such as `View.DOM`, `View.Reactivity`, `View.Render`, `SSR.Html`, `SSR.Markers`, and `Hydration.DOMWalker`. These exist to share implementation code inside the package and should be treated as internal details unless they are explicitly documented as public API.

### Reactive Primitives

Reactive behavior comes from `rescript-signals`:

- **`Signal.t<'a>`** stores mutable reactive state.
- **`Signal.make(~name?, ~equals?, value)`** creates a signal. The default equality is JavaScript strict equality (`===`); pass `~equals` for custom comparison.
- **`Signal.get(signal)`** reads and tracks a dependency when called inside an effect or computed.
- **`Signal.peek(signal)`** reads without dependency tracking.
- **`Signal.set(signal, value)`** updates and notifies dependents when the value differs by the configured equality check.
- **`Signal.update(signal, fn)`** updates from the current value.
- **`Signal.batch(fn)`** coalesces multiple signal writes.
- **`Signal.untrack(fn)`** disables dependency capture inside a function.

Computed values and effects are also provided by `rescript-signals`:

- **`Computed.make(~name?, ~equals?, fn)`** creates a lazy derived signal. Upstream writes mark it dirty; it recomputes when read.
- **`Computed.dispose(signal)`** manually disposes a computed signal when needed.
- **`Effect.run(~name?, fn)`** creates a fire-and-forget effect.
- **`Effect.runWithDisposer(~name?, fn)`** returns a disposer with `dispose()`.
- Effect callbacks return `option<unit => unit>`: `Some(cleanup)` for teardown or `None` when no cleanup is needed.

### View And Rendering Model

Xote components are functions that return `View.node`. `Node.node` remains available as the deprecated equivalent alias.

`View.node` variants:

- `Text(string)`
- `SignalText(Signal.t<string>)`
- `Element({tag, attrs, events, children})`
- `Fragment(array<node>)`
- `SignalFragment(Signal.t<array<node>>)`
- `LazyComponent(unit => node)`
- `KeyedList({signal, keyFn, renderItem})`

Preferred public constructors:

- `View.text("hello")`
- `View.int(1)`, `View.float(1.5)`, and `View.bool(true)`
- `View.signalText(() => ...)`
- `View.signalInt(() => ...)` and `View.signalFloat(() => ...)`
- `<View.Text value={Prop.t<string>} />`
- `<View.Int value={Prop.t<int>} />`, `<View.Float value={Prop.t<float>} />`, and `<View.Bool value={Prop.t<bool>} />`
- `View.fragment(children)`
- `View.signalFragment(signal)`
- `View.each(signal, renderItem)`
- `View.eachWithKey(signal, keyFn, renderItem)`
- `<View.For each={Prop.t<array<'a>>} by={optionalKeyFn} render={renderItem} />`
- `<View.Show when_={Prop.t<bool>}>...</View.Show>`
- `<View.Maybe value={Prop.t<option<'a>>} render={renderItem} />`
- `<View.Value value={Prop.t<'a>} render={renderValue} />`
- `View.element("div", ~attrs?, ~events?, ~children?, ())`
- `View.null()` and `View.empty()`
- `View.mount(node, container)`
- `View.mountById(node, "root")`

Deprecated `Node.*` entry points remain supported as aliases, including `Node.list` / `Node.keyedList` alongside `View.each` / `View.eachWithKey`.

Rendering is fine-grained:

- Static text renders once.
- `SignalText` attaches an effect that updates the text node.
- Reactive attributes attach effects that update only the affected attribute/property.
- `SignalFragment` replaces its child region when its signal changes.
- `KeyedList` uses comment anchors and key-based reconciliation to preserve DOM identity.
- `LazyComponent` defers component evaluation until render/hydration time.

### Attributes

Attributes are represented as `(string, View.attrValue)` pairs:

- `View.Attr.string(key, value)` for static string attributes.
- `View.Attr.signal(key, signal)` for reactive string attributes.
- `View.Attr.compute(key, fn)` for computed string attributes.
- `View.attr`, `View.signalAttr`, and `View.computedAttr` remain available, and the equivalent deprecated `Node.*` names still forward to `View`.

The DOM renderer maps selected names to DOM properties or boolean attribute behavior:

- `value`, `checked`, and `disabled` are set as properties.
- Boolean attributes such as `required`, `readonly`, `multiple`, `hidden`, `autofocus`, and selected ARIA/global attributes are added for `"true"` and removed otherwise.
- Other attributes use `setAttribute`.

SSR mirrors the same boolean attribute behavior when rendering strings.

### JSX Support

`Xote.XoteJSX` implements ReScript JSX v4:

- `jsx`, `jsxs`, `jsxKeyed`, and `jsxsKeyed` are entry points for the JSX transform.
- Lowercase HTML tags are implemented in `XoteJSX.Elements`.
- JSX components are wrapped in `View.LazyComponent` so component evaluation happens during render/hydration rather than inside an unrelated computed context.
- JSX attributes accept raw values, `Prop.t<'a>`, raw `Signal.t<'a>`, or computed functions for compatibility.

`Prop.t<'a>` is:

```rescript
type t<'a> = Reactive(Signal.t<'a>) | Static('a)
```

Use `Prop.static(value)` or `Prop.reactive(signal)` when a component prop should support either static or reactive input. `ReactiveProp` remains available as a deprecated compatibility alias.

### Router

`Xote.Route` provides pure route matching:

- `Route.parsePattern("/users/:id")`
- `Route.compile("/users/:id")`
- `Route.matchPath(parsedPattern, pathname)`
- `Route.matchCompiled(compiledPattern, pathname)`
- `Route.match(pattern, pathname)`
- `Route.matchPathname(pattern, pathname)`

`Xote.Router` provides signal-based navigation:

- `Router.init(~basePath?, ())` initializes browser routing and must be called before routing helpers on the client.
- `Router.initSSR(~basePath?, ~pathname, ~search?, ~hash?, ())` initializes routing for server-side rendering without browser APIs.
- `Router.location()` returns the shared `Signal.t<Router.location>`.
- `Router.push(pathname, ~search?, ~hash?, ())`
- `Router.replace(pathname, ~search?, ~hash?, ())`
- `Router.route(pattern, params => node)`
- `Router.routes(configs)`
- `Router.link(~to, ~attrs?, ~children?, ())`
- `<Router.Link to="/path">...</Router.Link>` for JSX.

Router state is stored on `globalThis` with `Symbol.for("xote.router.state")`, so multiple bundled copies of Xote can share the same router state.

### SSR And Hydration

`Xote.SSR` renders nodes to HTML strings:

- `SSR.renderToString(component, ~options?)`
- `SSR.renderToStringWithRoot(component, ~rootId?, ~options?)`
- `SSR.generateHydrationScript(~nonce?)`
- `SSR.renderDocument(~head?, ~bodyAttrs?, ~scripts?, ~styles?, ~stateScript?, ~nonce?, component)`

SSR uses comment markers to identify reactive boundaries for hydration:

- Signal text: `<!--$-->...<!--/$-->`
- Signal fragments: `<!--#-->...<!--/#-->`
- Keyed lists: `<!--kl-->...<!--/kl-->`
- Keyed items: `<!--k:KEY-->...<!--/k-->`
- Lazy components: `<!--lc-->...<!--/lc-->`

`Xote.Hydration` walks server-rendered DOM and attaches effects/events without replacing the full tree:

- `Hydration.hydrate(component, container, ~options?)`
- `Hydration.hydrateById(component, containerId, ~options?)`

### SSR State

`Xote.SSRState` transfers signal values from server to client:

- `SSRState.register(id, signal, codec)` records state on the server.
- `SSRState.restore(id, signal, codec)` restores state on the client.
- `SSRState.sync(id, signal, codec)` registers or restores depending on runtime.
- `SSRState.signal(id, initial, codec)` creates a signal and syncs it.
- `SSRState.make(id, initial, codec)` remains available as the equivalent alias.
- `SSRState.syncSignal(id, signal, codec)` is a clearer alias for `sync`.
- `SSRState.generateScript(~nonce?)` serializes state into a script tag.
- `SSRState.clear()` resets the server registry between independent renders.

`SSRState.Codec` includes codecs for primitives, arrays, options, tuples, dictionaries, and custom encode/decode functions.

### Build And Distribution

- `npm run res:build` compiles ReScript sources.
- `npm run test` compiles and runs the test suite.
- `npm run build` builds the Vite library output.

The package exposes a bundled root entry through `dist/` and currently also exposes `./src/*` for ReScript/source-level consumers.

### Known Limitations And Future Work

- The renderer still has some implementation details nested inside public modules; interface files should narrow that surface over time.
- keyed JSX children now preserve identity inside reactive fragments when all siblings are keyed, but `View.For` with `by` remains the clearest explicit list API.
- JSX prop conversion currently uses dynamic checks to support several prop styles.
- Renderer extraction can continue by moving keyed reconciliation behind an internal render module while preserving `View.Render` as a compatibility alias.
