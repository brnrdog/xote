/**
 * What the hosts actually implement.
 *
 * A type that compiles and then does nothing is worse than a missing type: the
 * app author writes `letterSpacing: 2.0`, the compiler agrees, and the screen
 * is unchanged with nothing to read that says why. `native/test/surface_test.mjs`
 * turns this file into a failing test — every name `NativeStyle` and
 * `NativeJSX` declare has to appear here, and every name here has to appear in
 * the engine or the host that claims to implement it.
 *
 * **The DOM preview host is deliberately not counted.** It assigns the style
 * object straight onto a CSS `style` attribute, so it implements every property
 * CSS happens to share a name with — `lineHeight`, `letterSpacing` and
 * `textTransform` all work there and do nothing on a device. Counting it would
 * make this file agree with the preview and lie about the phone, which is the
 * failure mode being guarded against, not a lesser version of it.
 *
 * Growing any of these lists is a deliberate act: add the name here, implement
 * it in the engine and in every native host, then add it to the ReScript type.
 * In that order, because the test enforces it.
 */

/**
 * Style keys the flexbox engine reads. Checked against both `layout.mjs` and
 * `XoteLayout.swift`, which are the same algorithm written twice.
 *
 * Longhands the engine composes rather than reads by name — `marginTop`,
 * `paddingHorizontal` and the rest — are listed under `LAYOUT_EDGE_PREFIXES`.
 */
export const LAYOUT_STYLE = [
  "flex",
  "flexGrow",
  "flexShrink",
  "flexBasis",
  "flexDirection",
  "justifyContent",
  "alignItems",
  "alignSelf",
  "gap",
  "rowGap",
  "columnGap",
  "width",
  "height",
  "minWidth",
  "minHeight",
  "maxWidth",
  "maxHeight",
  "aspectRatio",
  "position",
  "top",
  "right",
  "bottom",
  "left",
  "borderWidth",
];

/**
 * `edge(style, prefix, side)` builds these from the prefix, so the engine never
 * names them and a grep for `marginTop` in `layout.mjs` finds nothing. They are
 * implemented; they are just implemented generically.
 */
export const LAYOUT_EDGE_PREFIXES = ["margin", "padding"];
export const LAYOUT_EDGE_SUFFIXES = [
  "",
  "Top",
  "Right",
  "Bottom",
  "Left",
  "Horizontal",
  "Vertical",
];

/** Style keys a native host paints. Checked against the Swift sources. */
export const PAINT_STYLE = [
  "backgroundColor",
  "opacity",
  "borderRadius",
  "borderWidth",
  "borderColor",
  "overflow",
  "color",
  "fontSize",
  "fontFamily",
  "fontWeight",
  "textAlign",
];

/**
 * Element props a native host applies, beyond `style`. Checked against the
 * `case "…"` arms of `XoteHost.setProp`.
 */
export const PROPS = [
  "testID",
  "accessibilityLabel",
  "numberOfLines",
  "source",
  "value",
  "placeholder",
  "placeholderTextColor",
  "secureTextEntry",
  "editable",
  "horizontal",
];

/**
 * Events a native host raises. Checked against the `case "…"` arms of
 * `XoteHost.listen`.
 */
export const EVENTS = [
  "press",
  "longPress",
  "changeText",
  "submit",
  "focus",
  "blur",
  "scroll",
  "layout",
];

/**
 * Every style key the ReScript type is allowed to declare.
 *
 * Deduplicated because `borderWidth` is honestly in both lists: it insets the
 * content box *and* it draws a border.
 */
export const STYLE = [
  ...new Set([
    ...LAYOUT_STYLE,
    ...LAYOUT_EDGE_PREFIXES.flatMap((prefix) =>
      LAYOUT_EDGE_SUFFIXES.map((suffix) => prefix + suffix),
    ),
    ...PAINT_STYLE,
  ]),
];
