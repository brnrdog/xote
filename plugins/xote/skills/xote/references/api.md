# Public API

The public surface is exactly what the `.resi` interface files declare. Fifteen
modules are public: `View`, `Html`, `XoteJSX`, `MaybeSignal`, `Prop`
(deprecated), `Route`, `Router`, `SSR`, `SSRContext`, `SSRState`, `Hydration`,
`Mdx`, `Signal`, `Computed`, `Effect`.

Everything else in the package is an internal `Runtime*` module. If a name is
not below, it is not API — do not import it, and do not reach for a
`Xote__`-prefixed name (there are none; `namespace: true` handles the prefix).

Signatures use ReScript notation; `=?` marks an optional labeled argument.

## Signal

```rescript
type t<'a>
let make: ('a, ~name: string=?, ~equals: ('a, 'a) => bool=?) => t<'a>
let get: t<'a> => 'a          /* read + subscribe */
let peek: t<'a> => 'a         /* read only */
let set: (t<'a>, 'a) => unit
let update: (t<'a>, 'a => 'a) => unit
let batch: (unit => 'a) => 'a
let untrack: (unit => 'a) => 'a
```

## Computed

```rescript
let make: (unit => 'a, ~name: string=?, ~equals: ('a, 'a) => bool=?) => Signal.t<'a>
let dispose: Signal.t<'a> => unit
```

## Effect

```rescript
type disposer = {dispose: unit => unit}
let run: (unit => option<unit => unit>, ~name: string=?) => unit
let runWithDisposer: (unit => option<unit => unit>, ~name: string=?) => disposer
```

## MaybeSignal

```rescript
type t<'a> = Reactive(Signal.t<'a>) | Static('a)
let static: 'a => t<'a>
let reactive: Signal.t<'a> => t<'a>
let computed: (unit => 'a) => t<'a>
let get: t<'a> => 'a
let peek: t<'a> => 'a
let isReactive: t<'a> => bool
let isStatic: t<'a> => bool
let map: (t<'a>, 'a => 'b) => t<'b>
let toSignal: t<'a> => Signal.t<'a>   /* Static lifts into a detached signal */
let ofUnknown: 'input => t<'a>        /* the JSX coercion; unchecked */
```

## View

### Types

```rescript
type attrValue =
  | Static(string) | SignalValue(Signal.t<string>) | Compute(unit => string)
  | OptionalStatic(option<string>)
  | OptionalSignalValue(Signal.t<option<string>>)
  | OptionalCompute(unit => option<string>)

type node =
  | Element({tag, attrs, events, children})
  | Text(string)
  | SignalText(Signal.t<string>)
  | Fragment(array<node>)
  | SignalFragment(Signal.t<array<node>>)
  | Keyed({key, identity, child})
  | LazyComponent(unit => node)
  | KeyedList({signal, keyFn, renderItem})
```

### Attributes

```rescript
let attr: (string, string) => (string, attrValue)
let signalAttr: (string, Signal.t<string>) => (string, attrValue)
let computedAttr: (string, unit => string) => (string, attrValue)
let optionalAttr: (string, option<string>) => (string, attrValue)
let optionalSignalAttr: (string, Signal.t<option<string>>) => (string, attrValue)
let optionalComputedAttr: (string, unit => option<string>) => (string, attrValue)

module Attr: { string, signal, compute, optional, optionalSignal, optionalCompute }
```

### Nodes

```rescript
let text: string => node
let signalText: (unit => string) => node
let signalInt: (unit => int) => node
let signalFloat: (unit => float) => node
let int: int => node
let float: float => node
let bool: bool => node
let fragment: array<node> => node
let signalFragment: Signal.t<array<node>> => node
let tracked: (unit => node) => node
let each: (Signal.t<array<'a>>, 'a => node) => node
let eachWithKey: (Signal.t<array<'a>>, 'a => string, 'a => node) => node
let element: (string, ~attrs=?, ~events=?, ~children=?, unit) => node
let null: unit => node
let empty: unit => node
```

### JSX components

```rescript
View.For    { each: MaybeSignal.t<array<'item>>, by?: 'item => string, render: 'item => node }
View.KeyedFor { each, by, render }              /* `by` required */
View.Show   { when_: MaybeSignal.t<bool>, children?: node, fallback?: node }
View.Maybe  { value: MaybeSignal.t<option<'v>>, render: 'v => node, fallback?: node }
View.Value  { value: MaybeSignal.t<'v>, render: 'v => node }
View.Text / View.Int / View.Float / View.Bool  { value?, children? }
```

### Mounting and PPX runtime

