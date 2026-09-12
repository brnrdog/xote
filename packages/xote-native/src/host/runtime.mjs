/**
 * Runtime glue: installs the shadow document as the ambient `document` that
 * Xote's renderer binds to, connects a host, and decides when batches flush.
 *
 * Flushing is where the difference from React Native shows up. There is no
 * reconciler pass to wait for: a `Signal.set` runs its dependents synchronously
 * and each one performs exactly the mutations its own value implies. All the
 * flush does is coalesce a synchronous burst — a `batch`, an event handler that
 * touches four signals — into one crossing.
 */

import { ShadowDocument } from "./shadow.mjs";
import { PROTOCOL_VERSION, checkProtocol } from "./protocol.mjs";

let installed = null;

/**
 * @param {{ apply: (batch: Array) => void, protocol?: {min: number, max: number} }} host
 *   `protocol` is the range of bundle protocol versions this host can apply. A
 *   host that declares nothing is assumed to speak version 1.
 * @param {{ autoFlush?: boolean, onError?: (what: string, error: unknown) => void }} [options]
 */
export function install(host, options = {}) {
  const { autoFlush = true, onError } = options;

  // The handshake, before anything is rendered into a host that cannot apply
  // it. A host older than the bundle is a warning: it skips what it does not
  // know and reports each one, so the screen may be missing something and the
  // app is still running. A host that has dropped this protocol entirely is an
  // error, because every alternative to throwing is a silently wrong screen.
  const agreement = checkProtocol(host?.protocol);
  if (!agreement.ok) {
    throw new Error(`Xote Native: incompatible host — ${agreement.reason}`);
  }
  if (agreement.degraded) {
    const message = `Xote Native: ${agreement.reason}`;
    if (onError !== undefined) onError("protocol", new Error(agreement.reason));
    else if (typeof console !== "undefined") console.warn(message);
  }

  const doc = new ShadowDocument();
  let scheduled = false;

  doc.onFlush = (batch) => host.apply(batch);
  if (onError !== undefined) doc.onError = onError;

  if (autoFlush) {
    const schedule = () => {
      if (scheduled) return;
      scheduled = true;
      queueMicrotask(() => {
        scheduled = false;
        // `flush` contains its own failures, so the scheduler cannot be left
        // permanently disarmed by one bad batch.
        doc.flush();
      });
    };
    const emit = doc.emit.bind(doc);
    doc.emit = (command) => {
      emit(command);
      schedule();
    };
  }

  /* The renderer reaches for `document` by name, so the shadow document has to
   *be* it. On a device that is free — a JavaScript engine embedded in an app
   has no `document` to begin with, and assigning the global is all it takes.

   A realm that already has a DOM is the one place it is not: `Window.document`
   is unforgeable, so the assignment cannot land. There are two ways out of
   that, and both are in this repository. The preview takes the first: run the
   app in a worker, which has no DOM at all — not a workaround so much as the
   real architecture in miniature, app code on one thread, views on another, a
   batch of commands in between. A host that cannot spawn one takes the second:
   evaluate the bundle inside a scope that *shadows* `document`, and leave
   behind `xoteBindDocument` to write to that binding. `WebViewRuntime` on
   Android is the case that needs it — see `XoteBridge.start`.

   The binder returns what it bound, because a shadowed binding is by
   definition not readable from here, and a seam that cannot be checked is a
   seam that quietly does nothing. */
  const bind = globalThis.xoteBindDocument;
  if (typeof bind === "function") {
    if (bind(doc) !== doc) {
      throw new Error("Xote Native: `xoteBindDocument` did not take the shadow document");
    }
  } else {
    try {
      globalThis.document = doc;
    } catch {
      throw new Error(
        "Xote Native: cannot install the shadow document — `document` is read-only here. " +
          "Run the app in a worker (or any realm without a DOM) and forward batches to the host, " +
          "or evaluate the bundle in a scope that shadows `document` and expose `xoteBindDocument`.",
      );
    }
    if (globalThis.document !== doc) {
      throw new Error("Xote Native: `document` did not take the shadow document");
    }
  }
  installed = {
    document: doc,
    /** What this bundle emits, and what the host said it can apply. */
    protocol: { bundle: PROTOCOL_VERSION, host: host?.protocol ?? null, agreement },
    flush: () => doc.flush(),
    /** Hosts call this when a native view reports an event. */
    dispatchEvent: (id, name, payload) => {
      doc.dispatchEvent(id, name, payload);
      // A handler that threw still leaves whatever it managed to change, and
      // the host should be told about it rather than left showing stale views.
      if (!autoFlush) doc.flush();
    },
    /** Report something that went wrong, without unwinding the caller. */
    onError: (handler) => {
      doc.onError = handler;
    },
  };
  return installed;
}

export function current() {
  if (installed === null) {
    throw new Error("Xote Native: no host installed — call install(host) before mounting");
  }
  return installed;
}

/** Create (or look up) a mount point by name. */
export function createRoot(name = "root") {
  const doc = current().document;
  return doc.getElementById(name) ?? doc.createRoot(name);
}

export function flush() {
  return current().flush();
}

export function dispatchEvent(id, name, payload) {
  return current().dispatchEvent(id, name, payload);
}
