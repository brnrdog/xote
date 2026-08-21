// Golden assertions on the JavaScript the ppx makes ReScript emit.
//
// verify.mjs proves *behaviour*: leaves are fine-grained, elements keep their
// identity across a signal change. What it structurally cannot prove is
// *reach* — JSX the traversal never visits still compiles and still renders,
// only statically, and without even a `View.probe` to report it. A runtime test
// mounts that markup and sees correct initial output, so it passes.
//
// That blind spot is how the same bug shipped three times: "an expression that
// ends up in node position was not reached by the traversal" (untracked
// control-flow branches, then render callbacks, then container-bound
// bindings). These assertions look at the emitted code instead, so a leaf that
// silently stayed static fails the build.
//
// Deliberately *not* full-file snapshots: those churn on every ReScript codegen
// change and teach you nothing when they break. Each assertion below names one
// binding and one property, and every positive has a matching negative — that a
// leaf became reactive is only half the claim; the other half is that static
// things stayed static.
//
//   npm run build && npm run golden
import { readFileSync } from 'node:fs';

/* A missing emitted file means the ReScript build did not produce it — usually
   because it failed to compile. Say that, rather than dying in readFileSync
   with an ENOENT stack that points at this script instead of at the build. */
const emitted = (name) => {
  try {
    return readFileSync(new URL(`./src/${name}.res.mjs`, import.meta.url), 'utf8');
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
    console.error(
      `\ngolden: src/${name}.res.mjs was not emitted, so there is nothing to assert on.\n` +
      `Run \`npm run build\` in ppx/example and fix the compile error first.\n` +
      `(A bare {…} child failing with "This has type: string" is the traversal\n` +
      ` not reaching that position — the loud half of the bug these tests guard.)`,
    );
    process.exit(1);
  }
};

const golden = emitted('Golden');
const demo = emitted('Demo');

let pass = 0;
const failures = [];

/* `why` is printed on failure: a golden test nobody can interpret is worse than
   no golden test, because the tempting fix is to update the expectation. */
const has = (name, src, needle, why) => {
  if (src.includes(needle)) { pass++; console.log('  ✓', name); }
  else { failures.push({ name, why, expected: `to contain: ${needle}` }); console.log('  ✗', name); }
};

const lacks = (name, src, needle, why) => {
  if (!src.includes(needle)) { pass++; console.log('  ✓', name); }
  else { failures.push({ name, why, expected: `NOT to contain: ${needle}` }); console.log('  ✗', name); }
};

console.log('\ntraversal reach: JSX one container down from its binding');
console.log('(each of these compiled to a frozen attribute, with no probe, before the fix)');

has('array-bound JSX gets a reactive attribute', golden,
  'class: () => Signal$Xote.get(themeArray)',
  'JSX inside `let rows = [<li …/>]` is node position. If this is a bare ' +
  '`Signal$Xote.get(themeArray)` the traversal stopped at the binding again.');

has('option-bound JSX gets a reactive attribute', golden,
  'class: () => Signal$Xote.get(themeOption)',
  'JSX inside `Some(<h1 …/>)` is node position, same as an array element.');

has('tuple-bound JSX gets a reactive attribute', golden,
  'class: () => Signal$Xote.get(themeTuple)',
  'JSX inside a tuple is node position too.');

has('JSX in a nested non-render lambda gets a reactive attribute', golden,
  'class: () => Signal$Xote.get(themeLambda)',
  'The binding body is `Array.map(…)`, not JSX, so is_render_callback does not ' +
  'fire — the walker still has to descend into the inner lambda.');

has('directly-bound JSX stays reactive', golden,
  'class: () => Signal$Xote.get(themeDirect)',
  'The case that always worked. If this breaks, the fix regressed the base case ' +
  'rather than extending it.');

console.log('\nnegative controls: what must NOT be rewritten');

has('a static attribute stays a plain string', golden,
  'class: "static-class"',
  'Nothing reads a signal here, so thunking it would allocate a computed ' +
  'attribute for a constant.');

