// A live example in the docs, inside the article column: the code on top, the
// running demo underneath, and a divider between them that can be dragged (or
// moved with the arrow keys, Home and End) to give either side more room.

@send external setPointerCapture: (Dom.element, int) => unit = "setPointerCapture"
@get external currentTarget: Dom.event => Dom.element = "currentTarget"
@get external pointerId: Dom.event => int = "pointerId"
@get external clientY: Dom.event => float = "clientY"
@get external key: Dom.event => string = "key"
@send external preventDefault: Dom.event => unit = "preventDefault"
@send external getBoundingClientRect: Dom.element => {"height": float} = "getBoundingClientRect"
@get @return(nullable) external firstElementChild: Dom.element => option<Dom.element> = "firstElementChild"
@get external scrollHeight: Dom.element => float = "scrollHeight"
@val @scope("window") external innerHeight: float = "innerHeight"

// Height the panel is designed around (see .docs-example-split in site.css);
// used to size the code pane to its content before anything is measured.
let designHeight = 640.0
let lineHeight = 22.4
let minShare = 0.15
let maxShare = 0.85
// Vertical padding of the demo stage, and the divider's height.
let stagePadding = 64.0
let dividerHeight = 16.0
// The code pane's filename row.
let codeHeader = 36.0

let clamp = share => Math.max(minShare, Math.min(maxShare, share))

// The code pane's starting share of the panel: enough for the code, but never
// so much that the demo has no room.
let initialShare = (code: string) => {
  let lines = code->String.split("\n")->Array.length->Int.toFloat
  Math.max(0.3, Math.min(0.5, (lines *. lineHeight +. 72.0) /. designHeight))
}

@xote.component
let make = (~filename, ~code, ~caption=?, ~children=?) => {
  let codePane = (~ref=?) =>
    <div class="docs-example-code">
      <div class="docs-example-header">
        <span class="docs-example-filename"> {filename} </span>
      </div>
      <pre ?ref class="docs-example-code-pre">
        <code> {SyntaxHighlight.highlight(code)} </code>
      </pre>
    </div>

  switch children {
  | None => <section class="docs-example-panel"> {codePane()} </section>
  | Some(children) =>
    let defaultShare = initialShare(code)
    let share = Signal.make(defaultShare)
    let dragging = Signal.make(false)
    let split = View.Ref.make()
    let stage = View.Ref.make()
    let codePre = View.Ref.make()
    // The panel's height once measured; until then CSS gives it a default.
    let height: Signal.t<option<float>> = Signal.make(None)
    // Where a drag started: pointer position, share, and panel height.
    let start = ref((0.0, defaultShare, designHeight))

    let onPointerDown = event => {
      let handle = currentTarget(event)
      setPointerCapture(handle, pointerId(event))
      let height = switch View.Ref.peek(split) {
      | Some(el) => getBoundingClientRect(el)["height"]
      | None => designHeight
      }
      start := (clientY(event), Signal.peek(share), height)
      Signal.set(dragging, true)
      preventDefault(event)
    }

    let onPointerMove = event =>
      if Signal.peek(dragging) {
        let (y, from, height) = start.contents
        Signal.set(share, clamp(from +. (clientY(event) -. y) /. height))
      }

    let stopDragging = _ => Signal.set(dragging, false)

    // Once on the page, size the panel to fit both the code and the demo, up
    // to most of the window. When both can't fit, the demo gets what it needs
    // (up to 72%) and the code scrolls in the rest.
    View.onMount(() =>
      switch (
        View.Ref.peek(codePre),
        View.Ref.peek(stage)->Option.flatMap(firstElementChild),
      ) {
      | (Some(pre), Some(demo)) =>
        let codeNeeded = scrollHeight(pre) +. codeHeader
        let demoNeeded = getBoundingClientRect(demo)["height"] +. stagePadding
        let limit = Math.min(innerHeight *. 0.88, 860.0)
        let wanted = codeNeeded +. demoNeeded +. dividerHeight
        let total = Math.min(wanted, limit)
        let demoShare = Math.min((demoNeeded +. dividerHeight) /. total, 0.72)
        Signal.set(height, Some(total))
        Signal.set(share, wanted <= limit ? codeNeeded /. total : clamp(1.0 -. demoShare))
      | _ => ()
      }
    )

    let onKeyDown = event => {
      let step = 0.05
      switch key(event) {
      | "ArrowUp" =>
        preventDefault(event)
        Signal.update(share, s => clamp(s -. step))
      | "ArrowDown" =>
        preventDefault(event)
        Signal.update(share, s => clamp(s +. step))
      | "Home" =>
        preventDefault(event)
        Signal.set(share, minShare)
      | "End" =>
        preventDefault(event)
        Signal.set(share, maxShare)
      | _ => ()
      }
    }

    let percent = value => Float.toFixed(value *. 100.0, ~digits=1)

    <section class="docs-example-panel">
      <div
        ref=split
        class={Signal.get(dragging) ? "docs-example-split is-dragging" : "docs-example-split"}
        style={`grid-template-rows: ${percent(Signal.get(share))}% auto minmax(0, 1fr)` ++
        switch Signal.get(height) {
        | Some(px) => `; height: ${Float.toFixed(px, ~digits=0)}px`
        | None => ""
        }}>
        {codePane(~ref=codePre)}
        <div
          class="docs-example-divider"
          role="separator"
          tabIndex=0
          ariaLabel="Resize code and demo"
          attrs=[
            View.attr("aria-orientation", "horizontal"),
            View.attr("aria-valuemin", "15"),
            View.attr("aria-valuemax", "85"),
            View.computedAttr("aria-valuenow", () =>
              Float.toFixed(Signal.get(share) *. 100.0, ~digits=0)
            ),
          ]
          onPointerDown
          onPointerMove
          onPointerUp=stopDragging
          onPointerCancel=stopDragging
          onKeyDown>
          <span class="docs-example-grip" />
        </div>
        <div class="docs-example-demo">
          <div ref=stage class="docs-example-demo-stage"> {children} </div>
        </div>
      </div>
      {switch caption {
      | Some(text) => <div class="docs-example-caption"> {text} </div>
      | None => View.null()
      }}
    </section>
  }
}
