# Xote benchmarks

A keyed-list benchmark that runs the same application in **Xote, React, Vue and
SolidJS** and measures operation latency, startup time, memory and payload size.

The app is the standard [js-framework-benchmark][jfb] workload: a table of rows
that gets created, replaced, updated, selected, swapped, appended to and
cleared. Every implementation renders byte-identical DOM, uses the same
stylesheet and consumes the same deterministic data generator
(`shared/data.js`), so the only thing that varies is the framework doing the
work.

Latest numbers: [`results/RESULTS.md`](./results/RESULTS.md). Raw samples:
[`results/results.json`](./results/results.json).

## Running it

```bash
npm install            # in the repo root, then:
npx rescript           # compiles benchmarks/apps/xote/BenchApp.res

cd benchmarks
npm install
node build.mjs         # production builds into benchmarks/dist/
node driver.mjs        # runs the suite, writes benchmarks/results/
node dom-ops.mjs       # optional: counts DOM calls per operation
```

`driver.mjs` flags:

| Flag | Default | Meaning |
| --- | --- | --- |
| `--iterations N` | `15` | Measured iterations per benchmark |
| `--warmup N` | `3` | Discarded warmup iterations |
| `--apps a,b` | all four | Restrict the run |
| `--out DIR` | `results` | Where to write `results.json` and `RESULTS.md` |
| `--headed` | off | Watch the browser drive the apps |

The driver prefers `BENCH_CHROME_PATH`, then the Chromium this dev environment
ships at `/opt/pw-browsers/chromium-1194/...`, and otherwise falls back to the
browser Playwright installed (`npx playwright install chromium`), which is how
CI runs it.

## Comparing two builds

CI runs this suite on every pull request and posts a `main` vs PR table. The
same comparison runs locally: build the base library into `dist/xote-base` and
name both apps in one invocation.

```bash
node driver.mjs --apps xote,xote-base --out ci-results
node dom-ops.mjs --apps xote,xote-base --json ci-results/dom-ops.json
node ../scripts/benchmark-report.mjs \
  --results ci-results/results.json \
  --dom-ops ci-results/dom-ops.json
```

Only Xote is rebuilt for the comparison. React, Vue and SolidJS are pinned
dependencies that cannot change between the two commits, so re-running them
would double the CI time for no signal.

### Why both builds run in one invocation

Position in the schedule costs more than almost any real change. Measured on
this repo with two byte-identical builds, the app that ran first paid **up to
2.5x** on the allocation-heavy benchmarks — enough to make every PR look like a
catastrophic regression.

The driver therefore runs one benchmark across all apps at a time, interleaved
iteration by iteration, alternating which app goes first on each round, with
`bringToFront()` before each measurement so no page is measured while
backgrounded. With that in place two identical builds report deltas that the
report suppresses as noise.

What survives is still noisy: single-digit to ~15% swings between identical
builds are normal on a shared runner. The report only flags a change when it
exceeds both the two runs' combined standard deviation and 5%; everything else
is printed with a `≈` and carries no claim. The DOM operation counts are
deterministic, so those are the signal to trust — a reconciler change shows up
there exactly, with no statistics involved.

## What is measured

Each iteration starts from an empty list, replays the setup clicks unmeasured,
then measures **one** click. Two timings are recorded per click:

- **Commit time** — click → framework finished mutating the DOM, with a forced
  style and layout pass. It drains microtasks and one macrotask first, so a
  framework that defers work into a scheduler task (React does) is still billed
  for it. This is the high-resolution number and the one to compare.
- **Time to paint** — the same click measured through to the frame that paints
  the result (`requestAnimationFrame` + `setTimeout(0)`). Closer to what a user
  perceives, but quantised by the compositor's frame cadence, so sub-frame
  differences collapse into a single ~16 ms bucket.

After every measurement the driver asserts the resulting DOM state (row count,
selected row count, number of updated labels). A framework cannot post a fast
time by leaving the update unfinished.

