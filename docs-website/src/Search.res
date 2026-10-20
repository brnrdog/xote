// ---- Spotlight search ----
// A command-palette search over every docs page and its sections. Results are
// ranked, matched words are highlighted, and the list is a proper listbox the
// keyboard and the pointer drive together.

@val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"
@val external decodeURIComponent: string => string = "decodeURIComponent"
@val external getById: string => Nullable.t<Dom.element> = "document.getElementById"
@send external scrollIntoView: (Dom.element, {"block": string}) => unit = "scrollIntoView"
@send external focus: Dom.element => unit = "focus"
@val @scope("window")
external addEventListenerCapture: (string, Dom.event => unit, {"capture": bool}) => unit =
  "addEventListener"
@val @scope("window")
external removeEventListenerCapture: (string, Dom.event => unit, {"capture": bool}) => unit =
  "removeEventListener"

let eventKey = (_evt: Dom.event): string => %raw(`_evt.key || ""`)
let eventValue = (_evt: Dom.event): string => %raw(`_evt.target.value`)
let shiftKey = (_evt: Dom.event): bool => %raw(`!!_evt.shiftKey`)
let preventDefault = (_evt: Dom.event) => {
  let _ = %raw(`_evt.preventDefault()`)
}
let isEscapeEvent = (_evt: Dom.event): bool =>
  %raw(`_evt.key === "Escape" || _evt.key === "Esc" || _evt.keyCode === 27`)
let isCommandKEvent = (_evt: Dom.event): bool =>
  %raw(`(_evt.ctrlKey || _evt.metaKey) && ((_evt.key && _evt.key.toLowerCase() === "k") || _evt.code === "KeyK")`)

// ---- Open state ----
let isOpen = Signal.make(false)

let open_ = () => {
  Signal.set(isOpen, true)
  PostHog.capture("search_opened")
}

let close = () => Signal.set(isOpen, false)

// ---- Index and ranking ----
type kind = Page | Section

type entry = {
  kind: kind,
  title: string,
  page: SearchIndex.page,
  hash: string,
  order: int,
}

let entries: array<entry> = {
  let counter = ref(0)
  let next = () => {
    let order = counter.contents
    counter := order + 1
    order
  }
  SearchIndex.pages->Array.flatMap(page => {
    let pageEntry = {kind: Page, title: page.title, page, hash: "", order: next()}
    let sections =
      page.headings->Array.map(heading => {
        kind: Section,
        title: heading.text,
        page,
        hash: "#" ++ heading.id,
        order: next(),
      })
    Array.concat([pageEntry], sections)
  })
}

let wordsOf = (query: string) =>
  query->String.toLowerCase->String.trim->String.split(" ")->Array.filter(word => word != "")

// Every word must appear in the entry's title or its page and section names.
// Title matches outrank context matches; pages edge out their own sections.
let score = (entry: entry, phrase: string, words: array<string>) => {
  let title = entry.title->String.toLowerCase
  let context = (entry.page.title ++ " " ++ entry.page.section)->String.toLowerCase
  let haystack = title ++ " " ++ context
  if !(words->Array.every(word => haystack->String.includes(word))) {
    None
  } else {
    let base = if title == phrase {
      1000
    } else if title->String.startsWith(phrase) {
      600
    } else if title->String.includes(phrase) {
      400
    } else if words->Array.every(word => title->String.includes(word)) {
      250
    } else {
      80
    }
    Some(base + (entry.kind == Page ? 60 : 0))
  }
}

let maxResults = 40

let search = (query: string): array<entry> => {
  let words = wordsOf(query)
  if Array.length(words) == 0 {
    entries->Array.filter(entry => entry.kind == Page)
  } else {
    let phrase = query->String.toLowerCase->String.trim
    entries
    ->Array.filterMap(entry => score(entry, phrase, words)->Option.map(points => (points, entry)))
    ->Array.toSorted(((pointsA, a), (pointsB, b)) =>
      pointsA != pointsB ? Int.toFloat(pointsB - pointsA) : Int.toFloat(a.order - b.order)
    )
    ->Array.slice(~start=0, ~end=maxResults)
    ->Array.map(((_, entry)) => entry)
  }
}

// Wraps every occurrence of the query words in <mark>.
let highlight = (text: string, words: array<string>): View.node => {
  let lower = text->String.toLowerCase
  let length = String.length(text)
  let marked = Array.make(~length, false)
  words->Array.forEach(word => {
    let size = String.length(word)
    let from = ref(0)
    let searching = ref(size > 0)
    while searching.contents {
      let index = lower->String.indexOfFrom(word, from.contents)
      if index < 0 {
        searching := false
      } else {
        for position in index to index + size - 1 {
          marked->Array.setUnsafe(position, true)
        }
        from := index + size
      }
    }
  })
  let nodes = []
  let index = ref(0)
  while index.contents < length {
    let isMarked = marked->Array.getUnsafe(index.contents)
    let start = index.contents
    while index.contents < length && marked->Array.getUnsafe(index.contents) == isMarked {
      index := index.contents + 1
    }
    let segment = text->String.slice(~start, ~end=index.contents)
    nodes
    ->Array.push(isMarked ? <mark class="search-hit"> {View.text(segment)} </mark> : View.text(segment))
    ->ignore
  }
  View.fragment(nodes)
}

