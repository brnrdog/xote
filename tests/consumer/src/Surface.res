/* Type-level surface check, compiled as a real consumer would compile it.

   This file only needs to *type-check*; it is never executed. What it guards is
   the dependency boundary: this project declares `["xote"]` and nothing else,
   exactly as the README and the docs site tell consumers to. If a public
   signature mentions a type owned by a transitive dependency (rescript-signals'
   `Signals` namespace), that path is unresolvable here and the build fails.

   The in-repo consumers (docs-website, ppx/example) all declare
   rescript-signals, so they cannot catch that class of leak. This one can.

   Keep this to the public API only, and prefer breadth over depth: one line per
   primitive is enough, since the failure being guarded is in the signatures. */

let count = Signal.make(0)

/* Computed: the value must be usable everywhere a signal is accepted. Passing
   it to Signal.get is what regressed — Computed.make returned a type named
   through rescript-signals' namespace, which a consumer cannot resolve. */
let doubled = Computed.make(() => Signal.get(count) * 2)
let doubledNow: int = Signal.get(doubled)
let doubledPeeked: int = Signal.peek(doubled)

let named = Computed.make(() => Signal.get(count) + 1, ~name="named")
let withEquals = Computed.make(() => Signal.get(count), ~equals=(a, b) => a === b)

/* Signal */
Signal.set(count, 1)
Signal.update(count, n => n + 1)
let batched: int = Signal.batch(() => Signal.peek(count))
let untracked: int = Signal.untrack(() => Signal.get(count))

/* Effect */
Effect.run(() => {
  let _ = Signal.get(count)
  None
})
let disposer = Effect.runWithDisposer(() => None)
disposer.dispose()

/* Prop: static and reactive, the latter built from both a signal and a computed */
let staticProp: Prop.t<int> = Prop.static(1)
let signalProp: Prop.t<int> = Prop.signal(count)
let computedProp: Prop.t<int> = Prop.signal(doubled)
let propValue: int = Prop.get(computedProp)

/* View nodes and attributes driven by a computed */
let textNode = View.signalText(() => Signal.get(doubled)->Int.toString)
let intNode = View.signalInt(() => Signal.get(doubled))
let attribute = View.computedAttr("class", () => Signal.get(doubled) > 0 ? "on" : "off")
let element = View.element("div", ~attrs=[attribute], ~children=[textNode, intNode], ())

/* JSX: a computed flowing through the components that take Prop.t */
let items = Signal.make([1, 2, 3])
let evens = Computed.make(() => Signal.get(items)->Array.filter(n => mod(n, 2) == 0))

let list =
  <ul>
    <View.For
      each={Prop.signal(evens)}
      render={n => <li> <View.Int> {n} </View.Int> </li>}
    />
  </ul>

let conditional =
  <View.Show when_={Prop.signal(Computed.make(() => Signal.get(count) > 0))}>
    <p> <View.Text> "positive" </View.Text> </p>
  </View.Show>

let valueNode =
  <View.Value value={Prop.signal(doubled)} render={n => <p> <View.Int> {n} </View.Int> </p>} />

/* Disposal takes a computed back, closing the round trip. */
Computed.dispose(doubled)

/* Keep every binding used so the file compiles without unused warnings. */
let scalars = [
  doubledNow,
  doubledPeeked,
  Signal.peek(named),
  Signal.peek(withEquals),
  batched,
  untracked,
  Prop.get(staticProp),
  Prop.get(signalProp),
  propValue,
]

let nodes = [element, list, conditional, valueNode]
