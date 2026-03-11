%%raw(`import './Basefn__Popover.css'`)

open Xote

type position = Top | Bottom | Left | Right

type align = Start | Center | End

let positionToString = (position: position) => {
  switch position {
  | Top => "top"
  | Bottom => "bottom"
  | Left => "left"
  | Right => "right"
  }
}

let alignToString = (align: align) => {
  switch align {
  | Start => "start"
  | Center => "center"
  | End => "end"
  }
}

@jsx.component
let make = (
  ~trigger: Component.node,
  ~content: Component.node,
  ~isOpen: Signal.t<bool>,
  ~onOpenChange: option<bool => unit>=?,
  ~position: position=Bottom,
  ~align: align=Center,
  ~closeOnClickOutside: bool=true,
  ~className: option<string>=?,
) => {
  let handleTriggerClick = _ => {
    let newValue = !Signal.get(isOpen)
    Signal.set(isOpen, newValue)
    switch onOpenChange {
    | Some(callback) => callback(newValue)
    | None => ()
    }
  }

  let handleClose = () => {
    Signal.set(isOpen, false)
    switch onOpenChange {
    | Some(callback) => callback(false)
    | None => ()
    }
  }

  let handleBackdropClick = _ => {
    if closeOnClickOutside {
      handleClose()
    }
  }

  let getPopoverClassName = () => {
    let baseClass = "basefn-popover"
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ customClass
  }

  let getContentClassName = () => {
    let baseClass = "basefn-popover__content"
    let positionClass = " basefn-popover__content--" ++ positionToString(position)
    let alignClass = " basefn-popover__content--align-" ++ alignToString(align)
    baseClass ++ positionClass ++ alignClass
  }

  let popoverContent = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <div class="basefn-popover__backdrop" onClick={handleBackdropClick} />,
        <div class={getContentClassName()}>
          {content}
        </div>,
      ]
    } else {
      []
    }
  })

  <div class={getPopoverClassName()}>
    <div class="basefn-popover__trigger" onClick={handleTriggerClick}>
      {trigger}
    </div>
    {Component.signalFragment(popoverContent)}
  </div>
}
