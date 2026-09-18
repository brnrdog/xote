# Xote vs React / Vue / Solid

Chromium 141.0.7390.37, 4x Intel(R) Xeon(R) Processor @ 2.10GHz, Node v22.22.2.
15 measured iterations per benchmark (3 warmup), median reported. Lower is better; the multiplier is relative to the fastest framework in the row.

Framework versions: Xote 0.0.0 (this checkout), React 19.2.8, Vue 3.5.41, Solid 1.9.14.

## Operations — commit time (ms)

Time from the click to the framework having finished its DOM work, with style and layout forced. This isolates framework cost from the browser's paint scheduling.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 39.5 (1.03x) | 41.9 (1.09x) | 40.6 (1.06x) | **38.3** (1.00x) |
| Replace 1,000 rows | 44.4 (1.03x) | 48.2 (1.12x) | **43.2** (1.00x) | 43.2 (1.00x) |
| Update every 10th row | 5.1 (1.19x) | 8.4 (1.95x) | 5.9 (1.37x) | **4.3** (1.00x) |
| Select a row | **0.6** (1.00x) | 4.5 (7.50x) | 1.7 (2.83x) | 0.7 (1.17x) |
| Swap two rows | 4.5 (1.05x) | 47.2 (10.98x) | 5.7 (1.33x) | **4.3** (1.00x) |
| Remove a row | **3.7** (1.00x) | 7.7 (2.08x) | 4.9 (1.32x) | 3.9 (1.05x) |
| Create 10,000 rows | 533.8 (1.28x) | 807.1 (1.93x) | **417.8** (1.00x) | 445.4 (1.07x) |
| Append 1,000 to 10,000 rows | **87.0** (1.00x) | 170.4 (1.96x) | 94.5 (1.09x) | 90.6 (1.04x) |
| Clear 10,000 rows | 64.4 (1.19x) | 86.1 (1.59x) | 69.1 (1.27x) | **54.2** (1.00x) |

## Operations — time to paint (ms)

The same clicks measured through to the frame that paints the result.

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Create 1,000 rows | 48.8 (1.05x) | 50.7 (1.09x) | 48.1 (1.04x) | **46.4** (1.00x) |
| Replace 1,000 rows | 50.5 (1.00x) | 56.3 (1.12x) | 51.9 (1.03x) | **50.4** (1.00x) |
| Update every 10th row | 15.8 (1.11x) | 16.7 (1.18x) | **14.2** (1.00x) | 14.8 (1.04x) |
| Select a row | 13.1 (1.75x) | 12.6 (1.68x) | **7.5** (1.00x) | 8.1 (1.08x) |
| Swap two rows | 16.5 (1.40x) | 56.2 (4.76x) | **11.8** (1.00x) | 17.4 (1.47x) |
| Remove a row | 16.3 (1.04x) | 19.0 (1.21x) | 18.1 (1.15x) | **15.7** (1.00x) |
| Create 10,000 rows | 546.1 (1.22x) | 811.6 (1.81x) | 512.0 (1.14x) | **449.4** (1.00x) |
| Append 1,000 to 10,000 rows | **126.7** (1.00x) | 231.0 (1.82x) | 134.8 (1.06x) | 128.7 (1.02x) |
| Clear 10,000 rows | 67.5 (1.13x) | 86.7 (1.45x) | 69.7 (1.17x) | **59.6** (1.00x) |

## Startup and payload

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| Time to first render (ms) | 18.6 (1.05x) | 34.8 (1.95x) | 23.0 (1.29x) | **17.8** (1.00x) |
| JS bundle, minified (KB) | 34.1 | 190.4 | 62.4 | 11.0 |
| JS bundle, gzipped (KB) | 10.8 | 59.9 | 24.9 | 4.7 |
| JS bundle, brotli (KB) | 9.8 | 51.6 | 22.6 | 4.2 |

## Memory (MB of used JS heap, after forced GC)

| Benchmark | Xote | React | Vue | Solid |
| --- | --- | --- | --- | --- |
| After load, empty list | 1.3 | 1.7 | 1.5 | 1.2 |
| 1,000 rows | 3.2 | 3.9 | 3.4 | 2.5 |
| 10,000 rows | 17.5 | 20.2 | 19.0 | 12.3 |
| After clearing 10,000 rows | 1.7 | 4.6 | 1.7 | 1.5 |
