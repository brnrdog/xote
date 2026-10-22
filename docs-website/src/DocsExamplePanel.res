// A live example in the docs, inside the article column: the code on top and
// the running demo underneath, always shown in full. The divider between them
// sets how much of the code is visible: drag it, or use the arrow keys, Home
// and End. Code taller than its pane scrolls.

@send external setPointerCapture: (Dom.element, int) => unit = "setPointerCapture"
@get external currentTarget: Dom.event => Dom.element = "currentTarget"
@get external pointerId: Dom.event => int = "pointerId"
@get external clientY: Dom.event => float = "clientY"
@get external key: Dom.event => string = "key"
@send external preventDefault: Dom.event => unit = "preventDefault"
@send external getBoundingClientRect: Dom.element => {"height": float} = "getBoundingClientRect"
@get external scrollHeight: Dom.element => float = "scrollHeight"

// The code pane's height before anyone drags: at most this, less when the
// code is shorter (see .docs-example-code-pre in site.css).
let defaultCodeHeight = 440.0
// The smallest the code pane gets: the filename row and a few lines.
let minCodeHeight = 96.0
let keyStep = 44.0

@xote.component
let make = (~filename, ~code, ~caption=?, ~children=?) => {
  switch children {
  | None =>
    <section class="docs-example-panel">
      <div class="docs-example-code">
        <div class="docs-example-header">
          <span class="docs-example-filename"> {filename} </span>
        </div>
        <pre class="docs-example-code-pre">
          <code> {SyntaxHighlight.highlight(code)} </code>
        </pre>
      </div>
    </section>
  | Some(children) =>
    // The code pane's height once the divider has moved; None keeps the CSS
    // default.
    let codeHeight: Signal.t<option<float>> = Signal.make(None)
    let dragging = Signal.make(false)
    let pane = View.Ref.make()
    let pre = View.Ref.make()
    // Where a drag started: pointer position and pane height.
    let start = ref((0.0, defaultCodeHeight))

    let currentHeight = () =>
      switch View.Ref.peek(pane) {
      | Some(el) => getBoundingClientRect(el)["height"]
      | None => defaultCodeHeight
      }

    // Tallest useful height: the whole file and its filename row.
    let fullHeight = () =>
      switch (View.Ref.peek(pre), View.Ref.peek(pane)) {
      | (Some(preEl), Some(paneEl)) =>
        scrollHeight(preEl) +. getBoundingClientRect(paneEl)["height"] -.
        getBoundingClientRect(preEl)["height"]
      | _ => defaultCodeHeight
      }

    let resize = height =>
      Signal.set(codeHeight, Some(Math.max(minCodeHeight, Math.min(fullHeight(), height))))

    let onPointerDown = event => {
      setPointerCapture(currentTarget(event), pointerId(event))
      start := (clientY(event), currentHeight())
      Signal.set(dragging, true)
      preventDefault(event)
    }

    let onPointerMove = event =>
      if Signal.peek(dragging) {
        let (y, from) = start.contents
        resize(from +. clientY(event) -. y)
      }

    let stopDragging = _ => Signal.set(dragging, false)

    let onKeyDown = event =>
      switch key(event) {
      | "ArrowUp" =>
        preventDefault(event)
        resize(currentHeight() -. keyStep)
      | "ArrowDown" =>
        preventDefault(event)
        resize(currentHeight() +. keyStep)
      | "Home" =>
        preventDefault(event)
        resize(minCodeHeight)
      | "End" =>
        preventDefault(event)
        resize(fullHeight())
      | _ => ()
      }

    <section class={Signal.get(dragging) ? "docs-example-panel is-dragging" : "docs-example-panel"}>
      <div
        ref=pane
        class={Signal.get(codeHeight) == None ? "docs-example-code" : "docs-example-code is-sized"}
        style={switch Signal.get(codeHeight) {
        | Some(px) => `height: ${Float.toFixed(px, ~digits=0)}px`
        | None => ""
        }}>
        <div class="docs-example-header">
          <span class="docs-example-filename"> {filename} </span>
        </div>
        <pre ref=pre class="docs-example-code-pre">
          <code> {SyntaxHighlight.highlight(code)} </code>
        </pre>
      </div>
      <div
        class="docs-example-divider"
        role="separator"
        tabIndex=0
        ariaLabel="Resize the code"
        attrs=[View.attr("aria-orientation", "horizontal")]
        onPointerDown
        onPointerMove
        onPointerUp=stopDragging
        onPointerCancel=stopDragging
        onKeyDown>
        <span class="docs-example-grip" />
      </div>
      <div class="docs-example-demo">
        <div class="docs-example-demo-stage"> {children} </div>
      </div>
      {switch caption {
      | Some(text) => <div class="docs-example-caption"> {text} </div>
      | None => View.null()
      }}
    </section>
  }
}
