/* Before `open! Zekr`, whose `Dom` shadows the standard one. */
type domElement = Dom.element

open! Zekr

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
@get external isConnected: domElement => bool = "isConnected"

let querySelectorAll: ('a, string) => array<domElement> = %raw(`function (container, selector) {
  return Array.from(container.querySelectorAll(selector))
}`)

/* Live subscriber links of a signal: what a leaked effect leaves behind. */
let subscriberCount: Signal.t<'a> => int = %raw(`function (signal) {
  let count = 0
  let link = signal.subs.first
  while (link) { count = count + 1; link = link.nextSub }
  return count
}`)

let find = (container, selector): domElement =>
  querySelector(container, selector)->Nullable.toOption->Option.getOrThrow

let has = (container, selector) => querySelector(container, selector)->Nullable.toOption->Option.isSome

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

exception Boom

/* Records what its ref and its `onMount` saw, and its cleanup. */
module Probe = {
  @jsx.component
  let make = (~log: array<string>, ~name: string="probe") => {
    let field = View.Ref.make()
    View.onMount(() => {
      let connected = View.Ref.peek(field)->Option.mapOr(false, isConnected)
      log->Array.push(name ++ ":mount:" ++ (connected ? "connected" : "detached"))->ignore
      View.onCleanup(() => log->Array.push(name ++ ":cleanup-from-mount")->ignore)
    })
    View.onCleanup(() => log->Array.push(name ++ ":cleanup")->ignore)
    <input ref=field class=name />
  }
}

module Parent = {
  @jsx.component
  let make = (~log: array<string>) => {
    View.onMount(() => log->Array.push("parent:mount")->ignore)
    <div> <Probe log name="child" /> </div>
  }
}

/* An effect set up in `onMount` belongs to the component. */
module Listener = {
  @jsx.component
  let make = (~ticks: Signal.t<int>) => {
    View.onMount(() =>
      Effect.run(() => {
        let _ = Signal.get(ticks)
        None
      })
    )
    <span />
  }
}

let theme = Context.make("light")

module ThemeReader = {
  @jsx.component
  let make = (~seen: ref<string>) => {
    View.onMount(() => seen := Context.use(theme))
    <span />
  }
}

module FailingMount = {
  @jsx.component
  let make = () => {
    View.onMount(() => throw(Boom))
    <span class="mounted" />
  }
}

module Fragile = {
  @jsx.component
  let make = () => throw(Boom)
}

/* A keyed row that logs its lifecycle; `fails` makes it throw after its body
   has scheduled everything. */
module LoggedRow = {
  @jsx.component
  let make = (~id: int, ~fails: bool, ~log: array<string>) => {
    let name = "row" ++ Int.toString(id)
    View.onMount(() => {
      log->Array.push(name ++ ":mount")->ignore
      View.onCleanup(() => log->Array.push(name ++ ":cleanup-from-mount")->ignore)
    })
    View.onCleanup(() => log->Array.push(name ++ ":cleanup")->ignore)
    fails ? throw(Boom) : <li />
  }
}

/* Schedules an onMount, then fails to render. */
module MountsThenFails = {
  @jsx.component
  let make = (~log: array<string>) => {
    View.onMount(() => log->Array.push("bad:mount")->ignore)
    throw(Boom)
  }
}

module CleansUp = {
  @jsx.component
  let make = (~log: array<string>) => {
    View.onCleanup(() => log->Array.push("cleanup")->ignore)
    <Fragile />
  }
}

module Logs = {
  @jsx.component
  let make = (~name: string, ~log: array<string>, ~fails: bool=false) => {
    View.onMount(() => {
      log->Array.push(name)->ignore
      if fails {
        throw(Boom)
      }
    })
    <span />
  }
}

let withoutDocument: (unit => unit) => unit = %raw(`function (fn) {
  const saved = globalThis.document
  delete globalThis.document
  try { fn() } finally { globalThis.document = saved }
}`)

let suite = Zekr.suite(
  "Refs and lifecycle",
  [
    test("onMount runs once, after the DOM is in the document", () => {
      let {container} = Dom.render("")
      let log = []
      let _ = mountTo(<Probe log />, container)
      assertEqual(log, ["probe:mount:connected"])
    }),
    test("a ref holds its element once mounted", () => {
      let {container} = Dom.render("")
      let field = View.Ref.make()
      let before = View.Ref.peek(field)
      let _ = mountTo(<div> <input ref=field class="field" /> </div>, container)
      combineResults([
        assertTrue(before->Option.isNone),
        assertTrue(
          View.Ref.peek(field)->Option.mapOr(false, element => element === find(container, ".field")),
        ),
      ])
    }),
    test("a parent's onMount sees every ref below it", () => {
      let {container} = Dom.render("")
      let field = View.Ref.make()
      let seen = ref(false)
      let _ = mountTo(
        View.LazyComponent(
          () => {
            View.onMount(() => seen := View.Ref.peek(field)->Option.isSome)
            <section> <div> <input ref=field /> </div> </section>
          },
        ),
        container,
      )
      assertTrue(seen.contents)
    }),
    test("hooks run for a component shown on a later update, and cleanups when it goes", () => {
      let {container} = Dom.render("")
      let log = []
      let visible = Signal.make(false)
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(visible)}> <Probe log /> </View.Show>,
        container,
      )
      Signal.set(visible, true)
      let shown = Array.copy(log)
      Signal.set(visible, false)
      combineResults([
        assertEqual(shown, ["probe:mount:connected"]),
        assertEqual(
          log,
          ["probe:mount:connected", "probe:cleanup", "probe:cleanup-from-mount"],
        ),
      ])
    }),
    test("a ref is cleared when its element is removed, and get is reactive", () => {
      let {container} = Dom.render("")
      let field = View.Ref.make()
      let visible = Signal.make(true)
      let seen = []
      Effect.run(() => {
        seen->Array.push(View.Ref.get(field)->Option.isSome)->ignore
        None
      })
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(visible)}> <input ref=field /> </View.Show>,
        container,
      )
      Signal.set(visible, false)
      assertEqual(seen, [false, true, false])
    }),
    test("a callback ref is called with the element once it is in the document", () => {
      let {container} = Dom.render("")
      let calls = []
      let canvas = View.Ref.fromCallback(element => calls->Array.push(isConnected(element))->ignore)
      let _ = mountTo(<div> <canvas ref=canvas /> </div>, container)
      assertEqual(calls, [true])
    }),
    test("parents mount before children, after the whole tree is inserted", () => {
      let {container} = Dom.render("")
      let log = []
      let _ = mountTo(<Parent log />, container)
      assertEqual(log, ["parent:mount", "child:mount:connected"])
    }),
    test("an effect set up in onMount is released with the component", () => {
      let {container} = Dom.render("")
      let ticks = Signal.make(0)
      let visible = Signal.make(true)
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(visible)}> <Listener ticks /> </View.Show>,
        container,
      )
      let mounted = subscriberCount(ticks)
      Signal.set(visible, false)
      combineResults([assertEqual(mounted, 1), assertEqual(subscriberCount(ticks), 0)])
    }),
    test("keyed rows, cloned or not, each get their own element and onMount", () => {
      let {container} = Dom.render("")
      let ids = Signal.make(["a"])
      let log = []
      let _ = mountTo(
        <ul>
          <View.For
            each={MaybeSignal.reactive(ids)}
            by={id => id}
            render={id => <li> <Probe log name=id /> </li>}
          />
        </ul>,
        container,
      )
      Signal.set(ids, ["a", "b", "c", "d"])
      combineResults([
        assertEqual(
          log,
          ["a:mount:connected", "b:mount:connected", "c:mount:connected", "d:mount:connected"],
        ),
        assertEqual(querySelectorAll(container, "input")->Array.length, 4),
      ])
    }),
    test("onMount runs under the component's context", () => {
      let {container} = Dom.render("")
      let seen = ref("")
      let _ = mountTo(
        <Context.Provider context=theme value="dark"> <ThemeReader seen /> </Context.Provider>,
        container,
      )
      assertEqual(seen.contents, "dark")
    }),
    test("a subtree an error boundary replaced never mounts, but its body cleans up", () => {
      let {container} = Dom.render("")
      let log = []
      let _ = mountTo(
        <View.ErrorBoundary fallback={(_, _) => <span class="fallback" />}>
          <Probe log />
          <Fragile />
        </View.ErrorBoundary>,
        container,
      )
      /* The body ran, so what it registered with onCleanup runs; onMount never
         did, so neither does the cleanup it would have registered. */
      combineResults([assertEqual(log, ["probe:cleanup"]), assertTrue(has(container, ".fallback"))])
    }),
    test("rows of a keyed list that fails its first render never mount, and clean up", () => {
      let {container} = Dom.render("")
      let log = []
      let shown = Signal.make(true)
      let rows = Signal.make([1, 2])
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(shown)}>
          <View.ErrorBoundary fallback={(_, _) => <p class="fallback" />}>
            <ul>
              {View.eachWithKey(rows, id => Int.toString(id), id => <LoggedRow id fails={id == 2} log />)}
            </ul>
          </View.ErrorBoundary>
        </View.Show>,
        container,
      )
      let mounted = Array.copy(log)
      let fellBack = has(container, ".fallback")
      Signal.set(shown, false)
      combineResults([
        assertTrue(fellBack),
        assertEqual(mounted, ["row1:cleanup", "row2:cleanup"]),
        assertEqual(log, ["row1:cleanup", "row2:cleanup"]),
      ])
    }),
    test("a nested pass that fails on an update leaves no onMount behind", () => {
      let {container} = Dom.render("")
      let log = []
      let show = Signal.make(false)
      let _ = mountTo(
        <View.ErrorBoundary fallback={(_, _) => <p class="fallback" />}>
          {View.tracked(() =>
            Signal.get(show)
              ? View.tracked(() => <MountsThenFails log />)
              : View.text("waiting")
          )}
        </View.ErrorBoundary>,
        container,
      )
      Signal.set(show, true)
      combineResults([assertEqual(log, []), assertTrue(has(container, ".fallback"))])
    }),
    test("a cleanup runs once when a boundary falls back and is later removed", () => {
      let {container} = Dom.render("")
      let log = []
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(shown)}>
          <View.ErrorBoundary fallback={(_, _) => <p class="fallback" />}>
            <CleansUp log />
          </View.ErrorBoundary>
        </View.Show>,
        container,
      )
      Signal.set(shown, false)
      assertEqual(log, ["cleanup"])
    }),
    test("a failing onMount does not cost the rest of the batch", () => {
      let {container} = Dom.render("")
      let log = []
      let raised = try {
        View.mount(
          <div>
            <Logs name="first" log fails=true />
            <Logs name="second" log />
          </div>,
          container,
        )
        false
      } catch {
      | Boom => true
      }
      combineResults([assertTrue(raised), assertEqual(log, ["first", "second"])])
    }),
    test("a failing ref callback does not hold back the mounts", () => {
      let {container} = Dom.render("")
      let log = []
      let broken = View.Ref.fromCallback(_ => throw(Boom))
      let raised = try {
        View.mount(<div> <input ref=broken /> <Logs name="mounted" log /> </div>, container)
        false
      } catch {
      | Boom => true
      }
      combineResults([assertTrue(raised), assertEqual(log, ["mounted"])])
    }),
    test("an eager component's onMount waits for its own mount, not an unrelated update", () => {
      let {container} = Dom.render("")
      let field = View.Ref.make()
      let seen = []
      let unrelated = Signal.make(0)
      let _ = mountTo(
        <div> {View.tracked(() => View.int(Signal.get(unrelated)))} </div>,
        Dom.render("").container,
      )
      let app = () => {
        View.onMount(() => seen->Array.push(View.Ref.peek(field)->Option.mapOr(false, isConnected))->ignore)
        View.element("input", ~ref=field, ())
      }
      let node = app()
      Signal.set(unrelated, 1)
      let afterUpdate = Array.copy(seen)
      View.mount(node, container)
      combineResults([assertEqual(afterUpdate, []), assertEqual(seen, [true])])
    }),
    test("nothing is scheduled where there is no document", () => {
      let {container} = Dom.render("")
      let ran = ref(false)
      withoutDocument(() => View.onMount(() => ran := true))
      View.mount(<div />, container)
      assertFalse(ran.contents)
    }),
    test("a failing onMount goes to the error boundary", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <View.ErrorBoundary fallback={(_, _) => <span class="fallback" />}>
          <FailingMount />
        </View.ErrorBoundary>,
        container,
      )
      combineResults([assertTrue(has(container, ".fallback")), assertFalse(has(container, ".mounted"))])
    }),
    test("a component called eagerly still mounts after its DOM is inserted", () => {
      let {container} = Dom.render("")
      let field = View.Ref.make()
      let connected = ref(false)
      let app = () => {
        View.onMount(() => connected := View.Ref.peek(field)->Option.mapOr(false, isConnected))
        View.element("input", ~ref=field, ())
      }
      View.mount(app(), container)
      assertTrue(connected.contents)
    }),
    test("server rendering runs no hooks; hydration hands over the server's elements", () => {
      let log = []
      let field = View.Ref.make()
      let component = () =>
        <div>
          <Probe log />
          <input ref=field class="hydrated" />
        </div>
      let html = SSR.renderToString(component)
      let afterServer = (Array.copy(log), View.Ref.peek(field)->Option.isNone)
      let {container} = Dom.render(html)
      let serverElement = find(container, ".hydrated")
      Hydration.hydrate(component, container)
      combineResults([
        assertEqual(afterServer, ([], true)),
        assertEqual(log, ["probe:mount:connected"]),
        assertTrue(View.Ref.peek(field)->Option.mapOr(false, element => element === serverElement)),
      ])
    }),
  ],
)
