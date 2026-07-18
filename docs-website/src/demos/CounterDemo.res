let count = Signal.make(0)

let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
let decrement = (_evt: Dom.event) => Signal.update(count, n => n - 1)
let reset = (_evt: Dom.event) => Signal.set(count, 0)

/* Pure derivations of the count — no thunks, no signal reads here. */
let toneClass = value =>
  if value > 0 {
    "counter-demo-value positive"
  } else if value < 0 {
    "counter-demo-value negative"
  } else {
    "counter-demo-value neutral"
  }

let statusLabel = value =>
  if value > 0 {
    "Positive"
  } else if value < 0 {
    "Negative"
  } else {
    "Neutral"
  }

/* The @xote.component annotation lets the reactive parts read `count` inline —
   no `() => ...` thunks, no `View.signalText`, and no `<View.Int>` value
   primitives: a bare `{...}` child is coerced to a node by `View.child`. It
   derives props like @jsx.component and the fine-grained ppx turns each
   attribute/text that reads a signal into its own reactive leaf, so only the
   class and the number update when `count` changes; the surrounding markup is
   built once. */
@xote.component
let make = () => {
  <div class="counter-demo">
    <div class="counter-demo-panel">
      <div class="counter-demo-head">
        <div>
          <div class="counter-demo-kicker"> {"Signal state"} </div>
          <h3 class="counter-demo-title"> {"Counter"} </h3>
        </div>
        <div class={"counter-demo-status " ++ String.toLowerCase(statusLabel(Signal.get(count)))}>
          {statusLabel(Signal.get(count))}
        </div>
      </div>

      <div class="counter-demo-readout">
        <div class={toneClass(Signal.get(count))}> {Signal.get(count)} </div>
        <div class="counter-demo-label"> {"Current Count"} </div>
      </div>

      <div class="counter-demo-note">
        {"One writable signal updates the UI immediately when the value changes."}
      </div>

      <div class="counter-demo-actions">
        <button class="counter-demo-btn" onClick={decrement}> {"Decrease"} </button>
        <button class="counter-demo-btn subtle" onClick={reset}> {"Reset"} </button>
        <button class="counter-demo-btn" onClick={increment}> {"Increase"} </button>
      </div>
    </div>
  </div>
}
