@get external target: Dom.event => Dom.element = "target"
@get external value: Dom.element => string = "value"
@get external checked: Dom.element => bool = "checked"
@send external preventDefault: Dom.event => unit = "preventDefault"

let name = Signal.make("")
let plan = Signal.make("free")
let agreed = Signal.make(false)
let submitted = Signal.make(None)

let nameError = Computed.make(() =>
  String.trim(Signal.get(name)) == "" ? Some("Tell us your name.") : None
)
let canSubmit = Computed.make(() => Signal.get(nameError) == None && Signal.get(agreed))

let reset = () => {
  Signal.set(name, "")
  Signal.set(plan, "free")
  Signal.set(agreed, false)
}

let submit = (evt: Dom.event) => {
  preventDefault(evt)
  if Signal.peek(canSubmit) {
    Signal.set(submitted, Some(Signal.peek(name) ++ " joined the " ++ Signal.peek(plan) ++ " plan."))
    reset()
  }
}

@xote.component
let make = () =>
  <form class="forms-demo" onSubmit={submit}>
    <label class="forms-demo-field">
      {"Name"}
      <input
        class="todo-demo-input"
        value={name}
        placeholder="Ada Lovelace"
        onInput={e => Signal.set(name, e->target->value)}
      />
    </label>
    <label class="forms-demo-field">
      {"Plan"}
      <select class="todo-demo-input" value={plan} onChange={e => Signal.set(plan, e->target->value)}>
        <option value="free"> {"Free"} </option>
        <option value="team"> {"Team"} </option>
      </select>
    </label>
    <label class="forms-demo-check">
      <input
        type_="checkbox"
        checked={agreed}
        onChange={e => Signal.set(agreed, e->target->checked)}
      />
      {"I agree to the terms"}
    </label>
    <button class="counter-demo-btn" type_="submit" disabled={!Signal.get(canSubmit)}>
      {"Sign up"}
    </button>
    <p class="forms-demo-note">
      {switch Signal.get(submitted) {
      | Some(message) => message
      | None => Signal.get(nameError)->Option.getOr("Ready to sign up.")
      }}
    </p>
  </form>
