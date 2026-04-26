open! Zekr

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

@get external valueOf: 'a => string = "value"
@get external selectedIndexOf: 'a => int = "selectedIndex"
@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
@val external objectIs: ('a, 'a) => bool = "Object.is"

let suite = Zekr.suite(
  "JSX",
  [
    test("renders basic JSX element with class", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<div class="container"> {View.text("Hello JSX")} </div>, container)
      let el = Dom.Query.getByText(container, "Hello JSX")
      combineResults([Dom.Assert.toBeInTheDocument(el), Dom.Assert.toHaveClass(el, "container")])
    }),
    test("handles click events in JSX", () => {
      let {container} = Dom.render("")
      let clicked = ref(false)
      let _ = mountTo(
        <button onClick={_evt => clicked := true}> {View.text("Press")} </button>,
        container,
      )
      let btn = Dom.Query.getByRole(container, "button")
      Dom.Event.click(btn)
      assertTrue(clicked.contents)
    }),
    test("renders input with type and placeholder", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<input type_="text" placeholder="Enter name" />, container)
      let input = Dom.Query.getByPlaceholder(container, "Enter name")
      Dom.Assert.toHaveAttribute(input, "type", ~value="text")
    }),
    test("renders multiple children in JSX", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <ul>
          <li> {View.text("One")} </li>
          <li> {View.text("Two")} </li>
          <li> {View.text("Three")} </li>
        </ul>,
        container,
      )
      let items = Dom.Query.getAllByRole(container, "listitem")
      assertEqual(Array.length(items), 3)
    }),
    test("renders JSX with reactive class via Prop", () => {
      let {container} = Dom.render("")
      let cls = Signal.make("initial")
      let _ = mountTo(
        <div class={Prop.reactive(cls)}> {View.text("reactive")} </div>,
        container,
      )
      let el = Dom.Query.getByText(container, "reactive")
      let r1 = Dom.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")
      let r2 = Dom.Assert.toHaveClass(el, "updated")
      combineResults([r1, r2])
    }),
    test("controlled select honors the initial reactive value", () => {
      let {container} = Dom.render("")
      let selected = Signal.make("green")

      let _ = mountTo(
        <select value={Prop.reactive(selected)}>
          <option value="red"> {View.text("Red")} </option>
          <option value="green"> {View.text("Green")} </option>
        </select>,
        container,
      )

      switch querySelector(container, "select")->Nullable.toOption {
      | Some(select) =>
          combineResults([
            assertEqual(valueOf(select), "green"),
            assertEqual(selectedIndexOf(select), 1),
          ])
      | None => assertTrue(false)
      }
    }),
    test("renders disabled input via JSX boolean attribute", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <input type_="text" disabled={true} placeholder="disabled field" />,
        container,
      )
      let input = Dom.Query.getByPlaceholder(container, "disabled field")
      Dom.Assert.toBeDisabled(input)
    }),
    test("renders JSX heading elements with correct roles", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <div>
          <h1> {View.text("Title")} </h1>
          <h2> {View.text("Subtitle")} </h2>
        </div>,
        container,
      )
      combineResults([
        Dom.Assert.toBeInTheDocument(Dom.Query.getByRole(container, "heading", ~level=1)),
        Dom.Assert.toBeInTheDocument(Dom.Query.getByRole(container, "heading", ~level=2)),
      ])
    }),
    test("renders link with href", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<a href="/about"> {View.text("About")} </a>, container)
      let link = Dom.Query.getByRole(container, "link")
      Dom.Assert.toHaveAttribute(link, "href", ~value="/about")
    }),
    test("renders image with src and alt", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<img src="/logo.png" alt="Logo" />, container)
      let img = Dom.Query.getByAltText(container, "Logo")
      Dom.Assert.toHaveAttribute(img, "src", ~value="/logo.png")
    }),
    test("component with effect inside computed does not leak dependencies", () => {
      // This test reproduces the timer example bug: when a JSX component
      // containing Effect.run is rendered inside a Computed.make (e.g. via
      // signalFragment for tab switching), the effect's Signal.get calls
      // must be tracked by the effect itself, not by the outer computed.
      let {container} = Dom.render("")

      module EffectComponent = {
        type props = {}
        let make = (_props: props) => {
          let counter = Signal.make(0)

          Effect.run(
            () => {
              let _ = Signal.get(counter)
              None
            },
          )

          <div>
            <span> {View.signalInt(() => Signal.get(counter))} </span>
            <button onClick={_evt => Signal.update(counter, n => n + 1)}>
              {View.text("Inc")}
            </button>
          </div>
        }
      }

      let tab = Signal.make("other")

      let _ = mountTo(
        View.signalFragment(
          Computed.make(
            () =>
              switch Signal.get(tab) {
              | "effect" => [<EffectComponent />]
              | _ => [View.text("other tab")]
              },
          ),
        ),
        container,
      )

      // Switch to the component with an effect
      Signal.set(tab, "effect")
      let r1 = Dom.Assert.toHaveTextContent(container, "0Inc")

      // Click the button - this should update the counter without
      // recreating the component (i.e. the outer computed should NOT re-run)
      let btn = Dom.Query.getByRole(container, "button")
      Dom.Event.click(btn)
      let r2 = Dom.Assert.toHaveTextContent(container, "1Inc")

      Dom.Event.click(btn)
      let r3 = Dom.Assert.toHaveTextContent(container, "2Inc")

      combineResults([r1, r2, r3])
    }),
    test("jsx keyed components reconcile by key inside signal fragments", () => {
      module Row = {
        type item = {id: string, label: string}
        type props = {item: item}

        let make = (props: props) => {
          <li> {View.text(props.item.label)} </li>
        }
      }

      let {container} = Dom.render("")
      let apple: Row.item = {id: "1", label: "Apple"}
      let banana: Row.item = {id: "2", label: "Banana"}
      let items = Signal.make([apple, banana])

      let _ = mountTo(
        <ul>
          {View.signalFragment(
            Computed.make(() =>
              Signal.get(items)->Array.map(item => <Row key={item.id} item={item} />)
            ),
          )}
        </ul>,
        container,
      )

      let initialNodes = Dom.Query.getAllByRole(container, "listitem")
      let appleNode = initialNodes->Array.get(0)->Option.getUnsafe
      let bananaNode = initialNodes->Array.get(1)->Option.getUnsafe

      Signal.set(items, [banana, apple])

      let reorderedNodes = Dom.Query.getAllByRole(container, "listitem")
      let reorderedBanana = reorderedNodes->Array.get(0)->Option.getUnsafe
      let reorderedApple = reorderedNodes->Array.get(1)->Option.getUnsafe

      let updatedBanana: Row.item = {id: "2", label: "Blueberry"}
      Signal.set(items, [updatedBanana, apple])

      let updatedNodes = Dom.Query.getAllByRole(container, "listitem")
      let updatedFirst = updatedNodes->Array.get(0)->Option.getUnsafe
      let updatedSecond = updatedNodes->Array.get(1)->Option.getUnsafe

      combineResults([
        assertEqual(
          reorderedNodes->Array.map(Zekr__DomBindings.textContent),
          ["Banana", "Apple"],
        ),
        assertTrue(objectIs(reorderedBanana, bananaNode)),
        assertTrue(objectIs(reorderedApple, appleNode)),
        assertEqual(
          updatedNodes->Array.map(Zekr__DomBindings.textContent),
          ["Blueberry", "Apple"],
        ),
        assertFalse(objectIs(updatedFirst, bananaNode)),
        assertTrue(objectIs(updatedSecond, appleNode)),
      ])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
