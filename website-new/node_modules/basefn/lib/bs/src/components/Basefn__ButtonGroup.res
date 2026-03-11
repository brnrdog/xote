%%raw(`import './Basefn__ButtonGroup.css'`)

open Xote

type orientation = Horizontal | Vertical

let orientationToString = (orientation: orientation) => {
  switch orientation {
  | Horizontal => "horizontal"
  | Vertical => "vertical"
  }
}

@jsx.component
let make = (
  ~orientation: orientation=Horizontal,
  ~className: option<string>=?,
  ~children: Component.node,
) => {
  let getClassName = () => {
    let baseClass = "basefn-button-group"
    let orientationClass = " basefn-button-group--" ++ orientationToString(orientation)
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ orientationClass ++ customClass
  }

  <div class={getClassName()} role="group">
    {children}
  </div>
}
