module Prop = Prop

/* ReScript JSX transform type aliases */
type element = View.node

type component<'props> = 'props => element

type componentLike<'props, 'return> = 'props => 'return

/* JSX functions for component creation - wrap in LazyComponent to defer evaluation.
 * This ensures component functions (which may create effects/computeds) are not
 * evaluated during a Computed context, which would incorrectly track their
 * dependencies as belonging to the outer computed. */
let jsx = (component: component<'props>, props: 'props): element => View.LazyComponent(
  () => component(props),
)

let jsxs = jsx

let jsxKeyed = (
  component: component<'props>,
  props: 'props,
  ~key: option<string>=?,
  _: unit,
): element => {
  switch key {
  | Some(key) => View.Keyed({key, identity: Obj.magic(props), child: jsx(component, props)})
  | None => jsx(component, props)
  }
}

let jsxsKeyed = jsxKeyed

/* Fragment support */
type fragmentProps = {children?: element}

let jsxFragment = (props: fragmentProps): element => {
  switch props.children {
  | Some(child) => child
  | None => View.fragment([])
  }
}

/* Element converters for JSX expressions */
let array = (children: array<element>): element => View.fragment(children)

let null = (): element => View.text("")

let childrenToArray = (child: option<element>): array<element> => {
  switch child {
  | Some(Fragment(children)) => children
  | Some(child) => [child]
  | None => []
  }
}

/* JSX control-flow primitives */
module For = {
  type props<'item> = {
    each: Prop.t<array<'item>>,
    render: 'item => element,
  }

  let make = (props: props<'item>): element => {
    switch props.each {
    | Static(items) => View.fragment(items->Array.map(props.render))
    | Reactive(signal) => View.each(signal, props.render)
    }
  }
}

module KeyedFor = {
  type props<'item> = {
    each: Prop.t<array<'item>>,
    by: 'item => string,
    render: 'item => element,
  }

  let make = (props: props<'item>): element => {
    switch props.each {
    | Static(items) =>
      View.fragment(
        items->Array.map(item =>
          View.Keyed({key: props.by(item), identity: Obj.magic(item), child: props.render(item)})
        ),
      )
    | Reactive(signal) => View.eachWithKey(signal, props.by, props.render)
    }
  }
}

module Show = {
  type props = {
    when_: Prop.t<bool>,
    children?: element,
    fallback?: element,
  }

  let make = (props: props): element => {
    switch props.when_ {
    | Static(true) => View.fragment(childrenToArray(props.children))
    | Static(false) => View.fragment(childrenToArray(props.fallback))
    | Reactive(signal) =>
      View.signalFragment(
        Computed.make(() =>
          if Signal.get(signal) {
            childrenToArray(props.children)
          } else {
            childrenToArray(props.fallback)
          }
        ),
      )
    }
  }
}

module Maybe = {
  type props<'value> = {
    value: Prop.t<option<'value>>,
    render: 'value => element,
    fallback?: element,
  }

  let renderValue = (props: props<'value>, value: option<'value>): array<element> => {
    switch value {
    | Some(value) => [props.render(value)]
    | None => childrenToArray(props.fallback)
    }
  }

  let make = (props: props<'value>): element => {
    switch props.value {
    | Static(value) => View.fragment(renderValue(props, value))
    | Reactive(signal) =>
      View.signalFragment(Computed.make(() => renderValue(props, Signal.get(signal))))
    }
  }
}

module Value = {
  type props<'value> = {
    value: Prop.t<'value>,
    render: 'value => element,
  }

  let make = (props: props<'value>): element => {
    switch props.value {
    | Static(value) => props.render(value)
    | Reactive(signal) =>
      View.signalFragment(Computed.make(() => [props.render(Signal.get(signal))]))
    }
  }
}

