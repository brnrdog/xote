# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.80GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.2.8, Vue 3.5.41, Solid 1.9.14.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 85.0 (1.71x) | 58.4 (1.17x) | 57.9 (1.16x) | **49.8** (1.00x) |
| Replace 1,000 rows | 122.7 (1.90x) | 73.9 (1.14x) | **64.7** (1.00x) | 68.3 (1.06x) |
| Update every 10th row | **6.7** (1.00x) | 14.8 (2.21x) | 8.7 (1.30x) | 7.2 (1.07x) |
| Select a row | 1.1 (1.22x) | 5.4 (6.00x) | 2.1 (2.33x) | **0.9** (1.00x) |
| Swap two rows | 70.1 (12.09x) | 65.8 (11.34x) | 8.2 (1.41x) | **5.8** (1.00x) |
| Remove a row | 5.9 (1.09x) | 11.0 (2.04x) | 7.3 (1.35x) | **5.4** (1.00x) |
| Create 10,000 rows | 924.1 (1.43x) | 961.2 (1.49x) | 706.4 (1.09x) | **645.7** (1.00x) |
| Append 1,000 to 10,000 rows | 187.7 (1.32x) | 290.7 (2.05x) | **141.9** (1.00x) | 142.0 (1.00x) |
| Clear 10,000 rows | 188.8 (2.81x) | 112.7 (1.67x) | 77.7 (1.15x) | **67.3** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 90.6 (1.48x) | 71.0 (1.16x) | 70.1 (1.14x) | **61.4** (1.00x) |
| Replace 1,000 rows | 123.6 (1.67x) | 87.2 (1.18x) | 76.7 (1.03x) | **74.2** (1.00x) |
| Update every 10th row | 18.3 (1.48x) | 19.1 (1.54x) | **12.4** (1.00x) | 13.6 (1.10x) |
| Select a row | 17.5 (1.41x) | **12.4** (1.00x) | 16.5 (1.33x) | 15.3 (1.23x) |
| Swap two rows | 74.4 (4.25x) | 80.6 (4.61x) | **17.5** (1.00x) | 19.0 (1.09x) |
| Remove a row | 25.2 (1.22x) | 22.8 (1.11x) | 20.9 (1.01x) | **20.6** (1.00x) |
| Create 10,000 rows | 927.4 (1.43x) | 964.3 (1.48x) | 709.8 (1.09x) | **649.5** (1.00x) |
| Append 1,000 to 10,000 rows | 216.6 (1.08x) | 316.2 (1.57x) | 210.0 (1.04x) | **201.2** (1.00x) |
| Clear 10,000 rows | 194.8 (2.68x) | 113.1 (1.56x) | 78.4 (1.08x) | **72.6** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | **23.9** (1.00x) | 43.5 (1.82x) | 30.7 (1.28x) | 24.8 (1.04x) |
| JS bundle, minified (KB) | 24.9 | 190.4 | 62.4 | 11.0 |
| JS bundle, gzipped (KB) | 7.8 | 59.9 | 24.9 | 4.7 |
| JS bundle, brotli (KB) | 7.0 | 51.6 | 22.6 | 4.2 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.7 | 1.5 | 1.2 |
| 1,000 rows | 5.8 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 43.7 | 20.2 | 19.0 | 12.2 |
| After clearing 10,000 rows | 1.6 | 4.6 | 1.7 | 1.5 |
