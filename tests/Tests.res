%%raw(`import './setup.mjs'`)

Zekr.setSnapshotDir("tests/__snapshots__")

Zekr.runSuites([
  Component_test.suite,
  JSX_test.suite,
  KeyedList_test.suite,
  Route_test.suite,
  SSR_test.suite,
  SSRState_test.suite,
  Hydration_test.suite,
])
