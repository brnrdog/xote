%%raw(`import './Basefn__Drawer.css'`)

open Xote

type position = Left | Right | Top | Bottom

type size = Sm | Md | Lg

let positionToString = (position: position) => {
  switch position {
  | Left => "left"
  | Right => "right"
  | Top => "top"
  | Bottom => "bottom"
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
  ~isOpen: Signal.t<bool>,
  ~onClose: unit => unit,
  ~position: position=Right,
  ~size: size=Md,
  ~title: option<string>=?,
  ~showCloseButton: bool=true,
  ~closeOnBackdrop: bool=true,
  ~children: Component.node,
  ~footer: option<Component.node>=?,
) => {
  let handleBackdropClick = evt => {
    if closeOnBackdrop {
      let target = Obj.magic(evt)["target"]
      let currentTarget = Obj.magic(evt)["currentTarget"]
      if target === currentTarget {
        onClose()
      }
    }
  }

  let getDrawerClass = () => {
    let positionClass = "basefn-drawer--" ++ positionToString(position)
    let sizeClass = "basefn-drawer--" ++ sizeToString(size)
    "basefn-drawer " ++ positionClass ++ " " ++ sizeClass
  }

  let content = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <>
          <div class="basefn-drawer-backdrop" onClick={handleBackdropClick} />
          <div class={getDrawerClass()}>
            {switch title {
            | Some(titleText) =>
              <div class="basefn-drawer__header">
                <h2 class="basefn-drawer__title"> {Component.text(titleText)} </h2>
                {showCloseButton
                  ? <button class="basefn-drawer__close" onClick={_ => onClose()}>
                      {Component.text("\u00d7")}
                    </button>
                  : <> </>}
              </div>
            | None => <> </>
            }}
            <div class="basefn-drawer__body"> {children} </div>
            {switch footer {
            | Some(footerContent) => <div class="basefn-drawer__footer"> {footerContent} </div>
            | None => <> </>
            }}
          </div>
        </>,
      ]
    } else {
      []
    }
  })

  Component.signalFragment(content)
}
