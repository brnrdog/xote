open! Zekr

/* `View.probe` is what `@xote.component` emits around a leaf whose expression
   contains a call the ppx cannot resolve. It has to be invisible when the leaf
   really is static, and report the leaf — once — when the call turns out to
   read a signal behind the ppx's back. */

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let captureWarnings: unit => unit = %raw(`function () {
  globalThis.__probeWarnings = []
  globalThis.__probeRealWarn = console.warn
  console.warn = function (message) { globalThis.__probeWarnings.push(String(message)) }
}`)

let releaseWarnings: unit => array<string> = %raw(`function () {
  console.warn = globalThis.__probeRealWarn
  return globalThis.__probeWarnings
}`)

let mentions = (messages: array<string>, site: string) =>
  messages->Array.some(message => message->String.includes(site))

let suite = Zekr.suite(
  "Probe",
  [
    test("returns the value untouched when nothing is read", () => {
      captureWarnings()
      let value = View.probe("Quiet.res:1:1", () => "static")
      let warnings = releaseWarnings()
      combineResults([assertEqual(value, "static"), assertEqual(Array.length(warnings), 0)])
    }),
    test("reports a scalar leaf that reads a signal through an opaque call", () => {
      let count = Signal.make(4)
      /* stands in for an imported helper: the ppx sees only the call */
      let hidden = () => Signal.get(count)
      captureWarnings()
      let value = View.probe("Hidden.res:12:9", () => hidden())
      let warnings = releaseWarnings()
      combineResults([
        assertEqual(value, 4),
        assertTrue(mentions(warnings, "Hidden.res:12:9")),
        assertTrue(mentions(warnings, "() => ...")),
      ])
    }),
    test("reports each site once, however often it is evaluated", () => {
      let count = Signal.make(1)
      let hidden = () => Signal.get(count)
      captureWarnings()
      let _ = View.probe("Repeat.res:3:3", () => hidden())
      let _ = View.probe("Repeat.res:3:3", () => hidden())
      let _ = View.probe("Repeat.res:3:3", () => hidden())
      let warnings = releaseWarnings()
      assertEqual(
        warnings->Array.filter(w => w->String.includes("Repeat.res:3:3"))->Array.length,
        1,
      )
    }),
    test("stays silent for a deliberate untracked peek", () => {
      let count = Signal.make(7)
      let peeked = () => Signal.peek(count)
      captureWarnings()
      let value = View.probe("Peek.res:5:5", () => peeked())
      let warnings = releaseWarnings()
      combineResults([assertEqual(value, 7), assertEqual(Array.length(warnings), 0)])
    }),
    test("stays silent for a value that is reactive on its own", () => {
      let count = Signal.make(2)
      captureWarnings()
      let value = View.probe("Reactive.res:7:7", () => Computed.make(() => Signal.get(count) * 2))
      let warnings = releaseWarnings()
      combineResults([assertEqual(Signal.get(value), 4), assertEqual(Array.length(warnings), 0)])
    }),
    test("an enclosing tracked block still subscribes through the probe", () => {
      let {container} = Dom.render("")
      let label = Signal.make("a")
      let hidden = () => Signal.get(label)
      captureWarnings()
      let _ = mountTo(
        View.tracked(() => View.text(View.probe("Tracked.res:9:9", () => hidden()))),
        container,
      )
      let r1 = Dom.Assert.toHaveTextContent(container, "a")
      Signal.set(label, "b")
      let r2 = Dom.Assert.toHaveTextContent(container, "b")
      let warnings = releaseWarnings()
      combineResults([r1, r2, assertTrue(mentions(warnings, "Tracked.res:9:9"))])
    }),
  ],
)
