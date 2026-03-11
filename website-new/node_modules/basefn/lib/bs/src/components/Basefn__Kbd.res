%%raw(`import './Basefn__Kbd.css'`)

open Xote

type size = Sm | Md | Lg

let sizeToString = (size: size) => {
  switch size {
  | Sm => "sm"
  | Md => "md"
  | Lg => "lg"
  }
}

@jsx.component
let make = (~keys: Signal.t<array<string>>, ~size: size=Md) => {
  let getClassName = () => {
    let sizeClass = "basefn-kbd--" ++ sizeToString(size)
    "basefn-kbd " ++ sizeClass
  }

  <kbd class={getClassName()}>
    {Component.list(keys, key => {
      <span class="basefn-kbd__key"> {Component.text(key)} </span>
    })}
  </kbd>
}
