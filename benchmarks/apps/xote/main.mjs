import "../../shared/bench.css";
import "./BenchApp.res.mjs";

/* Startup marker read by the benchmark driver. */
window.__BENCH_READY_AT__ = performance.now();
window.__BENCH_READY__ = true;
