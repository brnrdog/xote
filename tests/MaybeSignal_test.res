open! Zekr

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let suite = Zekr.suite(
  "MaybeSignal",
  [
    test("get reads both static and reactive values", () => {
      let count = Signal.make(1)
      let staticValue = MaybeSignal.static(41)
      let reactiveValue = MaybeSignal.reactive(count)

      let before = MaybeSignal.get(reactiveValue)
      Signal.set(count, 2)

      combineResults([
        assertEqual(MaybeSignal.get(staticValue), 41),
        assertEqual(before, 1),
        assertEqual(MaybeSignal.get(reactiveValue), 2),
      ])
    }),
    test("signal is an alias of reactive", () => {
      let name = Signal.make("xote")

      combineResults([
        assertEqual(MaybeSignal.get(MaybeSignal.signal(name)), "xote"),
        assertTrue(MaybeSignal.isReactive(MaybeSignal.signal(name))),
      ])
    }),
    test("peek reads without tracking", () => {
      let count = Signal.make(0)
      let value = MaybeSignal.reactive(count)
      let runs = ref(0)

      Effect.run(() => {
        runs := runs.contents + 1
        ignore(MaybeSignal.peek(value))
        None
      })

      let runsAfterFirst = runs.contents
      Signal.set(count, 1)

      combineResults([
        assertEqual(runsAfterFirst, 1),
        assertEqual(runs.contents, 1),
        assertEqual(MaybeSignal.peek(value), 1),
      ])
    }),
    test("isStatic and isReactive classify the variants", () => {
      let count = Signal.make(0)

      combineResults([
        assertTrue(MaybeSignal.isStatic(MaybeSignal.static(0))),
        assertFalse(MaybeSignal.isReactive(MaybeSignal.static(0))),
        assertTrue(MaybeSignal.isReactive(MaybeSignal.reactive(count))),
        assertFalse(MaybeSignal.isStatic(MaybeSignal.reactive(count))),
      ])
    }),
    test("map preserves staticness and stays reactive", () => {
      let count = Signal.make(2)
      let doubledStatic = MaybeSignal.static(2)->MaybeSignal.map(n => n * 2)
      let doubledReactive = MaybeSignal.reactive(count)->MaybeSignal.map(n => n * 2)

      let before = MaybeSignal.get(doubledReactive)
      Signal.set(count, 5)

      combineResults([
        assertTrue(MaybeSignal.isStatic(doubledStatic)),
        assertEqual(MaybeSignal.get(doubledStatic), 4),
        assertTrue(MaybeSignal.isReactive(doubledReactive)),
        assertEqual(before, 4),
        assertEqual(MaybeSignal.get(doubledReactive), 10),
      ])
    }),
    test("toSignal normalizes both variants to a signal", () => {
      let count = Signal.make(3)
      let fromStatic = MaybeSignal.static(7)->MaybeSignal.toSignal
      let fromReactive = MaybeSignal.reactive(count)->MaybeSignal.toSignal

      Signal.set(count, 4)

      combineResults([
        assertEqual(Signal.get(fromStatic), 7),
        assertEqual(Signal.get(fromReactive), 4),
      ])
    }),
    test("works as a JSX prop on View primitives", () => {
      let {container} = Dom.render("")
      let label = Signal.make("Ada")
      let _ = mountTo(
        <p>
          <View.Text value={MaybeSignal.static("Hello, ")} />
          <View.Text value={MaybeSignal.signal(label)} />
        </p>,
        container,
      )

      let before = Zekr__DomBindings.textContent(container)
      Signal.set(label, "Grace")

      combineResults([
        assertEqual(before, "Hello, Ada"),
        assertEqual(Zekr__DomBindings.textContent(container), "Hello, Grace"),
      ])
    }),
    /* Prop is deprecated but must stay interchangeable with MaybeSignal. */
    test("deprecated Prop module is an alias of MaybeSignal", () => {
      @warning("-3")
      let fromProp: MaybeSignal.t<string> = Prop.static("legacy")
      @warning("-3")
      let fromMaybeSignal: Prop.t<string> = MaybeSignal.static("legacy")
      @warning("-3")
      let read = Prop.get(MaybeSignal.static("legacy"))

      combineResults([
        assertEqual(MaybeSignal.get(fromProp), "legacy"),
        assertEqual(MaybeSignal.get(fromMaybeSignal), "legacy"),
        assertEqual(read, "legacy"),
      ])
    }),
  ],
)
