%%raw(`import './Basefn__Breadcrumb.css'`)

open Xote

type breadcrumbItem = {
  label: string,
  href: option<string>,
  onClick: option<unit => unit>,
}

@jsx.component
let make = (~items: array<breadcrumbItem>, ~separator: string="/") => {
  <nav class="basefn-breadcrumb">
    {items
    ->Array.mapWithIndex((item, index) => {
      let isLast = index == Array.length(items) - 1
      let className = isLast ? "basefn-breadcrumb__link--active" : ""

      <div key={Int.toString(index)} class="basefn-breadcrumb__item">
        {switch (item.href, item.onClick) {
        | (Some(href), _) =>
          <a href={href} class={"basefn-breadcrumb__link " ++ className}>
            {Component.text(item.label)}
          </a>
        | (None, Some(onClick)) =>
          <button
            class={"basefn-breadcrumb__link " ++ className}
            onClick={_ => onClick()}
            style="background: none; border: none; padding: 0; font: inherit;"
          >
            {Component.text(item.label)}
          </button>
        | (None, None) =>
          <span class={"basefn-breadcrumb__link " ++ className}>
            {Component.text(item.label)}
          </span>
        }}
        {!isLast
          ? <span class="basefn-breadcrumb__separator"> {Component.text(separator)} </span>
          : <> </>}
      </div>
    })
    ->Component.fragment}
  </nav>
}
