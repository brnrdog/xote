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
  'data: Primitive_option.some(() =>',
  '`data` is an `Obj.t` expanded entry-wise by the runtime; a thunk in that ' +
  'position does not typecheck (a `Dict.fromArray` value used to be thunked ' +
  'into exactly that no-location error), and objectEntries over a function ' +
  'would drop every data-* attribute. Entries carry their own reactivity.');

has('a Dict-shaped data value reaches the prop unwrapped', demo,
  'data: Primitive_option.some(Object.fromEntries(',
  'The shape that used to be thunked. It is the call, not the object literal, ' +
  'that looked like an eager read worth deferring, so `data` needs the case ' +
  'that is a call to stay pinned — the literal one cannot regress this way.');

lacks('the data object is not probed', demo,
  'data: Primitive_option.some(View$Xote.probe',
  'An object-literal `data` value used to be probed as an unresolvable leaf. ' +
  'Like `attrs`, `data` is a container whose entries carry their own ' +
  'reactivity, so the container itself is never a scalar leaf to report.');

has('an eager read in a data entry stays a one-shot read', demo,
  'theme: Signal$Xote.get(hatchData)',
  'The read is an ordinary argument evaluation; what must not happen is the ' +
  'object being wrapped or probed as a whole.');


/* The emitted code for one component, so an assertion can say "in this
   component" rather than "somewhere in the file" — `Signal.get(name)` is
   legitimately emitted by a dozen other cases. */
const fn = (src, name) => {
  /* a component in a submodule is emitted as `function Demo$Name(props)` */
  const start = Math.max(src.indexOf(`function Demo$${name}(`), src.indexOf(`function ${name}(`));
  if (start < 0) return '';
  const next = [src.indexOf('\nfunction ', start + 1), src.indexOf('\nlet ', start + 1)].filter((i) => i > 0);
  return src.slice(start, next.length ? Math.min(...next) : undefined);
};
/* Whitespace-insensitive, for shapes ReScript wraps across lines. */
const compact = (s) => s.replace(/\s+/g, ' ');

console.log('\nsignal-typed values: a signal-typed name inside a leaf is a read');
const sp = compact(fn(demo, 'SignalProps'));
has('a derived expression over a Signal.t prop becomes a reactive attribute', sp,
  'class: () => [ Signal$Xote.get(propA), propB ].join(", ")',
  'The headline case. `[propA, propB]->Array.join(", ")` mentions a signal-typed ' +
  'name, so it reads it and is thunked; without the rewrite it is a type error.');
has('a bare Signal.t child becomes an explicit reactive read', sp,
  'View$Xote.child(() => Signal$Xote.get(propA))',
  'Previously `View$Xote.child(propA)` worked only because the runtime ' +
  'duck-types a signal; the read is now explicit and type-checked.');
has('a hyphenated attribute is routed into attrs with a reactive read', sp,
  'attrs: [[ "data-hidden", () => Signal$Xote.get(propC) ]]',
  '`data-hidden={propC}` has no typed prop; the ppx moves it into the `attrs` ' +
  'escape hatch, where the runtime stringifies the boolean to "true"/"false".');
has('a plain string prop stays a static attribute', sp,
  'class: propB',
  'Only signal-typed names are reads; a string prop is a value.');
has('a plain string prop stays a static child', sp,
  'View$Xote.child(propB)',
  'Same: no thunk, no computed, for a value that cannot change.');

const sf = compact(fn(demo, 'SignalForms'));
has('a boolean attribute over a Signal.t<bool> prop is a reactive read', sf,
  'hidden: () => Signal$Xote.get(open_)',
  'The bool goes through the runtime\'s boolean-attribute path (add/remove).');
has('Signal.peek on a signal-typed name is left alone', sf,
  'title: Signal$Xote.peek(name)',
  'A signal-aware callee receives the signal itself; rewriting its argument ' +
  'would type-fail (`peek` wants a `Signal.t`, not a string).');
lacks('an explicit read is never read twice', sf,
  'Signal$Xote.get(Signal$Xote.get(',
  '`name->Signal.get` already reads; a second wrap would pass a string to ' +
  '`Signal.get` and fail to compile.');
has('a bare signal condition is read and the branch tracked', sf,
  'View$Xote.tracked(() => { if (Signal$Xote.get(open_))',
  '`{if open_ {…}}` with `open_: Signal.t<bool>` selects a branch by a signal, ' +
  'so it needs the tracked scope the visible-read rule already emits.');
has('a pipe into a value-taking function derefs its subject', sf,
  'Signal$Xote.get(name).toUpperCase()',
  '`name->String.toUpperCase` reaches the ppx as an operator application; the ' +
  'subject is the callee\'s first argument and gets the same rule as `f(name)`.');

const mp = compact(fn(demo, 'MaybeProp'));
has('a MaybeSignal.t prop reads through MaybeSignal.get', mp,
  'MaybeSignal$Xote.get(label)',
  'The wrapper is read with its own `get`, so a Static one renders once and a ' +
  'Reactive one subscribes — `View.child` cannot duck-type the wrapper.');

const ks = compact(fn(demo, 'KeepsSignal'));
has('a user-component prop still receives the signal itself', ks,
  'count: passedCount',
  'User-component props are never rewritten: passing the signal is how a prop ' +
  'becomes reactive, and the child reads it in its own leaf.');
has('an attrs escape-hatch entry is left as written', ks,
  'attrs: [[ "data-name", passedName ]]',
  'The entries carry their own reactivity at runtime; the container is not a leaf.');
