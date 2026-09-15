/* The app thread.
 *
 * A worker has no DOM, which is exactly the situation on a device: the shadow
 * document installs cleanly, and the only thing that leaves this thread is a
 * batch of commands. Events arrive the same way, in reverse.
 */

import { install } from "../src/host/runtime.mjs";
import * as NativeApp from "../src/NativeApp.res.mjs";
import * as CounterApp from "./CounterApp.res.mjs";

// Import order does not matter — no module reaches for `document` while it is
// being evaluated, only while it is rendering.
const runtime = install({ apply: (batch) => self.postMessage({ batch }) });

self.onmessage = ({ data }) => {
  if (data.type === "event") runtime.dispatchEvent(data.id, data.name, data.payload);
};

NativeApp.mount(CounterApp.make(), "root");
