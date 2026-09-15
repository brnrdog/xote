@@jsxConfig({version: 4, module_: "NativeJSX"})

/* The list screen: a search field, three filters, and five thousand issues.

 Everything on it is derived from two signals — the query and the status
 filter — and the derivation is where the interesting decisions are. Read the
 comments on `matches` and `visible` before changing either. */

module Style = NativeStyle
module Theme = TrackerTheme

let rowHeight = 84.0

let lower = (text: string) => text->String.toLowerCase

let matches = (issue: TrackerData.issue, query: string, filter: option<TrackerData.status>) => {
  let statusOk = switch filter {
  | None => true
  | Some(wanted) => Signal.peek(issue.status) == wanted
  }
  statusOk &&
  (query == "" ||
  lower(issue.title)->String.includes(query) ||
  lower(issue.assignee)->String.includes(query))
}

/* A props record, so this is a JSX component rather than a function that
 happens to return a node — and that is load-bearing. `NativeJSX.jsx` wraps a
 component in `View.LazyComponent`, whose body runs untracked in its own scope.
 Called as a plain function from inside the navigation's tracked block, the
 signals and the effect below would be created *in* that block, and every
 keystroke would re-render the whole screen and reset the search field. */
type props = {issues: array<TrackerData.issue>}

let make = (props: props) => {
  let issues = props.issues
  let query = Signal.make("")
  let filter: Signal.t<option<TrackerData.status>> = Signal.make(None)

  /* Filtering five thousand issues on every keystroke is a real cost and it
   belongs here, in the app, where it can be seen. What the framework
   guarantees is only that the *result* is applied surgically: a query that
   narrows the list to eleven rows moves eleven rows, not five thousand. */
  let visible = Computed.make(() => {
    let text = lower(Signal.get(query))
    let wanted = Signal.get(filter)
    issues->Array.filter(issue => matches(issue, text, wanted))
  })

  let count = Computed.make(() => Array.length(Signal.get(visible)))

  /* `View.tracked` re-renders its children wholesale, so it is given a boolean
   that only changes when the branch does — and a boolean in a `Signal`, not a
   `Computed`, because `Signal.set` does not notify when the value is unchanged
   and so the region is never even invalidated. Typing into the search field
   crosses this once, when the last result disappears. */
  let isEmpty = Signal.make(false)
  Effect.run(() => {
    Signal.set(isEmpty, Signal.get(count) == 0)
    None
  })

  let chip = (label, wanted) =>
    <pressable
      style={() =>
        Style.merge([
          Theme.chip,
          Signal.get(filter) == wanted
            ? Style.make({backgroundColor: Theme.accent, borderColor: Theme.accent})
            : Style.make({}),
        ])}
      onPress={_ => Signal.set(filter, Signal.get(filter) == wanted ? None : wanted)}
    >
      <text
        style={() =>
          Style.merge([
            Theme.chipLabel,
            Style.make({color: Signal.get(filter) == wanted ? "#ffffff" : Theme.muted}),
          ])}
      >
        {View.text(label)}
      </text>
    </pressable>

  let row = (issue: TrackerData.issue) =>
    <pressable
      style={Style.make({
        height: Style.pt(rowHeight),
        paddingHorizontal: Style.pt(20.0),
        paddingVertical: Style.pt(10.0),
        gap: 5.0,
        // A row in a windowed list is a fixed height by construction, so
        // anything that does not fit is clipped rather than allowed to bleed
        // into the row below it.
        overflow: #hidden,
      })}
      onPress={_ => TrackerNav.push(Detail(issue))}
    >
      <view style={Style.make({flexDirection: #row, alignItems: #center, gap: 8.0})}>
        // A dot whose colour is the issue's own status signal: toggling it in
        // the detail screen writes this one prop and nothing else.
        <view
          style={() =>
            Style.make({
              width: Style.pt(8.0),
              height: Style.pt(8.0),
              borderRadius: 4.0,
              backgroundColor: Theme.statusColor(Signal.get(issue.status)),
            })}
        />
        <text style={Style.make({color: Theme.dim, fontSize: 12.0})}>
          {View.text("#" ++ Int.toString(issue.id))}
        </text>
        <text style={Style.make({color: Theme.dim, fontSize: 12.0})}>
          {View.text(issue.assignee)}
        </text>
      </view>
      <text
        numberOfLines={1}
        style={() =>
          Style.merge([
            Style.make({color: Theme.ink, fontSize: 15.0}),
            Signal.get(issue.status) == Done ? Style.make({color: Theme.dim}) : Style.make({}),
          ])}
      >
        {View.text(issue.title)}
      </text>
      <view style={Style.make({flexDirection: #row, gap: 6.0, alignItems: #center})}>
        {View.fragment(
          issue.labels->Array.map(name =>
            <view style={Theme.label}>
              <text style={Theme.labelText}> {View.text(name)} </text>
            </view>
          ),
        )}
        <text style={Style.make({color: Theme.dim, fontSize: 11.0})}>
          {View.text(Int.toString(issue.comments) ++ " comments")}
        </text>
      </view>
    </pressable>

  <view style={Theme.screen}>
    <view style={Theme.bar}>
      <view style={Style.make({gap: 2.0})}>
        <text style={Theme.title}> {View.text("Issues")} </text>
        <text style={Theme.subtitle}>
          {View.signalText(() =>
            Int.toString(Signal.get(count)) ++ " of " ++ Int.toString(Array.length(issues))
          )}
        </text>
      </view>
      <view style={Style.make({position: #relative})}>
        <view
          style={Style.make({
            width: Style.pt(36.0),
            height: Style.pt(36.0),
            borderRadius: 18.0,
            backgroundColor: Theme.surfaceHigh,
          })}
        />
        // Absolutely positioned against the padding box of its parent, which is
        // the kind of thing the old UIStackView host could not express at all.
        <view
          style={Style.make({
            position: #absolute,
            top: Style.pt(-4.0),
            right: Style.pt(-4.0),
            width: Style.pt(18.0),
            height: Style.pt(18.0),
            borderRadius: 9.0,
            backgroundColor: Theme.accent,
            alignItems: #center,
            justifyContent: #center,
          })}
        >
          <text style={Style.make({color: "#ffffff", fontSize: 10.0, fontWeight: #bold})}>
            {View.text("3")}
          </text>
        </view>
      </view>
    </view>
    <view style={Style.make({paddingHorizontal: Style.pt(20.0), gap: 12.0})}>
      <input
        placeholder="Search issues"
        placeholderTextColor={Theme.dim}
        style={Theme.input}
        onChangeText={event => Signal.set(query, event.value)}
      />
      <view style={Style.make({flexDirection: #row, gap: 8.0})}>
        {chip("Open", Some(TrackerData.Open))}
        {chip("In progress", Some(TrackerData.InProgress))}
        {chip("Done", Some(TrackerData.Done))}
      </view>
    </view>
    {View.tracked(() =>
      Signal.get(isEmpty)
        ? <view
            style={Style.make({
              flex: 1.0,
              alignItems: #center,
              justifyContent: #center,
              gap: 6.0,
            })}
          >
            <text style={Style.make({color: Theme.muted, fontSize: 16.0})}>
              {View.text("Nothing matches")}
            </text>
            <text style={Style.make({color: Theme.dim, fontSize: 13.0})}>
              {View.text("Try a different search or clear the filter")}
            </text>
          </view>
        : NativeList.make(
            ~items=visible,
            ~rowHeight,
            ~key=issue => Int.toString(issue.id),
            ~renderRow=row,
            ~style=Style.make({flex: 1.0, marginTop: Style.pt(12.0)}),
            (),
          )
    )}
  </view>
}
