# SSR and hydration

Server rendering is experimental but complete: render to a string on the
server, ship the state alongside the markup, and attach reactivity on the
client without re-rendering the DOM.

## The shape that makes it work

Server and client must build the **same tree** from the **same state ids**. The
way to guarantee that is a shared module with a state factory and a component
that takes the state:

```rescript
/* App.res — imported by both entries */
let makeState = () => {
  let count = SSRState.signal("count", 0, SSRState.Codec.int)
  let items = SSRState.signal("items", [], SSRState.Codec.array(SSRState.Codec.string))
  (count, items)
}

let app = (count, items) => () =>
  <div>
    <p> {Signal.get(count)} </p>
    <View.For each={MaybeSignal.reactive(items)} render={i => <li> {i} </li>} />
  </div>
```

`SSR.renderToString`, `SSR.renderDocument` and `Hydration.hydrate*` all take a
`unit => View.node`, not a node — note the `() =>` in `app`.

## Server

```rescript
/* server.res */
let (count, items) = App.makeState()

let html = SSR.renderDocument(
  ~head=`<title>My App</title>`,
  ~scripts=["/client.res.mjs"],
  ~stateScript=SSRState.generateScript(),
  App.app(count, items),
)
```

Other entry points:

| Function | Produces |
|---|---|
| `SSR.renderToString(component, ~options?)` | markup only |
| `SSR.renderToStringWithRoot(component, ~rootId?, ~options?)` | markup wrapped in hydration root markers (`rootId` defaults to `"root"`) |
| `SSR.renderDocument(~head?, ~bodyAttrs?, ~scripts?, ~styles?, ~stateScript?, ~nonce?, component)` | a full HTML document |
| `SSR.generateHydrationScript(~nonce?)` | the `<script>` that sets `window.__XOTE_HYDRATED__` |

`renderOptions` is `{nonce?, renderId?}`. Pass `~nonce` throughout if the page
has a strict CSP.

**Call `SSRState.clear()` between renders.** The state registry is module-level
and a long-running server will otherwise leak one request's state into the
next.

## State transfer

`SSRState.signal(id, initial, codec)` creates a signal and syncs it in one
call — registering it on the server, restoring it on the client. That is the
one you want. The lower-level pieces are `register` (server), `restore`
(client), `sync` (either), `clear`, `getClientState`.

Codecs: `Codec.int`, `Codec.float`, `Codec.string`, `Codec.bool`,
`Codec.array(c)`, `Codec.option(c)`, `Codec.tuple2(a, b)`, `Codec.tuple3(a, b, c)`,
`Codec.dict(c)`, and `Codec.make(~encode, ~decode)` for anything else — `encode`
returns `JSON.t`, `decode` returns an `option`.

```rescript
let userCodec = SSRState.Codec.make(
  ~encode=user => JSON.Encode.object(Dict.fromArray([("id", JSON.Encode.string(user.id))])),
  ~decode=json => /* … */ None,
)
```

Ids must match between server and client, which is exactly why both sides call
the same factory. Only sync what the client cannot recompute: a draft input
value should start empty on the client rather than travel over the wire.

## Client

```rescript
/* client.res */
let (count, items) = App.makeState()

Hydration.hydrateById(
  App.app(count, items),
  "root",
  ~options={onHydrated: () => Console.log("hydrated")},
)
```

`Hydration.hydrate(component, element, ~options?)` is the variant taking a DOM
element. `hydrateOptions` is `{renderId?, onHydrated?}`; `renderId` must match
the one given to the server render when you set one.

Hydration walks the server DOM, finds reactive boundaries by their comment
markers, and attaches effects and listeners without rebuilding. It is
**one-way**: after hydration everything is normal client rendering. There is no
incremental or streaming hydration.

## Environment branching

```rescript
if SSRContext.isServer { … }

SSRContext.onClient(() => installAnalytics())      /* returns option<'a> */
let width = SSRContext.match(~server=() => 0, ~client=() => windowWidth())
```

Use these instead of testing for `window` by hand — they are what the SSR
bundle is compiled against.

## Mismatches

The two sides must produce structurally identical trees. Anything
non-deterministic — `Date.now()`, `Math.random()`, a locale-dependent format,
a read of `window` — must be either synced through `SSRState` or deferred into
an effect that only runs on the client. A markup mismatch shows up as
hydration attaching to the wrong node, and the symptom is a leaf that updates
the wrong element.

## Routing on the server

Call `Router.initSSR(~pathname, ~search?, ~hash?, ())` before rendering, never
`Router.init()` — the latter reads `window`. See `routing.md`.
