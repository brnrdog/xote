%%raw(`import './Basefn__Skeleton.css'`)

type variant = Text | Circular | Rectangular

type animation = Pulse | Wave | None

let variantToString = (variant: variant) => {
  switch variant {
  | Text => "text"
  | Circular => "circular"
  | Rectangular => "rectangular"
  }
}

let animationToString = (animation: animation) => {
  switch animation {
  | Pulse => "pulse"
  | Wave => "wave"
  | None => "none"
  }
}

@jsx.component
let make = (
  ~variant: variant=Rectangular,
  ~animation: animation=Pulse,
  ~width: option<string>=?,
  ~height: option<string>=?,
  ~className: option<string>=?,
) => {
  let getClassName = () => {
    let baseClass = "basefn-skeleton"
    let variantClass = " basefn-skeleton--" ++ variantToString(variant)
    let animationClass = " basefn-skeleton--" ++ animationToString(animation)
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ variantClass ++ animationClass ++ customClass
  }

  let getStyle = () => {
    let widthStyle = switch width {
    | Some(w) => "width: " ++ w ++ ";"
    | None => ""
    }
    let heightStyle = switch height {
    | Some(h) => "height: " ++ h ++ ";"
    | None => ""
    }
    widthStyle ++ heightStyle
  }

  <div class={getClassName()} style={getStyle()} />
}
