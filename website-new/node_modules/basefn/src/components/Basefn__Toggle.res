%%raw(`import './Basefn__Toggle.css'`)

open Xote

type variant = Default | Outline

type size = Sm | Md | Lg

let variantToString = (variant: variant) => {
  switch variant {
  | Default => "default"
  | Outline => "outline"
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
  ~pressed: Signal.t<bool>,
  ~onPressedChange: option<bool => unit>=?,
  ~variant: variant=Default,
  ~size: size=Md,
  ~disabled: bool=false,
  ~className: option<string>=?,
  ~children: Component.node,
) => {
  let handleClick = _ => {
    if !disabled {
      let newValue = !Signal.get(pressed)
      Signal.set(pressed, newValue)
      switch onPressedChange {
      | Some(callback) => callback(newValue)
      | None => ()
      }
    }
  }

  let computedClassName = Computed.make(() => {
    let baseClass = "basefn-toggle"
    let variantClass = " basefn-toggle--" ++ variantToString(variant)
    let sizeClass = " basefn-toggle--" ++ sizeToString(size)
    let pressedClass = Signal.get(pressed) ? " basefn-toggle--pressed" : ""
    let disabledClass = disabled ? " basefn-toggle--disabled" : ""
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ variantClass ++ sizeClass ++ pressedClass ++ disabledClass ++ customClass
  })

  <button
    class={computedClassName}
    onClick={handleClick}
    disabled={disabled}
  >
    {children}
  </button>
}
