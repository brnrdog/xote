/* The dataset the example screen runs on.

 Generated rather than fetched, and generated deterministically, so the numbers
 in `native/test/tracker_test.mjs` mean the same thing on every run. Five
 thousand issues is not a stress test — it is roughly what a real tracker holds
 after a year, and the point of the example is to find out what a real screen
 costs. */

type status = Open | InProgress | Done

type issue = {
  id: int,
  title: string,
  body: string,
  assignee: string,
  labels: array<string>,
  comments: int,
  /* Per-issue state lives in its own signal rather than in the array. Rebuilding
   the array to change one issue's status would make the keyed list retire the
   row and render a new one; a signal makes it two style writes. */
  status: Signal.t<status>,
}

let statusLabel = status =>
  switch status {
  | Open => "Open"
  | InProgress => "In progress"
  | Done => "Done"
  }

/* A Lehmer generator, in floats.

 In integers this would be wrong in a way that is easy to miss: ReScript
 compiles `*` on `int` to `Math.imul`, which wraps to 32 bits, so the product
 goes negative, `mod` follows it, and every index derived from it lands outside
 its array as `undefined`. Floats hold the product exactly — 2147483646 × 48271
 is comfortably inside what a double represents — and the sequence is the same
 on every platform. */
let seed = ref(20260825.0)

let random = () => {
  let next = seed.contents *. 48271.0
  seed := next -. Math.floor(next /. 2147483647.0) *. 2147483647.0
  seed.contents
}

let randomInt = (bound: int): int => {
  let value = random()
  let bound = Int.toFloat(bound)
  Int.fromFloat(value -. Math.floor(value /. bound) *. bound)
}

let pick = (options: array<'a>): 'a => options->Array.getUnsafe(randomInt(Array.length(options)))

let verbs = ["Fix", "Add", "Remove", "Rework", "Investigate", "Document", "Speed up", "Simplify"]

let subjects = [
  "the keyed reconciler",
  "text measurement",
  "the scroll offset",
  "flex shrink",
  "the batch flush",
  "layout on rotation",
  "the conformance suite",
  "percentage widths",
  "the bridge protocol",
  "view recycling",
  "the empty state",
  "an absolute badge",
]

let qualifiers = [
  "on first paint",
  "when the list is empty",
  "under a reverse direction",
  "after a hot reload",
  "on a narrow screen",
  "with overscan",
  "",
]

let bodies = [
  "Reproduces every time on a fresh install. The first pass measures one line, and the row settles a frame later, which reads as a flicker on anything slower than a recent phone.",
  "Only shows up once the window has moved at least once, so it needs a scroll before it can be seen at all. Worth a regression case in the conformance suite either way.",
  "Not urgent, but it is the kind of thing that gets much harder to change once there are more hosts. Better to decide now what the right shape is and write it down.",
  "The workaround is to materialise the condition into a signal, which works, but it is a thing every app author has to know — which is the definition of a leak.",
]

let assignees = ["bern", "ana", "rafa", "lu", "kim", "sam", "noa"]

let labelPool = ["layout", "bridge", "ios", "perf", "text", "scroll", "docs", "flaky"]

let make = (count: int): array<issue> => {
  seed := 20260825.0
  Array.fromInitializer(~length=count, index => {
    let qualifier = pick(qualifiers)
    let title =
      pick(verbs) ++
      " " ++
      pick(subjects) ++
      (qualifier == "" ? "" : " " ++ qualifier)
    let labelCount = 1 + randomInt(3)
    {
      id: index + 1,
      title,
      body: pick(bodies),
      assignee: pick(assignees),
      labels: Array.fromInitializer(~length=labelCount, _ => pick(labelPool)),
      comments: randomInt(24),
      status: Signal.make(
        switch randomInt(5) {
        | 0 => Done
        | 1 | 2 => InProgress
        | _ => Open
        },
      ),
    }
  })
}
