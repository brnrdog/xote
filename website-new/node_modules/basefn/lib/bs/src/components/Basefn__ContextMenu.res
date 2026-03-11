%%raw(`import './Basefn__ContextMenu.css'`)

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
  ~className: option<string>=?,
) => {
  let isOpen = Signal.make(false)
  let position = Signal.make((0, 0))

  let handleContextMenu = evt => {
    let _ = Obj.magic(evt)["preventDefault"]()
    let x: int = Obj.magic(evt)["clientX"]
    let y: int = Obj.magic(evt)["clientY"]
    Signal.set(position, (x, y))
    Signal.set(isOpen, true)
  }

  let handleClose = () => {
    Signal.set(isOpen, false)
  }

  let handleItemClick = (onClick: unit => unit, disabled: bool) => {
    switch disabled {
    | true => ()
    | false => {
        onClick()
        handleClose()
      }
    }
  }

  let getWrapperClass = () => {
    let baseClass = "basefn-context-menu"
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ customClass
  }

  let menuContent = Computed.make(() => {
    if Signal.get(isOpen) {
      let (x, y) = Signal.get(position)
      let styleStr = "left: " ++ Int.toString(x) ++ "px; top: " ++ Int.toString(y) ++ "px;"
      [
        <div class="basefn-context-menu__backdrop" onClick={_ => handleClose()} />,
        <div class="basefn-context-menu__menu" style={styleStr}>
          {items
          ->Array.mapWithIndex((item, index) => {
            switch item {
            | Item({label, onClick, ?disabled, ?danger}) => {
                let disabled = disabled->Option.getOr(false)
                let danger = danger->Option.getOr(false)
                let itemClass =
                  "basefn-context-menu__item" ++
                  (disabled ? " basefn-context-menu__item--disabled" : "") ++
                  (danger ? " basefn-context-menu__item--danger" : "")

                <button
                  key={Int.toString(index)}
                  class={itemClass}
                  onClick={_ => handleItemClick(onClick, disabled)}
                  disabled={disabled}
                >
                  {Component.text(label)}
                </button>
              }
            | Separator => <div key={Int.toString(index)} class="basefn-context-menu__separator" />
            }
          })
          ->Component.fragment}
        </div>,
      ]
    } else {
      []
    }
  })

  <div class={getWrapperClass()} onContextMenu={handleContextMenu}>
    {trigger}
    {Component.signalFragment(menuContent)}
  </div>
}
