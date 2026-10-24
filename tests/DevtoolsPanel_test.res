open! Zekr

/* The panel applies the app's events once per frame, so these tests wait a
 frame after acting. Its contents live in a shadow root. */

type element

let graphVisible = {
  let visible = Devtools.install().signals
  Devtools.uninstall()
  visible
}

let graphTest = (name, run) => graphVisible ? asyncTest(name, run) : asyncTestSkip(name, run)

let frame = (): promise<unit> =>
  Promise.make((resolve, _) => setTimeout(() => resolve(), 40)->ignore)

let shadowQuery: string => Nullable.t<element> = %raw(`function (selector) {
  var host = document.getElementById("xote-devtools")
  return host && host.shadowRoot ? host.shadowRoot.querySelector(selector) : null
}`)

let shadowTexts: string => array<string> = %raw(`function (selector) {
  var host = document.getElementById("xote-devtools")
  if (!host || !host.shadowRoot) return []
  return Array.from(host.shadowRoot.querySelectorAll(selector)).map(function (el) { return el.textContent })
}`)

let textOf: element => string = %raw(`function (el) { return el.textContent }`)

let click: element => unit = %raw(`function (el) { el.click() }`)

let clickTab: string => unit = %raw(`function (name) {
  var host = document.getElementById("xote-devtools")
  Array.from(host.shadowRoot.querySelectorAll(".tab")).find(function (b) { return b.textContent === name }).click()
}`)

let hostExists: unit => bool = %raw(`function () { return document.getElementById("xote-devtools") !== null }`)

let has = selector => shadowQuery(selector)->Nullable.toOption->Option.isSome

/* Install, run, and always clean up — the panel and the hooks. */
let withPanel = async (~expanded=true, fn: (unit => unit) => promise<testResult>): testResult => {
  let _ = Devtools.install()
  let unmount = DevtoolsPanel.mount(~expanded, ())
  try {
    let result = await fn(unmount)
    if hostExists() {
      unmount()
    }
    Devtools.uninstall()
    result
  } catch {
  | exn =>
    if hostExists() {
      unmount()
    }
    Devtools.uninstall()
    throw(exn)
  }
}

let suite = Zekr.asyncSuite(
  "DevtoolsPanel",
  [
    asyncTest("starts as a launcher that opens the panel", async () =>
      await withPanel(~expanded=false, async _ => {
        let launcher = has(".launcher")
        shadowQuery(".launcher")->Nullable.toOption->Option.forEach(click)
        combineResults([
          assertTrue(launcher),
          assertTrue(has(".panel")),
          assertFalse(has(".launcher")),
        ])
      })
    ),
    asyncTest("unmounting removes it from the page", async () =>
      await withPanel(async unmount => {
        let before = hostExists()
        unmount()
        combineResults([assertTrue(before), assertFalse(hostExists())])
      })
    ),
    graphTest("its own nodes stay out of the graph it shows", async () => {
      let _ = Devtools.install()
      let _app = Signal.make(0, ~name="app")
      let before = Devtools.snapshot().nodes->Array.length
      let unmount = DevtoolsPanel.mount(~expanded=true, ())
      clickTab("Timeline")
      clickTab("Graph")
      await frame()
      let after = Devtools.snapshot().nodes->Array.length
      unmount()
      Devtools.uninstall()
      assertEqual(after, before)
    }),
    asyncTest("an idle panel emits nothing of its own", async () =>
      await withPanel(async _ => {
        let app = Signal.make(0)
        Signal.set(app, 1)
        await frame()
        let seen = []
        let unsubscribe = Devtools.subscribe(event => seen->Array.push(event)->ignore)
        await frame()
        await frame()
        await frame()
        unsubscribe()
        assertEqual(Array.length(seen), 0)
      })
    ),
    graphTest("the app's writes reach the timeline", async () =>
      await withPanel(async _ => {
        let count = Signal.make(0, ~name="clicks")
        clickTab("Timeline")
        Signal.set(count, 1)
        await frame()
        let entries = shadowTexts(".entry.write")
        assertTrue(
          entries->Array.some(text => text->String.startsWith(`write signal "clicks" = 1`)),
          ~message=entries->Array.join(" | "),
        )
      })
    ),
    graphTest("selecting a node explains why it last ran", async () =>
      await withPanel(async _ => {
        let count = Signal.make(1, ~name="base")
        let doubled = Computed.make(() => Signal.get(count) * 2, ~name="twice")
        Effect.run(
          () => {
            let _ = Signal.get(doubled)
            None
          },
          ~name="reader",
        )
        Signal.set(count, 2)
        await frame()
        let rows: array<
          element,
        > = %raw(`Array.from(document.getElementById("xote-devtools").shadowRoot.querySelectorAll(".row"))`)
        let reader = rows->Array.find(row => textOf(row)->String.includes(`"reader"`))
        reader->Option.forEach(click)
        await frame()
        let causes = shadowTexts(".why .cause")
        combineResults([
          assertTrue(reader->Option.isSome, ~message="the effect is listed"),
          assertEqual(
            causes,
            [`effect "reader" ran`, `computed "twice" recomputed`, `signal "base" written`],
          ),
        ])
      })
    ),
  ],
)
