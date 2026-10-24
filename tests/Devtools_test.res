open! Zekr

/* Devtools observes two streams: the renderer's (scopes, DOM writes, keyed
   passes), which Xote emits itself, and the reactive graph, which comes from
   the debug hooks of `rescript-signals`. The graph half needs a release of
   `rescript-signals` that has them; against one that predates them those tests
   report as skipped rather than passing vacuously. */

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"

exception Boom

let graphVisible = {
  let visible = Devtools.install().signals
  Devtools.uninstall()
  visible
}

let graphTest = (name, run) => graphVisible ? test(name, run) : testSkip(name, run)

let silencingWarnings: (unit => 'a) => 'a = %raw(`function (fn) {
  const warn = console.warn
  console.warn = function () {}
  try { return fn() } finally { console.warn = warn }
}`)

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let find = (container, selector) =>
  querySelector(container, selector)->Nullable.toOption->Option.getOrThrow

/* Install for one test, so ids start at 1 and nothing leaks between tests. */
let withDevtools = (fn: unit => testResult): testResult => {
  let _ = Devtools.install()
  try {
    let result = fn()
    Devtools.uninstall()
    result
  } catch {
  | exn =>
    Devtools.uninstall()
    throw(exn)
  }
}

let list = (items: Signal.t<array<string>>) =>
  Html.ul(
    ~children=[
      View.eachWithKey(items, item => item, item => Html.li(~children=[View.text(item)], ())),
    ],
    (),
  )

let rec flatten = (cause: Devtools.cause): array<string> =>
  [`${cause.name->Option.getOr(Int.toString(cause.id))}:${(cause.action :> string)}`]->Array.concat(
    cause.causes->Array.flatMap(flatten),
  )

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

let suite = Zekr.suite(
  "Devtools",
  [
    test("keyed rows are reported as scopes, and their release with them", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let items = Signal.make(["a", "b", "c"])
        let _ = mountTo(list(items), container)
        Signal.set(items, ["c", "a", "d"])
        let scopes = Devtools.scopes()
        let row = key => scopes->Array.find(scope => scope.key == Some(key))
        combineResults([
          assertEqual(scopes->Array.filter(scope => scope.kind == #list)->Array.length, 1),
          assertEqual(row("b")->Option.map(scope => scope.disposed), Some(true)),
          assertEqual(row("a")->Option.map(scope => scope.disposed), Some(false)),
          assertEqual(row("d")->Option.map(scope => scope.kind), Some(#row)),
        ])
      })
    ),
    test("a keyed pass reports what it kept, created, removed and moved", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let items = Signal.make(["a", "b", "c"])
        let _ = mountTo(list(items), container)
        let trace = Devtools.record(() => Signal.set(items, ["c", "a", "d"]))
        let passes = trace.events->Array.filterMap(
          event =>
            switch event {
            | Reconciled({kept, created, removed, moved, rebuilt}) =>
              Some((kept, created, removed, moved, rebuilt))
            | _ => None
            },
        )
        assertEqual(passes, [(2, 1, 1, 1, 0)])
      })
    ),
    test("a binding's DOM write is reported with a path to its node", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let label = Signal.make("one")
        let _ = mountTo(Html.p(~children=[View.signalText(() => Signal.get(label))], ()), container)
        let trace = Devtools.record(() => Signal.set(label, "two"))
        let writes = trace.events->Array.filterMap(
          event =>
            switch event {
            | DomWrite({what, target}) => Some((what, target->String.endsWith("p")))
            | _ => None
            },
        )
        assertEqual(writes, [("text", true)])
      })
    ),
    test("a hidden read found by a probe is reported", () =>
      withDevtools(() => {
        let count = Signal.make(1)
        let _ = silencingWarnings(
          () => View.probe("Devtools_test.res:1:1", () => Signal.get(count)),
        )
        let probes = Devtools.history()->Array.filterMap(
          event =>
            switch event {
            | Probe({site, hidden}) => Some((site, hidden))
            | _ => None
            },
        )
        assertEqual(probes, [("Devtools_test.res:1:1", true)])
      })
    ),
    test("a failure an error boundary catches is reported", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        module Fails = {
          @jsx.component
          let make = () => throw(Boom)
        }
        let _ = mountTo(
          <View.ErrorBoundary fallback={(_, _) => View.text("fallback")}>
            <Fails />
          </View.ErrorBoundary>,
          container,
        )
        let caught = Devtools.history()->Array.filter(
          event =>
            switch event {
            | Caught(_) => true
            | _ => false
            },
        )
        assertEqual(Array.length(caught), 1)
      })
    ),
    graphTest("a text update costs one write, one computed, one binding and one DOM write", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let count = Signal.make(0, ~name="count")
        let _ = mountTo(
          Html.p(~children=[View.signalText(() => Int.toString(Signal.get(count)))], ()),
          container,
        )
        let trace = Devtools.record(() => Signal.set(count, 1))
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
        )
      })
    ),
    graphTest("a budget that does not hold names every mismatch", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let count = Signal.make(0)
        let _ = mountTo(
          Html.p(~children=[View.signalText(() => Int.toString(Signal.get(count)))], ()),
          container,
        )
        let trace = Devtools.record(() => Signal.set(count, 1))
        assertEqual(
          Devtools.Budget.check(trace, ~effects=0, ~domWrites=0, ~writes=1),
          Error("effects: expected 0, got 1; domWrites: expected 0, got 1"),
        )
      })
    ),
    graphTest("why traces a DOM update back to the write that caused it", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let first = Signal.make("Ada", ~name="first")
        let last = Signal.make("Lovelace", ~name="last")
        let full = Computed.make(() => Signal.get(first) ++ " " ++ Signal.get(last), ~name="full")
        let _ = mountTo(Html.p(~children=[View.signalText(() => Signal.get(full))], ()), container)
        Signal.set(last, "Byron")
        let writer = Devtools.writerOf(find(container, "p"))
        let chain = writer->Option.flatMap(Devtools.why)->Option.map(flatten)
        switch chain {
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
      })
    ),
    graphTest("the first run of a node is explained as its creation", () =>
      withDevtools(() => {
        let count = Signal.make(0, ~name="count")
        let doubled = Computed.make(() => Signal.get(count) * 2, ~name="doubled")
        let ids =
          Devtools.snapshot().nodes->Array.filterMap(
            node => node.name == Some("doubled") ? Some(node.id) : None,
          )
        let _ = doubled
        assertEqual(
          ids->Array.get(0)->Option.flatMap(Devtools.why)->Option.map(cause => cause.action),
          Some(#created),
        )
      })
    ),
    graphTest("snapshot reports values, edges, scopes and bindings", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let count = Signal.make(41, ~name="count")
        let _ = mountTo(
          Html.p(~children=[View.signalText(() => Int.toString(Signal.get(count) + 1))], ()),
          container,
        )
        let snapshot = Devtools.snapshot()
        let byName = name => snapshot.nodes->Array.find(node => node.name == Some(name))
        let binding = snapshot.nodes->Array.find(node => node.binding->Option.isSome)
        combineResults([
          assertEqual(byName("count")->Option.flatMap(node => node.value), Some("41")),
          assertEqual(byName("count")->Option.map(node => Array.length(node.observers)), Some(1)),
          assertEqual(
            binding->Option.flatMap(node => node.binding)->Option.map(b => b.what),
            Some("text"),
          ),
          assertEqual(binding->Option.map(node => node.kind), Some(#effect)),
        ])
      })
    ),
    graphTest("an effect that outlives its row is reported as a leak", () =>
      withDevtools(() => {
        let {container} = Dom.render("")
        let ticks = Signal.make(0)
        let rows = Signal.make(["a"])
        let _ = mountTo(
          Html.div(~children=[View.eachWithKey(rows, row => row, _ => <Leaky ticks />)], ()),
          container,
        )
        let before = Devtools.leaks()
        Signal.set(rows, [])
        let after = Devtools.leaks()->Array.map(leak => (leak.name, leak.reason))
        combineResults([
          assertEqual(before, []),
          assertEqual(after, [(Some("leaky"), #effectOutlivedScope)]),
        ])
      })
    ),
    graphTest("an effect created inside another effect's run, under no scope, is reported", () =>
      withDevtools(() => {
        let trigger = Signal.make(0)
        Effect.run(
          () => {
            let _ = Signal.get(trigger)
            Effect.run(() => None, ~name="inner")
            None
          },
          ~name="outer",
        )
        let reasons = Devtools.leaks()->Array.map(leak => (leak.name, leak.reason))
        assertEqual(reasons, [(Some("inner"), #unownedEffect)])
      })
    ),
    graphTest("what a muted function creates stays out of snapshots and traces", () =>
      withDevtools(() => {
        let count = Signal.make(0, ~name="visible")
        let hidden = Devtools.mute(
          () => {
            let hidden = Signal.make(0, ~name="hidden")
            Effect.run(
              () => {
                let _ = Signal.get(hidden)
                None
              },
              ~name="hidden-effect",
            )
            hidden
          },
        )
        let trace = Devtools.record(
          () => {
            Signal.set(hidden, 1)
            Signal.set(count, 1)
          },
        )
        let names = Devtools.snapshot().nodes->Array.filterMap(node => node.name)
        combineResults([
          assertEqual(names, ["visible"]),
          assertEqual(trace.counts.writes, 1),
          assertEqual(trace.counts.effects, 0),
        ])
      })
    ),
  ],
)
