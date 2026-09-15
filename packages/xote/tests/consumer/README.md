# Consumer boundary fixture

This is a throwaway ReScript package that depends on `xote` the way a real
downstream app does. It exists because the public API boundary cannot be checked
from inside the package: `tests/*.res` compile as dev sources of `xote` itself,
so they see whatever the package sees.

`scripts/consumer-boundary-test.mjs` drives it:

1. it stages the *publishable* files (`src/**`, `rescript.json`, `package.json`)
   into a temporary `node_modules/xote`,
2. compiles [`allowed/`](./allowed) and expects success — every file there uses
   only documented API,
3. compiles each file in [`deprecated/`](./deprecated) on its own and expects
   **success with a deprecation warning** — removing any of them would be a
   breaking change, so they have to keep working until the next major,
4. compiles each file in [`forbidden/`](./forbidden) on its own and expects
   **failure** — every file there reaches for an implementation detail.

`forbidden/` is a representative sample, not an exhaustive list: one probe per
*sealing mechanism* (nested module, module alias, plain `let`, upstream
re-export, abstract-type field), plus a control case. Each file says which
mechanism it stands for and what else that covers. The general detector for a
surface that quietly widens is `npm run test:exports`, which snapshots every
public module; these probes exist to stop the specific holes from reopening.

Run it with `npm run test:boundary` (also part of `npm test`).

## Known gap

`rescript.json`'s `sources.public` field has no effect in ReScript 12, so the
internal `Runtime*` modules stay reachable as `Xote.RuntimeDom`, `Xote.RuntimeOwner`
and friends. The fixture therefore does not assert that they are unreachable —
what it does assert is that no *documented* module leaks them, and that the
values inside each documented module are exactly the intended ones.