let optionId = index => "search-option-" ++ Int.toString(index)

let scrollHashIntoView = (hash: string) =>
  if hash != "" {
    let id = hash->String.slice(~start=1)->decodeURIComponent
    switch getById(id)->Nullable.toOption {
    | Some(element) => scrollIntoView(element, {"block": "start"})
    | None => ()
    }
  }

// ---- Icons ----
let searchIcon =
  <svg class="search-icon" width="18" height="18" viewBox="0 0 16 16" ariaHidden=true>
    <circle cx="7" cy="7" r="5" fill="none" stroke="currentColor" strokeWidth="1.5" />
    <path d="M11 11l3.5 3.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
  </svg>

let pageIcon =
  <svg width="16" height="16" viewBox="0 0 16 16" ariaHidden=true>
    <path
      d="M4 1.75h5.5L12.25 4.5v9.75H4z"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.3"
      strokeLinejoin="round"
    />
    <path d="M6 8h4.25M6 10.5h4.25" stroke="currentColor" strokeWidth="1.3" strokeLinecap="round" />
  </svg>

let sectionIcon =
  <svg width="16" height="16" viewBox="0 0 16 16" ariaHidden=true>
    <path
      d="M6.5 2.5L5 13.5M11 2.5l-1.5 11M2.75 6h11M2.25 10h11"
      stroke="currentColor"
      strokeWidth="1.3"
      strokeLinecap="round"
    />
  </svg>

// ---- The palette ----
module Modal = {
  type props = {}

