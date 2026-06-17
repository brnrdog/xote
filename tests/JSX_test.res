open! Zekr

%%raw(`
function __xoteTestDispatchEventByName(node, eventName) {
  node.dispatchEvent(new Event(eventName, {bubbles: true}));
}
`)

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

@get external valueOf: 'a => string = "value"
@get external selectedIndexOf: 'a => int = "selectedIndex"
@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
@val external objectIs: ('a, 'a) => bool = "Object.is"
@val external dispatchEventByName: ('a, string) => unit = "__xoteTestDispatchEventByName"

type keyedForItem = {id: string, label: string}

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
    test("handles pointer events in JSX", () => {
      let {container} = Dom.render("")
      let pointerDown = ref(false)
      let pointerUp = ref(false)
      let _ = mountTo(
        <button
          onPointerDown={_evt => pointerDown := true}
          onPointerUp={_evt => pointerUp := true}>
          {View.text("Drag handle")}
        </button>,
        container,
      )
      let btn = Dom.Query.getByRole(container, "button")

      dispatchEventByName(btn, "pointerdown")
      dispatchEventByName(btn, "pointerup")

      combineResults([
        assertTrue(pointerDown.contents),
        assertTrue(pointerUp.contents),
      ])
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
    test("View.For renders static data", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <ul>
          <View.For
            each={Prop.static(["One", "Two"])}
            render={label => <li> {View.text(label)} </li>}
          />
        </ul>,
        container,
      )
      assertEqual(
        Dom.Query.getAllByRole(container, "listitem")->Array.map(Zekr__DomBindings.textContent),
        ["One", "Two"],
      )
    }),
    test("View.For renders reactive data", () => {
      let {container} = Dom.render("")
      let items = Signal.make(["One"])
      let _ = mountTo(
        <ul>
          <View.For
            each={Prop.signal(items)}
            render={label => <li> {View.text(label)} </li>}
          />
        </ul>,
        container,
      )

      let r1 = assertEqual(
        Dom.Query.getAllByRole(container, "listitem")->Array.map(Zekr__DomBindings.textContent),
        ["One"],
      )
      Signal.set(items, ["Two", "Three"])
      let r2 = assertEqual(
        Dom.Query.getAllByRole(container, "listitem")->Array.map(Zekr__DomBindings.textContent),
        ["Two", "Three"],
      )

      combineResults([r1, r2])
    }),
    test("View.Show renders conditional branches", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(false)
      let _ = mountTo(
        <View.Show when_={Prop.signal(visible)} fallback={<p> {View.text("Hidden")} </p>}>
          <p> {View.text("Visible")} </p>
        </View.Show>,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "Hidden")
      Signal.set(visible, true)
      let r2 = Dom.Assert.toHaveTextContent(container, "Visible")
      Signal.set(visible, false)
      let r3 = Dom.Assert.toHaveTextContent(container, "Hidden")

      combineResults([r1, r2, r3])
    }),
    test("View.Maybe renders option values and fallback", () => {
      let {container} = Dom.render("")
      let selected = Signal.make(None)
      let _ = mountTo(
        <View.Maybe
          value={Prop.signal(selected)}
          fallback={<p> {View.text("None")} </p>}
          render={value => <p> {View.text("Selected: " ++ value)} </p>}
        />,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "None")
      Signal.set(selected, Some("Ada"))
      let r2 = Dom.Assert.toHaveTextContent(container, "Selected: Ada")
      Signal.set(selected, None)
      let r3 = Dom.Assert.toHaveTextContent(container, "None")

      combineResults([r1, r2, r3])
    }),
    test("View.Value renders reactive values", () => {
      let {container} = Dom.render("")
      let count = Signal.make(1)
      let _ = mountTo(
        <View.Value
          value={Prop.signal(count)}
          render={value => <p> {View.text("Count: " ++ value->Int.toString)} </p>}
        />,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "Count: 1")
      Signal.set(count, 2)
      let r2 = Dom.Assert.toHaveTextContent(container, "Count: 2")

      combineResults([r1, r2])
    }),
    test("View value primitives render static values", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <p>
          <View.Text value={Prop.static("Items: ")} />
          <View.Int value={Prop.static(2)} />
          <View.Text value={Prop.static(", ratio: ")} />
          <View.Float value={Prop.static(1.5)} />
          <View.Text value={Prop.static(", ready: ")} />
          <View.Bool value={Prop.static(true)} />
        </p>,
        container,
      )

      Dom.Assert.toHaveTextContent(container, "Items: 2, ratio: 1.5, ready: true")
    }),
    test("View value primitives render reactive values", () => {
      let {container} = Dom.render("")
      let label = Signal.make("Count: ")
      let count = Signal.make(1)
      let ready = Signal.make(false)
      let _ = mountTo(
        <p>
          <View.Text value={Prop.signal(label)} />
          <View.Int value={Prop.signal(count)} />
          <View.Text value={Prop.static(", ready: ")} />
          <View.Bool value={Prop.signal(ready)} />
        </p>,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "Count: 1, ready: false")
      Signal.set(label, "Total: ")
      Signal.set(count, 2)
      Signal.set(ready, true)
      let r2 = Dom.Assert.toHaveTextContent(container, "Total: 2, ready: true")

      combineResults([r1, r2])
    }),
    test("View value primitives render child values", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <p>
          <View.Text> {"Items: "} </View.Text>
          <View.Int> {2} </View.Int>
          <View.Text> {", ratio: "} </View.Text>
          <View.Float> {1.5} </View.Float>
          <View.Text> {", ready: "} </View.Text>
          <View.Bool> {true} </View.Bool>
        </p>,
        container,
      )

      Dom.Assert.toHaveTextContent(container, "Items: 2, ratio: 1.5, ready: true")
    }),
    test("View value primitives render signal children", () => {
      let {container} = Dom.render("")
      let label = Signal.make("Count: ")
      let count = Signal.make(1)
      let ready = Signal.make(false)
      let _ = mountTo(
        <p>
          <View.Text> {label} </View.Text>
          <View.Int> {count} </View.Int>
          <View.Text> {", ready: "} </View.Text>
          <View.Bool> {ready} </View.Bool>
        </p>,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "Count: 1, ready: false")
      Signal.set(label, "Total: ")
      Signal.set(count, 2)
      Signal.set(ready, true)
      let r2 = Dom.Assert.toHaveTextContent(container, "Total: 2, ready: true")

      combineResults([r1, r2])
    }),
    test("View value primitives render Prop children", () => {
      let {container} = Dom.render("")
      let count = Signal.make(1)
      let label: Prop.t<string> = Prop.static("Count: ")
      let value: Prop.t<int> = Prop.signal(count)
      let _ = mountTo(
        <p>
          <View.Text> {label} </View.Text>
          <View.Int> {value} </View.Int>
        </p>,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "Count: 1")
      Signal.set(count, 2)
      let r2 = Dom.Assert.toHaveTextContent(container, "Count: 2")

      combineResults([r1, r2])
    }),
    test("View value primitives tolerate empty props", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <p>
          <View.Text />
          <View.Int />
          <View.Float />
          <View.Bool />
        </p>,
        container,
      )

      Dom.Assert.toHaveTextContent(container, "")
    }),
    test("View.Text renders formatted Prop children", () => {
      let {container} = Dom.render("")
      let nameSignal = Signal.make("Ada")
      let reactiveName: Prop.t<string> = Prop.signal(nameSignal)
      let _ = mountTo(
        <p>
          <View.Text> {() => `Hello, ${Prop.get(reactiveName)}`} </View.Text>
        </p>,
        container,
      )

      let r1 = Dom.Assert.toHaveTextContent(container, "Hello, Ada")
      Signal.set(nameSignal, "Grace")
      let r2 = Dom.Assert.toHaveTextContent(container, "Hello, Grace")

      combineResults([r1, r2])
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
    test("renders SVG element with SVG-specific attributes via JSX", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
          <circle cx="50" cy="50" r="40" fill="red" stroke="black" strokeWidth="2" />
          <path d="M10 10 L90 90" stroke="blue" fill="none" strokeLinecap="round" />
        </svg>,
        container,
      )

      switch querySelector(container, "svg")->Nullable.toOption {
      | Some(svg) =>
        switch (
          querySelector(svg, "circle")->Nullable.toOption,
          querySelector(svg, "path")->Nullable.toOption,
        ) {
        | (Some(circle), Some(path)) =>
          combineResults([
            Dom.Assert.toHaveAttribute(svg, "viewBox", ~value="0 0 100 100"),
            Dom.Assert.toHaveAttribute(circle, "cx", ~value="50"),
            Dom.Assert.toHaveAttribute(circle, "cy", ~value="50"),
            Dom.Assert.toHaveAttribute(circle, "r", ~value="40"),
            Dom.Assert.toHaveAttribute(circle, "fill", ~value="red"),
            Dom.Assert.toHaveAttribute(circle, "stroke", ~value="black"),
            Dom.Assert.toHaveAttribute(circle, "stroke-width", ~value="2"),
            Dom.Assert.toHaveAttribute(path, "d", ~value="M10 10 L90 90"),
            Dom.Assert.toHaveAttribute(path, "stroke-linecap", ~value="round"),
          ])
        | _ => assertTrue(false)
        }
      | None => assertTrue(false)
      }
    }),
    test("renders SVG element with reactive fill attribute", () => {
      let {container} = Dom.render("")
      let color = Signal.make("red")
      let _ = mountTo(
        <svg viewBox="0 0 10 10">
          <rect x="0" y="0" width="10" height="10" fill={Prop.reactive(color)} />
        </svg>,
        container,
      )

      switch querySelector(container, "rect")->Nullable.toOption {
      | Some(rect) =>
        let r1 = Dom.Assert.toHaveAttribute(rect, "fill", ~value="red")
        Signal.set(color, "blue")
        let r2 = Dom.Assert.toHaveAttribute(rect, "fill", ~value="blue")
        combineResults([r1, r2])
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
    test("View.For reconciles reactive data when by is provided", () => {
      let {container} = Dom.render("")
      let apple: keyedForItem = {id: "1", label: "Apple"}
      let banana: keyedForItem = {id: "2", label: "Banana"}
      let items = Signal.make([apple, banana])

      let _ = mountTo(
        <ul>
          <View.For
            each={Prop.signal(items)}
            by={item => item.id}
            render={item => <li> {View.text(item.label)} </li>}
          />
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

      combineResults([
        assertEqual(
          reorderedNodes->Array.map(Zekr__DomBindings.textContent),
          ["Banana", "Apple"],
        ),
        assertTrue(objectIs(reorderedBanana, bananaNode)),
        assertTrue(objectIs(reorderedApple, appleNode)),
      ])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
