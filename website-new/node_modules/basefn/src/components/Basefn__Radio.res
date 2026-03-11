%%raw(`import './Basefn__Radio.css'`)

open Xote

@jsx.component
let make = (
  ~checked: Signal.t<bool>,
  ~onChange: option<Dom.event => unit>=?,
  ~value: string,
  ~label: string,
  ~disabled: bool=false,
  ~name: string,
) => {
  let getWrapperClassName = () => {
    let base = "basefn-radio-wrapper"
    if disabled {
      base ++ " basefn-radio-wrapper--disabled"
    } else {
      base
    }
  }

  <label class={getWrapperClassName()}>
    <input
      type_="radio"
      class="basefn-radio-input"
      name
      value
      checked={checked}
      disabled={disabled}
      ?onChange
    />
    <span class="basefn-radio-label"> {Component.text(label)} </span>
  </label>
}
