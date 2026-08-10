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
    test("computed derives a reactive value from a computation", () => {
      let first = Signal.make("Ada")
      let last = Signal.make("Lovelace")
      let full = MaybeSignal.computed(() => Signal.get(first) ++ " " ++ Signal.get(last))

      let before = MaybeSignal.get(full)
      Signal.set(last, "Byron")

      combineResults([
        assertTrue(MaybeSignal.isReactive(full)),
        assertEqual(before, "Ada Lovelace"),
        assertEqual(MaybeSignal.get(full), "Ada Byron"),
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
    test("map runs the function once up front, then lazily", () => {
      let count = Signal.make(2)
      let runs = ref(0)
      let doubled = MaybeSignal.reactive(count)->MaybeSignal.map(n => {
        runs := runs.contents + 1
        n * 2
      })

      let runsBeforeRead = runs.contents
      let value = MaybeSignal.get(doubled)

      combineResults([
        /* Computed.make performs an initial computation to establish deps */
        assertEqual(runsBeforeRead, 1),
        assertEqual(runs.contents, 1),
        assertEqual(value, 4),
      ])
    }),
    test("map stays tracked inside an effect", () => {
      let count = Signal.make(1)
      let doubled = MaybeSignal.reactive(count)->MaybeSignal.map(n => n * 2)
      let seen = ref([])

      Effect.run(() => {
        seen := Array.concat(seen.contents, [MaybeSignal.get(doubled)])
        None
      })

      Signal.set(count, 3)

      assertEqual(seen.contents, [2, 6])
    }),
    test("toSignal returns the source signal for reactive values", () => {
      let count = Signal.make(3)
      let value = MaybeSignal.reactive(count)
      let lifted = value->MaybeSignal.toSignal

      Signal.set(count, 4)

      combineResults([assertTrue(lifted === count), assertEqual(Signal.get(lifted), 4)])
    }),
    test("toSignal lifts static values into a fresh detached signal", () => {
      let value = MaybeSignal.static(7)
      let first = value->MaybeSignal.toSignal
      let second = value->MaybeSignal.toSignal

      Signal.set(first, 99)

      combineResults([
        /* Each call allocates its own signal ... */
        assertFalse(first === second),
        /* ... and writing to it does not reach the original or its siblings */
        assertEqual(Signal.get(first), 99),
        assertEqual(MaybeSignal.get(value), 7),
        assertEqual(Signal.get(second), 7),
      ])
    }),
    test("ofUnknown normalizes raw values, signals, thunks and wrapped values", () => {
      let count = Signal.make(1)
      let fromRaw: MaybeSignal.t<int> = MaybeSignal.ofUnknown(41)
      let fromSignal: MaybeSignal.t<int> = MaybeSignal.ofUnknown(count)
      let fromThunk: MaybeSignal.t<int> = MaybeSignal.ofUnknown(() => Signal.get(count) * 10)
      let fromWrapped: MaybeSignal.t<int> = MaybeSignal.ofUnknown(MaybeSignal.static(7))

      Signal.set(count, 2)

      combineResults([
        assertTrue(MaybeSignal.isStatic(fromRaw)),
        assertEqual(MaybeSignal.get(fromRaw), 41),
        assertTrue(MaybeSignal.isReactive(fromSignal)),
        assertEqual(MaybeSignal.get(fromSignal), 2),
        assertTrue(MaybeSignal.isReactive(fromThunk)),
        assertEqual(MaybeSignal.get(fromThunk), 20),
        assertTrue(MaybeSignal.isStatic(fromWrapped)),
        assertEqual(MaybeSignal.get(fromWrapped), 7),
      ])
    }),
    test("ofUnknown treats a plain object as a value, not a signal", () => {
      let record = {"label": "plain"}
      let value: MaybeSignal.t<{"label": string}> = MaybeSignal.ofUnknown(record)

      combineResults([
        assertTrue(MaybeSignal.isStatic(value)),
        assertEqual(MaybeSignal.get(value)["label"], "plain"),
      ])
    }),
    test("works as a JSX prop on View primitives", () => {
      let {container} = Dom.render("")
      let label = Signal.make("Ada")
      let _ = mountTo(
        <p>
          <View.Text value={MaybeSignal.static("Hello, ")} />
          <View.Text value={MaybeSignal.reactive(label)} />
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
    /* Element attributes accept untyped values, so no wrapper is needed there. */
    test("element attributes accept a raw signal without a wrapper", () => {
      let {container} = Dom.render("")
      let cls = Signal.make("initial")
      let _ = mountTo(<div class={cls}> {View.text("raw")} </div>, container)

      let el = Dom.Query.getByText(container, "raw")
      let before = Dom.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")

      combineResults([before, Dom.Assert.toHaveClass(el, "updated")])
    }),
    test("element attributes accept a thunk without a wrapper", () => {
      let {container} = Dom.render("")
      let active = Signal.make(false)
      let _ = mountTo(
        <div class={() => Signal.get(active) ? "on" : "off"}> {View.text("thunk")} </div>,
        container,
      )

      let el = Dom.Query.getByText(container, "thunk")
      let before = Dom.Assert.toHaveClass(el, "off")
      Signal.set(active, true)

      combineResults([before, Dom.Assert.toHaveClass(el, "on")])
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
    test("a Prop.t value is accepted by a prop typed MaybeSignal.t", () => {
      let {container} = Dom.render("")
      let visible = @warning("-3") Prop.signal(Signal.make(true))
      let _ = mountTo(
        <View.Show when_={visible}> <p> {View.text("shown")} </p> </View.Show>,
        container,
      )

      assertEqual(Zekr__DomBindings.textContent(container), "shown")
    }),
  ],
)
