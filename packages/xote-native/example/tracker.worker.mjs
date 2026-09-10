/* The app thread for the tracker preview. Same shape as `app.worker.mjs`: a
 worker has no DOM, so the shadow document installs cleanly and the only thing
 that leaves this thread is a batch of commands. */

import { install } from "../src/host/runtime.mjs";
import * as NativeApp from "../src/NativeApp.res.mjs";
import * as TrackerApp from "./tracker/TrackerApp.res.mjs";

const runtime = install({ apply: (batch) => self.postMessage({ batch }) });

self.onmessage = ({ data }) => {
  if (data.type === "event") runtime.dispatchEvent(data.id, data.name, data.payload);
};

NativeApp.mount(TrackerApp.make(), "root");
