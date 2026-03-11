%%raw(`import './Basefn__Modal.css'`)

open Xote

type size = Sm | Md | Lg | Xl

let sizeToString = (size: size) => {
  switch size {
  | Sm => "sm"
  | Md => "md"
  | Lg => "lg"
  | Xl => "xl"
  }
}

@jsx.component
let make = (
  ~isOpen: Signal.t<bool>,
  ~onClose: unit => unit,
  ~title: option<string>=?,
  ~size: size=Md,
  ~closeOnBackdrop: bool=true,
  ~showCloseButton: bool=true,
  ~children: Component.node,
  ~footer: option<Component.node>=?,
) => {
  let handleBackdropClick = evt => {
    if closeOnBackdrop {
      // Only close if clicking the backdrop itself, not the modal content
      let target = Obj.magic(evt)["target"]
      let currentTarget = Obj.magic(evt)["currentTarget"]
      if target === currentTarget {
        onClose()
      }
    }
  }

  let getModalClass = () => {
    let sizeClass = "basefn-modal--" ++ sizeToString(size)
    "basefn-modal " ++ sizeClass
  }

  let content = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <div class="basefn-modal-backdrop" onClick={handleBackdropClick}>
          <div class={getModalClass()}>
            {switch title {
            | Some(titleText) =>
              <div class="basefn-modal__header">
                <h2 class="basefn-modal__title"> {Component.text(titleText)} </h2>
                {showCloseButton
                  ? <button class="basefn-modal__close" onClick={_ => onClose()}>
                      {Component.text("\u00d7")}
                    </button>
                  : <> </>}
              </div>
            | None => <> </>
            }}
            <div class="basefn-modal__body"> {children} </div>
            {switch footer {
            | Some(footerContent) => <div class="basefn-modal__footer"> {footerContent} </div>
            | None => <> </>
            }}
          </div>
        </div>,
      ]
    } else {
      []
    }
  })

  Component.signalFragment(content)
}
