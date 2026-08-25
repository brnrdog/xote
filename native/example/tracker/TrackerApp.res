@@jsxConfig({version: 4, module_: "NativeJSX"})

/* The example app: an issue tracker over five thousand issues.

 It exists to answer the question `ROADMAP.md` ends on — whether the mutation
 stream stays proportional to what actually changed on a screen at real-app
 scale, or only on a counter. `native/test/tracker_test.mjs` measures it.

 The whole app is one `View.tracked` over the navigation stack, because a screen
 change is the one thing that really is a wholesale replacement. Everything
 inside a screen updates in place. */

module Style = NativeStyle

let issues = TrackerData.make(5000)

let make = () =>
  <view style={TrackerTheme.screen}>
    {View.tracked(() =>
      switch Signal.get(TrackerNav.current) {
      | Issues => <TrackerIssues issues />
      | Detail(issue) => <TrackerDetail issue />
      }
    )}
  </view>
