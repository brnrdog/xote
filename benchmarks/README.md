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
| `--only id,id` | all nine | Run only these benchmarks (ids as in `results.json`) |
| `--out DIR` | `results` | Where to write `results.json` and `RESULTS.md` |
| `--headed` | off | Watch the browser drive the apps |

The driver prefers `BENCH_CHROME_PATH`, then the Chromium this dev environment
ships at `/opt/pw-browsers/chromium-1194/...`, and otherwise falls back to the
browser Playwright installed (`npx playwright install chromium`), which is how
CI runs it.

## Comparing two builds

CI runs this suite on pull requests labelled **`benchmark`** and posts a `main`
vs PR table. It is opt-in because the run takes several minutes and the timings
only mean anything for changes that touch rendering — label a PR when you want
the comparison, and nothing runs when you do not. Adding the label to an
already-open PR starts a run; no new push is needed.

The same comparison runs locally: build the base library into `dist/xote-base`
and name both apps in one invocation.

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

Run on 4x Xeon @ 2.10 GHz, Chromium 141, 15 iterations. The absolute values
are container-slow; the ratios are the point, and even those move 10-25%
between runs of identical code, so read close rows as ties.

**Where Xote leads or ties**

- *Creating rows* — 39.5 ms for 1,000 rows against Solid's 38.3, Vue's 40.6
  and React's 41.9: a four-way tie. Xote used to be 1.7x Solid here, building
  every node individually (20,000 DOM calls per 1,000 rows). It now learns a
  skeleton from the first rows of a list and clones it for the rest, so
  `dom-ops.mjs` counts 2,046 calls (998 `cloneNode`, one `insertBefore` of a
  fragment) against Solid's 2,001 from a compiled template.
- *Appending 1,000 rows to 10,000* — 87.0 ms, ahead of Solid's 90.6 and Vue's
  94.5, and half of React's 170.4. Rows that kept their relative order are not
  touched; only the fresh run is inserted.
- *Row selection* — 0.6 ms, level with Solid's 0.7 and about 7x faster than
  React. A thousand class effects re-run, and all but two skip the DOM because
  the class they compute is the one they last wrote.
- *Removing a row* — 3.7 ms, level with Solid's 3.9.
- *Reordering* — 4.5 ms, level with Solid's 4.3 and about 10x faster than
  React. `dom-ops.mjs` shows why: 2 `insertBefore` calls, the same as Vue and
  Solid, where React still issues 997.
- *Update every 10th row* — 5.1 ms, behind Solid's 4.3 and ahead of Vue (5.9)
  and React (8.4). Per-row signals mean 100 text writes, no diff.
- *Startup* — 18.6 ms, near Solid's 17.8 and well ahead of React's 34.8.

**Where Xote trails**

- *Creating 10,000 rows* — 533.8 ms against Vue's 417.8 and Solid's 445.4,
  though well ahead of React's 807.1. At 1,000 rows the same code is a tie;
  the extra at 10,000 is garbage collection. Every row still builds and
  discards a view tree — the props objects, attribute pairs and node records
  the JSX transform produces — before the skeleton is cloned, where a compiled
  template allocates none of that.
- *Clearing 10,000 rows* — 64.4 ms vs Solid's 54.2, now ahead of Vue's 69.1
  and React's 86.1 (it was 109 ms). Rows own their reactive state directly, so
  clearing disposes one owner per row instead of walking every node of the
  removed subtree. The rest is the effect disposers themselves, one layer
  deeper in Xote than in Solid.
- *Memory* — 17.5 MB at 10,000 rows against Solid's 12.3 MB, down from 40.5.
  Nothing hangs off DOM nodes any more and most nodes never get a JavaScript
  wrapper; what remains is the per-row reactive bookkeeping, which is heavier
  in `rescript-signals` than in Solid's runtime. Heap returns to 1.7 MB after
  clearing, so this is allocation weight and not a leak.
- *Payload* — 10.8 KB gzipped for the whole app against Solid's 4.7 KB, still
  a fraction of Vue's 24.9 KB and React's 59.9 KB. The template cloner is about
  2 KB of that.

## Caveats

- One machine, one browser, one run. Treat differences under ~10% as noise;
  the per-iteration samples in `results.json` let you check the spread.
- Cross-framework numbers come from a single interleaved run, so no framework
  gets the first-position penalty described above. They are still one machine's
  numbers, not a ranking.
- The container is CPU-constrained, so absolute milliseconds are several times
  what a laptop would show. Ratios travel; absolute numbers do not.
- Solid and Vue are mature and heavily tuned against exactly this benchmark.
  Xote learns its templates at runtime from the trees it renders, where Solid's
  compiler emits them ahead of time.
- `--enable-precise-memory-info` and a forced GC make the heap numbers usable,
  but they still measure only the JS heap, not DOM-side native memory.

[jfb]: https://github.com/krausest/js-framework-benchmark
