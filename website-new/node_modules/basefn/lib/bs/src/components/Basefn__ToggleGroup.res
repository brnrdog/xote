%%raw(`import './Basefn__ToggleGroup.css'`)

open Xote

type selectionType = Single | Multiple

type toggleItem = {
  value: string,
  label: string,
  disabled?: bool,
}

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
  ~type_: selectionType=Single,
  ~value: Signal.t<array<string>>,
  ~items: array<toggleItem>,
  ~onValueChange: option<array<string> => unit>=?,
  ~variant: variant=Default,
  ~size: size=Md,
  ~className: option<string>=?,
) => {
  let handleItemClick = (itemValue: string, itemDisabled: bool) => {
    if !itemDisabled {
      let currentValues = Signal.get(value)
      let newValues = switch type_ {
      | Single =>
        if Array.includes(currentValues, itemValue) {
          []
        } else {
          [itemValue]
        }
      | Multiple =>
        if Array.includes(currentValues, itemValue) {
          currentValues->Array.filter(v => v !== itemValue)
        } else {
          Array.concat(currentValues, [itemValue])
        }
      }
      Signal.set(value, newValues)
      switch onValueChange {
      | Some(callback) => callback(newValues)
      | None => ()
      }
    }
  }

  let getGroupClassName = () => {
    let baseClass = "basefn-toggle-group"
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ customClass
  }

  let getItemClassName = (itemValue: string, itemDisabled: bool) => {
    Computed.make(() => {
      let baseClass = "basefn-toggle-group__item"
      let variantClass = " basefn-toggle-group__item--" ++ variantToString(variant)
      let sizeClass = " basefn-toggle-group__item--" ++ sizeToString(size)
      let currentValues = Signal.get(value)
      let pressedClass = Array.includes(currentValues, itemValue) ? " basefn-toggle-group__item--pressed" : ""
      let disabledClass = itemDisabled ? " basefn-toggle-group__item--disabled" : ""
      baseClass ++ variantClass ++ sizeClass ++ pressedClass ++ disabledClass
    })
  }

  <div class={getGroupClassName()} role="group">
    {items
    ->Array.map(item => {
      let isDisabled = switch item.disabled {
      | Some(d) => d
      | None => false
      }
      <button
        key={item.value}
        class={getItemClassName(item.value, isDisabled)}
        onClick={_ => handleItemClick(item.value, isDisabled)}
        disabled={isDisabled}
      >
        {Component.text(item.label)}
      </button>
    })
    ->Component.fragment}
  </div>
}
