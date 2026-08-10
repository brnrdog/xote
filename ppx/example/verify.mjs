// Runtime verification that the @tracked fine-grained ppx produces reactive
// *leaves* (not a wholesale rebuild). The key assertions tag DOM elements with
// a marker property, mutate signals, then check the marker survives — proving
// the element kept its identity and was not recreated.
//
//   sh ../build.sh && npm run build && npm run verify
import { JSDOM } from 'jsdom';

const dom = new JSDOM('<!DOCTYPE html><html><body></body></html>', { url: 'https://xote.test/' });
globalThis.window = dom.window;
globalThis.document = dom.window.document;
globalThis.HTMLElement = dom.window.HTMLElement;
globalThis.Node = dom.window.Node;

const View = await import('xote/src/View.res.mjs');
const Signal = await import('xote/src/Signal.res.mjs');
const Demo = await import('./src/Demo.res.mjs');

let pass = 0, fail = 0;
const check = (name, cond) => {
  if (cond) { pass++; console.log('  ✓', name); }
  else { fail++; console.log('  ✗', name); }
};
const mount = (factory) => {
  const host = document.createElement('div');
  document.body.appendChild(host);
  View.mount(factory(), host);
  return host.firstElementChild;
};

// --- Fine-grained leaves: attribute + text update, structure preserved -----
// Cases 1/3/4/5/6 all read `active` (class) and `name` (text), each via a
// different read form. If the ppx failed to recognise the read, the leaf
// would be static and the assertions below would fail.
const c = (m) => () => m({}); // call a propless @xote.component
const forms = [
  ['card    (Signal.get direct)',       c(Demo.Card.make),        '#card',        'Hello, Grace'],
  ['aliased (let g = Signal.get)',      c(Demo.Aliased.make),     '#aliased',     'Hi, Grace'],
  ['modAlias(module S = Signal)',       c(Demo.ModAliased.make),  '#mod-aliased', 'Yo, Grace'],
  ['open    (open Signal; get)',        c(Demo.OpenAliased.make), '#open-aliased','Hey, Grace'],
  ['piped   (active->Signal.get)',      c(Demo.Piped.make),       '#piped',       'Pipe, Grace'],
];

console.log('fine-grained reactive leaves (each read form):');
const mounted = forms.map(([, factory]) => mount(factory));
mounted.forEach((el) => { el.__marker = 'ORIGINAL'; });
check('all start class "off"', mounted.every((el) => el.className === 'off'));

Signal.set(Demo.active, true);
Signal.set(Demo.name, 'Grace');

forms.forEach(([label, , sel, expectedText], i) => {
  const el = document.querySelector(sel);
  check(`${label}: class -> "on"`, el.className === 'on');
  check(`${label}: text updated`, el.textContent.includes(expectedText));
  check(`${label}: element kept identity (not rebuilt)`, mounted[i].__marker === 'ORIGINAL' && el === mounted[i]);
});

// Case 1 also has a static sibling span that must never be touched.
check('card static <span> class intact', document.querySelector('#card .static-label') !== null);
check('card static label text intact', document.querySelector('#card').textContent.includes('Name:'));

// --- @xote.component: derives props AND fine-grains the returned JSX --------
console.log('@xote.component (props derived + fine-grained):');
const labeled = mount(() => Demo.Labeled.make({ label: 'Hits' }));
labeled.__marker = 'ORIGINAL';
check('prop rendered (label "Hits")', labeled.textContent.includes('Hits:'));
check('reads current signal via props form', labeled.textContent.includes('Grace')); // name already Grace
check('class is reactive ("on")', labeled.className === 'on');

Signal.set(Demo.active, false);
Signal.set(Demo.name, 'Ada');
check('class leaf updated to "off"', document.querySelector('#labeled').className === 'off');
check('text leaf updated (Ada)', document.querySelector('#labeled').textContent.includes('Hits: Ada'));
check('component element kept identity (fine-grained, no rebuild)', document.querySelector('#labeled').__marker === 'ORIGINAL');

// Pre-existing () => … thunks must not be double-wrapped: class stays a real
// string ("off"/"on"), not a function. active is currently false, name "Ada".
console.log('pre-existing thunks (not double-wrapped):');
const pre = mount(() => Demo.PreThunked.make({}));
check('class is a plain string, not double-thunked', pre.className === 'off');
check('text thunk resolves', pre.textContent.includes('T: Ada'));
Signal.set(Demo.active, true);
Signal.set(Demo.name, 'Zoe');
check('class thunk still reactive ("on")', pre.className === 'on');
check('text thunk still reactive (Zoe)', pre.textContent.includes('T: Zoe'));

// A Prop.reactive(Computed) class reads only inside a lambda -> not thunked;
// the class must be a real string and stay reactive. active is currently true.
console.log('already-reactive value (Prop.reactive not thunked):');
const pw = mount(() => Demo.PropWrapped.make({}));
check('Prop.reactive class is a real string ("on")', pw.className === 'on');
Signal.set(Demo.active, false);
check('Prop.reactive class still reactive ("off")', document.querySelector('#prop-wrapped').className === 'off');

