/* Deprecated re-export of the top-level `Prop` module, kept so existing
 `XoteJSX.Prop.*` call sites keep compiling — they now raise the same
 deprecation warnings as `Prop` itself. Use `MaybeSignal` directly. */
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

@val @scope("Object") external objectEntries: Obj.t => array<(string, Obj.t)> = "entries"

/* Elements module for lowercase HTML tags */
module Elements = {
  /* Props type for HTML elements - accepts both raw values and MaybeSignal.t for
   * flexibility. This allows ergonomic JSX like class="foo" while also supporting
   * class={MaybeSignal.reactive(signal)}
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
    /* Escape hatch */
    'attrs,
  > = {
    /* Standard attributes - accept raw strings or MaybeSignal.t<string> */
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
    /* Escape hatch for attributes with no typed prop — `aria-controls`,
     `aria-valuenow`, presence-toggled state attributes, ... Entries are merged
     after the typed props, so an entry here overrides a prop with the same key.
     Values accept everything a typed attribute prop accepts (raw value,
     `Signal.t`, `unit => 'a` thunk, `MaybeSignal.t`, `None`) as well as a
     `View.attrValue` built with `View.attr`/`View.optionalComputedAttr`/... —
     which is also how a single array mixes static and reactive entries, since
     they then share one type. */
    attrs?: array<(string, 'attrs)>,
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

  /* How each typed prop is written: under which attribute name, and whether
     it carries a string, a boolean, or an int. Keyed by the property name the
     JSX transform emits (the `@as` name where there is one), so a props object
     can be walked over the keys it actually has instead of probing every
     optional field — a `<td class="...">` holds two properties, the record
     declares over a hundred and twenty, and the renderer builds eight
     elements per row. */
  type propKind = StringProp(string) | BoolProp(string) | IntProp(string)

  let propKinds: Dict.t<propKind> = {
    let table = Dict.make()
    let string = (key, name) => table->Dict.set(key, StringProp(name))
    let same = name => string(name, name)
    let bool = (key, name) => table->Dict.set(key, BoolProp(name))
    let int = (key, name) => table->Dict.set(key, IntProp(name))

    /* Standard attributes */
    same("id")
    same("class")
    same("style")
    same("title")
    /* Form/Input attributes */
    same("type")
    same("name")
    same("value")
    same("placeholder")
    bool("disabled", "disabled")
    bool("checked", "checked")
    bool("required", "required")
    bool("readOnly", "readonly")
    int("maxLength", "maxlength")
    int("minLength", "minlength")
    same("min")
    same("max")
    same("step")
    same("pattern")
    string("autoComplete", "autocomplete")
    bool("multiple", "multiple")
    same("accept")
    int("rows", "rows")
    int("cols", "cols")
    bool("autofocus", "autofocus")
    same("action")
    same("method")
    /* Label attributes */
    same("for")
    /* Link attributes */
    same("href")
    same("target")
    /* Image attributes */
    same("src")
    same("alt")
    same("width")
    same("height")
    /* Global attributes */
    bool("draggable", "draggable")
    bool("hidden", "hidden")
    bool("contentEditable", "contenteditable")
    bool("spellcheck", "spellcheck")
    /* Accessibility attributes */
    same("role")
    int("tabIndex", "tabindex")
    same("aria-label")
    bool("aria-hidden", "aria-hidden")
    bool("aria-expanded", "aria-expanded")
    bool("aria-selected", "aria-selected")
    /* SVG attributes - root */
    same("xmlns")
    same("xmlns:xlink")
    same("version")
    same("viewBox")
    same("preserveAspectRatio")
    /* SVG attributes - geometry */
    same("d")
    same("pathLength")
    same("cx")
    same("cy")
    same("r")
    same("rx")
    same("ry")
    same("x")
    same("y")
    same("x1")
    same("y1")
    same("x2")
    same("y2")
    same("fx")
    same("fy")
    same("dx")
    same("dy")
    same("points")
    same("transform")
    same("transform-origin")
    /* SVG attributes - presentation */
    same("fill")
    same("fill-opacity")
    same("fill-rule")
    same("stroke")
    same("stroke-width")
    same("stroke-linecap")
    same("stroke-linejoin")
    same("stroke-dasharray")
    same("stroke-dashoffset")
    same("stroke-opacity")
    same("stroke-miterlimit")
    same("opacity")
    same("color")
    same("visibility")
    same("vector-effect")
    same("pointer-events")
    /* SVG attributes - clipping/masking/filter */
    same("clip-path")
    same("clip-rule")
    same("mask")
    same("filter")
    /* SVG attributes - text */
    same("text-anchor")
    same("dominant-baseline")
    same("font-family")
    same("font-size")
    same("font-weight")
    same("letter-spacing")
    same("word-spacing")
    same("text-decoration")
    /* SVG attributes - gradient/stop */
    same("offset")
    same("stop-color")
    same("stop-opacity")
    same("gradientUnits")
    same("gradientTransform")
    same("spreadMethod")
    /* SVG attributes - markers */
    same("marker-start")
    same("marker-mid")
    same("marker-end")
    /* SVG attributes - xlink (legacy) */
    same("xlink:href")
    table
  }

  /* DOM event name for each handler prop. */
  let eventNames: Dict.t<string> = {
    let table = Dict.make()
    let event = (key, name) => table->Dict.set(key, name)
    event("onClick", "click")
    event("onInput", "input")
    event("onChange", "change")
    event("onSubmit", "submit")
    event("onFocus", "focus")
    event("onBlur", "blur")
    event("onKeyDown", "keydown")
    event("onKeyUp", "keyup")
    event("onMouseEnter", "mouseenter")
    event("onMouseLeave", "mouseleave")
    event("onMouseDown", "mousedown")
    event("onMouseMove", "mousemove")
    event("onMouseUp", "mouseup")
    event("onContextMenu", "contextmenu")
    event("onPointerDown", "pointerdown")
    event("onPointerMove", "pointermove")
    event("onPointerUp", "pointerup")
    event("onPointerCancel", "pointercancel")
    event("onPointerEnter", "pointerenter")
    event("onPointerLeave", "pointerleave")
    event("onPointerOver", "pointerover")
    event("onPointerOut", "pointerout")
    event("onGotPointerCapture", "gotpointercapture")
    event("onLostPointerCapture", "lostpointercapture")
    event("onDrag", "drag")
    event("onDragStart", "dragstart")
    event("onDragEnd", "dragend")
    event("onDragOver", "dragover")
    event("onDragEnter", "dragenter")
    event("onDragLeave", "dragleave")
    event("onDrop", "drop")
    table
  }

  /* The typed props record as the JavaScript object it is at runtime. An
     optional field that was not given is absent from the object; one given as
     `None` is present and `undefined`, and is skipped the same way. */
  let propDict = (props): Dict.t<Obj.t> => Obj.magic(props)

  let pushAttr = (attrs, key: string, value: Obj.t) =>
    switch propKinds->Dict.get(key) {
    | Some(StringProp(name)) => attrs->Array.push(RuntimeJsxProp.toStringAttr(name, value))->ignore
    | Some(BoolProp(name)) => attrs->Array.push(RuntimeJsxProp.toBoolAttr(name, value))->ignore
    | Some(IntProp(name)) => {
        let int: int = Obj.magic(value)
        attrs->Array.push(View.attr(name, Int.toString(int)))->ignore
      }
    | None => ()
    }

  /* `data` entries and the `attrs` escape hatch come after the typed props
     whatever their position in the source, so an `attrs` entry still wins over
     a typed prop with the same key. */
  let finishAttrs = (props, attrs): array<(string, View.attrValue)> => {
    switch props.data {
    | Some(dataObj) => {
        let entries = objectEntries(dataObj)
        entries->Array.forEach(((key, value)) => {
          attrs->Array.push(RuntimeJsxProp.toStringAttr("data-" ++ key, value))->ignore
        })
      }
    | None => ()
    }

    switch props.attrs {
    | Some(entries) =>
      RuntimeJsxProp.mergeAttrs(
        attrs,
        entries->Array.map(((key, value)) => RuntimeJsxProp.toAttrEntry(key, value)),
      )
    | None => attrs
    }
  }

  /* Convert props to attrs array, in the order the props were written. */
  let propsToAttrs = (props): array<(string, View.attrValue)> => {
    let attrs = []
    let dict = propDict(props)
    dict
    ->Dict.keysToArray
    ->Array.forEach(key => {
      let value = dict->Dict.getUnsafe(key)
      if !RuntimeValue.isUndefined(value) {
        pushAttr(attrs, key, value)
      }
    })
    finishAttrs(props, attrs)
  }

  let pushEvent = (events, key: string, value: Obj.t) =>
    switch eventNames->Dict.get(key) {
    | Some(name) => {
        let handler: Dom.event => unit = Obj.magic(value)
        events->Array.push((name, handler))->ignore
      }
    | None => ()
    }

  /* Convert props to events array */
  let propsToEvents = (props): array<(string, Dom.event => unit)> => {
    let events = []
    let dict = propDict(props)
    dict
    ->Dict.keysToArray
    ->Array.forEach(key => {
      let value = dict->Dict.getUnsafe(key)
      if !RuntimeValue.isUndefined(value) {
        pushEvent(events, key, value)
      }
    })
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

  /* Create an element from a tag string and props. One walk over the props
     sorts every key into an attribute, an event, or neither. */
  let createElement = (tag: string, props): element => {
    let attrs = []
    let events = []
    let dict = propDict(props)
    dict
    ->Dict.keysToArray
    ->Array.forEach(key => {
      let value = dict->Dict.getUnsafe(key)
      if !RuntimeValue.isUndefined(value) {
        switch propKinds->Dict.get(key) {
        | Some(_) => pushAttr(attrs, key, value)
        | None => pushEvent(events, key, value)
        }
      }
    })
    View.Element({
      tag,
      attrs: finishAttrs(props, attrs),
      events,
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
