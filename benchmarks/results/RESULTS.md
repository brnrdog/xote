# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.80GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.2.8, Vue 3.5.41, Solid 1.9.14.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 85.5 (1.52x) | 63.8 (1.14x) | **56.1** (1.00x) | 60.2 (1.07x) |
| Replace 1,000 rows | 120.6 (1.59x) | 77.5 (1.02x) | **76.0** (1.00x) | 81.8 (1.08x) |
| Update every 10th row | **7.8** (1.00x) | 13.4 (1.72x) | 11.5 (1.47x) | 9.6 (1.23x) |
| Select a row | 1.1 (1.22x) | 6.6 (7.33x) | 2.7 (3.00x) | **0.9** (1.00x) |
| Swap two rows | 57.0 (7.13x) | 63.7 (7.96x) | 10.7 (1.34x) | **8.0** (1.00x) |
| Remove a row | 9.2 (1.53x) | 12.8 (2.13x) | 10.0 (1.67x) | **6.0** (1.00x) |
| Create 10,000 rows | 960.6 (1.53x) | 1017.4 (1.62x) | 742.4 (1.18x) | **629.0** (1.00x) |
| Append 1,000 to 10,000 rows | 202.8 (1.55x) | 191.7 (1.46x) | 138.7 (1.06x) | **130.9** (1.00x) |
| Clear 10,000 rows | 187.4 (2.72x) | 120.8 (1.75x) | 77.4 (1.12x) | **69.0** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 90.4 (1.31x) | 75.2 (1.09x) | **68.9** (1.00x) | 75.3 (1.09x) |
| Replace 1,000 rows | 121.3 (1.40x) | 92.2 (1.06x) | 92.6 (1.07x) | **86.6** (1.00x) |
| Update every 10th row | 20.5 (1.13x) | 21.7 (1.19x) | 21.0 (1.15x) | **18.2** (1.00x) |
| Select a row | 17.7 (1.55x) | 13.4 (1.18x) | 14.5 (1.27x) | **11.4** (1.00x) |
| Swap two rows | 70.8 (3.96x) | 76.7 (4.28x) | 20.5 (1.15x) | **17.9** (1.00x) |
| Remove a row | 26.2 (1.14x) | 26.1 (1.14x) | 27.3 (1.19x) | **22.9** (1.00x) |
| Create 10,000 rows | 966.4 (1.53x) | 1021.8 (1.62x) | 746.8 (1.18x) | **632.6** (1.00x) |
| Append 1,000 to 10,000 rows | 243.1 (1.41x) | 256.5 (1.49x) | 201.2 (1.17x) | **172.4** (1.00x) |
| Clear 10,000 rows | 199.0 (2.67x) | 126.2 (1.70x) | 78.0 (1.05x) | **74.4** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | **23.2** (1.00x) | 48.0 (2.07x) | 31.1 (1.34x) | 25.8 (1.11x) |
| JS bundle, minified (KB) | 24.9 | 190.4 | 62.4 | 11.0 |
| JS bundle, gzipped (KB) | 7.8 | 59.9 | 24.9 | 4.7 |
| JS bundle, brotli (KB) | 7.0 | 51.6 | 22.6 | 4.2 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.7 | 1.5 | 1.2 |
| 1,000 rows | 5.8 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 43.6 | 20.2 | 19.0 | 12.3 |
| After clearing 10,000 rows | 1.6 | 4.6 | 1.7 | 1.5 |