// A read hidden behind a local helper (statusClass) must still be reactive —
// the helper is tracked, so class={statusClass()} is thunked, not static.
// active is currently false.
//
// NOTE: only *local* helpers are covered. A read behind an imported /
// cross-module helper is invisible to the (single-file) PPX and compiles to a
// static attribute with no error — a limitation this jsdom suite cannot catch
// structurally, since the missed read produces valid code that simply never
// updates. See ppx/README.md "Known limitations"; the escape hatch is to wrap
// the value in `() =>` yourself.
console.log('helper-hidden read (local reactive helper tracked):');
const hh = mount(() => Demo.HelperHidden.make({}));
check('helper class reactive ("off")', hh.className === 'off');
Signal.set(Demo.active, true);
check('helper class updates ("on") — not a silent static bug', document.querySelector('#helper-hidden').className === 'on');

// --- Structural swap via View.tracked, outer element preserved -------------
console.log('panel (structural swap, outer element preserved):');
const panel = mount(c(Demo.Panel.make));
panel.__pmarker = 'PANEL';
check('initial Loading <span>', panel.querySelector('span') !== null && panel.textContent.includes('Loading'));

Signal.set(Demo.status, { TAG: 'Ready', _0: 'Done!' });
check('swapped to <strong>', panel.querySelector('strong') !== null);
check('shows "Done!"', panel.textContent.includes('Done!'));
check('outer DIV kept identity (only inner region swapped)', panel.__pmarker === 'PANEL');

// --- Branch leaf stays fine-grained (item 2) -------------------------------
// The switch tracks only `status`; the Ready branch's class reads `theme`.
// Changing `theme` must update the class leaf WITHOUT re-running the switch —
// i.e. the <strong> keeps its identity. (Before branch decomposition, `theme`
// was read eagerly during the tracked render, so the whole branch rebuilt.)
console.log('switchLeaf (branch leaf reacts without re-running the switch):');
Signal.set(Demo.status, { TAG: 'Ready', _0: 'Ready!' }); // select the Ready branch
const outer = mount(c(Demo.SwitchLeaf.make));
outer.__omarker = 'OUTER';
const strong = outer.querySelector('#ready-strong');
strong.__marker = 'STRONG';
check('initial class = theme "light"', strong.className === 'light');

Signal.set(Demo.theme, 'dark');
check('class leaf updated to "dark"', outer.querySelector('#ready-strong').className === 'dark');
check('<strong> kept identity (switch did NOT re-run)', outer.querySelector('#ready-strong').__marker === 'STRONG');
check('outer div kept identity', outer.__omarker === 'OUTER');

// Structural swap still works: changing the scrutinee rebuilds the branch.
Signal.set(Demo.status, 'Loading');
check('scrutinee change still swaps to <span>',
  outer.querySelector('span') !== null && outer.querySelector('#ready-strong') === null);

// --- Bare children coerced by View.child (no <View.Int>/<View.Text> needed) --
// <div>{Signal.get(count)}</div> — a bare *reactive scalar* becomes reactive
// text; the <div> keeps its identity across the change (fine-grained leaf).
console.log('bare reactive int child (View.child):');
Signal.set(Demo.count, 0);
const bi = mount(() => Demo.BareInt.make({}));
bi.__marker = 'BI';
check('bare int renders "0"', bi.textContent === '0');
Signal.set(Demo.count, 7);
check('bare int updates to "7"', document.querySelector('#bare-int').textContent === '7');
check('bare int <div> kept identity (reactive leaf, not rebuilt)', document.querySelector('#bare-int').__marker === 'BI');

// <div><span>…</span>{Signal.get(name)}</div> — bare reactive string alongside a
// static sibling; only the text leaf reacts, the <span> keeps its identity.
console.log('bare reactive string child + static sibling:');
Signal.set(Demo.name, 'Ada');
const bs = mount(() => Demo.BareString.make({}));
const bsSpan = bs.querySelector('.lbl');
bsSpan.__marker = 'SPAN';
check('bare string shows "n: Ada"', bs.textContent === 'n: Ada');
Signal.set(Demo.name, 'Bo');
check('bare string updates to "n: Bo"', document.querySelector('#bare-string').textContent === 'n: Bo');
check('static <span> sibling kept identity', document.querySelector('#bare-string .lbl').__marker === 'SPAN');

// <div>{"literal"}</div> — a bare *static* scalar (a type error before View.child)
// becomes a static text node.
console.log('bare static scalar child:');
const bst = mount(() => Demo.BareStatic.make({}));
check('bare static renders "literal"', bst.textContent === 'literal');

// <div>{View.text("noded")}</div> — a bare child that is *already a node* passes
// through View.child untouched.
console.log('bare already-a-node child (passthrough):');
const bn = mount(() => Demo.BareNode.make({}));
check('bare node renders "noded"', bn.textContent === 'noded');

