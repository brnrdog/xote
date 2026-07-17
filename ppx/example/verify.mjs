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
const forms = [
  ['card    (Signal.get direct)',       Demo.card,        '#card',        'Hello, Grace'],
  ['aliased (let g = Signal.get)',      Demo.aliased,     '#aliased',     'Hi, Grace'],
  ['modAlias(module S = Signal)',       Demo.modAliased,  '#mod-aliased', 'Yo, Grace'],
  ['open    (open Signal; get)',        Demo.openAliased, '#open-aliased','Hey, Grace'],
  ['piped   (active->Signal.get)',      Demo.piped,       '#piped',       'Pipe, Grace'],
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

// --- Structural swap via View.tracked, outer element preserved -------------
console.log('panel (structural swap, outer element preserved):');
const panel = mount(Demo.panel);
panel.__pmarker = 'PANEL';
check('initial Loading <span>', panel.querySelector('span') !== null && panel.textContent.includes('Loading'));

Signal.set(Demo.status, { TAG: 'Ready', _0: 'Done!' });
check('swapped to <strong>', panel.querySelector('strong') !== null);
check('shows "Done!"', panel.textContent.includes('Done!'));
check('outer DIV kept identity (only inner region swapped)', panel.__pmarker === 'PANEL');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
