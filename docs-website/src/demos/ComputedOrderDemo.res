let unitPrice = Signal.make(24)
let quantity = Signal.make(2)
let expressShipping = Signal.make(false)

let subtotal = Computed.make(() => Signal.get(unitPrice) * Signal.get(quantity))
let shippingCost = Computed.make(() => if Signal.get(expressShipping) { 15 } else { 0 })
let total = Computed.make(() => Signal.get(subtotal) + Signal.get(shippingCost))

let decreaseQuantity = (_evt: Dom.event) => {
  Signal.update(quantity, current => if current > 1 { current - 1 } else { 1 })
}

let increaseQuantity = (_evt: Dom.event) => {
  Signal.update(quantity, current => current + 1)
}

let setStandard = (_evt: Dom.event) => Signal.set(unitPrice, 24)
let setPremium = (_evt: Dom.event) => Signal.set(unitPrice, 42)
let setStandardShipping = (_evt: Dom.event) => Signal.set(expressShipping, false)
let setExpressShipping = (_evt: Dom.event) => Signal.set(expressShipping, true)

@xote.component
let make = () => {
  <div class="computed-order-demo">
    <div class="computed-order-demo-section">
      <div class="computed-order-demo-heading">
        <h3> {View.text("Order Summary")} </h3>
        <p>
          {View.text("The writable state is unit price, quantity, and shipping mode. Everything else is derived.")}
        </p>
      </div>

      <div class="computed-order-demo-controls">
        <div class="computed-order-demo-control-group">
          <div class="computed-order-demo-label"> {View.text("Quantity")} </div>
          <div class="computed-order-demo-stepper">
            <button class="computed-order-demo-stepper-btn" onClick={decreaseQuantity}>
              {View.text("-")}
            </button>
            <div class="computed-order-demo-stepper-value">
              <View.Int> {quantity} </View.Int>
            </div>
            <button class="computed-order-demo-stepper-btn" onClick={increaseQuantity}>
              {View.text("+")}
            </button>
          </div>
        </div>

        <div class="computed-order-demo-control-group">
          <div class="computed-order-demo-label"> {View.text("Plan")} </div>
          <div class="computed-order-demo-choice-row">
            <button
              class={
                if Signal.get(unitPrice) == 24 {
                  "computed-order-demo-choice active"
                } else {
                  "computed-order-demo-choice"
                }}
              onClick={setStandard}>
              {View.text("Standard")}
            </button>
            <button
              class={
                if Signal.get(unitPrice) == 42 {
                  "computed-order-demo-choice active"
                } else {
                  "computed-order-demo-choice"
                }}
              onClick={setPremium}>
              {View.text("Premium")}
            </button>
          </div>
        </div>

        <div class="computed-order-demo-control-group">
          <div class="computed-order-demo-label"> {View.text("Shipping")} </div>
          <div class="computed-order-demo-choice-row">
            <button
              class={
                if !Signal.get(expressShipping) {
                  "computed-order-demo-choice active"
                } else {
                  "computed-order-demo-choice"
                }}
              onClick={setStandardShipping}>
              {View.text("Standard")}
            </button>
            <button
              class={
                if Signal.get(expressShipping) {
                  "computed-order-demo-choice active"
                } else {
                  "computed-order-demo-choice"
                }}
              onClick={setExpressShipping}>
              {View.text("Express")}
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="computed-order-demo-summary">
      <div class="computed-order-demo-row">
        <span> {View.text("Subtotal")} </span>
        <strong>
          <View.Text> "$" </View.Text>
          <View.Int> {subtotal} </View.Int>
        </strong>
      </div>
      <div class="computed-order-demo-row">
        <span> {View.text("Shipping")} </span>
        <strong>
          <View.Text> "$" </View.Text>
          <View.Int> {shippingCost} </View.Int>
        </strong>
      </div>
      <div class="computed-order-demo-row total">
        <span> {View.text("Total")} </span>
        <strong>
          <View.Text> "$" </View.Text>
          <View.Int> {total} </View.Int>
        </strong>
      </div>
    </div>
  </div>
}
