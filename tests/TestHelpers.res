/* Bridges the xote test suite onto zekr 2.x's self-registering module API.
   Each `*_test.res` file opens this module, which re-exports the flat helpers
   the suites use and wires up the shared jsdom environment before any test
   runs. Suites register themselves through `Suite.make`, so the zekr CLI can
   discover and run them by filename pattern without a central runner. */

%%raw(`import "./setup.mjs"`)

open Zekr

include Types

module Suite = Suite
module Test = Test
module Dom = DomTesting
module DomBindings = DomBindings

let test = Test.make
let combineResults = Assert.combineResults
let assertEqual = (actual, expected) => Assert.equal(actual, expected)
let assertTrue = condition => Assert.isTrue(condition)
let assertFalse = condition => Assert.isFalse(condition)
let assertContains = (haystack, needle) => Assert.contains(haystack, needle)
let assertMatchesSnapshot = (value, ~name) => Snapshot.matches(value, ~name)
let setSnapshotDir = Snapshot.setDir