Also collected: time to first render (navigation → app mounted), JS payload
(minified / gzip / brotli), and used JS heap after a forced GC at four points in
the lifecycle.

## Implementation choices

Each app is written the way its own documentation recommends for a large list,
which is what makes the comparison interesting — the architectures genuinely
differ:

| | State model | Label update path |
| --- | --- | --- |
| **Xote** | `Signal<array<row>>`, each row owns a `Signal<string>` label | Writes one text node |
| **Solid** | `createSignal` array, per-row label signal | Writes one text node |
| **React** | `useState` array, immutable replacement | Re-renders and diffs the list |
| **Vue** | `shallowRef` array + `triggerRef` | Re-renders and diffs the list |

Rows are keyed by id everywhere. Event handlers are attached per row (no
delegation) in all four. No app is memoised beyond what the framework does by
default.

## What the numbers showed

Run on 4× Xeon @ 2.10 GHz, Chromium 141, 15 iterations. The absolute values
are container-slow; the ratios are the point, and even those move 10-25%
between runs of identical code, so read close rows as ties.

**Where Xote leads**

- *Update every 10th row* — 4.2 ms, level with Solid's 4.4 and about 2x ahead
  of Vue (5.6) and React (9.4). Per-row signals mean 100 text-node writes, no
  diff.
- *Row selection* — 0.7 ms, a few tenths off Solid and roughly 6x faster than
  React.
- *Payload* — 7.9 KB gzipped for the whole app against React's 59.9 KB and
  Vue's 24.9 KB. Solid is smaller still at 4.7 KB.
- *Startup* — 18.8 ms, in the same range as Solid's 17.1 and about half
  React's 35.0.

**Where Xote trails**

- *Swapping two rows* — 43 ms against Solid's 4.0 ms and Vue's 4.9 ms. This is
  not overhead, it is an algorithmic gap: `dom-ops.mjs` shows Xote issuing
  **997 `insertBefore` calls to swap two rows**, where Vue and Solid issue 2.
  Phase 3 of the keyed reconciler in `src/View.res` walks the new order
  against the live DOM and inserts every node whose position does not match
  the walk marker, so one early mismatch cascades through the rest of the
  list. A longest-increasing-subsequence pass (what Vue and Solid do) would
  move only the two nodes that actually changed places. React shows the same
  997 moves — the difference is that this is a known trade in a diffing
  reconciler and less expected in a fine-grained one.
- *Creating rows* — 1.75x Solid and 1.4x React for 1,000 rows. Xote makes
  20,000 DOM calls per 1,000 rows (8,000 `createElement`, 9,000 `appendChild`,
  2,000 `createTextNode`, 1,000 `insertBefore`); Solid makes 2,001 by cloning a
  compiled template. Template cloning is the structural win here, and it needs
  a compiler.
- *Memory* — 44.0 MB at 10,000 rows against Solid's 12.3 MB. Each row
  allocates a label signal plus effects for the reactive class and text, and
  Xote's owner records are heavier per node. Heap returns to 1.6 MB after
  clearing, so this is allocation weight and not a leak.
- *Clearing 10,000 rows* — 176 ms vs Solid's 61 ms; the recursive owner
  disposal walk is the cost.

## Caveats

- One machine, one browser, one run. Treat differences under ~10% as noise;
  the per-iteration samples in `results.json` let you check the spread.
- Cross-framework numbers come from a single interleaved run, so no framework
  gets the first-position penalty described above. They are still one machine's
  numbers, not a ranking.
- The container is CPU-constrained, so absolute milliseconds are several times
  what a laptop would show. Ratios travel; absolute numbers do not.
- Solid and Vue are mature and heavily tuned against exactly this benchmark.
  Xote is at version 0.0.0 with no compiler-assisted templating.
- `--enable-precise-memory-info` and a forced GC make the heap numbers usable,
  but they still measure only the JS heap, not DOM-side native memory.

[jfb]: https://github.com/krausest/js-framework-benchmark
