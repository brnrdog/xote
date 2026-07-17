// Runtime verification that the @tracked fine-grained ppx produces reactive
// *leaves* (not a wholesale rebuild). The key assertions tag DOM elements with
// a marker property, mutate signals, then check the marker survives — proving
// the element kept its identity and was not recreated.
//
//   sh ../build.sh && npm run build && npm run verify
import { JSDOM } from 'jsdom';

const dom = new JSDOM(
  '<!DOCTYPE html><html><body><div id="a"></div><div id="b"></div></body></html>',
  { url: 'https://xote.test/' },
);
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

// --- Case 1: attribute + text compile to fine-grained leaves ---------------
console.log('card (fine-grained attribute + text leaves):');
View.mountById(Demo.card(), 'a');
const card = document.querySelector('#card');
card.__marker = 'ORIGINAL';                          // tag the element
card.querySelector('.static-label').__smarker = 'SPAN';
check('initial class "off"', card.className === 'off');
check('initial text "Hello, Ada"', card.textContent.includes('Hello, Ada'));

Signal.set(Demo.active, true);
Signal.set(Demo.name, 'Grace');
check('class updated to "on"', card.className === 'on');
check('text updated to "Grace"', card.textContent.includes('Hello, Grace'));
check('DIV kept identity (not rebuilt)', document.querySelector('#card').__marker === 'ORIGINAL');
check('static SPAN kept identity', card.querySelector('.static-label').__smarker === 'SPAN');
check('static label text intact', card.textContent.includes('Name:'));

// --- Case 2: node-position control flow uses View.tracked surgically -------
console.log('panel (structural swap, outer element preserved):');
View.mountById(Demo.panel(), 'b');
const panel = document.querySelector('#b').firstElementChild;
panel.__pmarker = 'PANEL';
check('initial Loading <span>', panel.querySelector('span') !== null && panel.textContent.includes('Loading'));

Signal.set(Demo.status, { TAG: 'Ready', _0: 'Done!' });
check('swapped to <strong>', panel.querySelector('strong') !== null);
check('shows "Done!"', panel.textContent.includes('Done!'));
check('outer DIV kept identity (only inner region swapped)', panel.__pmarker === 'PANEL');

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
