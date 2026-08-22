import "../../shared/bench.css";
import { createApp } from "vue";
import App from "./App.vue";

createApp(App).mount("#root");
/* Startup marker read by the benchmark driver. */
window.__BENCH_READY_AT__ = performance.now();
window.__BENCH_READY__ = true;
