let count = Signal.make(0)

let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
let decrement = (_evt: Dom.event) => Signal.update(count, n => n - 1)
let reset = (_evt: Dom.event) => Signal.set(count, 0)

@jsx.component
let make = () => {
  let countTone = () => {
    let value = Signal.get(count)
    if value > 0 {
      "counter-demo-value positive"
    } else if value < 0 {
      "counter-demo-value negative"
    } else {
      "counter-demo-value neutral"
    }
  }

  let countStatus = () => {
    let value = Signal.get(count)
    if value > 0 {
      "Positive"
    } else if value < 0 {
      "Negative"
    } else {
      "Neutral"
    }
  }

  <div class="counter-demo">
    <div class="counter-demo-panel">
      <div class="counter-demo-head">
        <div>
          <div class="counter-demo-kicker"> {View.text("Signal state")} </div>
          <h3 class="counter-demo-title"> {View.text("Counter")} </h3>
        </div>
        <div class={() => "counter-demo-status " ++ String.toLowerCase(countStatus())}>
          {View.signalText(countStatus)}
        </div>
      </div>

      <div class="counter-demo-readout">
        <div class={() => countTone()}><View.Int> {count} </View.Int></div>
        <div class="counter-demo-label"> {View.text("Current Count")} </div>
      </div>

      <div class="counter-demo-note">
        {View.text("One writable signal updates the UI immediately when the value changes.")}
      </div>

      <div class="counter-demo-actions">
        <button class="counter-demo-btn" onClick={decrement}>
          {View.text("Decrease")}
        </button>
        <button class="counter-demo-btn subtle" onClick={reset}>
          {View.text("Reset")}
        </button>
        <button class="counter-demo-btn" onClick={increment}>
          {View.text("Increase")}
        </button>
      </div>
    </div>
  </div>
}
