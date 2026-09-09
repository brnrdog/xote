/* The app-thread entry point, shared by every native host.
 *
 * An embedded JavaScript engine — JavaScriptCore on iOS, QuickJS or Hermes on
 * Android — has no DOM, no module loader and no host objects beyond what the
 * platform injects. So this is bundled to a single classic script and talks to
 * the platform through three globals, and only three:
 *
 *   XoteHost.apply(json)        injected by the host — a batch of commands
 *   xoteStart()                 called by the host once the root view exists
 *   xoteDispatchEvent(...)      called by the host when a view reports an event
 *
 * Nothing here is platform-specific, and that is the point: the same bundle
 * byte-for-byte runs on both. A host is a thing that provides those three
 * globals and can apply eight commands.
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
  {
    apply: (batch) => globalThis.XoteHost.apply(JSON.stringify(batch)),
    // The host declares which protocol versions it can apply; `install`
    // compares it against what this bundle emits. A host older than the bundle
    // is a warning, one that has dropped this protocol is a refusal.
    protocol: globalThis.XoteHost.protocol,
  },
  { autoFlush: false },
);

globalThis.xoteStart = () => {
  NativeApp.mount(app.make(), "root");
  runtime.flush();
};

// `install` flushes for us after each event when autoFlush is off.
globalThis.xoteDispatchEvent = (id, name, payloadJson) =>
  runtime.dispatchEvent(id, name, payloadJson ? JSON.parse(payloadJson) : {});
