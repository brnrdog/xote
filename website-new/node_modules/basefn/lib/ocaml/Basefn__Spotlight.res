%%raw(`import './Basefn__Spotlight.css'`)

open Xote

@get external key: Dom.event => string = "key"
@send external focus: Dom.element => unit = "focus"
@send external querySelector: (Dom.element, string) => Nullable.t<Dom.element> = "querySelector"

type spotlightItem = {
  id: string,
  label: string,
  description?: string,
  group?: string,
  onSelect: unit => unit,
}

@jsx.component
let make = (
  ~isOpen: Signal.t<bool>,
  ~onClose: unit => unit,
  ~items: array<spotlightItem>,
  ~placeholder: string="Search...",
  ~emptyMessage: string="No results found.",
  ~filterFn: option<(string, spotlightItem) => bool>=?,
) => {
  let query = Signal.make("")
  let activeIndex = Signal.make(0)

  let defaultFilter = (q: string, item: spotlightItem) => {
    let q = String.toLowerCase(q)
    String.toLowerCase(item.label)->String.includes(q) ||
      switch item.description {
      | Some(desc) => String.toLowerCase(desc)->String.includes(q)
      | None => false
      }
  }

  let filterItem = switch filterFn {
  | Some(fn) => fn
  | None => defaultFilter
  }

  let filteredItems = Computed.make(() => {
    let q = Signal.get(query)
    if q === "" {
      items
    } else {
      items->Array.filter(item => filterItem(q, item))
    }
  })

  let handleSelect = (item: spotlightItem) => {
    item.onSelect()
    Signal.set(query, "")
    Signal.set(activeIndex, 0)
    onClose()
  }

  let handleKeyDown = (evt: Dom.event) => {
    let k = key(evt)
    let currentItems = Signal.get(filteredItems)
    let len = Array.length(currentItems)

    switch k {
    | "ArrowDown" => {
        let _ = Basefn__Dom.preventDefault(evt)
        Signal.update(activeIndex, i => mod(i + 1, max(len, 1)))
      }
    | "ArrowUp" => {
        let _ = Basefn__Dom.preventDefault(evt)
        Signal.update(activeIndex, i => mod(i - 1 + max(len, 1), max(len, 1)))
      }
    | "Enter" =>
      if len > 0 {
        let idx = Signal.get(activeIndex)
        switch currentItems->Array.get(idx) {
        | Some(item) => handleSelect(item)
        | None => ()
        }
      }
    | "Escape" => {
        Signal.set(query, "")
        Signal.set(activeIndex, 0)
        onClose()
      }
    | _ => ()
    }
  }

  let handleInput = (evt: Dom.event) => {
    let value = Basefn__Dom.target(evt)["value"]
    Signal.set(query, value)
    Signal.set(activeIndex, 0)
  }

  let handleBackdropClick = evt => {
    let target = Obj.magic(evt)["target"]
    let currentTarget = Obj.magic(evt)["currentTarget"]
    if target === currentTarget {
      Signal.set(query, "")
      Signal.set(activeIndex, 0)
      onClose()
    }
  }

  // Auto-focus input when opened
  let _ = Effect.run(() => {
    if Signal.get(isOpen) {
      let _ = setTimeout(() => {
        let doc: Dom.element = %raw(`document.body`)
        switch querySelector(doc, ".basefn-spotlight__input") {
        | Value(el) => focus(el)
        | _ => ()
        }
      }, 16)
    }
    None
  })

  let renderResults = () => {
    let currentItems = Signal.get(filteredItems)

    if Array.length(currentItems) === 0 {
      <div class="basefn-spotlight__empty"> {Component.text(emptyMessage)} </div>
    } else {
      let lastGroup: ref<option<string>> = ref(None)
      let elements: array<Component.node> = []

      currentItems->Array.forEachWithIndex((item, index) => {
        switch item.group {
        | Some(group) if Some(group) !== lastGroup.contents => {
            lastGroup := Some(group)
            let _ = elements->Array.push(
              <div key={"group-" ++ group} class="basefn-spotlight__group-label">
                {Component.text(group)}
              </div>,
            )
          }
        | _ => ()
        }

        let itemClass =
          "basefn-spotlight__item" ++
          (index === Signal.get(activeIndex) ? " basefn-spotlight__item--active" : "")

        let _ = elements->Array.push(
          <button key={item.id} class={itemClass} onClick={_ => handleSelect(item)}>
            <div class="basefn-spotlight__item-content">
              <div class="basefn-spotlight__item-label"> {Component.text(item.label)} </div>
              {switch item.description {
              | Some(desc) =>
                <div class="basefn-spotlight__item-description"> {Component.text(desc)} </div>
              | None => <> </>
              }}
            </div>
          </button>,
        )
      })

      elements->Component.fragment
    }
  }

  let content = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <div class="basefn-spotlight-backdrop" onClick={handleBackdropClick}>
          <div class="basefn-spotlight">
            <div class="basefn-spotlight__input-wrapper">
              <Basefn__Icon name={Basefn__Icon.Search} size={Basefn__Icon.Sm} />
              <input
                class="basefn-spotlight__input"
                type_="text"
                placeholder
                value={ReactiveProp.reactive(query)}
                onInput={handleInput}
                onKeyDown={handleKeyDown}
              />
            </div>
            <div class="basefn-spotlight__results"> {renderResults()} </div>
            <div class="basefn-spotlight__footer">
              <span class="basefn-spotlight__footer-hint">
                <span class="basefn-spotlight__footer-key"> {Component.text("\u2191")} </span>
                <span class="basefn-spotlight__footer-key"> {Component.text("\u2193")} </span>
                {Component.text("to navigate")}
              </span>
              <span class="basefn-spotlight__footer-hint">
                <span class="basefn-spotlight__footer-key"> {Component.text("\u21b5")} </span>
                {Component.text("to select")}
              </span>
              <span class="basefn-spotlight__footer-hint">
                <span class="basefn-spotlight__footer-key"> {Component.text("esc")} </span>
                {Component.text("to close")}
              </span>
            </div>
          </div>
        </div>,
      ]
    } else {
      []
    }
  })

  Component.signalFragment(content)
}