/* Elements module for lowercase HTML tags */
module Elements = {
  /* Props type for HTML elements - accepts both raw values and Prop.t for flexibility
   * This allows ergonomic JSX like class="foo" while also supporting class={Prop.reactive(signal)}
   */
  type props<
    'id,
    'class,
    'style,
    'typ,
    'name,
    'value,
    'placeholder,
    'min,
    'max,
    'step,
    'pattern,
    'autoComplete,
    'accept,
    'forAttr,
    'href,
    'target,
    'src,
    'alt,
    'width,
    'height,
    'role,
    'ariaLabel,
    'disabled,
    'checked,
    'required,
    'readOnly,
    'multiple,
    'ariaHidden,
    'ariaExpanded,
    'ariaSelected,
    'draggable,
    'hidden,
    'title,
    'contentEditable,
    'spellcheck,
    'autofocus,
    'action,
    'method,
    /* SVG props */
    'xmlns,
    'xmlnsXlink,
    'version,
    'viewBox,
    'preserveAspectRatio,
    'd,
    'pathLength,
    'cx,
    'cy,
    'r,
    'rx,
    'ry,
    'x,
    'y,
    'x1,
    'y1,
    'x2,
    'y2,
    'fx,
    'fy,
    'dx,
    'dy,
    'points,
    'transform,
    'transformOrigin,
    'fill,
    'fillOpacity,
    'fillRule,
    'stroke,
    'strokeWidth,
    'strokeLinecap,
    'strokeLinejoin,
    'strokeDasharray,
    'strokeDashoffset,
    'strokeOpacity,
    'strokeMiterlimit,
    'opacity,
    'color,
    'visibility,
    'vectorEffect,
    'pointerEvents,
    'clipPath,
    'clipRule,
    'mask,
    'filter,
    'textAnchor,
    'dominantBaseline,
    'fontFamily,
    'fontSize,
    'fontWeight,
    'letterSpacing,
    'wordSpacing,
    'textDecoration,
    'offset,
    'stopColor,
    'stopOpacity,
    'gradientUnits,
    'gradientTransform,
    'spreadMethod,
    'markerStart,
    'markerMid,
    'markerEnd,
    'xlinkHref,
  > = {
    /* Standard attributes - accept raw strings or Prop.t<string> */
    id?: 'id,
    class?: 'class,
    style?: 'style,
    title?: 'title,
    /* Form/Input attributes */
    @as("type") type_?: 'typ,
    name?: 'name,
    value?: 'value,
    placeholder?: 'placeholder,
    disabled?: 'disabled,
    checked?: 'checked,
    required?: 'required,
    readOnly?: 'readOnly,
    maxLength?: int,
    minLength?: int,
    min?: 'min,
    max?: 'max,
    step?: 'step,
    pattern?: 'pattern,
    autoComplete?: 'autoComplete,
    multiple?: 'multiple,
    accept?: 'accept,
    rows?: int,
    cols?: int,
    autofocus?: 'autofocus,
    action?: 'action,
    method?: 'method,
    /* Label attributes */
    @as("for") for_?: 'forAttr,
    /* Link attributes */
    href?: 'href,
    target?: 'target,
    /* Image attributes */
    src?: 'src,
    alt?: 'alt,
    width?: 'width,
    height?: 'height,
    /* Global attributes */
    draggable?: 'draggable,
    hidden?: 'hidden,
    contentEditable?: 'contentEditable,
    spellcheck?: 'spellcheck,
    /* Accessibility attributes */
    role?: 'role,
    tabIndex?: int,
    @as("aria-label") ariaLabel?: 'ariaLabel,
    @as("aria-hidden") ariaHidden?: 'ariaHidden,
    @as("aria-expanded") ariaExpanded?: 'ariaExpanded,
    @as("aria-selected") ariaSelected?: 'ariaSelected,
    /* Data attributes */
    data?: Obj.t,
    /* SVG attributes - root */
    xmlns?: 'xmlns,
    @as("xmlns:xlink") xmlnsXlink?: 'xmlnsXlink,
    version?: 'version,
    viewBox?: 'viewBox,
    preserveAspectRatio?: 'preserveAspectRatio,
    /* SVG attributes - path/shape geometry */
    d?: 'd,
    pathLength?: 'pathLength,
    cx?: 'cx,
    cy?: 'cy,
    r?: 'r,
    rx?: 'rx,
    ry?: 'ry,
    x?: 'x,
    y?: 'y,
    x1?: 'x1,
    y1?: 'y1,
    x2?: 'x2,
    y2?: 'y2,
    fx?: 'fx,
    fy?: 'fy,
    dx?: 'dx,
    dy?: 'dy,
    points?: 'points,
    transform?: 'transform,
    @as("transform-origin") transformOrigin?: 'transformOrigin,
    /* SVG attributes - presentation */
    fill?: 'fill,
    @as("fill-opacity") fillOpacity?: 'fillOpacity,
    @as("fill-rule") fillRule?: 'fillRule,
    stroke?: 'stroke,
    @as("stroke-width") strokeWidth?: 'strokeWidth,
    @as("stroke-linecap") strokeLinecap?: 'strokeLinecap,
    @as("stroke-linejoin") strokeLinejoin?: 'strokeLinejoin,
    @as("stroke-dasharray") strokeDasharray?: 'strokeDasharray,
    @as("stroke-dashoffset") strokeDashoffset?: 'strokeDashoffset,
    @as("stroke-opacity") strokeOpacity?: 'strokeOpacity,
    @as("stroke-miterlimit") strokeMiterlimit?: 'strokeMiterlimit,
    opacity?: 'opacity,
    color?: 'color,
    visibility?: 'visibility,
    @as("vector-effect") vectorEffect?: 'vectorEffect,
    @as("pointer-events") pointerEvents?: 'pointerEvents,
    /* SVG attributes - clipping/masking/filter */
    @as("clip-path") clipPath?: 'clipPath,
    @as("clip-rule") clipRule?: 'clipRule,
    mask?: 'mask,
    filter?: 'filter,
    /* SVG attributes - text */
    @as("text-anchor") textAnchor?: 'textAnchor,
    @as("dominant-baseline") dominantBaseline?: 'dominantBaseline,
    @as("font-family") fontFamily?: 'fontFamily,
    @as("font-size") fontSize?: 'fontSize,
    @as("font-weight") fontWeight?: 'fontWeight,
    @as("letter-spacing") letterSpacing?: 'letterSpacing,
    @as("word-spacing") wordSpacing?: 'wordSpacing,
    @as("text-decoration") textDecoration?: 'textDecoration,
    /* SVG attributes - gradient/stop */
    offset?: 'offset,
    @as("stop-color") stopColor?: 'stopColor,
    @as("stop-opacity") stopOpacity?: 'stopOpacity,
    gradientUnits?: 'gradientUnits,
    gradientTransform?: 'gradientTransform,
    spreadMethod?: 'spreadMethod,
    /* SVG attributes - markers */
    @as("marker-start") markerStart?: 'markerStart,
    @as("marker-mid") markerMid?: 'markerMid,
    @as("marker-end") markerEnd?: 'markerEnd,
    /* SVG attributes - xlink (legacy) */
    @as("xlink:href") xlinkHref?: 'xlinkHref,
    /* Event handlers */
    onClick?: Dom.event => unit,
    onInput?: Dom.event => unit,
    onChange?: Dom.event => unit,
    onSubmit?: Dom.event => unit,
    onFocus?: Dom.event => unit,
    onBlur?: Dom.event => unit,
    onKeyDown?: Dom.event => unit,
    onKeyUp?: Dom.event => unit,
    onMouseEnter?: Dom.event => unit,
    onMouseLeave?: Dom.event => unit,
    onMouseDown?: Dom.event => unit,
    onMouseMove?: Dom.event => unit,
    onMouseUp?: Dom.event => unit,
    onContextMenu?: Dom.event => unit,
    /* Pointer event handlers */
    onPointerDown?: Dom.event => unit,
    onPointerMove?: Dom.event => unit,
    onPointerUp?: Dom.event => unit,
    onPointerCancel?: Dom.event => unit,
    onPointerEnter?: Dom.event => unit,
    onPointerLeave?: Dom.event => unit,
    onPointerOver?: Dom.event => unit,
    onPointerOut?: Dom.event => unit,
    onGotPointerCapture?: Dom.event => unit,
    onLostPointerCapture?: Dom.event => unit,
    /* Drag-and-drop event handlers */
    onDrag?: Dom.event => unit,
    onDragStart?: Dom.event => unit,
    onDragEnd?: Dom.event => unit,
    onDragOver?: Dom.event => unit,
    onDragEnter?: Dom.event => unit,
    onDragLeave?: Dom.event => unit,
    onDrop?: Dom.event => unit,
    /* Children */
    children?: element,
  }

