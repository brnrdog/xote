%%raw(`import './Basefn__Separator.css'`)

open Xote

type orientation = Horizontal | Vertical

type variant = Solid | Dashed | Dotted

let orientationToString = (orientation: orientation) => {
  switch orientation {
  | Horizontal => "horizontal"
  | Vertical => "vertical"
  }
}

let variantToString = (variant: variant) => {
  switch variant {
  | Solid => "solid"
  | Dashed => "dashed"
  | Dotted => "dotted"
  }
}

@jsx.component
let make = (
  ~orientation: orientation=Horizontal,
  ~variant: variant=Solid,
  ~label: option<string>=?,
) => {
  let getClassName = () => {
    let orientationClass = "basefn-separator--" ++ orientationToString(orientation)
    let variantClass = "basefn-separator--" ++ variantToString(variant)
    "basefn-separator " ++ orientationClass ++ " " ++ variantClass
  }

  switch label {
  | Some(text) =>
    <div class={getClassName() ++ " basefn-separator--with-label"}>
      <div class="basefn-separator__line" />
      <span class="basefn-separator__label"> {Component.text(text)} </span>
      <div class="basefn-separator__line" />
    </div>
  | None => <div class={getClassName()} role="separator" />
  }
}