  let make = (_props: props) => {
    let query = Signal.make("")
    let selected = Signal.make(0)
    let inputRef = View.Ref.make()
    let results = Computed.make(() => search(Signal.get(query)))

    let reset = () =>
      Signal.batch(() => {
        close()
        Signal.set(query, "")
        Signal.set(selected, 0)
      })

    let focusInput = () => inputRef->View.Ref.peek->Option.forEach(focus)

    let go = (entry: entry) => {
      PostHog.capture(
        "search_result_selected",
        ~properties={"result_path": entry.page.path ++ entry.hash, "result_title": entry.title},
      )
      reset()
      queueMicrotask(() => {
        Router.push(entry.page.path, ~hash=entry.hash, ())
        if entry.hash != "" {
          queueMicrotask(() => scrollHashIntoView(entry.hash))
        }
      })
    }

    let move = delta => {
      let count = Array.length(Signal.peek(results))
      if count > 0 {
        Signal.update(selected, index => mod(index + delta + count, count))
      }
    }

    if SSRContext.isClient {
      // Focus the field on open.
      Effect.run(() => {
        if Signal.get(isOpen) {
          queueMicrotask(focusInput)
        }
        None
      })

      // Keep the active option in view.
      Effect.run(() => {
        let index = Signal.get(selected)
        let _ = Signal.get(results)
        if Signal.peek(isOpen) {
          queueMicrotask(() =>
            switch getById(optionId(index))->Nullable.toOption {
            | Some(element) => scrollIntoView(element, {"block": "nearest"})
            | None => ()
            }
          )
        }
        None
      })

      // Navigating anywhere closes the palette.
      Effect.run(() => {
        let _ = Signal.get(Router.location())
        if Signal.peek(isOpen) {
          reset()
        }
        None
      })

      // Escape closes it from anywhere on the page.
      Effect.run(() =>
        if Signal.get(isOpen) {
          let onEscape = (evt: Dom.event) =>
            if isEscapeEvent(evt) {
              preventDefault(evt)
              reset()
            }
          addEventListenerCapture("keydown", onEscape, {"capture": true})
          Some(() => removeEventListenerCapture("keydown", onEscape, {"capture": true}))
        } else {
          None
        }
      )
    }

    let onKeyDown = (evt: Dom.event) =>
      switch eventKey(evt) {
      | "ArrowDown" =>
        preventDefault(evt)
        move(1)
      | "ArrowUp" =>
        preventDefault(evt)
        move(-1)
      | "Tab" =>
        preventDefault(evt)
        move(shiftKey(evt) ? -1 : 1)
      | "Home" if Signal.peek(query) == "" =>
        preventDefault(evt)
        Signal.set(selected, 0)
      | "End" if Signal.peek(query) == "" =>
        preventDefault(evt)
        Signal.set(selected, max(0, Array.length(Signal.peek(results)) - 1))
      | "Enter" =>
        preventDefault(evt)
        Signal.peek(results)->Array.get(Signal.peek(selected))->Option.forEach(go)
      | _ => ()
      }

    let clear = _ => {
      Signal.batch(() => {
        Signal.set(query, "")
        Signal.set(selected, 0)
      })
      focusInput()
    }

    let option = (entry: entry, index: int, words: array<string>) =>
      View.element(
        "li",
        ~attrs=[
          View.attr("id", optionId(index)),
          View.attr("role", "option"),
          View.computedAttr("class", () =>
            "search-option" ++ (Signal.get(selected) == index ? " active" : "")
          ),
          View.computedAttr("aria-selected", () =>
            Signal.get(selected) == index ? "true" : "false"
          ),
        ],
        ~events=[
          ("mousemove", _ => if Signal.peek(selected) != index {
            Signal.set(selected, index)
          }),
          // mousedown keeps focus in the field; click then navigates.
          ("mousedown", preventDefault),
          ("click", _ => go(entry)),
        ],
        ~children=[
          <span class="search-option-icon"> {entry.kind == Page ? pageIcon : sectionIcon} </span>,
          <span class="search-option-text">
            <span class="search-option-title"> {highlight(entry.title, words)} </span>
            <span class="search-option-crumb">
              {View.text(
                switch entry.kind {
                | Page => entry.page.section
                | Section => entry.page.section ++ " › " ++ entry.page.title
                },
              )}
            </span>
          </span>,
          <span class="search-option-enter" ariaHidden=true> {View.text("↵")} </span>,
        ],
        (),
      )

    let resultList = () => {
      let items = Signal.get(results)
      let words = wordsOf(Signal.get(query))
      if Array.length(items) == 0 {
        [
          <div class="search-empty">
            <p> {View.text("No results for “" ++ Signal.get(query)->String.trim ++ "”")} </p>
            <span> {View.text("Try a module name like Signal, View or Router.")} </span>
          </div>,
        ]
      } else {
        [
          <div class="search-group-label">
            {View.text(Array.length(words) == 0 ? "Pages" : "Best matches")}
          </div>,
          View.element(
            "ul",
            ~attrs=[
              View.attr("id", "search-listbox"),
              View.attr("role", "listbox"),
              View.attr("class", "search-list"),
              View.attr("aria-label", "Search results"),
            ],
            ~children=items->Array.mapWithIndex((entry, index) => option(entry, index, words)),
            (),
          ),
        ]
      }
    }

    let palette = () =>
      View.element(
        "div",
        ~attrs=[View.attr("class", "search-overlay")],
        ~events=[
          (
            "mousedown",
            _evt => {
              let onBackdrop: bool = %raw(`_evt.target === _evt.currentTarget`)
              if onBackdrop {
                reset()
              }
            },
          ),
        ],
        ~children=[
          <div class="search-modal" role="dialog" ariaLabel="Search the docs">
            <div class="search-field">
              {searchIcon}
              {View.element(
                "input",
                ~ref=inputRef,
                ~attrs=[
                  View.attr("class", "search-input"),
                  View.attr("type", "text"),
                  View.attr("placeholder", "Search pages and sections…"),
                  View.attr("autocomplete", "off"),
                  View.attr("spellcheck", "false"),
                  View.attr("role", "combobox"),
                  View.attr("aria-expanded", "true"),
                  View.attr("aria-controls", "search-listbox"),
                  View.attr("aria-autocomplete", "list"),
                  View.computedAttr("aria-activedescendant", () => optionId(Signal.get(selected))),
                  View.computedAttr("value", () => Signal.get(query)),
                ],
                ~events=[
                  (
                    "input",
                    evt =>
                      Signal.batch(() => {
                        Signal.set(query, eventValue(evt))
                        Signal.set(selected, 0)
                      }),
                  ),
                  ("keydown", onKeyDown),
                ],
                (),
              )}
              {View.signalFragment(
                Computed.make(() =>
                  Signal.get(query) == ""
                    ? []
                    : [
                        View.element(
                          "button",
                          ~attrs=[
                            View.attr("type", "button"),
                            View.attr("class", "search-clear"),
                            View.attr("aria-label", "Clear search"),
                          ],
                          ~events=[("mousedown", preventDefault), ("click", clear)],
                          ~children=[View.text("✕")],
                          (),
                        ),
                      ]
                ),
              )}
              <kbd class="search-esc"> {View.text("esc")} </kbd>
            </div>
            <div class="search-results"> {View.signalFragment(Computed.make(resultList))} </div>
            <div class="search-footer">
              <span>
                <kbd> {View.text("↑")} </kbd>
                <kbd> {View.text("↓")} </kbd>
                {View.text(" to navigate")}
              </span>
              <span>
                <kbd> {View.text("↵")} </kbd>
                {View.text(" to open")}
              </span>
              <span>
                <kbd> {View.text("esc")} </kbd>
                {View.text(" to close")}
              </span>
              <span class="search-count">
                {View.signalText(() => {
                  let count = Array.length(Signal.get(results))
                  count == 1 ? "1 result" : Int.toString(count) ++ " results"
                })}
              </span>
            </div>
          </div>,
        ],
        (),
      )

    View.signalFragment(Computed.make(() => Signal.get(isOpen) ? [palette()] : []))
  }
}

// ---- Global Cmd/Ctrl+K (client only) ----
if SSRContext.isClient {
  let onShortcut = (evt: Dom.event) =>
    if isCommandKEvent(evt) {
      preventDefault(evt)
      Signal.peek(isOpen) ? close() : open_()
    }
  addEventListenerCapture("keydown", onShortcut, {"capture": true})
}
