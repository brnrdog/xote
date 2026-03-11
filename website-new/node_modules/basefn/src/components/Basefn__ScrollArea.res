%%raw(`import './Basefn__ScrollArea.css'`)

open Xote

type orientation = Vertical | Horizontal | Both

type scrollbarSize = Sm | Md | Lg

let orientationToString = (orientation: orientation) => {
  switch orientation {
  | Vertical => "vertical"
  | Horizontal => "horizontal"
  | Both => "both"
  }
}

let scrollbarSizeToString = (size: scrollbarSize) => {
  switch size {
  | Sm => "sm"
  | Md => "md"
  | Lg => "lg"
  }
}

@jsx.component
let make = (
  ~orientation: orientation=Vertical,
  ~scrollbarSize: scrollbarSize=Md,
  ~maxHeight: option<string>=?,
  ~maxWidth: option<string>=?,
  ~className: option<string>=?,
  ~children: Component.node,
) => {
  let getClassName = () => {
    let baseClass = "basefn-scroll-area"
    let orientationClass = " basefn-scroll-area--" ++ orientationToString(orientation)
    let sizeClass = " basefn-scroll-area--scrollbar-" ++ scrollbarSizeToString(scrollbarSize)
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ orientationClass ++ sizeClass ++ customClass
  }

  let getStyle = () => {
    let maxHeightStyle = switch maxHeight {
    | Some(h) => "max-height: " ++ h ++ ";"
    | None => ""
    }
    let maxWidthStyle = switch maxWidth {
    | Some(w) => "max-width: " ++ w ++ ";"
    | None => ""
    }
    maxHeightStyle ++ maxWidthStyle
  }

  <div class={getClassName()} style={getStyle()}>
    {children}
  </div>
}
