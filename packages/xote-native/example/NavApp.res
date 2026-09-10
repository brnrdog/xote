@@jsxConfig({version: 4, module_: "NativeJSX"})

/* The smallest app that is really navigating.

 Three screens deep, each one pushed from the last, with a counter on every
 screen so that "was this screen rebuilt" is a thing you can see rather than
 infer. `test/navigation_test.mjs` drives this through the real renderer and
 asserts that pushing a fourth screen leaves the first three's state alone.

 It is also what the browser preview shows for `XOTE_APP=nav`. */

module Style = NativeStyle

type screen = {title: string, level: int}

let nav = NativeNav.make({title: "One", level: 1})

let palette = ["#1d3557", "#457b9d", "#2a9d8f", "#e76f51"]

let colour = level =>
  switch palette->Array.get(mod(level - 1, Array.length(palette))) {
  | Some(colour) => colour
  | None => "#1d3557"
  }

/* A screen with state of its own, so the tests have something to lose.

 It has to be a component rather than a plain function for the reason written up
 twice in `REPORT.md`: a function called from inside a reactive region creates
 its signals in *that* region's scope, and they are disposed with it. */
module Page = {
  @react.component
  let make = (~screen: screen) => {
    let count = Signal.make(0)

    <screen style={Style.make({flex: 1.0, backgroundColor: colour(screen.level), padding: Style.pt(24.0)})}>
      <text style={Style.make({color: "#ffffff", fontSize: 28.0})}>
        {View.text(screen.title)}
      </text>
      <pressable
        style={Style.make({
          marginTop: Style.pt(16.0),
          padding: Style.pt(12.0),
          borderRadius: 8.0,
          backgroundColor: "#ffffff33",
        })}
        onPress={_ => Signal.update(count, n => n + 1)}>
        <text style={Style.make({color: "#ffffff"})}>
          {View.tracked(() => View.text("tapped " ++ Int.toString(Signal.get(count)) ++ "×"))}
        </text>
      </pressable>
      <pressable
        style={Style.make({
          marginTop: Style.pt(12.0),
          padding: Style.pt(12.0),
          borderRadius: 8.0,
          backgroundColor: "#ffffff33",
        })}
        onPress={_ =>
          NativeNav.push(
            nav,
            {title: "Level " ++ Int.toString(screen.level + 1), level: screen.level + 1},
          )}>
        <text style={Style.make({color: "#ffffff"})}> {View.text("push")} </text>
      </pressable>
      {View.tracked(() =>
        Signal.get(nav.canGoBack)
          ? <pressable
              style={Style.make({marginTop: Style.pt(12.0), padding: Style.pt(12.0)})}
              onPress={_ => NativeNav.pop(nav)}>
              <text style={Style.make({color: "#ffffff"})}> {View.text("back")} </text>
            </pressable>
          : View.null()
      )}
    </screen>
  }
}

let make = () =>
  NativeNav.view(
    nav,
    ~style=Style.make({flex: 1.0}),
    ~render=screen => <Page screen />,
    (),
  )
