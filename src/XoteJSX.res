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
  let _ = key /* TODO: Implement key support for list reconciliation */
  jsx(component, props)
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
    let _ = key
    jsx(tag, props)
  }

  let jsxsKeyed = jsxKeyed

  /* Element helper for ReScript JSX type checking */
  external someElement: element => option<element> = "%identity"
}