  /* Helper to add optional attribute to attrs array */
  let addAttr = (attrs, opt, key, converter) => {
    switch opt {
    | Some(v) => attrs->Array.push(converter(key, v))
    | None => ()
    }
  }

  /* Helper to add optional int attribute */
  let addIntAttr = (attrs, opt, key) => {
    switch opt {
    | Some(v) => attrs->Array.push(View.attr(key, Int.toString(v)))
    | None => ()
    }
  }

  /* Convert props to attrs array */
  let propsToAttrs = (props): array<(string, View.attrValue)> => {
    let attrs = []

    /* Standard attributes */
    addAttr(attrs, props.id, "id", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.class, "class", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.style, "style", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.title, "title", RuntimeJsxProp.toStringAttr)

    /* Form/Input attributes */
    addAttr(attrs, props.type_, "type", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.name, "name", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.value, "value", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.placeholder, "placeholder", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.disabled, "disabled", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.checked, "checked", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.required, "required", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.readOnly, "readonly", RuntimeJsxProp.toBoolAttr)
    addIntAttr(attrs, props.maxLength, "maxlength")
    addIntAttr(attrs, props.minLength, "minlength")
    addAttr(attrs, props.min, "min", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.max, "max", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.step, "step", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.pattern, "pattern", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.autoComplete, "autocomplete", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.multiple, "multiple", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.accept, "accept", RuntimeJsxProp.toStringAttr)
    addIntAttr(attrs, props.rows, "rows")
    addIntAttr(attrs, props.cols, "cols")
    addAttr(attrs, props.autofocus, "autofocus", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.action, "action", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.method, "method", RuntimeJsxProp.toStringAttr)

    /* Label attributes */
    addAttr(attrs, props.for_, "for", RuntimeJsxProp.toStringAttr)

    /* Link attributes */
    addAttr(attrs, props.href, "href", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.target, "target", RuntimeJsxProp.toStringAttr)

    /* Image attributes */
    addAttr(attrs, props.src, "src", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.alt, "alt", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.width, "width", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.height, "height", RuntimeJsxProp.toStringAttr)

    /* Global attributes */
    addAttr(attrs, props.draggable, "draggable", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.hidden, "hidden", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.contentEditable, "contenteditable", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.spellcheck, "spellcheck", RuntimeJsxProp.toBoolAttr)

    /* Accessibility attributes */
    addAttr(attrs, props.role, "role", RuntimeJsxProp.toStringAttr)
    addIntAttr(attrs, props.tabIndex, "tabindex")
    addAttr(attrs, props.ariaLabel, "aria-label", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.ariaHidden, "aria-hidden", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.ariaExpanded, "aria-expanded", RuntimeJsxProp.toBoolAttr)
    addAttr(attrs, props.ariaSelected, "aria-selected", RuntimeJsxProp.toBoolAttr)

    /* SVG attributes - root */
    addAttr(attrs, props.xmlns, "xmlns", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.xmlnsXlink, "xmlns:xlink", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.version, "version", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.viewBox, "viewBox", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.preserveAspectRatio, "preserveAspectRatio", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - geometry */
    addAttr(attrs, props.d, "d", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.pathLength, "pathLength", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.cx, "cx", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.cy, "cy", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.r, "r", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.rx, "rx", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.ry, "ry", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.x, "x", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.y, "y", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.x1, "x1", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.y1, "y1", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.x2, "x2", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.y2, "y2", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fx, "fx", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fy, "fy", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.dx, "dx", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.dy, "dy", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.points, "points", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.transform, "transform", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.transformOrigin, "transform-origin", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - presentation */
    addAttr(attrs, props.fill, "fill", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fillOpacity, "fill-opacity", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fillRule, "fill-rule", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.stroke, "stroke", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeWidth, "stroke-width", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeLinecap, "stroke-linecap", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeLinejoin, "stroke-linejoin", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeDasharray, "stroke-dasharray", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeDashoffset, "stroke-dashoffset", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeOpacity, "stroke-opacity", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.strokeMiterlimit, "stroke-miterlimit", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.opacity, "opacity", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.color, "color", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.visibility, "visibility", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.vectorEffect, "vector-effect", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.pointerEvents, "pointer-events", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - clipping/masking/filter */
    addAttr(attrs, props.clipPath, "clip-path", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.clipRule, "clip-rule", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.mask, "mask", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.filter, "filter", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - text */
    addAttr(attrs, props.textAnchor, "text-anchor", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.dominantBaseline, "dominant-baseline", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fontFamily, "font-family", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fontSize, "font-size", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.fontWeight, "font-weight", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.letterSpacing, "letter-spacing", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.wordSpacing, "word-spacing", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.textDecoration, "text-decoration", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - gradient/stop */
    addAttr(attrs, props.offset, "offset", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.stopColor, "stop-color", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.stopOpacity, "stop-opacity", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.gradientUnits, "gradientUnits", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.gradientTransform, "gradientTransform", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.spreadMethod, "spreadMethod", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - markers */
    addAttr(attrs, props.markerStart, "marker-start", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.markerMid, "marker-mid", RuntimeJsxProp.toStringAttr)
    addAttr(attrs, props.markerEnd, "marker-end", RuntimeJsxProp.toStringAttr)

    /* SVG attributes - xlink (legacy) */
    addAttr(attrs, props.xlinkHref, "xlink:href", RuntimeJsxProp.toStringAttr)

    /* Data attributes */
    switch props.data {
    | Some(dataObj) => {
        ignore(dataObj)
        let entries: array<(string, Obj.t)> = %raw(`Object.entries(dataObj)`)
        entries->Array.forEach(((key, value)) => {
          attrs->Array.push(RuntimeJsxProp.toStringAttr("data-" ++ key, value))->ignore
        })
      }
    | None => ()
    }

    attrs
  }

  /* Helper to add optional event handler to events array */
  let addEvent = (events, opt, eventName) => {
    switch opt {
    | Some(handler) => events->Array.push((eventName, handler))
    | None => ()
    }
  }

  /* Convert props to events array */
  let propsToEvents = (props): array<(string, Dom.event => unit)> => {
    let events = []

    addEvent(events, props.onClick, "click")
    addEvent(events, props.onInput, "input")
    addEvent(events, props.onChange, "change")
    addEvent(events, props.onSubmit, "submit")
    addEvent(events, props.onFocus, "focus")
    addEvent(events, props.onBlur, "blur")
    addEvent(events, props.onKeyDown, "keydown")
    addEvent(events, props.onKeyUp, "keyup")
    addEvent(events, props.onMouseEnter, "mouseenter")
    addEvent(events, props.onMouseLeave, "mouseleave")
    addEvent(events, props.onMouseDown, "mousedown")
    addEvent(events, props.onMouseMove, "mousemove")
    addEvent(events, props.onMouseUp, "mouseup")
    addEvent(events, props.onContextMenu, "contextmenu")
    addEvent(events, props.onPointerDown, "pointerdown")
    addEvent(events, props.onPointerMove, "pointermove")
    addEvent(events, props.onPointerUp, "pointerup")
    addEvent(events, props.onPointerCancel, "pointercancel")
    addEvent(events, props.onPointerEnter, "pointerenter")
    addEvent(events, props.onPointerLeave, "pointerleave")
    addEvent(events, props.onPointerOver, "pointerover")
    addEvent(events, props.onPointerOut, "pointerout")
    addEvent(events, props.onGotPointerCapture, "gotpointercapture")
    addEvent(events, props.onLostPointerCapture, "lostpointercapture")
    addEvent(events, props.onDrag, "drag")
    addEvent(events, props.onDragStart, "dragstart")
    addEvent(events, props.onDragEnd, "dragend")
    addEvent(events, props.onDragOver, "dragover")
    addEvent(events, props.onDragEnter, "dragenter")
    addEvent(events, props.onDragLeave, "dragleave")
    addEvent(events, props.onDrop, "drop")

    events
  }

  /* Extract children from props */
  let getChildren = (props): array<element> => {
    switch props.children {
    | Some(Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* Create an element from a tag string and props */
  let createElement = (tag: string, props): element => {
    View.Element({
      tag,
      attrs: propsToAttrs(props),
      events: propsToEvents(props),
      children: getChildren(props),
    })
  }

  /* JSX functions for HTML elements - all delegate to createElement */
  let jsx = (tag: string, props): element => createElement(tag, props)

  let jsxs = jsx

  let jsxKeyed = (tag: string, props, ~key: option<string>=?, _: unit): element => {
    switch key {
    | Some(key) => View.Keyed({key, identity: Obj.magic(props), child: jsx(tag, props)})
    | None => jsx(tag, props)
    }
  }

  let jsxsKeyed = jsxKeyed

  /* Element helper for ReScript JSX type checking */
  external someElement: element => option<element> = "%identity"
}