```rescript
let mount: (node, Dom.element) => unit
let mountById: (node, string) => unit
let child: 'a => node          /* emitted by @xote.component for bare children */
let probe: (string, unit => 'a) => 'a   /* emitted for unresolvable reads */
```

`View.isReactiveProp` is deprecated — use `MaybeSignal.ofUnknown`.

## Html

`div span button input h1 h2 h3 p ul li a`, each
`(~attrs=?, ~events=?, ~children=?, unit) => View.node` (`input` has no
`children`). Any other tag: `View.element("tag", …)` or JSX.

## Router

```rescript
type location = {pathname: string, search: string, hash: string}
let location: unit => Signal.t<location>
let init: (~basePath: string=?, unit) => unit
let initSSR: (~basePath=?, ~pathname=?, ~search=?, ~hash=?, unit) => unit
let push: (string, ~search: string=?, ~hash: string=?, unit) => unit
let replace: (string, ~search: string=?, ~hash: string=?, unit) => unit

type routeConfig = {pattern: string, render: Route.params => View.node}
let route: (string, Route.params => View.node) => View.node
let routes: array<routeConfig> => View.node
let link: (~to: string, ~attrs=?, ~children=?, unit) => View.node

module Link  /* props: to, class?, id?, style?, target?, aria-label?, attrs?, onClick?, children? */
```

## Route

```rescript
type params = Dict.t<string>
type matchResult = Match(params) | NoMatch
let match: (string, string) => matchResult
```

`parsePattern`, `matchPath`, `compile`, `matchCompiled`, `matchPathname` and the
`segment` type are deprecated and go away in the next major release.

## SSR

```rescript
type renderOptions = {nonce?: string, renderId?: string}
let renderToString: (unit => View.node, ~options: renderOptions=?) => string
let renderToStringWithRoot: (unit => View.node, ~rootId: string=?, ~options=?) => string
let generateHydrationScript: (~nonce: string=?) => string
let renderDocument: (
  ~head: string=?, ~bodyAttrs: string=?, ~scripts: array<string>=?,
  ~styles: array<string>=?, ~stateScript: string=?, ~nonce: string=?,
  unit => View.node,
) => string
```

## SSRState

```rescript
module Codec: {
  type t<'a> = {encode: 'a => JSON.t, decode: JSON.t => option<'a>}
  let int: t<int>
  let float: t<float>
  let string: t<string>
  let bool: t<bool>
  let array: t<'a> => t<array<'a>>
  let option: t<'a> => t<option<'a>>
  let tuple2: (t<'a>, t<'b>) => t<('a, 'b)>
  let tuple3: (t<'a>, t<'b>, t<'c>) => t<('a, 'b, 'c)>
  let dict: t<'a> => t<Dict.t<'a>>
  let make: (~encode: 'a => JSON.t, ~decode: JSON.t => option<'a>) => t<'a>
}

let signal: (string, 'a, Codec.t<'a>) => Signal.t<'a>   /* create + sync */
let sync: (string, Signal.t<'a>, Codec.t<'a>) => unit
let register: (string, Signal.t<'a>, Codec.t<'a>) => unit   /* server */
let restore: (string, Signal.t<'a>, Codec.t<'a>) => unit    /* client */
let clear: unit => unit
let generateScript: (~nonce: string=?) => string
let getClientState: unit => Dict.t<JSON.t>
```

## SSRContext

```rescript
let isServer: bool
let isClient: bool
let onServer: (unit => 'a) => option<'a>
let onClient: (unit => 'a) => option<'a>
let match: (~server: unit => 'a, ~client: unit => 'a) => 'a
```

## Hydration

```rescript
type hydrateOptions = {renderId?: string, onHydrated?: unit => unit}
let hydrate: (unit => View.node, Dom.element, ~options: hydrateOptions=?) => unit
let hydrateById: (unit => View.node, string, ~options: hydrateOptions=?) => unit
```

## Mdx

```rescript
type children = Obj.t
type components = dict<Obj.t => View.node>
type props = {components?: components}
type document = props => View.node
let component: ('props => View.node) => Obj.t => View.node
let components: array<(string, Obj.t => View.node)> => components
let render: (document, ~components: components=?, unit) => View.node
let childrenToNodes: children => array<View.node>
let childrenToText: children => string
```

## JavaScript entry points

`xote` / `xote/client` (`View`, `Html`, `XoteJSX`, `MaybeSignal`, signal shims),
`xote/router`, `xote/ssr`, `xote/hydration`, `xote/mdx`. The root entry is
client-only: router, SSR, hydration and MDX are not re-exported from it.
