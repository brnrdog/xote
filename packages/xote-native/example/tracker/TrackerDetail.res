@@jsxConfig({version: 4, module_: "NativeJSX"})

/* The detail screen: wrapping text, a scroll view, and the status control.

 The status buttons are the whole fine-grained argument in one gesture. Pressing
 one writes a single signal that belongs to the issue, and the three things that
 depend on it — this row of buttons, the coloured dot on the list row behind,
 and that row's title colour — each update themselves. Nothing re-renders. */

module Style = NativeStyle
module Theme = TrackerTheme

let activity = (issue: TrackerData.issue) => {
  let voices = ["ana", "rafa", "lu", "kim"]
  let notes = [
    "Reproduced on the simulator, adding a case to the conformance suite.",
    "This is the same root cause as #412 — the frame is measured before the width is known.",
    "Pushed a fix. The interesting part was that the batch was already correct; the host was not.",
    "Leaving this open until there is a real screen to measure it against.",
    "Confirmed fixed on the latest build. Closing after one more pass.",
  ]
  let count = 2 + mod(issue.id, 4)
  Array.fromInitializer(~length=count, index => (
    voices->Array.getUnsafe(mod(issue.id + index, Array.length(voices))),
    notes->Array.getUnsafe(mod(issue.id * 3 + index, Array.length(notes))),
  ))
}

type props = {issue: TrackerData.issue}

let make = (props: props) => {
  let issue = props.issue
  let statusButton = (wanted: TrackerData.status) =>
    <pressable
      style={() =>
        Style.merge([
          Theme.chip,
          Style.make({flex: 1.0, alignItems: #center}),
          Signal.get(issue.status) == wanted
            ? Style.make({
                backgroundColor: Theme.statusColor(wanted),
                borderColor: Theme.statusColor(wanted),
              })
            : Style.make({}),
        ])}
      onPress={_ => Signal.set(issue.status, wanted)}
    >
      <text
        style={() =>
          Style.merge([
            Theme.chipLabel,
            Style.make({
              color: Signal.get(issue.status) == wanted ? "#0a0a11" : Theme.muted,
            }),
          ])}
      >
        {View.text(TrackerData.statusLabel(wanted))}
      </text>
    </pressable>

  <view style={Theme.screen}>
    <view style={Theme.bar}>
      <pressable
        style={Style.make({
          paddingVertical: Style.pt(6.0),
          paddingRight: Style.pt(12.0),
        })}
        onPress={_ => TrackerNav.pop()}
      >
        <text style={Style.make({color: Theme.accent, fontSize: 16.0, fontWeight: #semibold})}>
          {View.text("← Issues")}
        </text>
      </pressable>
      <text style={Style.make({color: Theme.dim, fontSize: 13.0})}>
        {View.text("#" ++ Int.toString(issue.id))}
      </text>
    </view>

    <scroll style={Style.make({flex: 1.0, paddingHorizontal: Style.pt(20.0), gap: 16.0})}>
      // A long title with no explicit height: the host measures it, and the
      // card below it moves down by however many lines it turned out to be.
      <text style={Style.make({color: Theme.ink, fontSize: 22.0, fontWeight: #bold})}>
        {View.text(issue.title)}
      </text>

      <view style={Style.make({flexDirection: #row, alignItems: #center, gap: 8.0})}>
        <view
          style={() =>
            Style.make({
              width: Style.pt(8.0),
              height: Style.pt(8.0),
              borderRadius: 4.0,
              backgroundColor: Theme.statusColor(Signal.get(issue.status)),
            })}
        />
        <text style={Style.make({color: Theme.muted, fontSize: 13.0})}>
          {View.signalText(() => TrackerData.statusLabel(Signal.get(issue.status)))}
        </text>
        <text style={Style.make({color: Theme.dim, fontSize: 13.0})}>
          {View.text("· assigned to " ++ issue.assignee)}
        </text>
      </view>

      <view style={Style.make({flexDirection: #row, gap: 8.0})}>
        {statusButton(Open)}
        {statusButton(InProgress)}
        {statusButton(Done)}
      </view>

      <view style={Theme.card}>
        <text style={Theme.body}> {View.text(issue.body)} </text>
        <view style={Style.make({flexDirection: #row, gap: 6.0})}>
          {View.fragment(
            issue.labels->Array.map(name =>
              <view style={Theme.label}>
                <text style={Theme.labelText}> {View.text(name)} </text>
              </view>
            ),
          )}
        </view>
      </view>

      <text style={Style.make({color: Theme.muted, fontSize: 13.0, fontWeight: #semibold})}>
        {View.text("Activity")}
      </text>

      {View.fragment(
        activity(issue)->Array.map(((who, note)) =>
          <view style={Style.merge([Theme.card, Style.make({gap: 6.0})])}>
            <text style={Style.make({color: Theme.accent, fontSize: 12.0, fontWeight: #semibold})}>
              {View.text(who)}
            </text>
            <text style={Style.make({color: Theme.muted, fontSize: 14.0})}>
              {View.text(note)}
            </text>
          </view>
        ),
      )}

      <view style={Style.make({height: Style.pt(40.0)})} />
    </scroll>
  </view>
}
