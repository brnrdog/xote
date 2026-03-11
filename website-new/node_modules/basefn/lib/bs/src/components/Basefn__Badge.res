%%raw(`import './Basefn__Badge.css'`)

open Xote

type variant = Default | Primary | Secondary | Success | Warning | Error

type size = Sm | Md | Lg

let variantToString = (variant: variant) => {
  switch variant {
  | Default => "default"
  | Primary => "primary"
  | Secondary => "secondary"
  | Success => "success"
  | Warning => "warning"
  | Error => "error"
  }
}

let sizeToString = (size: size) => {
  switch size {
  | Sm => "sm"
  | Md => "md"
  | Lg => "lg"
  }
}

@jsx.component
let make = (
  ~label: Signal.t<string>,
  ~variant: variant=Default,
  ~size: size=Md,
  ~dot: bool=false,
) => {
  let getClassName = () => {
    let variantClass = "basefn-badge--" ++ variantToString(variant)
    let sizeClass = "basefn-badge--" ++ sizeToString(size)
    let dotClass = dot ? " basefn-badge--dot" : ""
    "basefn-badge " ++ variantClass ++ " " ++ sizeClass ++ dotClass
  }

  <span class={getClassName()}> {Component.SignalText(label)} </span>
}
