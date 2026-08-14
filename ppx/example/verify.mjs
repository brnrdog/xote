// Runtime verification that the @xote.component fine-grained ppx produces
// reactive *leaves* (not a wholesale rebuild). The key assertions tag DOM elements with
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
const Store = await import('./src/Store.res.mjs');

// `View.probe` reports hidden reads through console.warn. Capture from the very
// first mount so the hidden-read section can assert both what was reported and
// what was not — a false positive is as much a failure as a missed read.
const warnings = [];
const realWarn = console.warn;
console.warn = (...args) => { warnings.push(args.join(' ')); };

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

// --- Poly-variant payload in attribute position -----------------------------
// `class={switch #tone(Signal.get(theme)) { ... }}`: the read sits inside a
// polymorphic variant payload (Pexp_variant), which the eager-read traversal
// must descend into — previously this attribute silently stayed static.
console.log('poly-variant payload in attribute position:');
Signal.set(Demo.theme, 'light');
const vaHost = document.createElement('div');
document.body.appendChild(vaHost);
View.mount(Demo.VariantAttr.make({}), vaHost);
const vaEl = vaHost.querySelector('#variant-attr');
vaEl.__marker = 'VA';
check('variant payload read renders initial class', vaEl.className === 'tone-light');
Signal.set(Demo.theme, 'dark');
check('variant payload read is reactive (class updates)', vaHost.querySelector('#variant-attr').className === 'tone-dark');
check('element kept identity across class update', vaHost.querySelector('#variant-attr').__marker === 'VA');

// --- Guard-only reads make the switch tracked -------------------------------
// `switch v { | _ if Signal.get(active) => … }`: the ONLY read is in the
// `when` guard. Guards are evaluated eagerly, so the switch must be tracked —
// previously the guard was invisible and the branch was static forever.
console.log('switch guard read (tracked via when-guard):');
Signal.set(Demo.active, true);
const gs = mount(() => Demo.GuardSwitch.make({}));
gs.__marker = 'GS';
check('guard true renders "on" branch', gs.querySelector('#gs-on') !== null);
Signal.set(Demo.active, false);
check('guard read is tracked: swaps to "off" branch', document.querySelector('#guard-switch #gs-off') !== null);
check('guard switch outer div kept identity', document.querySelector('#guard-switch').__marker === 'GS');

// --- Signature-constrained module still transformed -------------------------
// `module ConstrainedPanel: Sig = { @xote.component … }`: the traversal must
// descend through Pmod_constraint — previously the annotation was silently
// left unexpanded there (static attrs, or a type error on bare children).
console.log('component inside `module X: Sig = { … }`:');
Signal.set(Demo.theme, 'light');
Signal.set(Demo.count, 1);
const cp = mount(() => Demo.ConstrainedPanel.make({}));
cp.__marker = 'CP';
check('constrained: reactive class renders', cp.className === 'light');
check('constrained: bare int child renders', cp.textContent === '1');
Signal.set(Demo.theme, 'dark');
Signal.set(Demo.count, 2);
check('constrained: class updates (transform ran under the constraint)', document.querySelector('#constrained').className === 'dark');
check('constrained: bare child updates', document.querySelector('#constrained').textContent === '2');
check('constrained: element kept identity', document.querySelector('#constrained').__marker === 'CP');

// --- let-block child stays fine-grained -------------------------------------
// `{let label = …; <span class={Signal.get(theme)}/>}` in node position: the
// tail JSX keeps fine-grained leaves. Previously the whole block collapsed
// into one coarse View.child thunk that rebuilt the span on every change.
console.log('let-block in node position (fine-grained, identity kept):');
Signal.set(Demo.theme, 'light');
const lb = mount(() => Demo.LetBlockChild.make({}));
const lbSpan = lb.querySelector('#lb-span');
lbSpan.__marker = 'LB';
check('let-block span renders with initial class', lbSpan.className === 'light');
Signal.set(Demo.theme, 'dark');
check('let-block class updates', lb.querySelector('#lb-span').className === 'dark');
check('let-block span kept identity (no coarse rebuild)', lb.querySelector('#lb-span').__marker === 'LB');