lacks('a static attribute is not thunked', golden,
  'class: () => "static-class"',
  'An over-eager walker that thunks everything would still pass every positive ' +
  'assertion above. This is what distinguishes "reaches the leaf" from ' +
  '"rewrites indiscriminately".');

lacks('an existing thunk is not double-wrapped', golden,
  '() => () => Signal$Xote.get(themeThunked)',
  '`class={() => Signal.get(x)}` is already reactive. Double-wrapping would ' +
  'make the attribute a function-returning-function and render "() => …" as ' +
  'the attribute value. This is what keeps @xote.component a safe drop-in.');

console.log('\ncore contract (regression guards on the existing behaviour)');

has('bare children are coerced through View.child', golden,
  'View$Xote.child("open")',
  'A bare `{"open"}` child in element position is coerced at runtime rather ' +
  'than needing a <View.Text> wrapper.');

has('control flow lowers to View.tracked', golden,
  'View$Xote.tracked(',
  'An if/switch in node position whose condition reads a signal is the one ' +
  'place a structural swap needs a tracked scope.');

lacks('a tracked branch does not thunk its own static leaf', golden,
  'class: () => "open"',
  'Leaves inside a branch are decomposed on their own merits; a static class ' +
  'inside a tracked branch stays static.');

has('an unresolvable call is wrapped in View.probe with its source location', demo,
  'View$Xote.probe("Demo.res:525:32", () => Store.themeClass())',
  'The hidden-read safety net. If the site string loses its line:col the ' +
  'warning stops naming where to look, which is most of its value.');

has('a user-component scalar prop is left as a one-shot read', demo,
  'label: Signal$Xote.get(name)',
  'Props land in the component\'s typed props record; thunking one would ' +
  'change its type and fail to compile with a baffling error.');

console.log('\nescape hatches: props that cannot hold a thunk');

lacks('the attrs escape hatch is not thunked', demo,
  'attrs: () =>',
  '`attrs` is an `array<(string, \'a)>`; a thunk in that position does not ' +
  'typecheck, and the error names no file or line because the emitted thunk ' +
  'has no location. Entries carry their own reactivity instead.');

lacks('an event handler is not thunked', demo,
  'onClick: () =>',
  'A handler is a `Dom.event => unit`. Thunking a handler built by a factory ' +
  'that reads a signal made the build fail with "This pattern matches values ' +
  'of type unit but ... Dom.event".');

has('an eager read in a handler argument stays a one-shot read', demo,
  'Signal$Xote.get(hatchStep)',
  'The read is an ordinary argument evaluation, like any other call the ppx ' +
  'leaves alone — what must not happen is the whole handler being wrapped.');

lacks('the data object is not thunked', demo,
  'data: () =>',
  '`data` is an `Obj.t` expanded entry-wise by the runtime; a thunk in that ' +
  'position does not typecheck (a `Dict.fromArray` value used to be thunked ' +
  'into exactly that no-location error), and objectEntries over a function ' +
  'would drop every data-* attribute. Entries carry their own reactivity.');

lacks('the data object is not probed', demo,
  'data: Primitive_option.some(View$Xote.probe',
  'An object-literal `data` value used to be probed as an unresolvable leaf. ' +
  'Like `attrs`, `data` is a container whose entries carry their own ' +
  'reactivity, so the container itself is never a scalar leaf to report.');

has('an eager read in a data entry stays a one-shot read', demo,
  'theme: Signal$Xote.get(hatchData)',
  'The read is an ordinary argument evaluation; what must not happen is the ' +
  'object being wrapped or probed as a whole.');

console.log(`\n${pass} passed, ${failures.length} failed`);

if (failures.length > 0) {
  console.log('\nfailures:');
  for (const f of failures) {
    console.log(`\n  ✗ ${f.name}`);
    console.log(`    expected ${f.expected}`);
    console.log(`    why this matters: ${f.why}`);
  }
  process.exit(1);
}
