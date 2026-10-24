open! Zekr

/* The graph half of these tests needs a `rescript-signals` with debug hooks;
   against one without, those tests report as skipped rather than passing
   vacuously. */

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"

exception Boom

let graphVisible = {
  let visible = Devtools.install().signals
  Devtools.uninstall()
  visible
}

let silencingWarnings: (unit => 'a) => 'a = %raw(`function (fn) {
  const warn = console.warn
  console.warn = function () {}
  try { return fn() } finally { console.warn = warn }
}`)

/* Each test installs afresh, so ids start at 1 and nothing leaks between tests. */
let devtoolsTest = (name, fn: unit => testResult) =>
  test(name, () => {
    let _ = Devtools.install()
    switch fn() {
    | result =>
      Devtools.uninstall()
      result
    | exception exn =>
      Devtools.uninstall()
      throw(exn)
    }
  })

let graphTest = (name, fn) =>
  graphVisible ? devtoolsTest(name, fn) : testSkip(name, () => assertTrue(true))

let mount = node => {
  let {container} = Dom.render("")
  View.mount(node, container)
  container
}

let find = (container, selector) =>
  querySelector(container, selector)->Nullable.toOption->Option.getOrThrow

let list = (items: Signal.t<array<string>>) =>
  Html.ul(
    ~children=[
      View.eachWithKey(items, item => item, item => Html.li(~children=[View.text(item)], ())),
    ],
    (),
  )

let paragraph = (read: unit => string) => Html.p(~children=[View.signalText(read)], ())

/* A keyed list of `initial`, then the budget of setting it to `next`. */
let keyedBudget = (name, initial, next, ~effects, ~scopesCreated, ~scopesDisposed, ~domWrites=?) =>
  graphTest(`keyed list budget: ${name}`, () => {
    let items = Signal.make(initial)
    let _ = mount(list(items))
    let trace = Devtools.record(() => Signal.set(items, next))
    assertEqual(
      Devtools.Budget.check(trace, ~effects, ~scopesCreated, ~scopesDisposed, ~domWrites?),
      Ok(),
    )
  })

let rec flatten = (cause: Devtools.cause): array<string> =>
  [`${cause.name->Option.getOr(Int.toString(cause.id))}:${(cause.action :> string)}`]->Array.concat(
    cause.causes->Array.flatMap(flatten),
  )

let leakReasons = () => Devtools.leaks()->Array.map(leak => (leak.name, leak.reason))

module Leaky = {
  /* Uses `rescript-signals` directly, which does not register the effect with
   the row rendering it: removing the row leaves it running. */
  @jsx.component
  let make = (~ticks: Signal.t<int>) => {
    Signals.Effect.run(() => {
      let _ = Signal.get(ticks)
      None
    }, ~name="leaky")
    <span> {View.text("row")} </span>
  }
}

module Fails = {
  @jsx.component
  let make = () => throw(Boom)
}

let suite = Zekr.suite(
  "Devtools",
  [
    devtoolsTest("keyed rows are reported as scopes, and their release with them", () => {
      let items = Signal.make(["a", "b", "c"])
      let _ = mount(list(items))
      Signal.set(items, ["c", "a", "d"])
      let scopes = Devtools.scopes()
      let row = key => scopes->Array.find(scope => scope.key == Some(key))
      combineResults([
        assertEqual(scopes->Array.filter(scope => scope.kind == #list)->Array.length, 1),
        assertEqual(row("b")->Option.map(scope => scope.disposed), Some(true)),
        assertEqual(row("a")->Option.map(scope => scope.disposed), Some(false)),
        assertEqual(row("d")->Option.map(scope => scope.kind), Some(#row)),
      ])
    }),
    devtoolsTest("a keyed pass reports what it kept, created, removed and moved", () => {
      let items = Signal.make(["a", "b", "c"])
      let _ = mount(list(items))
      let trace = Devtools.record(() => Signal.set(items, ["c", "a", "d"]))
      let passes = trace.events->Array.filterMap(event =>
        switch event {
        | Reconciled({kept, created, removed, moved, rebuilt}) =>
          Some((kept, created, removed, moved, rebuilt))
        | _ => None
        }
      )
      assertEqual(passes, [(2, 1, 1, 1, 0)])
    }),
    devtoolsTest("a binding's DOM write is reported with a path to its node", () => {
      let label = Signal.make("one")
      let _ = mount(paragraph(() => Signal.get(label)))
      let trace = Devtools.record(() => Signal.set(label, "two"))
      let writes = trace.events->Array.filterMap(event =>
        switch event {
        | DomWrite({what, target}) => Some((what, target->String.endsWith("p")))
        | _ => None
        }
      )
      assertEqual(writes, [("text", true)])
    }),
    devtoolsTest("probes and caught failures are reported", () => {
      let count = Signal.make(1)
      let _ = silencingWarnings(() => View.probe("Devtools_test.res:1:1", () => Signal.get(count)))
      let _ = mount(
        <View.ErrorBoundary fallback={(_, _) => View.text("fallback")}>
          <Fails />
        </View.ErrorBoundary>,
      )
      let reported = Devtools.history()->Array.filterMap(event =>
        switch event {
        | Probe({site, hidden}) => Some(`probe ${site} ${hidden ? "hidden" : "visible"}`)
        | Caught(_) => Some("caught")
        | _ => None
        }
      )
      assertEqual(reported, ["probe Devtools_test.res:1:1 hidden", "caught"])
    }),
    graphTest("a text update costs one write, one computed, one binding and one DOM write", () => {
      let count = Signal.make(0, ~name="count")
      let _ = mount(paragraph(() => Int.toString(Signal.get(count))))
      let trace = Devtools.record(() => Signal.set(count, 1))
      combineResults([
        assertEqual(
          Devtools.Budget.check(
            trace,
            ~writes=1,
            ~computeds=1,
            ~effects=1,
            ~bindings=1,
            ~domWrites=1,
          ),
          Ok(),
        ),
        assertEqual(
          Devtools.Budget.check(trace, ~effects=0, ~domWrites=0, ~writes=1),
          Error("effects: expected 0, got 1; domWrites: expected 0, got 1"),
        ),
      ])
    }),
    /* Each keyed list operation touches exactly the rows it changes; the list's
     own binding runs once per update. */
    keyedBudget(
      "appending builds one row and touches no other",
      ["a", "b", "c"],
      ["a", "b", "c", "d"],
      ~effects=1,
      ~scopesCreated=1,
      ~scopesDisposed=0,
      ~domWrites=0,
    ),
    keyedBudget(
      "removing releases one row and builds none",
      ["a", "b", "c"],
      ["a", "c"],
      ~effects=1,
      ~scopesCreated=0,
      ~scopesDisposed=1,
    ),
    keyedBudget(
      "swapping two rows builds and releases nothing",
      ["a", "b", "c", "d"],
      ["a", "c", "b", "d"],
      ~effects=1,
      ~scopesCreated=0,
      ~scopesDisposed=0,
    ),
    keyedBudget(
      "replacing every key rebuilds every row",
      ["a", "b", "c"],
      ["x", "y", "z"],
      ~effects=1,
      ~scopesCreated=3,
      ~scopesDisposed=3,
    ),
    graphTest("keyed list budget: a row's own signal updates that row alone", () => {
      let labels = ["a", "b", "c"]->Array.map(label => (label, Signal.make(label)))
      let _ = mount(
        Html.ul(
          ~children=[
            View.eachWithKey(
              Signal.make(labels),
              ((key, _)) => key,
              ((_, label)) => Html.li(~children=[View.signalText(() => Signal.get(label))], ()),
            ),
          ],
          (),
        ),
      )
      let (_, second) = labels->Array.getUnsafe(1)
      let trace = Devtools.record(() => Signal.set(second, "B"))
      assertEqual(
        Devtools.Budget.check(
          trace,
          ~writes=1,
          ~computeds=1,
          ~effects=1,
          ~bindings=1,
          ~domWrites=1,
          ~scopesCreated=0,
          ~scopesDisposed=0,
        ),
        Ok(),
      )
    }),
    graphTest("why traces a DOM update back to the write that caused it", () => {
      let first = Signal.make("Ada", ~name="first")
      let last = Signal.make("Lovelace", ~name="last")
      let full = Computed.make(() => Signal.get(first) ++ " " ++ Signal.get(last), ~name="full")
      let container = mount(paragraph(() => Signal.get(full)))
      Signal.set(last, "Byron")
      let writer = Devtools.writersOf(find(container, "p"))->Array.get(0)
      switch writer->Option.flatMap(Devtools.why)->Option.map(flatten) {
      | Some([binding, leaf, "full:recomputed", "last:written"]) =>
        combineResults([
          assertTrue(binding->String.endsWith(":ran")),
          assertTrue(leaf->String.endsWith(":recomputed")),
        ])
      | other =>
        assertEqual(
          other,
          Some(["<binding>:ran", "<leaf>:recomputed", "full:recomputed", "last:written"]),
        )
      }
    }),
    graphTest("the first run of a node is explained as its creation", () => {
      let count = Signal.make(0, ~name="count")
      let _ = Computed.make(() => Signal.get(count) * 2, ~name="doubled")
      let doubled = Devtools.snapshot().nodes->Array.find(node => node.name == Some("doubled"))
      assertEqual(
        doubled->Option.flatMap(node => Devtools.why(node.id))->Option.map(cause => cause.action),
        Some(#created),
      )
    }),
    graphTest("snapshot reports values, edges, scopes and bindings", () => {
      let count = Signal.make(41, ~name="count")
      let _ = mount(paragraph(() => Int.toString(Signal.get(count) + 1)))
      let snapshot = Devtools.snapshot()
      let counter = snapshot.nodes->Array.find(node => node.name == Some("count"))
      let binding = snapshot.nodes->Array.find(node => node.binding->Option.isSome)
      combineResults([
        assertEqual(counter->Option.flatMap(node => node.value), Some("41")),
        assertEqual(counter->Option.map(node => Array.length(node.observers)), Some(1)),
        assertEqual(
          binding->Option.flatMap(node => node.binding)->Option.map(b => b.what),
          Some("text"),
        ),
        assertEqual(binding->Option.map(node => node.kind), Some(#effect)),
      ])
    }),
    graphTest("an effect that outlives its row is reported as a leak", () => {
      let ticks = Signal.make(0)
      let rows = Signal.make(["a"])
      let _ = mount(
        Html.div(~children=[View.eachWithKey(rows, row => row, _ => <Leaky ticks />)], ()),
      )
      let before = leakReasons()
      Signal.set(rows, [])
      combineResults([
        assertEqual(before, []),
        assertEqual(leakReasons(), [(Some("leaky"), #effectOutlivedScope)]),
      ])
    }),
    graphTest("an effect created inside another effect's run, under no scope, is reported", () => {
      let trigger = Signal.make(0)
      Effect.run(() => {
        let _ = Signal.get(trigger)
        Effect.run(() => None, ~name="inner")
        None
      }, ~name="outer")
      assertEqual(leakReasons(), [(Some("inner"), #unownedEffect)])
    }),
    graphTest("what a muted function creates stays out of snapshots and traces", () => {
      let count = Signal.make(0, ~name="visible")
      let hidden = Devtools.mute(() => {
        let hidden = Signal.make(0, ~name="hidden")
        Effect.run(
          () => {
            let _ = Signal.get(hidden)
            None
          },
          ~name="hidden-effect",
        )
        hidden
      })
      let trace = Devtools.record(() => {
        Signal.set(hidden, 1)
        Signal.set(count, 1)
      })
      combineResults([
        assertEqual(Devtools.snapshot().nodes->Array.filterMap(node => node.name), ["visible"]),
        assertEqual(trace.counts.writes, 1),
        assertEqual(trace.counts.effects, 0),
      ])
    }),
  ],
)
