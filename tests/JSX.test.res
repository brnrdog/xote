%%raw(`import "./setup.mjs"`)

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

let suite = Suite.make(
  "JSX",
  [
    Test.make("renders basic JSX element with class", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(<div class="container"> {View.text("Hello JSX")} </div>, container)
      let el = DomTesting.Query.getByText(container, "Hello JSX")
      Assert.combineResults([DomTesting.Assert.toBeInTheDocument(el), DomTesting.Assert.toHaveClass(el, "container")])
    }),
    Test.make("handles click events in JSX", () => {
      let {container} = DomTesting.render("")
      let clicked = ref(false)
      let _ = mountTo(
        <button onClick={_evt => clicked := true}> {View.text("Press")} </button>,
        container,
      )
      let btn = DomTesting.Query.getByRole(container, "button")
      DomTesting.Event.click(btn)
      Assert.isTrue(clicked.contents)
    }),
    Test.make("handles pointer events in JSX", () => {
      let {container} = DomTesting.render("")
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
      let btn = DomTesting.Query.getByRole(container, "button")

      dispatchEventByName(btn, "pointerdown")
      dispatchEventByName(btn, "pointerup")

      Assert.combineResults([
        Assert.isTrue(pointerDown.contents),
        Assert.isTrue(pointerUp.contents),
      ])
    }),
    Test.make("renders input with type and placeholder", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(<input type_="text" placeholder="Enter name" />, container)
      let input = DomTesting.Query.getByPlaceholder(container, "Enter name")
      DomTesting.Assert.toHaveAttribute(input, "type", ~value="text")
    }),
    Test.make("renders multiple children in JSX", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        <ul>
          <li> {View.text("One")} </li>
          <li> {View.text("Two")} </li>
          <li> {View.text("Three")} </li>
        </ul>,
        container,
      )
      let items = DomTesting.Query.getAllByRole(container, "listitem")
      Assert.equal(Array.length(items), 3)
    }),
    Test.make("View.For renders static data", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        <ul>
          <View.For
            each={Prop.static(["One", "Two"])}
            render={label => <li> {View.text(label)} </li>}
          />
        </ul>,
        container,
      )
      Assert.equal(
        DomTesting.Query.getAllByRole(container, "listitem")->Array.map(DomBindings.textContent),
        ["One", "Two"],
      )
    }),
    Test.make("View.For renders reactive data", () => {
      let {container} = DomTesting.render("")
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

      let r1 = Assert.equal(
        DomTesting.Query.getAllByRole(container, "listitem")->Array.map(DomBindings.textContent),
        ["One"],
      )
      Signal.set(items, ["Two", "Three"])
      let r2 = Assert.equal(
        DomTesting.Query.getAllByRole(container, "listitem")->Array.map(DomBindings.textContent),
        ["Two", "Three"],
      )

      Assert.combineResults([r1, r2])
    }),
    Test.make("View.Show renders conditional branches", () => {
      let {container} = DomTesting.render("")
      let visible = Signal.make(false)
      let _ = mountTo(
        <View.Show when_={Prop.signal(visible)} fallback={<p> {View.text("Hidden")} </p>}>
          <p> {View.text("Visible")} </p>
        </View.Show>,
        container,
      )

      let r1 = DomTesting.Assert.toHaveTextContent(container, "Hidden")
      Signal.set(visible, true)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Visible")
      Signal.set(visible, false)
      let r3 = DomTesting.Assert.toHaveTextContent(container, "Hidden")

      Assert.combineResults([r1, r2, r3])
    }),
    Test.make("View.Maybe renders option values and fallback", () => {
      let {container} = DomTesting.render("")
      let selected = Signal.make(None)
      let _ = mountTo(
        <View.Maybe
          value={Prop.signal(selected)}
          fallback={<p> {View.text("None")} </p>}
          render={value => <p> {View.text("Selected: " ++ value)} </p>}
        />,
        container,
      )

      let r1 = DomTesting.Assert.toHaveTextContent(container, "None")
      Signal.set(selected, Some("Ada"))
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Selected: Ada")
      Signal.set(selected, None)
      let r3 = DomTesting.Assert.toHaveTextContent(container, "None")

      Assert.combineResults([r1, r2, r3])
    }),
    Test.make("View.Value renders reactive values", () => {
      let {container} = DomTesting.render("")
      let count = Signal.make(1)
      let _ = mountTo(
        <View.Value
          value={Prop.signal(count)}
          render={value => <p> {View.text("Count: " ++ value->Int.toString)} </p>}
        />,
        container,
      )

      let r1 = DomTesting.Assert.toHaveTextContent(container, "Count: 1")
      Signal.set(count, 2)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Count: 2")

      Assert.combineResults([r1, r2])
    }),
    Test.make("View value primitives render static values", () => {
      let {container} = DomTesting.render("")
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

      DomTesting.Assert.toHaveTextContent(container, "Items: 2, ratio: 1.5, ready: true")
    }),
    Test.make("View value primitives render reactive values", () => {
      let {container} = DomTesting.render("")
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

      let r1 = DomTesting.Assert.toHaveTextContent(container, "Count: 1, ready: false")
      Signal.set(label, "Total: ")
      Signal.set(count, 2)
      Signal.set(ready, true)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Total: 2, ready: true")

      Assert.combineResults([r1, r2])
    }),
    Test.make("View value primitives render child values", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        <p>
          <View.Text> "Items: " </View.Text>
          <View.Int> {2} </View.Int>
          <View.Text> ", ratio: " </View.Text>
          <View.Float> {1.5} </View.Float>
          <View.Text> ", ready: " </View.Text>
          <View.Bool> {true} </View.Bool>
        </p>,
        container,
      )

      DomTesting.Assert.toHaveTextContent(container, "Items: 2, ratio: 1.5, ready: true")
    }),
    Test.make("View value primitives render signal children", () => {
      let {container} = DomTesting.render("")
      let label = Signal.make("Count: ")
      let count = Signal.make(1)
      let ready = Signal.make(false)
      let _ = mountTo(
        <p>
          <View.Text> {label} </View.Text>
          <View.Int> {count} </View.Int>
          <View.Text> ", ready: " </View.Text>
          <View.Bool> {ready} </View.Bool>
        </p>,
        container,
      )

      let r1 = DomTesting.Assert.toHaveTextContent(container, "Count: 1, ready: false")
      Signal.set(label, "Total: ")
      Signal.set(count, 2)
      Signal.set(ready, true)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Total: 2, ready: true")

      Assert.combineResults([r1, r2])
    }),
    Test.make("View value primitives render Prop children", () => {
      let {container} = DomTesting.render("")
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

      let r1 = DomTesting.Assert.toHaveTextContent(container, "Count: 1")
      Signal.set(count, 2)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Count: 2")

      Assert.combineResults([r1, r2])
    }),
    Test.make("View value primitives tolerate empty props", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        <p>
          <View.Text />
          <View.Int />
          <View.Float />
          <View.Bool />
        </p>,
        container,
      )

      DomTesting.Assert.toHaveTextContent(container, "")
    }),
    Test.make("View value primitives treat null and undefined as empty output", () => {
      let {container} = DomTesting.render("")
      let nullText: string = %raw("null")
      let undefinedText: string = %raw("undefined")
      let nullInt: int = %raw("null")
      let undefinedInt: int = %raw("undefined")
      let nullFloat: float = %raw("null")
      let undefinedFloat: float = %raw("undefined")
      let nullBool: bool = %raw("null")
      let undefinedBool: bool = %raw("undefined")

      let _ = mountTo(
        <p>
          <View.Text value={nullText} />
          <View.Text value={undefinedText} />
          <View.Int value={nullInt} />
          <View.Int value={undefinedInt} />
          <View.Float value={nullFloat} />
          <View.Float value={undefinedFloat} />
          <View.Bool value={nullBool} />
          <View.Bool value={undefinedBool} />
        </p>,
        container,
      )

      DomTesting.Assert.toHaveTextContent(container, "")
    }),
    Test.make("View.Text renders formatted Prop children", () => {
      let {container} = DomTesting.render("")
      let nameSignal = Signal.make("Ada")
      let reactiveName: Prop.t<string> = Prop.signal(nameSignal)
      let _ = mountTo(
        <p>
          <View.Text> {() => `Hello, ${Prop.get(reactiveName)}`} </View.Text>
        </p>,
        container,
      )

      let r1 = DomTesting.Assert.toHaveTextContent(container, "Hello, Ada")
      Signal.set(nameSignal, "Grace")
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Hello, Grace")

      Assert.combineResults([r1, r2])
    }),
    Test.make("View.Value detaches previous reactive descendants after shape changes", () => {
      let {container} = DomTesting.render("")
      let selected = Signal.make(true)
      let first = Signal.make("First")
      let second = Signal.make("Second")

      let _ = mountTo(
        <View.Value
          value={Prop.signal(selected)}
          render={isFirst =>
            if isFirst {
              <p> <View.Text> {first} </View.Text> </p>
            } else {
              <section> <View.Text> {second} </View.Text> </section>
            }}
        />,
        container,
      )

      let r1 = DomTesting.Assert.toHaveTextContent(container, "First")
      Signal.set(selected, false)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Second")
      Signal.set(first, "Detached")
      let r3 = DomTesting.Assert.toHaveTextContent(container, "Second")
      Signal.set(second, "Current")
      let r4 = DomTesting.Assert.toHaveTextContent(container, "Current")

      Assert.combineResults([r1, r2, r3, r4])
    }),
    Test.make("renders JSX with reactive class via Prop", () => {
      let {container} = DomTesting.render("")
      let cls = Signal.make("initial")
      let _ = mountTo(
        <div class={Prop.reactive(cls)}> {View.text("reactive")} </div>,
        container,
      )
      let el = DomTesting.Query.getByText(container, "reactive")
      let r1 = DomTesting.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")
      let r2 = DomTesting.Assert.toHaveClass(el, "updated")
      Assert.combineResults([r1, r2])
    }),
    Test.make("controlled select honors the initial reactive value", () => {
      let {container} = DomTesting.render("")
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
          Assert.combineResults([
            Assert.equal(valueOf(select), "green"),
            Assert.equal(selectedIndexOf(select), 1),
          ])
      | None => Assert.isTrue(false)
      }
    }),
    Test.make("renders SVG element with SVG-specific attributes via JSX", () => {
      let {container} = DomTesting.render("")
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
          Assert.combineResults([
            DomTesting.Assert.toHaveAttribute(svg, "viewBox", ~value="0 0 100 100"),
            DomTesting.Assert.toHaveAttribute(circle, "cx", ~value="50"),
            DomTesting.Assert.toHaveAttribute(circle, "cy", ~value="50"),
            DomTesting.Assert.toHaveAttribute(circle, "r", ~value="40"),
            DomTesting.Assert.toHaveAttribute(circle, "fill", ~value="red"),
            DomTesting.Assert.toHaveAttribute(circle, "stroke", ~value="black"),
            DomTesting.Assert.toHaveAttribute(circle, "stroke-width", ~value="2"),
            DomTesting.Assert.toHaveAttribute(path, "d", ~value="M10 10 L90 90"),
            DomTesting.Assert.toHaveAttribute(path, "stroke-linecap", ~value="round"),
          ])
        | _ => Assert.isTrue(false)
        }
      | None => Assert.isTrue(false)
      }
    }),
    Test.make("renders SVG element with reactive fill attribute", () => {
      let {container} = DomTesting.render("")
      let color = Signal.make("red")
      let _ = mountTo(
        <svg viewBox="0 0 10 10">
          <rect x="0" y="0" width="10" height="10" fill={Prop.reactive(color)} />
        </svg>,
        container,
      )

      switch querySelector(container, "rect")->Nullable.toOption {
      | Some(rect) =>
        let r1 = DomTesting.Assert.toHaveAttribute(rect, "fill", ~value="red")
        Signal.set(color, "blue")
        let r2 = DomTesting.Assert.toHaveAttribute(rect, "fill", ~value="blue")
        Assert.combineResults([r1, r2])
      | None => Assert.isTrue(false)
      }
    }),
    Test.make("renders disabled input via JSX boolean attribute", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        <input type_="text" disabled={true} placeholder="disabled field" />,
        container,
      )
      let input = DomTesting.Query.getByPlaceholder(container, "disabled field")
      DomTesting.Assert.toBeDisabled(input)
    }),
    Test.make("renders JSX heading elements with correct roles", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        <div>
          <h1> {View.text("Title")} </h1>
          <h2> {View.text("Subtitle")} </h2>
        </div>,
        container,
      )
      Assert.combineResults([
        DomTesting.Assert.toBeInTheDocument(DomTesting.Query.getByRole(container, "heading", ~level=1)),
        DomTesting.Assert.toBeInTheDocument(DomTesting.Query.getByRole(container, "heading", ~level=2)),
      ])
    }),
    Test.make("renders link with href", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(<a href="/about"> {View.text("About")} </a>, container)
      let link = DomTesting.Query.getByRole(container, "link")
      DomTesting.Assert.toHaveAttribute(link, "href", ~value="/about")
    }),
    Test.make("renders image with src and alt", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(<img src="/logo.png" alt="Logo" />, container)
      let img = DomTesting.Query.getByAltText(container, "Logo")
      DomTesting.Assert.toHaveAttribute(img, "src", ~value="/logo.png")
    }),
    Test.make("component with effect inside computed does not leak dependencies", () => {
      // This test reproduces the timer example bug: when a JSX component
      // containing Effect.run is rendered inside a Computed.make (e.g. via
      // signalFragment for tab switching), the effect's Signal.get calls
      // must be tracked by the effect itself, not by the outer computed.
      let {container} = DomTesting.render("")

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
      let r1 = DomTesting.Assert.toHaveTextContent(container, "0Inc")

      // Click the button - this should update the counter without
      // recreating the component (i.e. the outer computed should NOT re-run)
      let btn = DomTesting.Query.getByRole(container, "button")
      DomTesting.Event.click(btn)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "1Inc")

      DomTesting.Event.click(btn)
      let r3 = DomTesting.Assert.toHaveTextContent(container, "2Inc")

      Assert.combineResults([r1, r2, r3])
    }),
    Test.make("jsx keyed components reconcile by key inside signal fragments", () => {
      module Row = {
        type item = {id: string, label: string}
        type props = {item: item}

        let make = (props: props) => {
          <li> {View.text(props.item.label)} </li>
        }
      }

      let {container} = DomTesting.render("")
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

      let initialNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let appleNode = initialNodes->Array.get(0)->Option.getUnsafe
      let bananaNode = initialNodes->Array.get(1)->Option.getUnsafe

      Signal.set(items, [banana, apple])

      let reorderedNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let reorderedBanana = reorderedNodes->Array.get(0)->Option.getUnsafe
      let reorderedApple = reorderedNodes->Array.get(1)->Option.getUnsafe

      let updatedBanana: Row.item = {id: "2", label: "Blueberry"}
      Signal.set(items, [updatedBanana, apple])

      let updatedNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let updatedFirst = updatedNodes->Array.get(0)->Option.getUnsafe
      let updatedSecond = updatedNodes->Array.get(1)->Option.getUnsafe

      Assert.combineResults([
        Assert.equal(
          reorderedNodes->Array.map(DomBindings.textContent),
          ["Banana", "Apple"],
        ),
        Assert.isTrue(objectIs(reorderedBanana, bananaNode)),
        Assert.isTrue(objectIs(reorderedApple, appleNode)),
        Assert.equal(
          updatedNodes->Array.map(DomBindings.textContent),
          ["Blueberry", "Apple"],
        ),
        Assert.isFalse(objectIs(updatedFirst, bananaNode)),
        Assert.isTrue(objectIs(updatedSecond, appleNode)),
      ])
    }),
    Test.make("View.For reconciles reactive data when by is provided", () => {
      let {container} = DomTesting.render("")
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

      let initialNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let appleNode = initialNodes->Array.get(0)->Option.getUnsafe
      let bananaNode = initialNodes->Array.get(1)->Option.getUnsafe

      Signal.set(items, [banana, apple])

      let reorderedNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let reorderedBanana = reorderedNodes->Array.get(0)->Option.getUnsafe
      let reorderedApple = reorderedNodes->Array.get(1)->Option.getUnsafe

      Assert.combineResults([
        Assert.equal(
          reorderedNodes->Array.map(DomBindings.textContent),
          ["Banana", "Apple"],
        ),
        Assert.isTrue(objectIs(reorderedBanana, bananaNode)),
        Assert.isTrue(objectIs(reorderedApple, appleNode)),
      ])
    }),
    Test.make("View.KeyedFor renders static data", () => {
      let {container} = DomTesting.render("")
      let apple: keyedForItem = {id: "1", label: "Apple"}
      let banana: keyedForItem = {id: "2", label: "Banana"}

      let _ = mountTo(
        <ul>
          <View.KeyedFor
            each={Prop.static([apple, banana])}
            by={item => item.id}
            render={item => <li> {View.text(item.label)} </li>}
          />
        </ul>,
        container,
      )

      Assert.equal(
        DomTesting.Query.getAllByRole(container, "listitem")->Array.map(DomBindings.textContent),
        ["Apple", "Banana"],
      )
    }),
    Test.make("View.KeyedFor reconciles reactive data", () => {
      let {container} = DomTesting.render("")
      let apple: keyedForItem = {id: "1", label: "Apple"}
      let banana: keyedForItem = {id: "2", label: "Banana"}
      let cherry: keyedForItem = {id: "3", label: "Cherry"}
      let items = Signal.make([apple, banana])

      let _ = mountTo(
        <ul>
          <View.KeyedFor
            each={Prop.signal(items)}
            by={item => item.id}
            render={item => <li> {View.text(item.label)} </li>}
          />
        </ul>,
        container,
      )

      let initialNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let appleNode = initialNodes->Array.get(0)->Option.getUnsafe
      let bananaNode = initialNodes->Array.get(1)->Option.getUnsafe

      Signal.set(items, [cherry, banana, apple])

      let updatedNodes = DomTesting.Query.getAllByRole(container, "listitem")
      let updatedCherry = updatedNodes->Array.get(0)->Option.getUnsafe
      let updatedBanana = updatedNodes->Array.get(1)->Option.getUnsafe
      let updatedApple = updatedNodes->Array.get(2)->Option.getUnsafe

      Assert.combineResults([
        Assert.equal(
          updatedNodes->Array.map(DomBindings.textContent),
          ["Cherry", "Banana", "Apple"],
        ),
        Assert.isFalse(objectIs(updatedCherry, appleNode)),
        Assert.isFalse(objectIs(updatedCherry, bananaNode)),
        Assert.isTrue(objectIs(updatedBanana, bananaNode)),
        Assert.isTrue(objectIs(updatedApple, appleNode)),
      ])
    }),
  ],
  ~afterEach=() => DomTesting.cleanup(),
)