// --- User-component props ----------------------------------------------------
// A scalar prop that eagerly reads a signal passes through untouched (a
// deliberate one-shot read — previously the ppx thunked it into a baffling
// type error). A JSX-valued prop is node position: its own leaves stay
// reactive and keep identity.
console.log('user-component props (one-shot scalars, reactive JSX values):');
Signal.set(Demo.name, 'Ada');
Signal.set(Demo.theme, 'light');
const tc = mount(() => Demo.UseTitleCard.make({}));
check('scalar prop rendered from one-shot read', tc.querySelector('#tc-label').textContent === 'Ada');
const tcHeader = tc.querySelector('#tc-header');
tcHeader.__marker = 'TCH';
check('JSX-valued prop rendered with its reactive class', tcHeader.className === 'light');
Signal.set(Demo.name, 'Bo');
Signal.set(Demo.theme, 'dark');
check('scalar prop is a deliberate one-shot read (stays "Ada")', tc.querySelector('#tc-label').textContent === 'Ada');
check('JSX prop class updates (leaves decomposed inside the prop)', tc.querySelector('#tc-header').className === 'dark');
check('JSX prop element kept identity', tc.querySelector('#tc-header').__marker === 'TCH');

// --- peek + shadowing: rebound helper is dropped -----------------------------
// `toneClass` is a reactive helper at top level, but the component rebinds it
// to a peek-based one — the rebind drops it from the reactive-helper set, so
// the attribute is a plain, intentionally static string.
console.log('peek-based rebind drops the reactive helper:');
Signal.set(Demo.active, true);
const ps = mount(() => Demo.PeekShadow.make({}));
check('peek class evaluated once ("peek-on")', ps.className === 'peek-on');
Signal.set(Demo.active, false);
check('peek class intentionally static (no update)', document.querySelector('#peek-shadow').className === 'peek-on');

// --- Bare mapped-list child (array-returning thunk) --------------------------
// `{Signal.get(items)->Array.map(…)}`: the eager read is thunked and the
// thunk returns an *array* — View.child must re-coerce it per run, not lock
// into reactive-text mode from the first value.
console.log('bare mapped list child (array thunk re-coerced per run):');
Signal.set(Demo.items, ['a', 'b']);
const ml = mount(() => Demo.MappedList.make({}));
ml.__marker = 'ML';
check('mapped list renders items', ml.textContent === 'ab');
check('mapped list renders real <li> elements', ml.querySelectorAll('li.ml-item').length === 2);
Signal.set(Demo.items, ['a', 'b', 'c']);
check('mapped list updates', document.querySelector('#mapped-list').textContent === 'abc');
check('mapped list outer <ul> kept identity', document.querySelector('#mapped-list').__marker === 'ML');


// --- Control flow on a plain (non-signal) condition -------------------------
// The conditional is built once, but its branches are node position: bare
// children inside them must still be coerced by View.child. This is the shape
// that failed to compile before the branches were decomposed on this path.
console.log('control flow on a plain condition:');
const sbTrue = document.createElement('div');
document.body.appendChild(sbTrue);
View.mount(Demo.StaticBranch.make({ flag: true }), sbTrue);
check('plain-cond branch renders bare literal child', sbTrue.querySelector('#sb-yes').textContent === 'yes');
check('plain-cond ternary over strings renders', sbTrue.textContent.includes('on'));

const sbFalse = document.createElement('div');
document.body.appendChild(sbFalse);
View.mount(Demo.StaticBranch.make({ flag: false }), sbFalse);
check('plain-cond else branch renders bare literal child', sbFalse.querySelector('#sb-no').textContent === 'no');
check('plain-cond ternary takes the else value', sbFalse.textContent.includes('off'));

// A reactive leaf inside a statically-chosen branch stays fine-grained: the
// branch element keeps its identity while the leaf updates.
Signal.set(Demo.theme, 'light');
Signal.set(Demo.name, 'Ada');
const sbrl = document.createElement('div');
document.body.appendChild(sbrl);
View.mount(Demo.StaticBranchReactiveLeaf.make({ flag: true }), sbrl);
const sbrlTag = sbrl.querySelector('#sbrl-tag');
sbrlTag.__marker = 'SBRL';
check('plain-cond branch leaf renders initial class', sbrlTag.className === 'light');
check('plain-cond branch leaf renders bare signal read', sbrlTag.textContent.includes('Ada'));
Signal.set(Demo.theme, 'dark');
Signal.set(Demo.name, 'Bo');
check('leaf class updates inside a plain-cond branch', sbrl.querySelector('#sbrl-tag').className === 'dark');
check('leaf text updates inside a plain-cond branch', sbrl.querySelector('#sbrl-tag').textContent.includes('Bo'));
check('branch element kept identity (built once, not rebuilt)', sbrl.querySelector('#sbrl-tag').__marker === 'SBRL');


