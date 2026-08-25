/* One place for the palette and the shapes that repeat.

 Styles are plain records, so a shared one is a value and a variation is a
 merge. Nothing here is reactive: a style that depends on state is built in a
 thunk at the call site, which is what makes it a fine-grained update rather
 than a re-render. */

module Style = NativeStyle

let ink = "#e9e9f2"
let muted = "#8b8b9f"
let dim = "#5f5f74"
let accent = "#7c5cff"
let surface = "#14141d"
let surfaceHigh = "#1c1c28"
let background = "#0a0a11"
let line = "#26263a"

let open_ = "#4c9aff"
let progress = "#f2b134"
let done_ = "#3ec98b"

let statusColor = status =>
  switch status {
  | TrackerData.Open => open_
  | TrackerData.InProgress => progress
  | TrackerData.Done => done_
  }

let screen = Style.make({flex: 1.0, backgroundColor: background})

let bar = Style.make({
  flexDirection: #row,
  alignItems: #center,
  justifyContent: #"space-between",
  paddingHorizontal: Style.pt(20.0),
  paddingTop: Style.pt(56.0),
  paddingBottom: Style.pt(14.0),
  gap: 12.0,
})

let title = Style.make({color: ink, fontSize: 26.0, fontWeight: #bold})

let subtitle = Style.make({color: muted, fontSize: 13.0})

let body = Style.make({color: ink, fontSize: 15.0, lineHeight: 21.0})

let card = Style.make({
  backgroundColor: surface,
  borderRadius: 14.0,
  padding: Style.pt(16.0),
  gap: 12.0,
})

let input = Style.make({
  backgroundColor: surfaceHigh,
  borderRadius: 10.0,
  paddingHorizontal: Style.pt(12.0),
  height: Style.pt(40.0),
  color: ink,
  fontSize: 15.0,
})

let chip = Style.make({
  paddingHorizontal: Style.pt(12.0),
  paddingVertical: Style.pt(7.0),
  borderRadius: 999.0,
  borderWidth: 1.0,
  borderColor: line,
})

let chipLabel = Style.make({fontSize: 13.0, fontWeight: #medium})

let row = Style.make({
  flexDirection: #row,
  alignItems: #center,
  gap: 10.0,
  paddingHorizontal: Style.pt(20.0),
})

let label = Style.make({
  backgroundColor: surfaceHigh,
  borderRadius: 6.0,
  paddingHorizontal: Style.pt(6.0),
  paddingVertical: Style.pt(2.0),
})

let labelText = Style.make({color: dim, fontSize: 11.0})

let button = Style.make({
  backgroundColor: accent,
  borderRadius: 12.0,
  paddingVertical: Style.pt(12.0),
  paddingHorizontal: Style.pt(18.0),
  alignItems: #center,
})

let buttonLabel = Style.make({color: "#ffffff", fontSize: 15.0, fontWeight: #semibold})
