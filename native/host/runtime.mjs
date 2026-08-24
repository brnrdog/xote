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

let installed = null;

/**
 * @param {{ apply: (batch: Array) => void }} host
 * @param {{ autoFlush?: boolean }} [options]
 */
export function install(host, options = {}) {
  const { autoFlush = true } = options;
  const doc = new ShadowDocument();
  let scheduled = false;

  doc.onFlush = (batch) => host.apply(batch);

  if (autoFlush) {
    const schedule = () => {
      if (scheduled) return;
      scheduled = true;
      queueMicrotask(() => {
        scheduled = false;
        doc.flush();
      });
    };
    const emit = doc.emit.bind(doc);
    doc.emit = (command) => {
      emit(command);
      schedule();
    };
  }

  // The renderer reaches for `document` by name, so the shadow document has to
  // *be* it. On a device that is free — a JavaScript engine embedded in an app
  // has no `document` to begin with. A browser tab is the one place it is not:
  // `Window.document` is unforgeable there, which is why the preview runs the
  // app in a worker. That is not a workaround so much as the real architecture
  // in miniature: app code on one thread, views on another, a batch of commands
  // in between.
  try {
    globalThis.document = doc;
  } catch {
    throw new Error(
      "Xote Native: cannot install the shadow document — `document` is read-only here. " +
        "Run the app in a worker (or any realm without a DOM) and forward batches to the host.",
    );
  }
  if (globalThis.document !== doc) {
    throw new Error("Xote Native: `document` did not take the shadow document");
  }
  installed = {
    document: doc,
    flush: () => doc.flush(),
    /** Hosts call this when a native view reports an event. */
    dispatchEvent: (id, name, payload) => {
      doc.dispatchEvent(id, name, payload);
      if (!autoFlush) doc.flush();
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
