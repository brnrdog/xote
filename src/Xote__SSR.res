open Signals

module Component = Xote__Component

/* ============================================================================
 * HTML Utilities
 * ============================================================================ */

module Html = {
  /* Escape HTML special characters to prevent XSS */
  let escape = (str: string): string => {
    str
    ->String.replaceAll("&", "&amp;")
    ->String.replaceAll("<", "&lt;")
    ->String.replaceAll(">", "&gt;")
    ->String.replaceAll("\"", "&quot;")
    ->String.replaceAll("'", "&#x27;")
  }

  /* Void elements that don't have closing tags */
  let voidElements = [
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "param",
    "source",
    "track",
    "wbr",
  ]

  let isVoidElement = (tag: string): bool => {
    voidElements->Array.includes(tag)
  }
}

/* ============================================================================
 * Hydration Markers
 * ============================================================================ */

module Markers = {
  /* Markers for different reactive node types */
  let signalTextStart = "<!--$-->"
  let signalTextEnd = "<!--/$-->"

  let signalFragmentStart = "<!--#-->"
  let signalFragmentEnd = "<!--/#-->"

  let keyedListStart = "<!--kl-->"
  let keyedListEnd = "<!--/kl-->"

  let keyedItemStart = (key: string): string => `<!--k:${key}-->`
  let keyedItemEnd = "<!--/k-->"

  let lazyComponentStart = "<!--lc-->"
  let lazyComponentEnd = "<!--/lc-->"
}

/* ============================================================================
 * Render Options
 * ============================================================================ */

type renderOptions = {
  nonce?: string,
  renderId?: string,
}

/* ============================================================================
 * Attribute Rendering
 * ============================================================================ */

module Attributes = {
  /* Render a single attribute to string */
  let renderAttr = ((key, value): (string, Component.attrValue)): string => {
    let attrValue = switch value {
    | Component.Static(v) => v
    | Component.SignalValue(signal) => Signal.peek(signal)
    | Component.Compute(fn) => fn()
    }

    /* Handle boolean attributes */
    switch key {
    | "checked" | "disabled" | "required" | "readonly" | "multiple" | "aria-hidden" | "aria-expanded" | "aria-selected" =>
      if attrValue == "true" {
        key
      } else {
        ""
      }
    | _ => `${key}="${Html.escape(attrValue)}"`
    }
  }

  /* Render all attributes to string */
  let renderAttrs = (attrs: array<(string, Component.attrValue)>): string => {
    let rendered =
      attrs
      ->Array.map(renderAttr)
      ->Array.filter(s => s != "")

    if Array.length(rendered) > 0 {
      " " ++ rendered->Array.join(" ")
    } else {
      ""
    }
  }
}

/* ============================================================================
 * Node Rendering
 * ============================================================================ */

/* Render a virtual node to an HTML string */
let rec renderNodeToString = (node: Component.node): string => {
  switch node {
  | Component.Text(content) => Html.escape(content)

  | Component.SignalText(signal) => {
      /* Read current signal value and wrap with hydration markers */
      let value = Signal.peek(signal)
      Markers.signalTextStart ++ Html.escape(value) ++ Markers.signalTextEnd
    }

  | Component.Fragment(children) => {
      children->Array.map(renderNodeToString)->Array.join("")
    }

  | Component.SignalFragment(signal) => {
      /* Read current signal value and wrap with hydration markers */
      let children = Signal.peek(signal)
      let content = children->Array.map(renderNodeToString)->Array.join("")
      Markers.signalFragmentStart ++ content ++ Markers.signalFragmentEnd
    }

  | Component.Element({tag, attrs, children, events: _}) => {
      let attrsStr = Attributes.renderAttrs(attrs)

      if Html.isVoidElement(tag) {
        `<${tag}${attrsStr} />`
      } else {
        let childrenStr = children->Array.map(renderNodeToString)->Array.join("")
        `<${tag}${attrsStr}>${childrenStr}</${tag}>`
      }
    }

  | Component.LazyComponent(fn) => {
      /* Execute the lazy component and render its result */
      let childNode = fn()
      Markers.lazyComponentStart ++ renderNodeToString(childNode) ++ Markers.lazyComponentEnd
    }

  | Component.KeyedList({signal, keyFn, renderItem}) => {
      let items = Signal.peek(signal)
      let content =
        items
        ->Array.map(item => {
          let key = keyFn(item)
          let itemHtml = renderNodeToString(renderItem(item))
          Markers.keyedItemStart(key) ++ itemHtml ++ Markers.keyedItemEnd
        })
        ->Array.join("")

      Markers.keyedListStart ++ content ++ Markers.keyedListEnd
    }
  }
}

/* ============================================================================
 * Public API
 * ============================================================================ */

/* Render a component to an HTML string synchronously */
let renderToString = (component: unit => Component.node, ~options: renderOptions={}): string => {
  let _ = options /* Will be used for nonce/renderId in future phases */
  let node = component()
  renderNodeToString(node)
}

/* Render a component and wrap with a hydration root marker */
let renderToStringWithRoot = (
  component: unit => Component.node,
  ~rootId: string="root",
  ~options: renderOptions={},
): string => {
  let _ = options
  let node = component()
  let content = renderNodeToString(node)

  /* Add root marker for hydration */
  `<!--xote-root:${rootId}-->${content}<!--/xote-root-->`
}

/* Generate the hydration script tag (placeholder for Phase 4) */
let generateHydrationScript = (~nonce: option<string>=?): string => {
  let nonceAttr = switch nonce {
  | Some(n) => ` nonce="${Html.escape(n)}"`
  | None => ""
  }

  `<script${nonceAttr}>window.__XOTE_HYDRATED__=false;</script>`
}

/* Helper to render a full HTML document */
let renderDocument = (
  ~head: string="",
  ~bodyAttrs: string="",
  ~scripts: array<string>=[],
  ~styles: array<string>=[],
  ~stateScript: string="",
  ~nonce: option<string>=?,
  component: unit => Component.node,
): string => {
  let content = renderToString(component)
  let hydrationScript = generateHydrationScript(~nonce?)

  let styleLinks =
    styles
    ->Array.map(href => `<link rel="stylesheet" href="${Html.escape(href)}" />`)
    ->Array.join("\n    ")

  let scriptTags =
    scripts
    ->Array.map(src => {
      let nonceAttr = switch nonce {
      | Some(n) => ` nonce="${Html.escape(n)}"`
      | None => ""
      }
      `<script type="module" src="${Html.escape(src)}"${nonceAttr}></script>`
    })
    ->Array.join("\n    ")

  `<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    ${styleLinks}
    ${head}
  </head>
  <body${if bodyAttrs != "" { " " ++ bodyAttrs } else { "" }}>
    <div id="root">${content}</div>
    ${stateScript}
    ${hydrationScript}
    ${scriptTags}
  </body>
</html>`
}
