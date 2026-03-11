%%raw(`import './Basefn__Dropdown.css'`)

open Xote

type menuItem = {
  label: string,
  onClick: unit => unit,
  disabled?: bool,
  danger?: bool,
}

type menuContent =
  | Item(menuItem)
  | Separator

@jsx.component
let make = (
  ~trigger: Component.node,
  ~items: array<menuContent>,
  ~align: [#left | #right]=#left,
) => {
  let isOpen = Signal.make(false)

  let handleToggle = _ => {
    Signal.update(isOpen, prev => !prev)
  }

  let handleItemClick = (onClick: unit => unit, disabled: bool) => {
    switch disabled {
    | true => ()
    | _ => {
        onClick()
        Signal.set(isOpen, false)
      }
    }
  }

  let getMenuClass = () => {
    let baseClass = "basefn-dropdown__menu"
    let alignClass = switch align {
    | #right => " basefn-dropdown__menu--right"
    | #left => ""
    }
    baseClass ++ alignClass
  }

  let handleBackdropClick = _ => {
    Signal.set(isOpen, false)
  }

  let menuContent = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <div class="basefn-dropdown__backdrop" onClick={handleBackdropClick} />,
        <div class={getMenuClass()}>
          {items
          ->Array.mapWithIndex((item, index) => {
            switch item {
            | Item({label, onClick, ?disabled, ?danger}) => {
                let disabled = disabled->Option.getOr(false)
                let danger = danger->Option.getOr(false)
                let className =
                  "basefn-dropdown__item" ++
                  (disabled ? " basefn-dropdown__item--disabled" : "") ++ (
                    danger ? " basefn-dropdown__item--danger" : ""
                  )

                <button
                  key={Int.toString(index)}
                  class={className}
                  onClick={_ => handleItemClick(onClick, disabled)}
                  disabled={disabled}
                >
                  {Component.text(label)}
                </button>
              }
            | Separator => <div key={Int.toString(index)} class="basefn-dropdown__separator" />
            }
          })
          ->Component.fragment}
        </div>,
      ]
    } else {
      []
    }
  })

  <div class="basefn-dropdown">
    <div onClick={handleToggle}> {trigger} </div>
    {Component.signalFragment(menuContent)}
  </div>
}
