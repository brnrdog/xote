# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.10GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.2.8, Vue 3.5.41, Solid 1.9.14.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 76.3 (1.75x) | 54.0 (1.24x) | 48.4 (1.11x) | **43.7** (1.00x) |
| Replace 1,000 rows | 87.4 (1.75x) | 62.6 (1.25x) | 55.4 (1.11x) | **50.0** (1.00x) |
| Update every 10th row | **4.2** (1.00x) | 9.4 (2.24x) | 5.6 (1.33x) | 4.4 (1.05x) |
| Select a row | 0.7 (1.40x) | 4.5 (9.00x) | 1.5 (3.00x) | **0.5** (1.00x) |
| Swap two rows | 43.1 (10.77x) | 51.4 (12.85x) | 4.9 (1.23x) | **4.0** (1.00x) |
| Remove a row | 4.0 (1.11x) | 7.7 (2.14x) | 4.8 (1.33x) | **3.6** (1.00x) |
| Create 10,000 rows | 844.1 (1.62x) | 943.4 (1.81x) | 670.6 (1.29x) | **520.2** (1.00x) |
| Append 1,000 to 10,000 rows | 174.9 (1.57x) | 210.0 (1.88x) | **111.5** (1.00x) | 133.1 (1.19x) |
| Clear 10,000 rows | 176.1 (2.90x) | 106.4 (1.75x) | 74.7 (1.23x) | **60.8** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 76.6 (1.46x) | 62.5 (1.19x) | 57.5 (1.10x) | **52.5** (1.00x) |
| Replace 1,000 rows | 88.4 (1.52x) | 71.7 (1.23x) | 63.8 (1.09x) | **58.3** (1.00x) |
| Update every 10th row | 17.3 (1.68x) | 11.7 (1.14x) | **10.3** (1.00x) | 15.4 (1.50x) |
| Select a row | 17.2 (1.70x) | **10.1** (1.00x) | 10.8 (1.07x) | 12.5 (1.24x) |
| Swap two rows | 51.2 (5.12x) | 59.6 (5.96x) | **10.0** (1.00x) | 13.9 (1.39x) |
| Remove a row | 21.4 (1.35x) | 15.8 (1.00x) | **15.8** (1.00x) | 19.8 (1.25x) |
| Create 10,000 rows | 848.8 (1.43x) | 946.4 (1.60x) | 673.8 (1.14x) | **592.8** (1.00x) |
| Append 1,000 to 10,000 rows | 184.9 (1.13x) | 268.0 (1.64x) | **163.7** (1.00x) | 196.5 (1.20x) |
| Clear 10,000 rows | 178.7 (2.71x) | 109.2 (1.65x) | 75.2 (1.14x) | **66.0** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | 18.8 (1.10x) | 35.0 (2.05x) | 24.4 (1.43x) | **17.1** (1.00x) |
| JS bundle, minified (KB) | 25.3 | 190.4 | 62.4 | 11.0 |
| JS bundle, gzipped (KB) | 7.9 | 59.9 | 24.9 | 4.7 |
| JS bundle, brotli (KB) | 7.2 | 51.6 | 22.6 | 4.2 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.7 | 1.5 | 1.2 |
| 1,000 rows | 5.8 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 44.0 | 20.2 | 19.0 | 12.3 |
| After clearing 10,000 rows | 1.6 | 4.6 | 1.7 | 1.5 |
