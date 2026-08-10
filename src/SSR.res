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
  let renderAttr = ((key, value): (string, View.attrValue)): string => {
    /* A missing value means the attribute is not rendered at all, matching the
     `removeAttribute` the client does for the same value. */
    switch RuntimeNode.peekAttr(value)->Nullable.toOption {
    | None => ""
    | Some(attrValue) =>
      if RuntimeAttr.isBoolean(key) {
        if RuntimeAttr.shouldRenderBoolean(attrValue) {
          key
        } else {
          ""
        }
      } else {
        `${key}="${RuntimeHtml.escape(attrValue)}"`
      }
    }
  }

  /* Render all attributes to string */
  let renderAttrs = (attrs: array<(string, View.attrValue)>): string => {
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
 * View Rendering
 * ============================================================================ */

/* Render a virtual node to an HTML string */
let rec renderNodeToString = (node: View.node): string => {
  switch node {
  | View.Text(content) => RuntimeHtml.escape(content)

  | View.SignalText(signal) => {
      /* Read current signal value and wrap with hydration markers */
      let value = Signal.peek(signal)
      RuntimeHydrationMarkers.signalTextStart ++
      RuntimeHtml.escape(value) ++
      RuntimeHydrationMarkers.signalTextEnd
    }

  | View.Fragment(children) => children->Array.map(renderNodeToString)->Array.join("")

  | View.SignalFragment(signal) => {
      /* Read current signal value and wrap with hydration markers */
      let children = Signal.peek(signal)
      let content = children->Array.map(renderNodeToString)->Array.join("")
      RuntimeHydrationMarkers.signalFragmentStart ++
      content ++
      RuntimeHydrationMarkers.signalFragmentEnd
    }

  | View.Keyed({child, key: _, identity: _}) => renderNodeToString(child)

  | View.Element({tag, attrs, children, events: _}) => {
      let attrsStr = Attributes.renderAttrs(attrs)

      if RuntimeHtml.isVoidElement(tag) {
        `<${tag}${attrsStr} />`
      } else {
        let childrenStr = children->Array.map(renderNodeToString)->Array.join("")
        `<${tag}${attrsStr}>${childrenStr}</${tag}>`
      }
    }

  | View.LazyComponent(fn) => {
      /* Execute the lazy component and render its result */
      let childNode = fn()
      RuntimeHydrationMarkers.lazyComponentStart ++
      renderNodeToString(childNode) ++
      RuntimeHydrationMarkers.lazyComponentEnd
    }

  | View.KeyedList({signal, keyFn, renderItem}) => {
      let items = Signal.peek(signal)
      let content =
        items
        ->Array.map(item => {
          let key = keyFn(item)
          let itemHtml = renderNodeToString(renderItem(item))
          RuntimeHydrationMarkers.keyedItemStart(key) ++
          itemHtml ++
          RuntimeHydrationMarkers.keyedItemEnd
        })
        ->Array.join("")

      RuntimeHydrationMarkers.keyedListStart ++ content ++ RuntimeHydrationMarkers.keyedListEnd
    }
  }
}

/* ============================================================================
 * Public API
 * ============================================================================ */

/* Render a component to an HTML string synchronously */
let renderToString = (component: unit => View.node, ~options: renderOptions={}): string => {
  let _ = options /* Will be used for nonce/renderId in future phases */
  let node = component()
  renderNodeToString(node)
}

/* Render a component and wrap with a hydration root marker */
let renderToStringWithRoot = (
  component: unit => View.node,
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
  | Some(n) => ` nonce="${RuntimeHtml.escape(n)}"`
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
  component: unit => View.node,
): string => {
  let content = renderToString(component)
  let hydrationScript = generateHydrationScript(~nonce?)

  let styleLinks =
    styles
    ->Array.map(href => `<link rel="stylesheet" href="${RuntimeHtml.escape(href)}" />`)
    ->Array.join("\n    ")

  let scriptTags =
    scripts
    ->Array.map(src => {
      let nonceAttr = switch nonce {
      | Some(n) => ` nonce="${RuntimeHtml.escape(n)}"`
      | None => ""
      }
      `<script type="module" src="${RuntimeHtml.escape(src)}"${nonceAttr}></script>`
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
  <body${if bodyAttrs != "" {
      " " ++ bodyAttrs
    } else {
      ""
    }}>
    <div id="root">${content}</div>
    ${stateScript}
    ${hydrationScript}
    ${scriptTags}
  </body>
</html>`
}
