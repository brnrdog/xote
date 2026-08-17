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
| `--headed` | off | Watch the browser drive the apps |

The driver uses the Chromium already present in this environment
(`/opt/pw-browsers/chromium-1194/...`). Point `BENCH_CHROME_PATH` at another
binary to override it.

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

Run on 4× Xeon @ 2.80 GHz, Chromium 141, 15 iterations. The absolute values are
container-slow; the ratios are the point.

**Where Xote leads**

- *Update every 10th row* — 7.8 ms, the fastest of the four (Solid 9.6, Vue
  11.5, React 13.4). Per-row signals mean 100 text-node writes, no diff.
- *Time to first render* — 23 ms vs React's 48 ms and Vue's 31 ms.
- *Payload* — 7.8 KB gzipped for the whole app against React's 59.9 KB and
  Vue's 24.9 KB. Solid is smaller still at 4.7 KB.
- *Row selection* — 1.1 ms, within noise of Solid and 6× faster than React.

**Where Xote trails**

- *Swapping two rows* — 57 ms against Solid's and Vue's 8–11 ms. This is not
  overhead, it is an algorithmic gap: `dom-ops.mjs` shows Xote issuing **997
  `insertBefore` calls to swap two rows**, where Vue and Solid issue 2. Phase 3
  of the keyed reconciler in `src/View.res` walks the new order against the
  live DOM and inserts every node whose position does not match the walk
  marker, so one early mismatch cascades through the rest of the list. A
  longest-increasing-subsequence pass (what Vue and Solid do) would move only
  the two nodes that actually changed places. React shows the same 997 moves —
  the difference is that this is a known trade in a diffing reconciler and less
  expected in a fine-grained one.
- *Creating rows* — 1.5× Solid and 1.35× React for 1,000 rows. Xote makes
  20,000 DOM calls per 1,000 rows (8,000 `createElement`, 9,000 `appendChild`,
  2,000 `createTextNode`, 1,000 `insertBefore`); Solid makes 2,001 by cloning a
  compiled template. Template cloning is the structural win here, and it needs
  a compiler.
- *Memory* — 43.6 MB at 10,000 rows against Solid's 12.3 MB. Each row allocates
  a label signal plus effects for the reactive class and text, and Xote's owner
  records are heavier per node. Heap returns to 1.6 MB after clearing, so this
  is allocation weight and not a leak.
- *Clearing 10,000 rows* — 187 ms vs Solid's 69 ms; the recursive owner
  disposal walk is the cost.

## Caveats

- One machine, one browser, one run. Treat differences under ~10% as noise;
  the per-iteration samples in `results.json` let you check the spread.
- The container is CPU-constrained, so absolute milliseconds are several times
  what a laptop would show. Ratios travel; absolute numbers do not.
- Solid and Vue are mature and heavily tuned against exactly this benchmark.
  Xote is at version 0.0.0 with no compiler-assisted templating.
- `--enable-precise-memory-info` and a forced GC make the heap numbers usable,
  but they still measure only the JS heap, not DOM-side native memory.

[jfb]: https://github.com/krausest/js-framework-benchmark
