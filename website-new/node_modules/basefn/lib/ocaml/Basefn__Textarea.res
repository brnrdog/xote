%%raw(`import './Basefn__Textarea.css'`)

open Xote

@jsx.component
let make = (
  ~value: ReactiveProp.t<string>,
  ~onInput=?,
  ~placeholder: string="",
  ~disabled: bool=false,
) => {
  let onInput = (e: Dom.event) => {
    let t = Basefn__Dom.target(e)
    let v = t["value"]

    switch value {
    | Reactive(signal) => Signal.set(signal, v)
    | _ => ()
    }

    switch onInput {
    | Some(onInput) => onInput(v)
    | None => ()
    }
  }

  <textarea class="basefn-textarea" placeholder value disabled onInput />
}
