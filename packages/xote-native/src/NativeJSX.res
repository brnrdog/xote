/* The JSX module for native apps.

 A native app sets `"jsx": {"version": 4, "module": "NativeJSX"}` in its
 `rescript.json` (or `@@jsxConfig` per file) and then writes `<view>`, `<text>`,
 `<image>` instead of `<div>` and `<span>`. Everything above the tag names — the
 component transform, keys, fragments — is Xote's, re-exported unchanged, so the
 two element vocabularies share one renderer and one reactivity model.

 Lowercase tags are the primitives a host must implement:

 | tag           | host view                                              |
 |---------------|--------------------------------------------------------|
 | `view`        | a flexbox box; the only container                      |
 | `text`        | a text run; the only node that may contain raw text     |
 | `image`       | a bitmap, sized by style, sourced by `source`           |
 | `scroll`      | a scrollable `view`                                     |
 | `input`       | a single- or multi-line text field                      |
 | `pressable`   | a `view` that reports touches                           |
 | `stack`       | a navigation controller; holds `screen` children only   |
 | `screen`      | one entry in a `stack`, filling it                      |

 Anything else is passed through to the host by name, so a host can add its own
 primitives without a change here. */

type element = View.node

type component<'props> = 'props => element

type componentLike<'props, 'return> = 'props => 'return

let jsx = XoteJSX.jsx

let jsxs = XoteJSX.jsxs

let jsxKeyed = XoteJSX.jsxKeyed

let jsxsKeyed = XoteJSX.jsxsKeyed

type fragmentProps = XoteJSX.fragmentProps = {children?: element}

let jsxFragment = XoteJSX.jsxFragment

let array = XoteJSX.array

let null = XoteJSX.null

module Elements = {
  /* Every prop is polymorphic for the same reason it is in `XoteJSX`: a prop
   accepts a plain value, a `Signal.t`, a `unit => 'a` thunk or a
   `MaybeSignal.t`, and `NativeProp.ofUnknown` sorts out which it got.

   Every prop here is one a native host actually applies, and every handler is
   an event a native host actually raises — `native/test/surface_test.mjs` fails
   if that stops being true. A prop that type-checks and then does nothing is
   worse than a missing one, because a missing one is a compile error and a
   five-minute answer.

   `attrs` is how an app reaches a prop this module does not name, so nothing is
   unreachable — only unpromised. */
  type props<
    'style,
    'testID,
    'accessibilityLabel,
    'numberOfLines,
    'source,
    'value,
    'placeholder,
    'placeholderTextColor,
    'secureTextEntry,
    'editable,
    'horizontal,
  > = {
    /* Common */
    style?: 'style,
    testID?: 'testID,
    accessibilityLabel?: 'accessibilityLabel,
    /* text */
    numberOfLines?: 'numberOfLines,
    /* image */
    source?: 'source,
    /* input */
    value?: 'value,
    placeholder?: 'placeholder,
    placeholderTextColor?: 'placeholderTextColor,
    secureTextEntry?: 'secureTextEntry,
    editable?: 'editable,
    /* scroll */
    horizontal?: 'horizontal,
    /* stack — see `NativeNav`, which is what an app should reach for first */
    /* Events */
    onPress?: NativeEvent.press => unit,
    onLongPress?: NativeEvent.press => unit,
    onChangeText?: NativeEvent.text => unit,
    onSubmit?: NativeEvent.text => unit,
    onFocus?: NativeEvent.focus => unit,
    onBlur?: NativeEvent.focus => unit,
    onScroll?: NativeEvent.scroll => unit,
    onLayout?: NativeEvent.layout => unit,
    onStackChange?: NativeEvent.stackChange => unit,
    /* Escape hatch for a host primitive this module does not name */
    attrs?: array<(string, View.attrValue)>,
    children?: element,
  }

  let addProp = (attrs, opt, key) =>
    switch opt {
    | Some(v) => attrs->Array.push(NativeProp.ofUnknown(key, v))
    | None => ()
    }

  let propsToAttrs = (props): array<(string, View.attrValue)> => {
    let attrs = []

    addProp(attrs, props.style, "style")
    addProp(attrs, props.testID, "testID")
    addProp(attrs, props.accessibilityLabel, "accessibilityLabel")
    addProp(attrs, props.numberOfLines, "numberOfLines")
    addProp(attrs, props.source, "source")
    addProp(attrs, props.value, "value")
    addProp(attrs, props.placeholder, "placeholder")
    addProp(attrs, props.placeholderTextColor, "placeholderTextColor")
    addProp(attrs, props.secureTextEntry, "secureTextEntry")
    addProp(attrs, props.editable, "editable")
    addProp(attrs, props.horizontal, "horizontal")

    switch props.attrs {
    | Some(extra) => extra->Array.forEach(entry => attrs->Array.push(entry))
    | None => ()
    }

    attrs
  }

  let addEvent = (events, opt, name) =>
    switch opt {
    | Some(handler) => events->Array.push((name, NativeEvent.handler(handler)))
    | None => ()
    }

  let propsToEvents = (props): array<(string, Dom.event => unit)> => {
    let events = []

    addEvent(events, props.onPress, "press")
    addEvent(events, props.onLongPress, "longPress")
    addEvent(events, props.onChangeText, "changeText")
    addEvent(events, props.onSubmit, "submit")
    addEvent(events, props.onFocus, "focus")
    addEvent(events, props.onBlur, "blur")
    addEvent(events, props.onScroll, "scroll")
    addEvent(events, props.onLayout, "layout")
    addEvent(events, props.onStackChange, "stackChange")

    events
  }

  let getChildren = (props): array<element> =>
    switch props.children {
    | Some(View.Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }

  let createElement = (tag: string, props): element => View.Element({
    tag,
    attrs: propsToAttrs(props),
    events: propsToEvents(props),
    children: getChildren(props),
  })

  let jsx = (tag: string, props): element => createElement(tag, props)

  let jsxs = jsx

  let jsxKeyed = (tag: string, props, ~key: option<string>=?, _: unit): element =>
    switch key {
    | Some(key) => View.Keyed({key, identity: Obj.magic(props), child: jsx(tag, props)})
    | None => jsx(tag, props)
    }

  let jsxsKeyed = jsxKeyed

  external someElement: element => option<element> = "%identity"
}