// --- Bare children inside a render callback ---------------------------------
// `render={row => …}` is a function returning JSX: node position once applied,
// but not JSX itself, so the traversal used to stop at the callback boundary.
console.log('bare children inside a render callback:');
Signal.set(Demo.theme, 'light');
Signal.set(Demo.count, 7);
const cb = mount(() => Demo.CallbackRows.make({}));
const cbFirst = cb.querySelector('#cb-rows li');
cbFirst.__marker = 'ROW1';
check('callback bare child renders (author)', cb.textContent.includes('Ada'));
check('callback bare literal renders (separator)', cb.textContent.includes('·'));
check('callback bare signal read renders (count)', cb.textContent.includes('7'));
check('callback leaf attribute rendered', cbFirst.className === 'light');
// The leaves inside the callback are fine-grained: updating a signal they read
// changes them in place instead of rebuilding the row.
Signal.set(Demo.count, 8);
check('callback bare signal read updates', document.querySelector('#cb-rows').textContent.includes('8'));
Signal.set(Demo.theme, 'dark');
check('callback leaf attribute updates', document.querySelector('#cb-rows li').className === 'dark');
check('row kept identity across leaf updates', document.querySelector('#cb-rows li').__marker === 'ROW1');


// --- Node-taking helpers called as plain functions --------------------------
// `View.tracked(() => …)` / `View.each(xs, x => …)` are applications, not JSX,
// so the traversal used to stop at the call and leave their callback bodies
// undecomposed.
console.log('bare children inside node-taking helper callbacks:');
Signal.set(Demo.active, false);
Signal.set(Demo.theme, 'light');
Signal.set(Demo.name, 'Ada');
const hc = mount(() => Demo.HelperCallbacks.make({}));
check('tracked callback: else branch bare literal', hc.textContent.includes('inactive'));
check('each callback: bare item rendered', hc.textContent.includes('one') && hc.textContent.includes('two'));
Signal.set(Demo.active, true);
const hcOn = document.querySelector('#hc-on');
hcOn.__marker = 'HC';
check('tracked callback: branch bare signal read', hcOn.textContent.includes('Ada'));
check('tracked callback: branch leaf attribute', hcOn.className === 'light');
// Leaves inside the tracked callback stay fine-grained: the element survives.
Signal.set(Demo.name, 'Bo');
Signal.set(Demo.theme, 'dark');
check('tracked callback: bare read updates', document.querySelector('#hc-on').textContent.includes('Bo'));
check('tracked callback: leaf attribute updates', document.querySelector('#hc-on').className === 'dark');
check('tracked callback: element kept identity', document.querySelector('#hc-on').__marker === 'HC');


// --- Plain helper functions returning markup --------------------------------
// The file opts in via its @xote.component bindings, so helper bodies are
// decomposed too: bare child coerced, class a reactive leaf.
console.log('helper function returning markup:');
Signal.set(Demo.theme, 'light');
const hb = mount(() => Demo.HelperHost.make({}));
const hbBtn = hb.querySelector('#helper-btn');
hbBtn.__marker = 'HB';
check('helper bare child rendered', hbBtn.textContent.includes('Press'));
check('helper leaf attribute rendered', hbBtn.className === 'light');
Signal.set(Demo.theme, 'dark');
check('helper leaf attribute updates (reactive, not static)', document.querySelector('#helper-btn').className === 'dark');
check('helper element kept identity', document.querySelector('#helper-btn').__marker === 'HB');

// --- JSX reached through arrays, applications, pipes, local bindings --------
console.log('JSX nested in non-child positions:');
const ns = mount(() => Demo.NestedShapes.make({}));
check('let-bound JSX renders bare child', ns.querySelector('#ns-heading').textContent.includes('Nested'));
check('array literal inside View.fragment', ns.querySelector('#ns-arr').textContent.includes('array'));
check('pipe + map callback decomposed', ns.querySelectorAll('.ns-map').length === 2);
check('local helper items rendered', ns.textContent.includes('one') && ns.textContent.includes('two'));

