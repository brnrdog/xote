# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.80GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.3.0, Vue 3.5.43, Solid 1.9.15.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 58.5 (1.17x) | 59.2 (1.19x) | 55.3 (1.11x) | **49.9** (1.00x) |
| Replace 1,000 rows | 68.3 (1.15x) | 65.6 (1.10x) | **59.5** (1.00x) | 59.7 (1.00x) |
| Update every 10th row | 5.5 (1.12x) | 9.6 (1.96x) | 6.7 (1.37x) | **4.9** (1.00x) |
| Select a row | **0.5** (1.00x) | 4.9 (9.80x) | 1.8 (3.60x) | 0.7 (1.40x) |
| Swap two rows | 4.9 (1.09x) | 58.2 (12.93x) | 5.6 (1.24x) | **4.5** (1.00x) |
| Remove a row | 4.4 (1.13x) | 8.5 (2.18x) | 5.7 (1.46x) | **3.9** (1.00x) |
| Create 10,000 rows | 796.8 (1.34x) | 938.9 (1.58x) | 701.5 (1.18x) | **594.0** (1.00x) |
| Append 1,000 to 10,000 rows | 103.7 (1.01x) | 200.9 (1.95x) | 124.7 (1.21x) | **102.9** (1.00x) |
| Clear 10,000 rows | 79.9 (1.11x) | 108.1 (1.51x) | 82.1 (1.14x) | **71.8** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 68.4 (1.15x) | 68.8 (1.15x) | 64.8 (1.09x) | **59.7** (1.00x) |
| Replace 1,000 rows | 70.0 (1.03x) | 74.6 (1.10x) | 67.9 (1.00x) | **67.8** (1.00x) |
| Update every 10th row | 17.1 (1.80x) | 16.0 (1.68x) | 15.2 (1.60x) | **9.5** (1.00x) |
| Select a row | 17.0 (1.30x) | 14.6 (1.11x) | 14.6 (1.11x) | **13.1** (1.00x) |
| Swap two rows | 16.5 (1.50x) | 69.6 (6.33x) | 16.2 (1.47x) | **11.0** (1.00x) |
| Remove a row | 21.7 (1.44x) | 21.8 (1.44x) | 21.2 (1.40x) | **15.1** (1.00x) |
| Create 10,000 rows | 800.0 (1.14x) | 941.8 (1.34x) | 709.9 (1.01x) | **701.5** (1.00x) |
| Append 1,000 to 10,000 rows | 148.2 (1.00x) | 258.8 (1.75x) | 174.8 (1.18x) | **147.8** (1.00x) |
| Clear 10,000 rows | 83.3 (1.11x) | 111.6 (1.49x) | 82.8 (1.11x) | **74.9** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | 20.5 (1.07x) | 43.4 (2.27x) | 24.9 (1.30x) | **19.1** (1.00x) |
| JS bundle, minified (KB) | 33.7 | 216.3 | 61.7 | 13.5 |
| JS bundle, gzipped (KB) | 10.4 | 66.9 | 24.1 | 5.5 |
| JS bundle, brotli (KB) | 9.5 | 57.6 | 22.0 | 5.0 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.8 | 1.5 | 1.2 |
| 1,000 rows | 3.2 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 17.6 | 20.3 | 19.0 | 12.3 |
| After clearing 10,000 rows | 1.7 | 4.6 | 1.7 | 1.5 |
