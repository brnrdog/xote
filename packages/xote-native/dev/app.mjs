/**
 * The app process.
 *
 * One Xote app, running in Node, with its batches going to the parent instead
 * of to a device. It is `example/app.worker.mjs` with `process.send` where the
 * worker had `postMessage` — the same shape for the same reason: a realm with
 * no DOM, so the shadow document installs cleanly and the only thing that
 * leaves is a command batch.
 *
 * It is a **child process** rather than a module the server re-imports, and
 * that is the whole reload strategy. Re-importing with a cache-busting query
 * reloads one module and none of its dependencies, so a change two files deep
 * would be invisible; killing this process and starting another gives a clean
 * realm, fresh module graph and fresh ids every time, with nothing to get
 * subtly wrong. Starting a Node process costs about 60ms, which is less than
 * the ReScript compile that preceded it.
 */

import { install } from "../src/host/runtime.mjs";
import * as NativeApp from "../src/NativeApp.res.mjs";

const APPS = {
  counter: () => import("../example/CounterApp.res.mjs"),
  tracker: () => import("../example/tracker/TrackerApp.res.mjs"),
  nav: () => import("../example/NavApp.res.mjs"),
};

const name = process.env.XOTE_APP ?? "tracker";
const load = APPS[name];
if (load === undefined) {
  console.error(`Xote: no app called "${name}" — try ${Object.keys(APPS).join(", ")}`);
  process.exit(1);
}

/** Everything that leaves this process, in the order it happened. */
const send = (message) => process.send?.(message);

const runtime = install(
  {
    apply: (batch) => send({ type: "batch", commands: batch }),
  },
  { autoFlush: true },
);

process.on("message", (message) => {
  if (message?.type === "event") {
    // A view reported something. The app cannot tell that the view is on a
    // phone and the handler is here — which is the point.
    runtime.dispatchEvent(message.id, message.name, message.payload ?? {});
  }
});

/* A handler that throws must not take the dev server down with it: the screen
 is already rendered, the mistake is in one callback, and killing the process
 would lose the whole session over it. */
process.on("uncaughtException", (error) => {
  send({ type: "error", message: String(error?.stack ?? error) });
});

const app = await load();
NativeApp.mount(app.make(), "root");
send({ type: "ready", app: name });