// --- MaybeSignal.get is a tracked read --------------------------------------
// Reading through the static-or-reactive wrapper subscribes exactly like
// Signal.get, so both leaves below must be reactive, not one-shot.
console.log('MaybeSignal.get is a tracked read:');
Signal.set(Demo.theme, 'light');
Signal.set(Demo.name, 'Ada');
const ms = mount(() => Demo.MaybeSignalRead.make({}));
ms.__marker = 'MS';
check('MaybeSignal.get attribute rendered', ms.className === 'light');
check('MaybeSignal.get bare child rendered', ms.textContent.includes('Ada'));
Signal.set(Demo.theme, 'dark');
Signal.set(Demo.name, 'Bo');
check('MaybeSignal.get attribute updates', document.querySelector('#maybe-signal').className === 'dark');
check('MaybeSignal.get bare child updates', document.querySelector('#maybe-signal').textContent.includes('Bo'));
check('MaybeSignal leaf kept element identity', document.querySelector('#maybe-signal').__marker === 'MS');

// --- A reactive helper behind a same-file module -----------------------------
console.log('same-file module helper is a tracked read:');
Signal.set(Demo.count, 2);
const mh = mount(() => Demo.ModuleHelper.make({}));
mh.__marker = 'MH';
check('module helper bare child rendered', mh.textContent.includes('4'));
check('module helper attribute rendered', mh.className === 'positive');
Signal.set(Demo.count, 0);
check('module helper bare child updates', document.querySelector('#module-helper').textContent.trim() === '0');
check('module helper attribute updates', document.querySelector('#module-helper').className === 'zero');
check('module helper kept element identity', document.querySelector('#module-helper').__marker === 'MH');

// --- Hidden reads: what detection cannot follow, reported at runtime ---------
// `Store` is another file, so the ppx sees only a call it cannot resolve. The
// leaf is wrapped in `View.probe`, which evaluates it inside a throwaway
// computed and reports it if that computed subscribed to anything.
console.log('hidden reads (an unresolvable call that does read a signal):');
const hidden = mount(() => Demo.Hidden.make({}));
check('hidden read still renders its initial value', hidden.textContent.includes('4'));
check('hidden read attribute still renders', hidden.className === 'tone-calm');
check('hidden read reported with its source location', warnings.some((w) => w.includes('Demo.res:525:54')));
check('hidden read attribute reported', warnings.some((w) => w.includes('Demo.res:525:32')));
check('warning names the fix', warnings.some((w) => w.includes('() => ...')));

// This is precisely what the warning is for: the leaf is frozen at its first
// value. Detection cannot fix it, so it has to say so.
Signal.set(Store.waiting, 9);
check('hidden read is indeed frozen (the failure the warning describes)', document.querySelector('#hidden-read').textContent.includes('4'));

const hiddenBranch = mount(() => Demo.HiddenBranch.make({}));
check('hidden condition renders a branch', hiddenBranch.querySelector('#hb-idle') !== null);
check('hidden condition reported', warnings.some((w) => w.includes('Demo.res:534:11')));

// Only once per site, however many times the component mounts.
const repeats = warnings.filter((w) => w.includes('Demo.res:525:54')).length;
mount(() => Demo.Hidden.make({}));
check('each site is reported once, not per render', warnings.filter((w) => w.includes('Demo.res:525:54')).length === repeats);

// --- ...and silent when there is nothing to report ---------------------------
// An unresolvable call is not evidence of a read. Probing decides by what the
// evaluation actually subscribed to, so a false positive is impossible.
console.log('probe stays silent when nothing is read:');
const quiet = warnings.length;
const clean = mount(() => Demo.HiddenClean.make({}));
check('unresolvable-but-static bare child renders', clean.textContent.includes('42'));
check('unresolvable-but-static attribute renders', clean.className === 'row!');
check('no warning for a call that reads nothing', warnings.length === quiet);
// Case 25 (PeekShadow) is probed too: `Signal.peek` registers no dependency, so
// a deliberate one-shot peek must not be reported either.
check('no warning for a deliberate peek-based helper', !warnings.some((w) => w.includes('Demo.res:357')));
check('no warning from any other case', warnings.every((w) => /Demo\.res:(525|534):/.test(w)));

console.warn = realWarn;

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
