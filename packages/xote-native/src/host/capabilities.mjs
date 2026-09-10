/**
 * What the hosts actually implement.
 *
 * A type that compiles and then does nothing is worse than a missing type: the
 * app author writes `letterSpacing: 2.0`, the compiler agrees, and the screen
 * is unchanged with nothing to read that says why. `xote-native/test/surface_test.mjs`
 * turns this file into a failing test — every name `NativeStyle` and
 * `NativeJSX` declare has to appear here, and every name here has to appear in
 * the engine or the host that claims to implement it.
 *
 * It also names the hosts, and where in each of them the implementing code
 * lives. There is more than one on purpose: `xote-native` targets iOS and
 * Android, and a capability only counts when *every* native host has it. A prop
 * that works on one platform and silently does nothing on the other is the same
 * bug as a prop that works nowhere, discovered later and by someone else.
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
 * The native hosts, and where each one keeps the code a capability is checked
 * against. Adding a host is an entry here; the tests loop.
 *
 * `dispatch` is how that language spells "handle the prop or event called
 * `name`" — a `switch` arm in Swift, a `when` branch in Kotlin. Crude, and it
 * is a real check: there is no Swift or Kotlin toolchain in this repository, so
 * reading the source as text is the only way a name in this file and a name in
 * a host can be found to disagree before a device finds out.
 */
export const HOSTS = [
  {
    name: "ios",
    language: "Swift",
    /** The flexbox engine and the style reader. */
    engine: [
      "hosts/ios/XoteNative/Sources/XoteLayout.swift",
      "hosts/ios/XoteNative/Sources/XoteStyle.swift",
    ],
    /** Where props are applied, events are raised, and paint happens. */
    host: [
      "hosts/ios/XoteNative/Sources/XoteHost.swift",
      "hosts/ios/XoteNative/Sources/XoteStyle.swift",
    ],
    dispatch: (name) => `case "${name}"`,
    protocol: {
      source: "hosts/ios/XoteNative/Sources/XoteHost.swift",
      min: "protocolMin",
      max: "protocolMax",
    },
  },
  {
    name: "android",
    language: "Kotlin",
    engine: [
      "hosts/android/app/src/main/java/dev/xote/host/XoteLayout.kt",
      "hosts/android/app/src/main/java/dev/xote/host/XoteStyle.kt",
    ],
    host: [
      "hosts/android/app/src/main/java/dev/xote/host/XoteHost.kt",
      "hosts/android/app/src/main/java/dev/xote/host/XoteStyle.kt",
    ],
    dispatch: (name) => `"${name}" ->`,
    protocol: {
      source: "hosts/android/app/src/main/java/dev/xote/host/XoteHost.kt",
      min: "PROTOCOL_MIN",
      max: "PROTOCOL_MAX",
    },
  },
];

/**
 * Style keys the flexbox engine reads. Checked against `layout.mjs` and against
 * every host's own engine — the same algorithm written once per language.
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

/** Style keys a native host paints. Checked against every host's sources. */
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
 * prop-dispatch arm of every host.
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
 * Events a native host raises. Checked against the event-dispatch arm of every
 * host.
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
