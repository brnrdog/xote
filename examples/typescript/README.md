# Xote TypeScript Example

A Vite TypeScript frontend that consumes Xote through the public `xote/client` entry.

It demonstrates:

- `Signal.make`, `Signal.get`, `Signal.peek`, `Signal.set`, `Signal.update`, and `Signal.batch`
- `Computed.make` for filtered and derived state
- `Effect.run` for a DOM side effect
- `View.signalText`, `View.signalAttr`, and `View.computedAttr`
- `View.eachWithKey` for keyed list rendering
- `Router.init`, `Router.routes`, `Router.link`, and `Router.location`
- `Html` constructors for building UI from TypeScript without ReScript JSX

Routes:

- `/` shows the task list
- `/tasks/:id` shows a task detail view backed by the same signal state

From the repository root:

```bash
npm run build
npm run example:typescript
```

For a production check:

```bash
npm run example:typescript:build
```
