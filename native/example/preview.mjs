/* The UI thread.
 *
 * It never imports the app, ReScript, or Xote — only the host and the protocol.
 * Everything it knows about the screen arrives as commands.
 */

import { createPreviewHost } from "../host/preview.mjs";
import { formatBatch } from "../host/protocol.mjs";

const screen = document.getElementById("screen");
const traffic = document.getElementById("traffic");
const counter = document.getElementById("counter");

const worker = new Worker(new URL("./app.worker.mjs", import.meta.url), { type: "module" });

let total = 0;
const host = createPreviewHost(screen, {
  dispatch: (id, name, payload) => worker.postMessage({ type: "event", id, name, payload }),
  onBatch: (batch) => {
    total += batch.length;
    counter.textContent = `${total} commands`;
    const block = document.createElement("div");
    block.className = "batch";
    block.textContent = formatBatch(batch).join("\n");
    traffic.prepend(block);
    while (traffic.childNodes.length > 40) traffic.lastChild.remove();
  },
});

worker.onmessage = ({ data }) => host.apply(data.batch);
