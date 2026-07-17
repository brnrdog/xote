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

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