// Control flow with *scalar* branches: still a tracked structural swap on
// `status`, but each scalar branch is coerced by View.child (no value primitive).
console.log('scalar switch branches (tracked + View.child):');
Signal.set(Demo.status, 'Loading');
const ss = mount(() => Demo.ScalarSwitch.make({}));
ss.__marker = 'SS';
check('scalar switch shows "…loading"', ss.textContent === '…loading');
Signal.set(Demo.status, { TAG: 'Ready', _0: 'done' });
check('scalar switch swaps to "done"', document.querySelector('#scalar-switch').textContent === 'done');
check('scalar switch outer <div> kept identity', document.querySelector('#scalar-switch').__marker === 'SS');

// --- Fragment body: nested regions stay independent ------------------------
// A make whose body is a <>…</> fragment with two reactive regions: a canvas
// element and a mobile-backdrop `if`. Each fragment child is decomposed on its
// own, so toggling the backdrop must NOT rebuild the canvas. (Regression: before
// fragments were recursed into, the whole fragment was one coarse thunk and a
// panel toggle rebuilt every sibling, losing DOM state.)
console.log('fragment body: independent reactive regions (no coarse collapse):');
Signal.set(Demo.mobileOpen, false);
Signal.set(Demo.canvas, 'canvas-a');
const wsHost = document.createElement('div');
document.body.appendChild(wsHost);
View.mount(Demo.Workspace.make({}), wsHost);
const canvasEl = wsHost.querySelector('#ws-canvas');
canvasEl.__marker = 'CANVAS';
check('canvas renders "canvas-a"', canvasEl.textContent === 'canvas-a');
check('backdrop absent initially', wsHost.querySelector('#ws-backdrop') === null);

Signal.set(Demo.mobileOpen, true);
check('backdrop appears on panel toggle', wsHost.querySelector('#ws-backdrop') !== null);
check('canvas kept identity across panel toggle (NOT rebuilt)', wsHost.querySelector('#ws-canvas').__marker === 'CANVAS');

Signal.set(Demo.canvas, 'canvas-b');
check('canvas content updates on its own', wsHost.querySelector('#ws-canvas').textContent === 'canvas-b');
check('canvas still same element after its own update', wsHost.querySelector('#ws-canvas').__marker === 'CANVAS');

Signal.set(Demo.mobileOpen, false);
check('backdrop removed on toggle off', wsHost.querySelector('#ws-backdrop') === null);
check('canvas kept identity across second toggle (regions independent)', wsHost.querySelector('#ws-canvas').__marker === 'CANVAS');

// --- Bare children directly in a fragment return ---------------------------
// A dropdown-style fragment whose labels sit at the top level next to a static
// anchor. Each bare read must be coerced in place (no display:contents root).
console.log('bare children directly in a fragment return:');
Signal.set(Demo.name, 'Ada');
Signal.set(Demo.count, 3);
const dfHost = document.createElement('div');
document.body.appendChild(dfHost);
View.mount(Demo.DropdownFragment.make({}), dfHost);
const dfAnchor = dfHost.querySelector('#df-anchor');
dfAnchor.__marker = 'ANCHOR';
check('fragment bare label renders (name)', dfHost.textContent.includes('Ada'));
check('fragment bare thunk renders (#count)', dfHost.textContent.includes('#3'));
Signal.set(Demo.name, 'Bo');
Signal.set(Demo.count, 9);
check('fragment bare label updates', dfHost.textContent.includes('Bo'));
check('fragment bare thunk updates', dfHost.textContent.includes('#9'));
check('fragment static anchor kept identity', dfHost.querySelector('#df-anchor').__marker === 'ANCHOR');

// --- Fragment as a control-flow branch body --------------------------------
// The dropdown's labels live inside CanvasMenu's `{if …}` as a fragment, not in
// their own component. The branch is decomposed so its bare labels are coerced;
// the anchor outside the `if` keeps its identity across toggles.
console.log('fragment as a control-flow branch body:');
Signal.set(Demo.active, false);
Signal.set(Demo.name, 'Ada');
Signal.set(Demo.count, 5);
const mb = mount(() => Demo.MenuBranch.make({}));
const mbAnchor = mb.querySelector('#mb-anchor');
mbAnchor.__marker = 'MB';
check('branch closed: no labels yet', !mb.textContent.includes('Ada'));
Signal.set(Demo.active, true);
check('branch open: bare label coerced (name)', document.querySelector('#mb-host').textContent.includes('Ada'));
check('branch open: bare int coerced (count)', document.querySelector('#mb-host').textContent.includes('5'));
check('anchor outside the if kept identity', document.querySelector('#mb-anchor').__marker === 'MB');
Signal.set(Demo.active, false);
check('branch closed again: labels gone', !document.querySelector('#mb-host').textContent.includes('Ada'));
check('anchor still same element after toggle', document.querySelector('#mb-anchor').__marker === 'MB');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
