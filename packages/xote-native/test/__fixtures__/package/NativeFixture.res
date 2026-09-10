/* A native screen written the way a downstream app would write one: against
 `xote` and `xote-native` as two separate packages, with neither of them in
 this project's own sources.

 It is deliberately unremarkable. What is being tested is not the screen, it is
 that the screen compiles at all from outside both packages — that the modules
 resolve, that the JSX module switch works across a package boundary, and that
 the emitted imports point at `xote/src/...` rather than at a relative path. */

@@jsxConfig({version: 4, module_: "NativeJSX"})

module Style = NativeStyle

type row = {id: string, label: string}

let make = () => {
  let count = Signal.make(0)
  let rows = Signal.make([{id: "a", label: "first"}, {id: "b", label: "second"}])

  let total = Computed.make(() => Signal.get(rows)->Array.length)

  <view style={Style.make({flex: 1.0, padding: Style.pt(16.0), gap: 8.0})}>
    <text style={Style.make({fontSize: 20.0, fontWeight: #bold, color: "#ffffff"})}>
      {View.text("Fixture")}
    </text>
    <pressable onPress={_ => Signal.update(count, c => c + 1)}>
      <text> {View.signalText(() => Int.toString(Signal.get(count)))} </text>
    </pressable>
    <input
      value={Signal.make("")}
      placeholder="search"
      placeholderTextColor="#888888"
      onChangeText={(event: NativeEvent.text) => ignore(event.value)}
      onSubmit={(event: NativeEvent.text) => ignore(event.value)}
      onFocus={(event: NativeEvent.focus) => ignore(event.value)}
    />
    {NativeList.make(
      ~items=rows,
      ~rowHeight=44.0,
      ~key=row => row.id,
      ~renderRow=row => <text> {View.text(row.label)} </text>,
      ~style=Style.make({flex: 1.0}),
      (),
    )}
    {View.tracked(() => View.text(Int.toString(Signal.get(total))))}
  </view>
}
