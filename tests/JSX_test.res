open Zekr
open Xote

let mountTo = (node, container) => {
  Component.mount(node, container)
  container
}

let suite = Zekr.suite(
  "JSX",
  [
    test("renders basic JSX element with class", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <div class="container">
          {Component.text("Hello JSX")}
        </div>,
        container,
      )
      let el = Dom.Query.getByText(container, "Hello JSX")
      combineResults([
        Dom.Assert.toBeInTheDocument(el),
        Dom.Assert.toHaveClass(el, "container"),
      ])
    }),
    test("handles click events in JSX", () => {
      let {container} = Dom.render("")
      let clicked = ref(false)
      let _ = mountTo(
        <button onClick={_evt => clicked := true}>
          {Component.text("Press")}
        </button>,
        container,
      )
      let btn = Dom.Query.getByRole(container, "button")
      Dom.Event.click(btn)
      assertTrue(clicked.contents)
    }),
    test("renders input with type and placeholder", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <input type_="text" placeholder="Enter name" />,
        container,
      )
      let input = Dom.Query.getByPlaceholder(container, "Enter name")
      Dom.Assert.toHaveAttribute(input, "type", ~value="text")
    }),
    test("renders multiple children in JSX", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <ul>
          <li> {Component.text("One")} </li>
          <li> {Component.text("Two")} </li>
          <li> {Component.text("Three")} </li>
        </ul>,
        container,
      )
      let items = Dom.Query.getAllByRole(container, "listitem")
      assertEqual(Array.length(items), 3)
    }),
    test("renders JSX with reactive class via ReactiveProp", () => {
      let {container} = Dom.render("")
      let cls = Signal.make("initial")
      let _ = mountTo(
        <div class={ReactiveProp.reactive(cls)}>
          {Component.text("reactive")}
        </div>,
        container,
      )
      let el = Dom.Query.getByText(container, "reactive")
      let r1 = Dom.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")
      let r2 = Dom.Assert.toHaveClass(el, "updated")
      combineResults([r1, r2])
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
          <h1> {Component.text("Title")} </h1>
          <h2> {Component.text("Subtitle")} </h2>
        </div>,
        container,
      )
      combineResults([
        Dom.Assert.toBeInTheDocument(
          Dom.Query.getByRole(container, "heading", ~level=1),
        ),
        Dom.Assert.toBeInTheDocument(
          Dom.Query.getByRole(container, "heading", ~level=2),
        ),
      ])
    }),
    test("renders link with href", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <a href="/about"> {Component.text("About")} </a>,
        container,
      )
      let link = Dom.Query.getByRole(container, "link")
      Dom.Assert.toHaveAttribute(link, "href", ~value="/about")
    }),
    test("renders image with src and alt", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <img src="/logo.png" alt="Logo" />,
        container,
      )
      let img = Dom.Query.getByAltText(container, "Logo")
      Dom.Assert.toHaveAttribute(img, "src", ~value="/logo.png")
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
