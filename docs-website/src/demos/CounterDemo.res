open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
let decrement = (_evt: Dom.event) => Signal.update(count, n => n - 1)
let reset = (_evt: Dom.event) => Signal.set(count, 0)

let content = () => {
  <div class="demo-container">
    <div class="demo-section" style="text-align: center;">
      <div class="counter-demo-display">
        {Component.textSignal(() => Signal.get(count)->Int.toString)}
      </div>
      <div class="counter-demo-label"> {Component.text("Current Count")} </div>
    </div>
    <div class="demo-btn-group">
      <button class="demo-btn demo-btn-primary" onClick={decrement}>
        {Component.text("- Decrement")}
      </button>
      <button class="demo-btn demo-btn-secondary" onClick={reset}>
        {Component.text("Reset")}
      </button>
      <button class="demo-btn demo-btn-primary" onClick={increment}>
        {Component.text("+ Increment")}
      </button>
    </div>
  </div>
}
