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
