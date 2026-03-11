%%raw(`import './Basefn__Checkbox.css'`)

open Xote

@jsx.component
let make = (
  ~checked: Signal.t<bool>,
  ~onChange: option<Dom.event => unit>=?,
  ~label: string,
  ~disabled: bool=false,
) => {
  let getWrapperClassName = () => {
    let base = "basefn-checkbox-wrapper"
    if disabled {
      base ++ " basefn-checkbox-wrapper--disabled"
    } else {
      base
    }
  }

  <label class={getWrapperClassName()}>
    <input type_="checkbox" class="basefn-checkbox-input" checked={checked} disabled ?onChange />
    <span class="basefn-checkbox-label"> {Component.text(label)} </span>
  </label>
}
