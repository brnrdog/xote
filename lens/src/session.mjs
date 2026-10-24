// A session: one headless jsdom page running one Xote component under
// devtools, installed before the component's module is imported so that
// module-level signals are visible. A session renders once: module state
// cannot be reset in place (so the MCP server forks a process per render).

import { JSDOM } from "jsdom";
import { resolve } from "node:path";
import { captureConsole, findCompiled, importXote, loadTarget, parseTarget, relPath, toNode } from "./project.mjs";
import { compareMarkup, markerOutline, parseStateScript, reflectProperties } from "./markup.mjs";
import { renderOnServer } from "./server.mjs";

const GLOBALS = `window document navigator location history Node Element HTMLElement HTMLInputElement HTMLTextAreaElement
  HTMLSelectElement SVGElement Text Comment DocumentFragment Event CustomEvent MouseEvent KeyboardEvent InputEvent
  FocusEvent SubmitEvent PopStateEvent MutationObserver getComputedStyle`.split(/\s+/);

function installGlobals(window) {
  for (const name of GLOBALS.filter((n) => window[n] !== undefined)) {
    const value = name === "window" ? window : window[name];
    try {
      globalThis[name] = value;
    } catch {
      /* some globals (navigator) are getters on newer Node; define over them */
      Object.defineProperty(globalThis, name, { value, configurable: true, writable: true });
    }
  }
  window.scrollTo = () => {};
  globalThis.requestAnimationFrame = (fn) => setTimeout(() => fn(Date.now()), 0);
  globalThis.cancelAnimationFrame = (id) => clearTimeout(id);
}

function showArg(a) {
  if (typeof a === "string") return a;
  if (a instanceof Error) return a.message;
  try {
    return JSON.stringify(a);
  } catch {
    return String(a);
  }
}

const LEAKS = {
  effectOutlivedScope: [
    "leaked-effect",
    "is still running after the scope that created it was released. Create it with Xote's Effect (which registers with the rendering scope), or dispose it in an onCleanup.",
  ],
  computedOutlivedScope: [
    "undisposed-computed",
    "is still subscribed after the scope that created it was released: something outside the scope reads it. Dispose it with Computed.dispose when the scope goes, or create it outside.",
  ],
  unownedEffect: [
    "unowned-effect",
    "was created inside another node's run with no scope to own it, so every run of that node creates another. Create it once, outside the run, or in a component body.",
  ],
};
const NO_WRITER =
  "no binding writes this element, so it never updates in place: it is static, or a fragment pass rebuilds it. If it should follow a signal, look for a one-shot prop or a hidden read (xote-lens check, and the unresolved-read diagnostic).";

