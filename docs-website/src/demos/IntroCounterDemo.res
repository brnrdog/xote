let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

@xote.component
let make = () =>
  <div class="intro-demo">
    <button class="counter-demo-btn" onClick={_ => Signal.update(count, n => n + 1)}>
      {"Clicked "}
      {Signal.get(count)}
      {" times"}
    </button>
    <p class="intro-demo-note"> {"Doubled: "} {Signal.get(doubled)} </p>
  </div>
