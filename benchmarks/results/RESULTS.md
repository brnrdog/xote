# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.80GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.2.8, Vue 3.5.41, Solid 1.9.14.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 88.7 (1.69x) | 62.1 (1.18x) | 59.2 (1.13x) | **52.5** (1.00x) |
| Replace 1,000 rows | 93.8 (1.47x) | 65.6 (1.03x) | **63.7** (1.00x) | 65.7 (1.03x) |
| Update every 10th row | 6.3 (1.17x) | 11.7 (2.17x) | 7.4 (1.37x) | **5.4** (1.00x) |
| Select a row | 1.0 (1.25x) | 5.8 (7.25x) | 1.9 (2.37x) | **0.8** (1.00x) |
| Swap two rows | 7.3 (1.16x) | 64.8 (10.29x) | 7.8 (1.24x) | **6.3** (1.00x) |
| Remove a row | 6.2 (1.17x) | 10.6 (2.00x) | 6.9 (1.30x) | **5.3** (1.00x) |
| Create 10,000 rows | 918.9 (1.39x) | 947.3 (1.43x) | 705.8 (1.07x) | **660.4** (1.00x) |
| Append 1,000 to 10,000 rows | 211.4 (1.77x) | 279.4 (2.33x) | 138.8 (1.16x) | **119.7** (1.00x) |
| Clear 10,000 rows | 108.9 (1.76x) | 96.4 (1.55x) | 75.3 (1.21x) | **62.0** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 89.7 (1.33x) | 76.4 (1.13x) | 70.6 (1.05x) | **67.4** (1.00x) |
| Replace 1,000 rows | 95.8 (1.39x) | 76.1 (1.10x) | 76.3 (1.10x) | **69.1** (1.00x) |
| Update every 10th row | 19.4 (1.53x) | 16.7 (1.31x) | 16.0 (1.26x) | **12.7** (1.00x) |
| Select a row | 15.9 (1.61x) | 12.5 (1.26x) | 13.9 (1.40x) | **9.9** (1.00x) |
| Swap two rows | 20.8 (1.34x) | 78.7 (5.08x) | **15.5** (1.00x) | 17.4 (1.12x) |
| Remove a row | 22.4 (1.19x) | 22.9 (1.21x) | 23.0 (1.22x) | **18.9** (1.00x) |
| Create 10,000 rows | 921.7 (1.39x) | 951.5 (1.43x) | 710.3 (1.07x) | **663.5** (1.00x) |
| Append 1,000 to 10,000 rows | 222.1 (1.30x) | 299.1 (1.74x) | 206.4 (1.20x) | **171.5** (1.00x) |
| Clear 10,000 rows | 109.4 (1.62x) | 97.2 (1.44x) | 76.0 (1.13x) | **67.4** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | 24.4 (1.07x) | 41.8 (1.84x) | 28.5 (1.25x) | **22.8** (1.00x) |
| JS bundle, minified (KB) | 26.4 | 190.4 | 62.4 | 11.0 |
| JS bundle, gzipped (KB) | 8.4 | 59.9 | 24.9 | 4.7 |
| JS bundle, brotli (KB) | 7.6 | 51.6 | 22.6 | 4.2 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.7 | 1.5 | 1.2 |
| 1,000 rows | 5.5 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 40.5 | 20.2 | 19.0 | 12.3 |
| After clearing 10,000 rows | 1.6 | 4.6 | 1.7 | 1.5 |
