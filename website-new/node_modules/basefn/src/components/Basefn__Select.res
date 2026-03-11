%%raw(`import './Basefn__Select.css'`)

open Xote

type selectOption = {
  value: string,
  label: string,
}

@jsx.component
let make = (
  ~value: Signal.t<string>,
  ~onChange: option<Dom.event => unit>=?,
  ~options: Signal.t<array<selectOption>>,
  ~disabled: bool=false,
) => {
  let onChange = (e: Dom.event) => {
    let t = Obj.magic(e)["target"]
    let v = t["value"]

    Signal.set(value, v)

    switch onChange {
    | Some(onChange) => onChange(v)
    | None => ()
    }
  }
  <select name="test" class="basefn-select" value={value} disabled onChange>
    {Component.list(options, opt =>
      <option value={opt.value}> {Component.text(opt.label)} </option>
    )}
  </select>
}