export async function createSession({ root, captureStacks = true, url = "http://localhost/" } = {}) {
  const dom = new JSDOM('<!DOCTYPE html><html><head></head><body><div id="root"></div></body></html>', { url, pretendToBeVisual: true });
  const { window } = dom;
  installGlobals(window);
  /* What the app prints becomes diagnostics (and keeps --json output clean). */
  const consoleLog = [];
  const restoreConsole = captureConsole(consoleLog, showArg);

  const Devtools = await importXote(root, "Devtools");
  const status = Devtools.install(captureStacks, undefined);
  const View = await importXote(root, "View");
  const XoteJSX = await importXote(root, "XoteJSX");
  const Hydration = await importXote(root, "Hydration");

  let rendered = false;
  const container = () => document.getElementById("root");
  const history = () => Devtools.history();
  const kinds = new Map();
  const nodeKind = (id) => {
    if (!kinds.has(id)) kinds.set(id, Devtools.inspect(id)?.kind);
    return kinds.get(id);
  };
  /* Devtools sites are relative to the working directory; report them relative to the project. */
  const relativeSite = (site) => (site ? relPath(root, resolve(process.cwd(), site)) : undefined);
  const siteOf = (x) => (x.site ? { site: relativeSite(x.site) } : {});
  const label = (x) => ({ id: x.id, kind: x.kind, ...(x.name ? { name: x.name } : {}), ...siteOf(x) });
  const nameOr = (node, fallback) => (node.name ? `"${node.name}"` : fallback);
  const describe = (id) => {
    const node = Devtools.inspect(id);
    if (!node) return { id };
    return { ...label({ ...node, id }), ...(node.binding ? { binding: node.binding } : {}), ...(node.value !== undefined ? { value: node.value } : {}) };
  };
  const decorate = (cause) => (cause ? { ...label(cause), action: cause.action, causes: cause.causes.map(decorate) } : null);

  async function render({ target, mode = "client" }) {
    if (rendered) throw new Error("this session already rendered; start a new session to render again");
    const file = findCompiled(root, parseTarget(target).module);
    const logStart = consoleLog.length;
    const result = { target, mode, file: relPath(root, file), status };

    /* The server half runs first, in its own DOM-less process. For hydration
       its state payload is in place before the app's modules load, as in a
       real page, so module-level SSRState.signal calls restore from it. */
    let server = null;
    if (mode !== "client") {
      server = await renderOnServer(root, target);
      Object.assign(result, { serverHtml: server.html, stateScript: server.stateScript, outline: markerOutline(server.html) });
      for (const entry of server.log) consoleLog.push({ ...entry, message: `[server] ${entry.message}` });
      if (mode === "hydrate") window.__XOTE_STATE__ = parseStateScript(server.stateScript);
    }

    const since = history().length;
    const { value } = await loadTarget(root, target);
    const node = () => toNode(XoteJSX, value);
    if (mode === "client") View.mount(node(), container());
    else if (mode === "hydrate") {
      container().innerHTML = server.html;
      Hydration.hydrate(node, container(), undefined);
      /* What the client renders on its own, hidden from devtools, against the server's markup. */
      const fresh = document.createElement("div");
      Devtools.mute(() => View.mount(node(), fresh));
      result.mismatches = compareMarkup(server.html, reflectProperties(fresh).innerHTML);
      result.state = stateReport(window.__XOTE_STATE__ ?? {}, history().slice(since));
    }
    rendered = true;
    if (mode !== "ssr") result.html = container().innerHTML;
    result.summary = summary();
    result.diagnostics = [...diagnostics({ logStart }), ...hydrationDiagnostics(result)];
    return result;
  }

  function hydrationDiagnostics({ mismatches = [], state = [] }) {
    const out = mismatches.map((m) => ({
      rule: "hydration-mismatch",
      severity: "error",
      message: `the server rendered ${m.server} where the client renders ${m.client}, at ${m.path}. Hydration keeps the server's markup, so the page shows what the server rendered until something re-renders it.`,
      path: m.path,
    }));
    const add = (rule, severity, message) => out.push({ rule, severity, message });
    for (const { key, node, server, inPayload, restored, decoded } of state) {
      const signal = node ? `signal ${nameOr(node, `#${node.id}`)}` : "signal";
      if (restored && !inPayload) {
        add("ssr-state-missing", "warning", `the client restores "${key}" into ${signal}, but the server never registered it, so the signal keeps its initial value. Register it on the server too (SSRState.sync and SSRState.signal do both).`);
      } else if (restored && !decoded) {
        add("ssr-state-decode-failed", "error", `the server sent ${JSON.stringify(server)} for "${key}", which the client's codec cannot decode, so ${signal} silently keeps its initial value. Use the same codec on both sides.`);
      } else if (!restored) {
        add("ssr-state-unrestored", "warning", `the server sent "${key}" but nothing on the client restored it. Restore it under the same id (SSRState.sync and SSRState.signal do both), or stop registering it.`);
      }
    }
    return out;
  }

  /* Join the server's payload with what the client restored. */
  function stateReport(payload, events) {
    const restored = new Map(events.filter((e) => e.type === "StateRestored").map((e) => [e.key, e]));
    return [...new Set([...Object.keys(payload), ...restored.keys()])].map((key) => {
      const event = restored.get(key);
      return {
        key,
        inPayload: key in payload,
        ...(key in payload ? { server: payload[key] } : {}),
        restored: Boolean(event),
        decoded: Boolean(event?.decoded),
        ...(event?.node !== undefined ? { node: describe(event.node) } : {}),
      };
    });
  }

  function summary() {
    const snap = Devtools.snapshot();
    const nodes = { signal: 0, computed: 0, effect: 0 };
    const liveScopes = {};
    for (const node of snap.nodes) nodes[node.kind]++;
    for (const scope of snap.scopes) if (!scope.disposed) liveScopes[scope.kind] = (liveScopes[scope.kind] ?? 0) + 1;
    return { nodes, bindings: snap.nodes.filter((n) => n.binding).length, liveScopes };
  }

  function findElement(selector) {
    const element = document.querySelector(selector);
    if (element) return element;
    const ids = [...document.querySelectorAll("[id]")].map((el) => `#${el.id}`).slice(0, 20);
    throw new Error(`nothing matches ${selector}${ids.length ? `; elements with ids: ${ids.join(", ")}` : ""}`);
  }

  function dispatch(element, action, value) {
    if (action === "click") return element.click();
    if ((action === "input" || action === "change") && value !== undefined) {
      if (element.type === "checkbox" || element.type === "radio") element.checked = value === "true" || value === true;
      else element.value = value;
    }
    const event =
      action === "focus" || action === "blur"
        ? new window.FocusEvent(action, { bubbles: false })
        : action === "keydown" || action === "keyup"
          ? new window.KeyboardEvent(action, { key: value ?? "Enter", bubbles: true })
          : new window.Event(action, { bubbles: true, cancelable: action === "submit" });
    element.dispatchEvent(event);
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
    const ofType = (type) => events.filter((e) => e.type === type && (type !== "Written" || e.changed));
    const runs = ofType("RunStart").map((e) => ({ kind: nodeKind(e.id), node: describe(e.id) }));
    const effects = runs.filter((r) => r.kind === "effect");
    const reconciled = ofType("Reconciled");
    return {
      action,
      selector,
      ...(value !== undefined ? { value } : {}),
      counts: {
        writes: ofType("Written").length,
        effects: effects.length,
        computeds: runs.filter((r) => r.kind === "computed").length,
        bindings: effects.filter((r) => r.node.binding).length,
        domWrites: ofType("DomWrite").length,
        scopesCreated: ofType("ScopeCreated").length,
        scopesDisposed: ofType("ScopeDisposed").length,
        reconciled: reconciled.length,
      },
      writes: ofType("Written").map((e) => ({ ...describe(e.id), ...siteOf(e) })),
      ran: runs.map((r) => r.node),
      domWrites: ofType("DomWrite").map(({ node, target, what }) => ({ node, target, what })),
      reconciled,
      html: container().innerHTML,
      diagnostics: diagnostics({ since, logStart }),
    };
  }

  /* Why a node, or the bindings writing a DOM element, last ran. */
  function why({ id, selector }) {
    if (id !== undefined) return { id, cause: decorate(Devtools.why(Number(id))) };
    const element = findElement(selector);
    const writers = [element, ...element.childNodes].flatMap((node) => Devtools.writersOf(node));
    if (writers.length === 0) return { selector, writers: [], note: NO_WRITER };
    return { selector, writers: writers.map((writer) => ({ ...describe(writer), cause: decorate(Devtools.why(writer)) })) };
  }

  /* The graph, or the neighbourhood of one node out to `depth` edges. */
  function graph({ around, depth = 2 } = {}) {
    const snap = Devtools.snapshot();
    const nodes = snap.nodes.map((node) => ({ ...node, site: relativeSite(node.site) }));
    if (around === undefined) return { nodes, scopes: snap.scopes };
    const byId = new Map(nodes.map((node) => [node.id, node]));
    const keep = new Set([Number(around)]);
    let frontier = [...keep];
    for (let d = 0; d < depth; d++) {
      const reached = frontier.flatMap((id) => (byId.has(id) ? [...byId.get(id).sources, ...byId.get(id).observers] : []));
      frontier = [...new Set(reached.filter((id) => !keep.has(id)))];
      for (const id of frontier) keep.add(id);
    }
    const kept = nodes.filter((node) => keep.has(node.id));
    const scopeIds = new Set(kept.map((node) => node.scope));
    return { nodes: kept, scopes: snap.scopes.filter((scope) => scopeIds.has(scope.id)) };
  }

  /* Runtime findings: leaks, hidden reads, effects that write what they read,
     and what the app printed. Event-based ones look at history from `since`. */
  function diagnostics({ since = 0, logStart = 0 } = {}) {
    const out = [];
    if (!status.signals) {
      out.push({
        rule: "no-graph",
        severity: "info",
        message: "the loaded rescript-signals has no debug hooks, so the reactive graph is not visible (only scopes, DOM writes and keyed passes are). Upgrade rescript-signals to a release with Signals.Debug.",
      });
    }
    for (const leak of Devtools.leaks()) {
      const [rule, text] = LEAKS[leak.reason];
      const what = leak.name ? `${leak.kind} "${leak.name}"` : `${leak.kind} #${leak.node}`;
      out.push({ rule, severity: "warning", message: `${what} ${text}`, node: leak.node, ...siteOf(leak) });
    }
    const events = history().slice(since);
    const probeSites = new Set(events.filter((e) => e.type === "Probe" && e.hidden).map((e) => e.site));
    for (const site of probeSites) {
      out.push({
        rule: "unresolved-read",
        severity: "warning",
        message: `this leaf reads a signal through a call @xote.component cannot see, so it rendered once and will not update. Wrap it in a thunk ({() => ...}) or inline the Signal.get.`,
        site,
      });
    }
    /* An effect that writes a signal it reads re-runs itself. */
    const sources = new Map();
    for (const { type, target, source } of history()) {
      if (type === "Linked") sources.set(target, (sources.get(target) ?? new Set()).add(source));
    }
    const stack = [];
    const flagged = new Set();
    for (const event of events) {
      if (event.type === "RunStart") stack.push(event.id);
      else if (event.type === "RunEnd") stack.pop();
      else if (event.type === "Written" && event.changed && stack.length) {
        const runner = stack[stack.length - 1];
        if (nodeKind(runner) !== "effect" || !sources.get(runner)?.has(event.id) || flagged.has(runner)) continue;
        flagged.add(runner);
        const effect = describe(runner);
        out.push({
          rule: "get-in-effect",
          severity: "warning",
          message: `effect ${nameOr(effect, `#${runner}`)} writes ${nameOr(describe(event.id), `signal #${event.id}`)}, which it also reads, so each write schedules it again. Read it with Signal.peek, or derive the value with a Computed.`,
          node: runner,
          ...(effect.site ? { site: effect.site } : {}),
          ...(event.site ? { writeSite: relativeSite(event.site) } : {}),
        });
      }
    }
    for (const { level, message } of consoleLog.slice(logStart)) out.push({ rule: "console", severity: level === "error" ? "error" : "warning", message });
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
    diagnostics: () => diagnostics(),
    html: (selector) => (selector ? findElement(selector).outerHTML : container().innerHTML),
    close() {
      Devtools.uninstall();
      restoreConsole();
      window.close();
    },
  };
}
