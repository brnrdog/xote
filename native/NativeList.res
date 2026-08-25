/* A list that renders a window, not a dataset.

 `View.eachWithKey` reconciles every row it is given, which is the right thing
 on the web — a browser is happy to hold ten thousand `<li>`s and only paint the
 visible ones. A phone is not: ten thousand `UIView`s is ten thousand
 allocations, a layout pass over all of them, and a lot of memory that never
 gets looked at.

 So the window is computed rather than the list: the rows on screen are the only
 ones that exist, and the space above and below them is padding on the content
 box. Scrolling changes which rows those are; the space keeps the scroll bar and
 the content size honest.

 It needs two things from the host that a browser gives for free — `scroll`, to
 know where the viewport is, and `layout`, to know how tall it is.

 **Rows are a fixed height.** That is the assumption that makes the window a
 division instead of a measurement, and it is the same one React Native's
 `getItemLayout` asks for when it wants a list to be fast. Variable heights need
 measured rows and a running offset table; see `ROADMAP.md`. */

module Style = NativeStyle

/* The rows that scrolling actually changed, rather than the pixel it changed by.
 A scroll event arrives for every frame of a drag; the window changes a few
 times a second. Keeping the range in a signal with a structural comparison
 means the rows are only re-sliced when they really differ — and because
 `Signal.set` does not notify when the value is unchanged, the reactive region
 downstream is not even invalidated. */
let sameRange = ((firstA, lastA), (firstB, lastB)) => firstA == firstB && lastA == lastB

let make = (
  ~items: Signal.t<array<'item>>,
  ~rowHeight: float,
  ~key: 'item => string,
  ~renderRow: 'item => View.node,
  ~overscan: int=2,
  ~style: option<Style.t>=?,
  ~attrs: array<(string, View.attrValue)>=[],
  (),
): View.node => {
  let scrollTop = Signal.make(0.0)
  let viewport = Signal.make(0.0)
  let range = Signal.make((0, 0), ~equals=sameRange)

  Effect.run(() => {
    let total = Signal.get(items)->Array.length
    let top = Signal.get(scrollTop)
    let height = Signal.get(viewport)

    let firstVisible = Int.fromFloat(top /. rowHeight)
    let first = firstVisible - overscan
    let first = first < 0 ? 0 : first
    let onScreen = Int.fromFloat(Math.ceil(height /. rowHeight))
    let last = first + onScreen + overscan * 2 + 1
    let last = last > total ? total : last

    Signal.set(range, (first, last > first ? last : first))
    None
  })

  let window = Computed.make(() => {
    let (first, last) = Signal.get(range)
    Signal.get(items)->Array.slice(~start=first, ~end=last)
  })

  /* The rows that are not rendered are still occupying space, or the scroll
   would jump every time the window moved. */
  let spacing = Computed.make(() => {
    let (first, last) = Signal.get(range)
    let total = Signal.get(items)->Array.length
    Style.make({
      paddingTop: Style.pt(Int.toFloat(first) *. rowHeight),
      paddingBottom: Style.pt(Int.toFloat(total - last) *. rowHeight),
    })
  })

  Native.scroll(
    ~style?,
    ~attrs,
    ~events=[
      ("scroll", NativeEvent.handler((event: NativeEvent.scroll) => Signal.set(scrollTop, event.y))),
      (
        "layout",
        NativeEvent.handler((event: NativeEvent.layout) => Signal.set(viewport, event.height)),
      ),
    ],
    ~children=[
      Native.view(~styleSignal=spacing, ~children=[View.eachWithKey(window, key, renderRow)], ()),
    ],
    (),
  )
}
