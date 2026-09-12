@@jsxConfig({version: 4, module_: "NativeJSX"})

/* The example app: an issue tracker over five thousand issues.

 It exists to answer the question `ROADMAP.md` ends on — whether the mutation
 stream stays proportional to what actually changed on a screen at real-app
 scale, or only on a counter. `test/tracker_test.mjs` measures it.

 The whole app is a navigation stack. It used to be one `View.tracked` that
 chose a screen and rebuilt it — which made a screen change a wholesale
 replacement, and made going back to the list a fresh list with the scroll
 position and the search text gone. `NativeNav` renders one `screen` per entry
 instead, so a push adds and a pop removes, and everything under the top is left
 exactly as it was. */

module Style = NativeStyle

let issues = TrackerData.make(5000)

let make = () =>
  NativeNav.view(
    TrackerNav.nav,
    ~style=TrackerTheme.screen,
    ~render=screen =>
      switch screen {
      | TrackerNav.Issues => <TrackerIssues issues />
      | TrackerNav.Detail(issue) => <TrackerDetail issue />
      },
    (),
  )
