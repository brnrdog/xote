open! Zekr

/* Counts the live subscriber links of a signal. Reaching into the
   `rescript-signals` record is deliberate: the leaks these tests guard against
   are invisible from the DOM — the element is gone, the subscription is not. */
let subscriberCount: Signal.t<'a> => int = %raw(`function (signal) {
  let count = 0
  let link = signal.subs.first
  while (link) { count = count + 1; link = link.nextSub }
  return count
}`)

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
@val external objectIs: ('a, 'a) => bool = "Object.is"

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let find = (container, selector) =>
  querySelector(container, selector)->Nullable.toOption->Option.getOrThrow

/* A body read is an ordinary eager evaluation: it happens once, when the
   component runs. What it must *not* do is subscribe whatever region is
   rendering the component. */
module BodyRead = {
  @jsx.component
  let make = (~counter: Signal.t<int>) => {
    let snapshot = Signal.get(counter)->Int.toString
    <span class="snapshot"> {View.text(snapshot)} </span>
  }
}

/* A component whose *root* element carries a reactive attribute: the element's
   own scope and the component's scope land on the same DOM node. */
module ThemedRoot = {
  @jsx.component
  let make = (~theme: Signal.t<string>) => <span class={theme} id="themed" />
}

/* An effect set up while a component renders belongs to that component. */
module Ticker = {
  @jsx.component
  let make = (~ticks: Signal.t<int>, ~runs: ref<int>) => {
    Effect.run(() => {
      runs := runs.contents + 1
      let _ = Signal.get(ticks)
      None
    })
    <span class="ticker" />
  }
}

let suite = Zekr.suite(
  "Ownership",
  [
    test("a component body read does not subscribe the enclosing region", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let counter = Signal.make(0)
      let _ = mountTo(
        <div>
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <BodyRead counter={counter} />
          </View.Show>
        </div>,
        container,
      )
      let before = find(container, ".snapshot")
      Signal.set(counter, 1)
      let after = find(container, ".snapshot")
      combineResults([
        /* the region did not rebuild */
        assertTrue(objectIs(before, after)),
        /* and the read stayed the one-shot read it reads as */
        assertEqual(Zekr__DomBindings.textContent(after), "0"),
      ])
    }),
    test("a component body read leaves the region subscribed to its own condition", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let counter = Signal.make(0)
      let _ = mountTo(
        <div>
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <BodyRead counter={counter} />
          </View.Show>
        </div>,
        container,
      )
      Signal.set(visible, false)
      let hidden = querySelector(container, ".snapshot")->Nullable.toOption
      Signal.set(visible, true)
      combineResults([
        assertTrue(hidden->Option.isNone),
        assertEqual(
          Zekr__DomBindings.textContent(find(container, ".snapshot")),
          "0",
        ),
      ])
    }),
    test("an effect created in a component body is disposed with the component", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let ticks = Signal.make(0)
      let runs = ref(0)
      let _ = mountTo(
        <div>
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <Ticker ticks={ticks} runs={runs} />
          </View.Show>
        </div>,
        container,
      )
      /* Remounting used to stack a new effect on top of every previous one. */
      Signal.set(visible, false)
      Signal.set(visible, true)
      Signal.set(visible, false)
      Signal.set(visible, true)
      let mounted = subscriberCount(ticks)
      let before = runs.contents
      Signal.set(ticks, 1)
      let afterOneWrite = runs.contents - before
      Signal.set(visible, false)
      let stopped = runs.contents
      Signal.set(ticks, 2)
      combineResults([
        assertEqual(mounted, 1),
        assertEqual(afterOneWrite, 1),
        assertEqual(runs.contents, stopped),
        assertEqual(subscriberCount(ticks), 0),
      ])
    }),
    test("an effect created outside a render is not owned by anything", () => {
      let ticks = Signal.make(0)
      let runs = ref(0)
      let disposer = Effect.runWithDisposer(() => {
        runs := runs.contents + 1
        let _ = Signal.get(ticks)
        None
      })
      Signal.set(ticks, 1)
      let live = runs.contents
      disposer.dispose()
      Signal.set(ticks, 2)
      combineResults([assertEqual(live, 2), assertEqual(runs.contents, 2)])
    }),
    test("a component's root element releases its attribute effect on unmount", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let theme = Signal.make("light")
      let _ = mountTo(
        <div>
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <ThemedRoot theme={theme} />
          </View.Show>
        </div>,
        container,
      )
      let whileMounted = subscriberCount(theme)
      Signal.set(visible, false)
      combineResults([
        assertEqual(whileMounted, 1),
        /* the component's own scope used to overwrite the element's, so the
           attribute effect was never disposed */
        assertEqual(subscriberCount(theme), 0),
      ])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
