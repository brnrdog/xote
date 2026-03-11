%%raw(`import './Basefn__Sidebar.css'`)

open Xote

type size = Sm | Md | Lg

type navItem = {
  label: string,
  icon: option<string>,
  active: bool,
  url: string,
}

type navSection = {
  title: option<string>,
  items: array<navItem>,
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
  ~logo: option<Component.node>=?,
  ~sections: array<navSection>,
  ~footer: option<Component.node>=?,
  ~size: size=Md,
  ~collapsed: bool=false,
) => {
  let scrolling = Signal.make(false)
  let getSidebarClass = () => {
    let sizeClass = " basefn-sidebar--" ++ sizeToString(size)
    let collapsedClass = collapsed ? " basefn-sidebar--collapsed" : ""
    "basefn-sidebar" ++ sizeClass ++ collapsedClass
  }

  let _ = Effect.run(() => {
    Basefn__Dom.addEventListener("scroll", () => {
      let scrollY = %raw("window.scrollY")
      Signal.set(scrolling, scrollY >= 64)
    })
  })

  <div class={getSidebarClass()}>
    {switch logo {
    | Some(logoContent) => {
        let class = Computed.make(() =>
          "basefn-sidebar__header" ++ (
            Signal.get(scrolling) ? " basefn-sidebar__header--scrolling" : ""
          )
        )
        <div class>
          <div class="basefn-sidebar__logo"> {logoContent} </div>
        </div>
      }
    | None => <> </>
    }}
    <nav class="basefn-sidebar__nav">
      {sections
      ->Array.map(section => {
        <div class="basefn-sidebar__section">
          {switch section.title {
          | Some(title) =>
            <div class="basefn-sidebar__section-title"> {Component.text(title)} </div>
          | None => <> </>
          }}
          {section.items
          ->Array.mapWithIndex((item, index) => {
            let itemClass =
              "basefn-sidebar__item" ++ (item.active ? " basefn-sidebar__item--active" : "")

            Router.link(
              ~to={item.url},
              ~attrs=[Component.attr("class", itemClass)],
              ~children=[
                <div class="basefn-sidebar__item-text"> {Component.text(item.label)} </div>,
              ],
              (),
            )
          })
          ->Component.fragment}
        </div>
      })
      ->Component.fragment}
    </nav>
    {switch footer {
    | Some(footerContent) => <div class="basefn-sidebar__footer"> {footerContent} </div>
    | None => <> </>
    }}
  </div>
}