lacks('an event handler body is not rewritten', ks,
  'Signal$Xote.update(Signal$Xote.get(',
  'A handler is a lambda: deferred code is the user\'s and reads what it reads.');

const sh = compact(fn(demo, 'Shadowing'));
lacks('a render-callback parameter shadows a same-named signal', sh,
  'Signal$Xote.get(name)',
  'The file has `let name = Signal.make(…)`; inside `render={name => …}` the ' +
  'name is the row and must not be read as the signal.');
lacks('a local let shadows a same-named signal', sh,
  'Signal$Xote.get(count)',
  '`let count = 5` rebinds the name to a plain value.');

const os = compact(fn(demo, 'OptionalSignal'));
lacks('an optional Signal.t prop without a default is not read', os,
  'Signal$Xote.get(maybe)',
  '`~maybe: Signal.t<int>=?` is an `option<Signal.t<int>>` in the body.');


console.log('\nsignal-typed values: which callees get the value');
const ca = compact(fn(demo, 'Callees'));
has('a callback inside a leaf reads the signal', ca,
  't + "-" + Signal$Xote.get(name)',
  'A lambda with a real parameter is run by its callee while the leaf is ' +
  'evaluated; only `() => …` is deferred.');
has('a local helper with a value parameter gets the value', ca,
  'greet(Signal$Xote.get(name))',
  '`greet` uses `who` in a template string, so it evidently takes a value.');
has('a local helper whose parameter goes to Signal.peek gets the signal', ca,
  '() => tone(count))',
  'The body hands `s` to `Signal.peek`, so the parameter is a signal; the ' +
  'call is left alone (it is a one-shot peek, so not thunked either).');
has('a local helper with an annotated Signal.t parameter gets the signal', ca,
  '() => MaybeSignal$Xote.reactive(count))',
  'The annotation is the evidence.');
has('a cross-module helper is left exactly as written', ca,
  'Store.wrap(count)',
  'The ppx cannot see `Store.wrap`; rewriting its argument would break code ' +
  'that compiles today. The call is probed, as before.');
has('a Signal.t constraint hands over the signal', ca,
  'Store.describe(name)',
  '`(name: Signal.t<string>)` is the typed opt-out; the constraint itself ' +
  'compiles away.');
const ou = compact(fn(demo, 'OptionalUnwrap'));
has('a Some(count) payload over an optional signal prop is read', ou,
  'View$Xote.child(() => Signal$Xote.get(count$1))',
  'The optional prop is an option; its `Some` payload is the signal.');
has('a Some(label) payload over an optional MaybeSignal prop is read', ou,
  'MaybeSignal$Xote.get(label)',
  'Same, through the wrapper\'s own get.');
lacks('the optional prop itself is never read', ou,
  'Signal$Xote.get(props.count',
  'Reading an option as a signal would be a type error.');
const hm = compact(fn(demo, 'HyphenMerge'));
has('relocated entries go before the user\'s attrs so attrs wins', hm,
  '[ "data-tone", "relocated" ], [ "data-tone", "explicit" ]',
  '`attrs` is the documented override; the runtime keeps the last entry per key.');

const es = compact(fn(demo, 'ExternalSignal'));
has('a bare cross-module signal is left to the runtime', es,
  'View$Xote.child(Store.waiting)',
  'The ppx cannot see Store.res, so `Store.waiting` is not a signal-typed name; ' +
  'the runtime recognises the signal by shape, as it always did.');
has('an annotated in-file alias of it is read', es,
  'Signal$Xote.get(Store.waiting) > 4',
  '`let waiting: Signal.t<int> = Store.waiting` tells the ppx what it is; ' +
  'ReScript inlines the alias in the output.');

console.log('\nthe % signal mark: says it, instead of inferring it');
const mk = compact(fn(demo, 'Marked'));
has('a marked name becomes a read and the leaf is thunked', mk,
  'class: () => Signal$Xote.get(theme)',
  'The mark is rewritten before anything else runs, so from there it is an ' +
  'ordinary visible read and the existing rules thunk the leaf.');
has('a marked cross-module signal is read', mk,
  'Signal$Xote.get(Store.tone2)',
  'This is the case inference cannot reach: the ppx never sees Store.res, but ' +
  'the mark needs no type knowledge.');
has('a marked record field is read', mk,
  'Signal$Xote.get(sigilStore.count)',
  'A dotted mark whose segments are lowercase is a field path, not a module ' +
  'path — `%store.count` must not compile to a lookup in a module named store.');
has('a marked scrutinee tracks its switch', mk,
  'View$Xote.tracked(',
  'Marking the scrutinee makes the structural swap reactive, with the branch ' +
  'leaves still decomposed on their own.');
lacks('an unmarked value is left static', mk,
  'Signal$Xote.get(propB)',
  'The mark is what distinguishes reactive from static; marking nothing must ' +
  'change nothing.');
const mw = compact(fn(demo, 'MarkedWrapper'));
has('a marked MaybeSignal prop reads through MaybeSignal.get', mw,
  'MaybeSignal$Xote.get(label)',
  'The ppx knows this prop is a wrapper, so the mark reads it with the ' +
  'wrapper\'s own get rather than Signal.get.');
has('ReScript\'s own extensions are left alone', demo,
  'function () { return "raw" }',
  '`%raw` and friends are extensions too; only a payload-free value path is a ' +
  'signal mark.');

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
