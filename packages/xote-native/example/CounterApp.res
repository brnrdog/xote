@@jsxConfig({version: 4, module_: "NativeJSX"})

/* A native app, written in ReScript with Xote.

 `@@jsxConfig` swaps the JSX module for this file alone, which is what lets a
 native screen live in the same project as web code. Nothing else here is
 native-specific: the signals, `View.tracked` and `View.eachWithKey` are the
 same ones a browser app uses, and each of them updates exactly the views its
 own value touches. */

module Style = NativeStyle

/* `done` is a signal, not a field that gets replaced. Rebuilding the array to
 flip a checkbox would make the keyed list retire the row and render a new one —
 cheap in the DOM, an allocation and a layout pass on a phone. Keeping the
 mutable part inside the row means a toggle writes two style props and touches
 nothing else. */
type todo = {id: int, title: string, done: Signal.t<bool>}

let ink = "#e8e8ef"
let muted = "#8b8b9c"
let accent = "#7c5cff"

let screen = Style.make({
  flex: 1.0,
  backgroundColor: "#0b0b12",
  paddingHorizontal: Style.pt(20.0),
  paddingTop: Style.pt(64.0),
  gap: 20.0,
})

let heading = Style.make({color: ink, fontSize: 28.0, fontWeight: #bold})

let row = Style.make({
  flexDirection: #row,
  alignItems: #center,
  justifyContent: #"space-between",
  gap: 12.0,
})

let button = Style.make({
  backgroundColor: accent,
  paddingVertical: Style.pt(12.0),
  paddingHorizontal: Style.pt(18.0),
  borderRadius: 12.0,
})

let buttonLabel = Style.make({color: "#ffffff", fontSize: 16.0, fontWeight: #semibold})

let card = Style.make({
  backgroundColor: "#15151f",
  borderRadius: 14.0,
  padding: Style.pt(16.0),
  gap: 10.0,
})

let make = () => {
  let count = Signal.make(0)
  let todos = Signal.make([
    {id: 1, title: "Wire the bridge", done: Signal.make(true)},
    {id: 2, title: "Embed Yoga", done: Signal.make(false)},
    {id: 3, title: "Ship a screen", done: Signal.make(false)},
  ])
  let nextId = ref(4)

  let add = () => {
    let id = nextId.contents
    nextId := id + 1
    Signal.update(todos, list =>
      list->Array.concat([{id, title: "Task " ++ Int.toString(id), done: Signal.make(false)}])
    )
  }

  let toggle = (todo: todo) => Signal.update(todo.done, done => !done)

  let remaining = Computed.make(() =>
    Signal.get(todos)->Array.filter(todo => !Signal.get(todo.done))->Array.length
  )

  /* A tracked block re-renders its children wholesale, which on a native host
   means tearing real views down and building them again. So the condition is
   materialised into a signal rather than read inline: `Signal.set` does not
   notify when the value is unchanged, and — unlike a computed's `~equals`,
   which stops the notification but not the dirty flag that already propagated
   — that keeps the block from being invalidated at all. Nine taps out of ten
   never reach it. */
  let showHint = Signal.make(false)
  Effect.run(() => {
    Signal.set(showHint, Signal.get(count) >= 3)
    None
  })

  <view style={screen}>
    <text style={heading}> {View.text("Xote Native")} </text>
    <view style={row}>
      <text style={Style.make({color: muted, fontSize: 16.0})}>
        {View.signalText(() => "Tapped " ++ Int.toString(Signal.get(count)) ++ "x")}
      </text>
      <pressable style={button} onPress={_ => Signal.update(count, c => c + 1)}>
        <text style={buttonLabel}> {View.text("Tap me")} </text>
      </pressable>
    </view>
    <view style={card}>
      <view style={row}>
        <text style={Style.make({color: ink, fontSize: 18.0, fontWeight: #semibold})}>
          {View.text("Todos")}
        </text>
        <text style={Style.make({color: muted, fontSize: 14.0})}>
          {View.signalText(() => Int.toString(Signal.get(remaining)) ++ " left")}
        </text>
      </view>
      {View.eachWithKey(
        todos,
        todo => Int.toString(todo.id),
        todo =>
          <pressable
            style={Style.make({
              flexDirection: #row,
              alignItems: #center,
              gap: 10.0,
              paddingVertical: Style.pt(8.0),
            })}
            onPress={_ => toggle(todo)}
          >
            // A thunk in a prop position is a reactive prop: it is read inside
            // that one attribute's effect, so flipping `done` rewrites this
            // style and no other.
            <view
              style={() =>
                Style.make({
                  width: Style.pt(18.0),
                  height: Style.pt(18.0),
                  borderRadius: 9.0,
                  borderWidth: 2.0,
                  borderColor: Signal.get(todo.done) ? accent : muted,
                  backgroundColor: Signal.get(todo.done) ? accent : "#00000000",
                })}
            />
            <text
              style={() => Style.make({color: Signal.get(todo.done) ? muted : ink, fontSize: 16.0})}
            >
              {View.text(todo.title)}
            </text>
          </pressable>,
      )}
      <pressable style={button} onPress={_ => add()}>
        <text style={buttonLabel}> {View.text("Add task")} </text>
      </pressable>
    </view>
    {View.tracked(() =>
      Signal.get(showHint)
        ? <text style={Style.make({color: accent, fontSize: 14.0})}>
            {View.text("You really like that button.")}
          </text>
        : View.empty()
    )}
  </view>
}
