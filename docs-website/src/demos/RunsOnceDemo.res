// Counts how many times the component function itself runs.
let bodyRuns = ref(0)

let clicks = Signal.make(0)

@xote.component
let make = () => {
  bodyRuns := bodyRuns.contents + 1
  let ranAtRender = bodyRuns.contents

  <div class="intro-demo">
    <button class="counter-demo-btn" onClick={_ => Signal.update(clicks, n => n + 1)}>
      {"Click me"}
    </button>
    <p class="intro-demo-note"> {"Clicks: "} {Signal.get(clicks)} </p>
    <p class="intro-demo-note"> {"Times the component ran: "} {ranAtRender} </p>
  </div>
}
