%%raw(`import './Basefn__AspectRatio.css'`)

open Xote

@jsx.component
let make = (
  ~ratio: float=1.0,
  ~className: option<string>=?,
  ~children: Component.node,
) => {
  let getClassName = () => {
    let baseClass = "basefn-aspect-ratio"
    switch className {
    | Some(c) => baseClass ++ " " ++ c
    | None => baseClass
    }
  }

  let getStyle = () => {
    "aspect-ratio: " ++ Float.toString(ratio) ++ ";"
  }

  <div class={getClassName()} style={getStyle()}>
    {children}
  </div>
}
