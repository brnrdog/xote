// Shared browser environment for the test suites.
//
// zekr 2.x owns a jsdom instance internally (created lazily by
// `DomBindings.ensureDocument`) and exposes its window on
// `globalThis.__zekr_window`. Xote's runtime, on the other hand, reads the
// plain `document`/`window` globals. To keep both halves operating on a single
// document, we force zekr to build its jsdom up front and mirror that window
// onto the globals Xote depends on.
//
// Importing the compiled `.res.mjs` (rather than the shipped `.js`) is
// deliberate: the test files are compiled with the `.res.mjs` suffix, so this
// path resolves to the exact module instance whose document zekr's DOM
// utilities return.
import * as DomBindings from "zekr/src/DomBindings.res.mjs";

DomBindings.ensureDocument();

// zekr builds its jsdom without a URL, so it defaults to `about:blank` — an
// opaque origin the History API refuses to rewrite, which breaks the router
// tests. Point it at a real origin so `history.pushState`/`replaceState` work.
DomBindings.currentJsdom.contents.reconfigure({ url: "https://xote.test/" });

const win = globalThis.__zekr_window;
globalThis.window = win;
globalThis.document = win.document;
globalThis.HTMLElement = win.HTMLElement;
globalThis.Node = win.Node;
globalThis.Event = win.Event;
globalThis.MouseEvent = win.MouseEvent;
globalThis.KeyboardEvent = win.KeyboardEvent;
globalThis.InputEvent = win.InputEvent;
win.scrollTo = () => {};
