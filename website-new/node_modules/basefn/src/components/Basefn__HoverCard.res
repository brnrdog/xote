%%raw(`import './Basefn__HoverCard.css'`)

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
  ~position: position=Bottom,
  ~align: align=Center,
  ~openDelay: int=200,
  ~closeDelay: int=100,
  ~className: option<string>=?,
) => {
  let isOpen = Signal.make(false)
  let timeoutId: ref<option<Js.Global.timeoutId>> = ref(None)

  let clearExistingTimeout = () => {
    switch timeoutId.contents {
    | Some(id) => {
        Js.Global.clearTimeout(id)
        timeoutId := None
      }
    | None => ()
    }
  }

  let handleMouseEnter = _ => {
    clearExistingTimeout()
    let id = Js.Global.setTimeout(() => {
      Signal.set(isOpen, true)
    }, openDelay)
    timeoutId := Some(id)
  }

  let handleMouseLeave = _ => {
    clearExistingTimeout()
    let id = Js.Global.setTimeout(() => {
      Signal.set(isOpen, false)
    }, closeDelay)
    timeoutId := Some(id)
  }

  let getHoverCardClassName = () => {
    let baseClass = "basefn-hover-card"
    let customClass = switch className {
    | Some(c) => " " ++ c
    | None => ""
    }
    baseClass ++ customClass
  }

  let getContentClassName = () => {
    let baseClass = "basefn-hover-card__content"
    let positionClass = " basefn-hover-card__content--" ++ positionToString(position)
    let alignClass = " basefn-hover-card__content--align-" ++ alignToString(align)
    baseClass ++ positionClass ++ alignClass
  }

  let hoverCardContent = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <div class={getContentClassName()} onMouseEnter={handleMouseEnter} onMouseLeave={handleMouseLeave}>
          {content}
        </div>,
      ]
    } else {
      []
    }
  })

  <div class={getHoverCardClassName()} onMouseEnter={handleMouseEnter} onMouseLeave={handleMouseLeave}>
    <div class="basefn-hover-card__trigger">
      {trigger}
    </div>
    {Component.signalFragment(hoverCardContent)}
  </div>
}
