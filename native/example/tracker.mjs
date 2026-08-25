/* The UI thread for the tracker preview. It never imports the app, ReScript or
 Xote — only the host and the protocol. */

import { createPreviewHost } from "../host/preview.mjs";
import { formatBatch } from "../host/protocol.mjs";

const screen = document.getElementById("screen");
const traffic = document.getElementById("traffic");
const counter = document.getElementById("counter");

const worker = new Worker(new URL("./tracker.worker.mjs", import.meta.url), { type: "module" });

let total = 0;
const host = createPreviewHost(screen, {
  dispatch: (id, name, payload) => worker.postMessage({ type: "event", id, name, payload }),
  onBatch: (batch) => {
    total += batch.length;
    counter.textContent = `${total} commands`;
    const block = document.createElement("div");
    block.className = "batch";
    block.textContent = `${batch.length} — ` + formatBatch(batch).slice(0, 8).join("\n");
    traffic.prepend(block);
    while (traffic.childNodes.length > 30) traffic.lastChild.remove();
  },
});

worker.onmessage = ({ data }) => host.apply(data.batch);
