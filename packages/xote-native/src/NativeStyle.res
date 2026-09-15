/* Typed styles for native views.

 A style is a plain record whose fields are all optional, so it is a plain
 JavaScript object at runtime and crosses the bridge without a conversion step.
 The vocabulary is flexbox — the same layout model React Native settled on,
 because it is the one Yoga implements and Yoga is what a host embeds.

 Sizes are density-independent points (`pt`), percentages (`pct`) or `auto`,
 never CSS strings: there is no cascade and no parser on the other side. */

type size

external pt: float => size = "%identity"

let pct = (value: float): size => Obj.magic(Float.toString(value) ++ "%")

let auto: size = Obj.magic("auto")

/* Every field here is one some host actually reads, and that is enforced:
 `native/test/surface_test.mjs` fails if this record declares a key the layout
 engine and the native hosts do not implement.

 Deliberately absent, and each absence is a signal rather than an oversight.
 `flexWrap`, `alignContent` and baseline alignment are the three things the
 layout engine does not do — reaching for one of them is the point at which the
 engine should be swapped for Yoga, and a compile error says so where a silently
 ignored property would not. `lineHeight`, `letterSpacing`, `fontStyle` and
 `textTransform` all change how big a string is, so they need the measure
 callback to change with them; they are real work, not a missing line.

 An app that needs one before it exists can pass it through `attrs` and teach
 its own host about it. */
type t = {
  /* Flex container */
  flex?: float,
  flexGrow?: float,
  flexShrink?: float,
  flexBasis?: size,
  flexDirection?: [#row | #column | #"row-reverse" | #"column-reverse"],
  justifyContent?: [
    | #"flex-start"
    | #center
    | #"flex-end"
    | #"space-between"
    | #"space-around"
    | #"space-evenly"
  ],
  alignItems?: [#"flex-start" | #center | #"flex-end" | #stretch],
  alignSelf?: [#auto | #"flex-start" | #center | #"flex-end" | #stretch],
  gap?: float,
  rowGap?: float,
  columnGap?: float,
  /* Box */
  width?: size,
  height?: size,
  minWidth?: size,
  minHeight?: size,
  maxWidth?: size,
  maxHeight?: size,
  aspectRatio?: float,
  margin?: size,
  marginTop?: size,
  marginRight?: size,
  marginBottom?: size,
  marginLeft?: size,
  marginHorizontal?: size,
  marginVertical?: size,
  padding?: size,
  paddingTop?: size,
  paddingRight?: size,
  paddingBottom?: size,
  paddingLeft?: size,
  paddingHorizontal?: size,
  paddingVertical?: size,
  /* Placement */
  position?: [#relative | #absolute],
  top?: size,
  right?: size,
  bottom?: size,
  left?: size,
  /* Paint */
  backgroundColor?: string,
  opacity?: float,
  borderRadius?: float,
  borderWidth?: float,
  borderColor?: string,
  overflow?: [#visible | #hidden | #scroll],
  /* Text — only meaningful on a text node, like React Native */
  color?: string,
  fontSize?: float,
  fontFamily?: string,
  /* Named rather than numeric: `#"700"` is a *numeric* polymorphic variant in
   ReScript and would cross the bridge as the number 700, which reads as a
   layout value on the other side. Names also map onto what the platforms
   actually expose (`UIFont.Weight`, Android's `FontWeight`). */
  fontWeight?: [#thin | #light | #regular | #medium | #semibold | #bold | #heavy],
  textAlign?: [#auto | #left | #center | #right | #justify],
}

/* Identity, but it gives the record literal a type to be inferred against at a
 polymorphic prop position: `style={Style.make({flex: 1.0})}`. */
external make: t => t = "%identity"

@val @scope("Object") external assign2: (t, t, t) => t = "assign"

/* Later styles win, field by field. */
let merge = (styles: array<t>): t =>
  styles->Array.reduce(make({}), (acc, style) => assign2(make({}), acc, style))
