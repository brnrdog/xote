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

/* An effect that registers a cleanup, and whose read sits behind a computed
   chain over the same signal that mounts it — so the write that unmounts the
   component also schedules this effect, and the disposed effect's leftover
   run lands after its cleanup has already run. */
module Closer = {
  @jsx.component
  let make = (~depth: Signal.t<int>, ~runs: ref<int>, ~cleanups: ref<int>) => {
    Effect.run(() => {
      runs := runs.contents + 1
      let _ = Signal.get(depth)
      Some(() => cleanups := cleanups.contents + 1)
    })
    <span class="closer" />
  }
}

exception RenderFailed

let detachById: string => unit = %raw(`function (id) {
  const node = document.getElementById(id)
  if (node !== null) { node.remove() }
}`)

/* A row that records its own disposal, and — for one of them — detaches a
   *later* sibling while doing so. Disposal walks the tree, so a cleanup that
   mutates it mid-walk must not cost the remaining siblings their disposal. */
module Sibling = {
  @jsx.component
  let make = (~name: string, ~log: array<string>, ~detaches: string="") => {
    Effect.run(() => Some(
      () => {
        log->Array.push(name)->ignore
        if detaches != "" {
          detachById(detaches)
        }
      },
    ))
    <span id={name} />
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
    test("a tracked block releases the leaf computeds it rebuilds", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let counter = Signal.make(0)
      let _ = mountTo(
        Html.div(
          ~children=[
            View.tracked(() =>
              if Signal.get(visible) {
                Html.span(
                  ~children=[View.signalText(() => Signal.get(counter)->Int.toString)],
                  (),
                )
              } else {
                View.null()
              }
            ),
          ],
          (),
        ),
        container,
      )
      let mounted = subscriberCount(counter)
      /* Each rebuild used to leave its leaf computed linked to `counter`, so
         the subscriber list grew for as long as the block kept toggling. */
      [1, 2, 3, 4, 5]->Array.forEach(_ => {
        Signal.set(visible, false)
        Signal.set(visible, true)
      })
      let afterToggles = subscriberCount(counter)
      Signal.set(visible, false)
      combineResults([
        assertEqual(mounted, 1),
        assertEqual(afterToggles, 1),
        assertEqual(subscriberCount(counter), 0),
      ])
    }),
    test("a computed the consumer built is left alone", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let counter = Signal.make(1)
      let doubled = Computed.make(() => Signal.get(counter) * 2)
      let _ = mountTo(
        Html.div(
          ~children=[
            View.tracked(() =>
              if Signal.get(visible) {
                Html.span(~children=[View.child(doubled)], ())
              } else {
                View.null()
              }
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(visible, false)
      Signal.set(counter, 5)
      /* Only the computeds the library allocated for the node are released;
         this one belongs to the caller and still tracks its source. */
      assertEqual(Signal.get(doubled), 10)
    }),
    test("an effect still queued when its region replaces it stays disposed", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      /* The chain gives the class effect a deeper scheduler level than the
         tracked region's effect, so one write to `visible` queues both and
         runs the region first: the region disposes the class effect while its
         own queued run is still waiting. That leftover run used to re-track
         the effect's dependencies and resurrect it — one immortal effect per
         branch swap, each still writing to its detached element. */
      let level1 = Computed.make(() => Signal.get(visible))
      let level2 = Computed.make(() => Signal.get(level1))
      let runs = ref(0)
      let _ = mountTo(
        Html.div(
          ~children=[
            View.tracked(() =>
              if Signal.get(visible) {
                Html.span(
                  ~attrs=[
                    View.computedAttr("class", () => {
                      runs := runs.contents + 1
                      Signal.get(level2) ? "on" : "off"
                    }),
                  ],
                  (),
                )
              } else {
                View.null()
              }
            ),
          ],
          (),
        ),
        container,
      )
      [1, 2, 3, 4, 5]->Array.forEach(_ => {
        Signal.set(visible, false)
        Signal.set(visible, true)
      })
      let subscribersAfterToggles = subscriberCount(level2)
      let before = runs.contents
      Signal.set(visible, false)
      Signal.set(visible, true)
      combineResults([
        /* only the live leaf subscribes; zombies grew this by 2 per toggle */
        assertEqual(subscribersAfterToggles, 1),
        /* one cycle runs the class thunk once (the new leaf's initial run) */
        assertEqual(runs.contents - before, 1),
      ])
    }),
    test("an effect's cleanup runs exactly once per run, disposal included", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let level1 = Computed.make(() => Signal.get(visible) ? 1 : 0)
      let level2 = Computed.make(() => Signal.get(level1))
      let runs = ref(0)
      let cleanups = ref(0)
      let _ = mountTo(
        <div>
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <Closer depth={level2} runs={runs} cleanups={cleanups} />
          </View.Show>
        </div>,
        container,
      )
      let mountedRuns = runs.contents
      let mountedCleanups = cleanups.contents
      /* Unmounts the component and schedules its effect in the same flush.
         The disposer runs the cleanup; the leftover queued run must not run
         it a second time, and must not start a new one. */
      Signal.set(visible, false)
      let afterUnmount = (runs.contents, cleanups.contents)
      /* Nothing is listening any more, so a later write changes neither. */
      Signal.set(visible, true)
      Signal.set(visible, false)
      combineResults([
        assertEqual(mountedRuns, 1),
        assertEqual(mountedCleanups, 0),
        /* one cleanup for the one completed run, and no extra run */
        assertEqual(afterUnmount, (1, 1)),
      ])
    }),
    test("disposal reaches every node even when a cleanup detaches a sibling", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(true)
      let log = []
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(visible)}>
          <div>
            <Sibling name="A" log={log} detaches="C" />
            <Sibling name="B" log={log} />
            <Sibling name="C" log={log} />
            <Sibling name="D" log={log} />
          </div>
        </View.Show>,
        container,
      )
      /* Walking the sibling chain live lost everything after the detached node,
         so C and D kept their effects — subscribed, and writing to DOM that is
         no longer in the document. */
      Signal.set(visible, false)
      combineResults([
        assertTrue(log->Array.includes("A")),
        assertTrue(log->Array.includes("B")),
        assertTrue(log->Array.includes("C")),
        assertTrue(log->Array.includes("D")),
      ])
    }),
    test("a render that throws leaves no scope behind", () => {
      let {container} = Dom.render("")
      let raised = ref(false)
      try {
        let _ = mountTo(View.LazyComponent(() => throw(RenderFailed)), container)
      } catch {
      | RenderFailed => raised := true
      }
      /* A scope left dangling here would collect every effect created
         afterwards — anywhere, including outside any render — into an owner
         attached to nothing, so nothing could ever dispose them. */
      combineResults([
        assertTrue(raised.contents),
        assertTrue(RuntimeOwner.currentScope.contents->Option.isNone),
      ])
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
