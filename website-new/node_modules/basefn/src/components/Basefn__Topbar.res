%%raw(`import './Basefn__Topbar.css'`)

open Xote

type size = Sm | Md | Lg

type navItem = {
  label: string,
  active: bool,
  onClick: unit => unit,
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
  ~navItems: option<array<navItem>>=?,
  ~leftContent: option<Component.node>=?,
  ~centerContent: option<Component.node>=?,
  ~rightContent: option<Component.node>=?,
  ~onMenuClick: option<unit => unit>=?,
  ~size: size=Md,
) => {
  let class = "basefn-topbar basefn-topbar--" ++ sizeToString(size)

  <header class>
    <div class="basefn-topbar__left">
      {switch onMenuClick {
      | Some(handler) =>
        <button class="basefn-topbar__menu-button" onClick={_ => handler()}>
          {Component.text("\u2630")}
        </button>
      | None => <> </>
      }}
      {switch logo {
      | Some(logoContent) => <div class="basefn-topbar__logo"> {logoContent} </div>
      | None => <> </>
      }}
      {switch leftContent {
      | Some(content) => content
      | None => <> </>
      }}
    </div>
    <div class="basefn-topbar__center">
      {switch navItems {
      | Some(items) =>
        <nav class="basefn-topbar__nav">
          {items
          ->Array.mapWithIndex((item, index) => {
            let className =
              "basefn-topbar__nav-item" ++ (item.active ? " basefn-topbar__nav-item--active" : "")

            <button key={Int.toString(index)} class={className} onClick={_ => item.onClick()}>
              {Component.text(item.label)}
            </button>
          })
          ->Component.fragment}
        </nav>
      | None => <> </>
      }}
      {switch centerContent {
      | Some(content) => content
      | None => <> </>
      }}
    </div>
    <div class="basefn-topbar__right">
      {switch rightContent {
      | Some(content) => content
      | None => <> </>
      }}
    </div>
  </header>
}
