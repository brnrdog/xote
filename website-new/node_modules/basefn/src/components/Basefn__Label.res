%%raw(`import './Basefn__Label.css'`)

open Xote

@jsx.component
let make = (~text: string, ~required: bool=false) => {
  let getClassName = () => {
    let base = "basefn-label"
    if required {
      base ++ " basefn-label--required"
    } else {
      base
    }
  }

  // TODO: Add htmlFor support to Xote JSX props
  <label class={getClassName()}> {Component.text(text)} </label>
}
