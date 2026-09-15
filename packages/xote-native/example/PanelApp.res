/* The same primitives without JSX.

 `Native.*` is `View.element` with the host's tag names, so a project that has
 not turned JSX on writes screens like this. It is also what the JSX module
 compiles down to. */

module Style = NativeStyle

let make = () => {
  let label = Signal.make("idle")
  let presses = Signal.make(0)

  let button = Style.merge([
    Style.make({paddingVertical: Style.pt(10.0), borderRadius: 10.0}),
    Style.make({backgroundColor: "#7c5cff"}),
  ])

  Native.view(
    ~style=Style.make({flex: 1.0, gap: 8.0}),
    ~children=[
      Native.text(~children=[View.signalText(() => Signal.get(label))], ()),
      Native.pressable(
        ~style=button,
        ~onPress=_ => {
          Signal.update(presses, n => n + 1)
          Signal.set(label, "pressed " ++ Int.toString(Signal.peek(presses)) ++ "x")
        },
        ~children=[Native.text(~children=[View.text("Press")], ())],
        (),
      ),
    ],
    (),
  )
}
