// A session: one headless page running one Xote component under devtools.
//
// The page is a jsdom document. Devtools are installed *before* the
// component's module is imported, because signals created at module level
// would otherwise be invisible. A session renders once: module state cannot be
// reset in place, so a new render needs a new session (the MCP server forks a
// fresh process per render for exactly this reason).

import { JSDOM } from "jsdom";
import { relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { findCompiled, importXote, parseTarget, toPosix } from "./project.mjs";
import { compareMarkup } from "./markup.mjs";
import { renderOnServer, resolveExport, toNode as nodeOf } from "./server.mjs";

const GLOBALS = [
  "window",
  "document",
  "navigator",
  "location",
  "history",
  "Node",
  "Element",
  "HTMLElement",
  "HTMLInputElement",
  "HTMLTextAreaElement",
  "HTMLSelectElement",
  "SVGElement",
  "Text",
  "Comment",
  "DocumentFragment",
  "Event",
  "CustomEvent",
  "MouseEvent",
  "KeyboardEvent",
  "InputEvent",
  "FocusEvent",
  "SubmitEvent",
  "PopStateEvent",
  "MutationObserver",
  "getComputedStyle",
];

function installGlobals(dom) {
  const { window } = dom;
  for (const name of GLOBALS) {
    if (window[name] === undefined) continue;
    try {
      globalThis[name] = name === "window" ? window : window[name];
    } catch {
      /* some globals (navigator) are getters on newer Node; define over them */
      Object.defineProperty(globalThis, name, { value: window[name], configurable: true, writable: true });
    }
  }
  window.scrollTo = () => {};
  globalThis.requestAnimationFrame = (fn) => setTimeout(() => fn(Date.now()), 0);
  globalThis.cancelAnimationFrame = (id) => clearTimeout(id);
}

/* What console.warn / console.error print while the app runs is captured, not
   printed: it becomes diagnostics, and keeps --json output clean. */
function captureConsole(sink) {
  const original = { warn: console.warn, error: console.error };
  for (const level of ["warn", "error"]) {
    console[level] = (...args) => {
      sink.push({
        level,
        message: args
          .map((a) => (typeof a === "string" ? a : a instanceof Error ? a.message : safeString(a)))
          .join(" "),
      });
    };
  }
  return () => Object.assign(console, original);
}

function safeString(value) {
  try {
    return JSON.stringify(value);
  } catch {
    return String(value);
  }
}

export async function createSession({ root, captureStacks = true, url = "http://localhost/" } = {}) {
  const dom = new JSDOM('<!DOCTYPE html><html><head></head><body><div id="root"></div></body></html>', {
    url,
    pretendToBeVisual: true,
  });
  installGlobals(dom);
  const consoleLog = [];
  const restoreConsole = captureConsole(consoleLog);

  const Devtools = await importXote(root, "Devtools");
  const status = Devtools.install(captureStacks, undefined);
  const xote = {
    View: await importXote(root, "View"),
    XoteJSX: await importXote(root, "XoteJSX"),
    Hydration: await importXote(root, "Hydration"),
  };

  let rendered = null;
  const kinds = new Map();
  const history = () => Devtools.history();
  const nodeKind = (id) => {
    if (!kinds.has(id)) kinds.set(id, Devtools.inspect(id)?.kind);
    return kinds.get(id);
  };
  /* Devtools report sites relative to the process's working directory;
     report them relative to the project. */
  const relativeSite = (site) => (site ? toPosix(relative(root, resolve(process.cwd(), site))) : undefined);

  const describe = (id) => {
    const node = Devtools.inspect(id);
    if (!node) return { id };
    return {
      id,
      kind: node.kind,
      ...(node.name ? { name: node.name } : {}),
      ...(node.site ? { site: relativeSite(node.site) } : {}),
      ...(node.binding ? { binding: node.binding } : {}),
      ...(node.value !== undefined ? { value: node.value } : {}),
    };
  };

  const toNode = (value) => nodeOf(xote.XoteJSX, value);

  async function render({ target, mode = "client" }) {
    if (rendered) throw new Error("this session already rendered; start a new session to render again");
    const { module: moduleName, path } = parseTarget(target);
    const file = findCompiled(root, moduleName);
    const logStart = consoleLog.length;
    const module = await import(pathToFileURL(file).href);
    const value = resolveExport(module, path);
    const container = document.getElementById("root");
    const result = { target, mode, file: toPosix(relative(root, file)), status };

    if (mode === "client") {
      xote.View.mount(toNode(value), container);
    } else {
      const server = await renderOnServer(root, target);
      result.serverHtml = server.html;
      result.stateScript = server.stateScript;
      for (const entry of server.log) consoleLog.push({ ...entry, message: `[server] ${entry.message}` });
      if (mode === "hydrate") {
        container.innerHTML = server.html;
        xote.Hydration.hydrate(() => toNode(value), container, undefined);
        /* What the client renders on its own, hidden from devtools, against
           the markup the server produced. */
        const fresh = document.createElement("div");
        Devtools.mute(() => xote.View.mount(toNode(value), fresh));
        result.mismatches = compareMarkup(server.html, fresh.innerHTML);
      }
    }
    rendered = { target, mode };
    if (mode !== "ssr") result.html = container.innerHTML;
    result.summary = summary();
    result.diagnostics = diagnostics({ since: 0, logStart });
    for (const mismatch of result.mismatches ?? []) {
      result.diagnostics.push({
        rule: "hydration-mismatch",
        severity: "error",
        message: `the server rendered ${mismatch.server} where the client renders ${mismatch.client}, at ${mismatch.path}. Hydration keeps the server's markup, so the page shows what the server rendered until something re-renders it.`,
        path: mismatch.path,
      });
    }
    return result;
  }

  function summary() {
    const snap = Devtools.snapshot();
    const byKind = { signal: 0, computed: 0, effect: 0 };
    let bindings = 0;
    for (const node of snap.nodes) {
      byKind[node.kind]++;
      if (node.binding) bindings++;
    }
    const scopes = {};
    for (const scope of snap.scopes) if (!scope.disposed) scopes[scope.kind] = (scopes[scope.kind] ?? 0) + 1;
    return { nodes: byKind, bindings, liveScopes: scopes };
  }

  function findElement(selector) {
    const element = document.querySelector(selector);
    if (!element) {
      const ids = [...document.querySelectorAll("[id]")].map((el) => `#${el.id}`).slice(0, 20);
      throw new Error(`nothing matches ${selector}${ids.length ? `; elements with ids: ${ids.join(", ")}` : ""}`);
    }
    return element;
  }

  function dispatch(element, action, value) {
    const { window } = dom;
    switch (action) {
      case "click":
        element.click();
        break;
      case "input":
      case "change": {
        if (value !== undefined) {
          if (element.type === "checkbox" || element.type === "radio") element.checked = value === "true" || value === true;
          else element.value = value;
        }
        element.dispatchEvent(new window.Event(action, { bubbles: true }));
        break;
      }
      case "submit":
        element.dispatchEvent(new window.Event("submit", { bubbles: true, cancelable: true }));
        break;
      case "focus":
      case "blur":
        element.dispatchEvent(new window.FocusEvent(action, { bubbles: action === "focus" ? false : false }));
        break;
      case "keydown":
      case "keyup":
        element.dispatchEvent(new window.KeyboardEvent(action, { key: value ?? "Enter", bubbles: true }));
        break;
      default:
        element.dispatchEvent(new window.Event(action, { bubbles: true }));
    }
  }

  function countEvents(events) {
    const counts = { writes: 0, effects: 0, computeds: 0, bindings: 0, domWrites: 0, scopesCreated: 0, scopesDisposed: 0, reconciled: 0 };
    for (const event of events) {
      switch (event.type) {
        case "Written":
          if (event.changed) counts.writes++;
          break;
        case "RunStart": {
          const node = Devtools.inspect(event.id);
          if (nodeKind(event.id) === "effect") {
            counts.effects++;
            if (node?.binding) counts.bindings++;
          } else if (nodeKind(event.id) === "computed") counts.computeds++;
          break;
        }
        case "DomWrite":
          counts.domWrites++;
          break;
        case "ScopeCreated":
          counts.scopesCreated++;
          break;
        case "ScopeDisposed":
          counts.scopesDisposed++;
          break;
        case "Reconciled":
          counts.reconciled++;
          break;
      }
    }
    return counts;
  }

  /* Dispatch one interaction and report everything it caused, including what
   settles asynchronously within `settle` milliseconds. */
  async function act({ action = "click", selector, value, settle = 0 }) {
    if (!rendered) throw new Error("render something first");
    const element = findElement(selector);
    const since = history().length;
    const logStart = consoleLog.length;
    const events = [];
    const unsubscribe = Devtools.subscribe((event) => events.push(event));
    try {
      dispatch(element, action, value);
      await new Promise((r) => setTimeout(r, settle));
    } finally {
      unsubscribe();
    }
    const writes = [];
    const ran = [];
    const domWrites = [];
    const reconciled = [];
    for (const event of events) {
      if (event.type === "Written" && event.changed) {
        writes.push({ ...describe(event.id), ...(event.site ? { site: relativeSite(event.site) } : {}) });
      } else if (event.type === "RunStart") ran.push(describe(event.id));
      else if (event.type === "DomWrite") domWrites.push({ node: event.node, target: event.target, what: event.what });
      else if (event.type === "Reconciled") reconciled.push(event);
    }
    return {
      action,
      selector,
      ...(value !== undefined ? { value } : {}),
      counts: countEvents(events),
      writes,
      ran,
      domWrites,
      reconciled,
      html: document.getElementById("root").innerHTML,
      diagnostics: diagnostics({ since, logStart }),
    };
  }

  /* Why a node, or the bindings writing a DOM element, last ran. */
  function why({ id, selector }) {
    if (id !== undefined) return { id, cause: decorate(Devtools.why(Number(id))) };
    const element = findElement(selector);
    const writers = [element, ...element.childNodes].flatMap((node) => Devtools.writersOf(node));
    if (writers.length === 0) {
      return {
        selector,
        writers: [],
        note: "no binding writes this element, so it never updates in place: it is static, or a fragment pass rebuilds it. If it should follow a signal, look for a one-shot prop or a hidden read (xote-lens check, and the unresolved-read diagnostic).",
      };
    }
    return { selector, writers: writers.map((writer) => ({ ...describe(writer), cause: decorate(Devtools.why(writer)) })) };
  }

  function decorate(cause) {
    if (!cause) return null;
    return {
      id: cause.id,
      kind: cause.kind,
      ...(cause.name ? { name: cause.name } : {}),
      ...(cause.site ? { site: relativeSite(cause.site) } : {}),
      action: cause.action,
      causes: cause.causes.map(decorate),
    };
  }

  /* The graph, or the neighbourhood of one node out to `depth` edges. */
  function graph({ around, depth = 2 } = {}) {
    const snap = Devtools.snapshot();
    const nodes = snap.nodes.map((node) => ({ ...node, site: relativeSite(node.site) }));
    if (around === undefined) return { nodes, scopes: snap.scopes };
    const byId = new Map(nodes.map((node) => [node.id, node]));
    const keep = new Set([Number(around)]);
    let frontier = [Number(around)];
    for (let d = 0; d < depth; d++) {
      const next = [];
      for (const id of frontier) {
        const node = byId.get(id);
        if (!node) continue;
        for (const other of [...node.sources, ...node.observers]) {
          if (!keep.has(other)) {
            keep.add(other);
            next.push(other);
          }
        }
      }
      frontier = next;
    }
    const kept = nodes.filter((node) => keep.has(node.id));
    const scopeIds = new Set(kept.map((node) => node.scope).filter((s) => s !== undefined));
    return { nodes: kept, scopes: snap.scopes.filter((scope) => scopeIds.has(scope.id)) };
  }

  /* Runtime findings: leaks, hidden reads, effects that write what they read,
   and whatever the app printed. `since` limits the event-based ones to the
   history after that index. */
  function diagnostics({ since = 0, logStart = 0 } = {}) {
    const out = [];
    if (!status.signals) {
      out.push({
        rule: "no-graph",
        severity: "info",
        message:
          "the loaded rescript-signals has no debug hooks, so the reactive graph is not visible (only scopes, DOM writes and keyed passes are). Upgrade rescript-signals to a release with Signals.Debug.",
      });
    }
    for (const leak of Devtools.leaks()) {
      const rule = { effectOutlivedScope: "leaked-effect", computedOutlivedScope: "undisposed-computed", unownedEffect: "unowned-effect" }[leak.reason];
      const what = leak.name ? `${leak.kind} "${leak.name}"` : `${leak.kind} #${leak.node}`;
      const message = {
        effectOutlivedScope: `${what} is still running after the scope that created it was released. Create it with Xote's Effect (which registers with the rendering scope), or dispose it in an onCleanup.`,
        computedOutlivedScope: `${what} is still subscribed after the scope that created it was released: something outside the scope reads it. Dispose it with Computed.dispose when the scope goes, or create it outside.`,
        unownedEffect: `${what} was created inside another node's run with no scope to own it, so every run of that node creates another. Create it once, outside the run, or in a component body.`,
      }[leak.reason];
      out.push({ rule, severity: "warning", message, node: leak.node, ...(leak.site ? { site: relativeSite(leak.site) } : {}) });
    }
    const events = history().slice(since);
    const seenProbe = new Set();
    for (const event of events) {
      if (event.type === "Probe" && event.hidden && !seenProbe.has(event.site)) {
        seenProbe.add(event.site);
        out.push({
          rule: "unresolved-read",
          severity: "warning",
          message: `this leaf reads a signal through a call @xote.component cannot see, so it rendered once and will not update. Wrap it in a thunk ({() => ...}) or inline the Signal.get.`,
          site: event.site,
        });
      }
    }
    /* An effect that writes a signal it reads re-runs itself. */
    const sources = new Map();
    for (const event of history()) {
      if (event.type === "Linked") {
        if (!sources.has(event.target)) sources.set(event.target, new Set());
        sources.get(event.target).add(event.source);
      }
    }
    const stack = [];
    const flagged = new Set();
    for (const event of events) {
      if (event.type === "RunStart") stack.push(event.id);
      else if (event.type === "RunEnd") stack.pop();
      else if (event.type === "Written" && event.changed && stack.length) {
        const runner = stack[stack.length - 1];
        if (nodeKind(runner) === "effect" && sources.get(runner)?.has(event.id) && !flagged.has(runner)) {
          flagged.add(runner);
          const effect = describe(runner);
          const signal = describe(event.id);
          out.push({
            rule: "get-in-effect",
            severity: "warning",
            message: `effect ${effect.name ? `"${effect.name}"` : `#${runner}`} writes ${signal.name ? `"${signal.name}"` : `signal #${event.id}`}, which it also reads, so each write schedules it again. Read it with Signal.peek, or derive the value with a Computed.`,
            node: runner,
            ...(effect.site ? { site: effect.site } : {}),
            ...(event.site ? { writeSite: relativeSite(event.site) } : {}),
          });
        }
      }
    }
    for (const entry of consoleLog.slice(logStart)) {
      out.push({ rule: "console", severity: entry.level === "error" ? "error" : "warning", message: entry.message });
    }
    return out;
  }

  return {
    status,
    render,
    act,
    why,
    graph,
    inspect: (id) => describe(Number(id)),
    leaks: () => Devtools.leaks(),
    diagnostics: () => diagnostics({}),
    html: (selector) => (selector ? findElement(selector).outerHTML : document.getElementById("root").innerHTML),
    close() {
      Devtools.uninstall();
      restoreConsole();
      dom.window.close();
    },
  };
}
