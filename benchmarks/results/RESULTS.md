# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.80GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.3.0, Vue 3.5.43, Solid 1.9.15.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 53.5 (1.09x) | 58.2 (1.18x) | 55.1 (1.12x) | **49.3** (1.00x) |
| Replace 1,000 rows | 76.1 (1.24x) | 66.6 (1.08x) | **61.5** (1.00x) | 75.1 (1.22x) |
| Update every 10th row | 6.5 (1.12x) | 11.2 (1.93x) | 9.1 (1.57x) | **5.8** (1.00x) |
| Select a row | **0.6** (1.00x) | 5.2 (8.67x) | 2.1 (3.50x) | 0.9 (1.50x) |
| Swap two rows | 5.6 (1.08x) | 64.1 (12.33x) | 8.1 (1.56x) | **5.2** (1.00x) |
| Remove a row | 5.0 (1.04x) | 10.2 (2.13x) | 7.2 (1.50x) | **4.8** (1.00x) |
| Create 10,000 rows | 734.7 (1.11x) | 1023.1 (1.54x) | 797.6 (1.20x) | **664.3** (1.00x) |
| Append 1,000 to 10,000 rows | 147.1 (1.09x) | 218.7 (1.62x) | 145.5 (1.08x) | **135.1** (1.00x) |
| Clear 10,000 rows | 76.1 (1.15x) | 108.0 (1.63x) | 90.4 (1.37x) | **66.1** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 62.6 (1.07x) | 67.8 (1.16x) | 64.0 (1.10x) | **58.4** (1.00x) |
| Replace 1,000 rows | 77.2 (1.10x) | 76.7 (1.09x) | **70.3** (1.00x) | 77.4 (1.10x) |
| Update every 10th row | **14.1** (1.00x) | 17.3 (1.23x) | 17.7 (1.26x) | 15.0 (1.06x) |
| Select a row | 12.4 (1.09x) | 16.3 (1.43x) | **11.4** (1.00x) | 15.3 (1.34x) |
| Swap two rows | 16.6 (1.19x) | 75.4 (5.42x) | 18.0 (1.29x) | **13.9** (1.00x) |
| Remove a row | **20.1** (1.00x) | 21.0 (1.04x) | 20.9 (1.04x) | 22.8 (1.13x) |
| Create 10,000 rows | 738.2 (1.09x) | 1026.1 (1.51x) | 800.6 (1.18x) | **679.7** (1.00x) |
| Append 1,000 to 10,000 rows | 176.4 (1.02x) | 307.8 (1.79x) | 209.9 (1.22x) | **172.3** (1.00x) |
| Clear 10,000 rows | 77.4 (1.11x) | 108.5 (1.56x) | 91.1 (1.31x) | **69.6** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | **19.2** (1.00x) | 40.0 (2.09x) | 25.4 (1.33x) | 19.5 (1.02x) |
| JS bundle, minified (KB) | 33.4 | 216.3 | 61.7 | 13.5 |
| JS bundle, gzipped (KB) | 10.4 | 66.9 | 24.1 | 5.5 |
| JS bundle, brotli (KB) | 9.5 | 57.6 | 22.0 | 5.0 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.8 | 1.5 | 1.2 |
| 1,000 rows | 2.7 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 13.1 | 20.3 | 19.0 | 12.3 |
| After clearing 10,000 rows | 1.7 | 4.6 | 1.7 | 1.5 |
