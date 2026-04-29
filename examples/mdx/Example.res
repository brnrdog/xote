@jsx.component
let make = () => {
  let count = Signal.make(0)

  <div class="xote-demo">
    <p class="xote-demo__eyebrow"> {View.text("Xote component rendered inside MDX")} </p>
    <div class="xote-demo__counter">
      <button
        class="xote-demo__button"
        ariaLabel="Decrease count"
        onClick={_event => Signal.update(count, value => value - 1)}>
        {View.text("-")}
      </button>
      <strong class="xote-demo__value"> {View.signalInt(() => Signal.get(count))} </strong>
      <button
        class="xote-demo__button"
        ariaLabel="Increase count"
        onClick={_event => Signal.update(count, value => value + 1)}>
        {View.text("+")}
      </button>
    </div>
  </div>
}
