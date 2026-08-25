/* The app-thread entry point for the iOS host.
 *
 * JavaScriptCore embedded in an app has no DOM, no module loader and no host
 * objects beyond what Swift injects, so this is bundled to a single classic
 * script and talks to Swift through three globals:
 *
 *   XoteHost.apply(json)        injected by Swift — a batch of commands
 *   xoteStart()                 called by Swift once the root view exists
 *   xoteDispatchEvent(...)      called by Swift when a view reports an event
 *
 * Flushing is explicit rather than microtask-driven. An embedded JSContext
 * drains its microtask queue when the current call into JavaScript returns,
 * which would work, but "the batch is on the other side before this function
 * returns" is a much easier property to reason about from Swift.
 *
 * Which app gets mounted is chosen at build time by `XOTE_APP`:
 *
 *   npm run native:ios:build                 # the tracker (default)
 *   XOTE_APP=counter npm run native:ios:build
 *
 * A real framework would take an entry point from the app rather than keeping
 * a list here; this is a repository of examples, so it keeps a list.
 */

import { install } from "../host/runtime.mjs";
import * as NativeApp from "../NativeApp.res.mjs";
import * as CounterApp from "../example/CounterApp.res.mjs";
import * as TrackerApp from "../example/tracker/TrackerApp.res.mjs";

// `__XOTE_APP__` is replaced by the bundler, so only the chosen app is bundled.
const apps = { counter: CounterApp, tracker: TrackerApp };
const app = apps[__XOTE_APP__] ?? TrackerApp;

const runtime = install(
  { apply: (batch) => globalThis.XoteHost.apply(JSON.stringify(batch)) },
  { autoFlush: false },
);

globalThis.xoteStart = () => {
  NativeApp.mount(app.make(), "root");
  runtime.flush();
};

// `install` flushes for us after each event when autoFlush is off.
globalThis.xoteDispatchEvent = (id, name, payloadJson) =>
  runtime.dispatchEvent(id, name, payloadJson ? JSON.parse(payloadJson) : {});
