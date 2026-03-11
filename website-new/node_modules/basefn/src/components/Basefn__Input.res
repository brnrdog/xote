open Xote

%%raw(`import './Basefn__Input.css'`)

type inputType = Text | Email | Password | Number | Tel | Url | Search | Date | Time

type inputSize = Sm | Md

type radius = Full | Md

let inputTypeToString = (type_: inputType) => {
  switch type_ {
  | Text => "text"
  | Email => "email"
  | Password => "password"
  | Number => "number"
  | Tel => "tel"
  | Url => "url"
  | Search => "search"
  | Date => "date"
  | Time => "time"
  }
}

@jsx.component
let make = (
  ~value: ReactiveProp.t<string>,
  ~onInput: option<Dom.event => unit>=?,
  ~type_: inputType=Text,
  ~placeholder: string="",
  ~disabled=ReactiveProp.static(false),
  ~size=Md,
  ~radius=Md,
  ~name=?,
  ~style=?,
) => {
  let class = {
    let radiusClass = switch radius {
    | Full => "basefn-input--radius-full"
    | _ => ""
    }

    "basefn-input " ++ radiusClass
  }
  <input
    class ?style type_={inputTypeToString(type_)} placeholder value={value} disabled name ?onInput
  />
}
