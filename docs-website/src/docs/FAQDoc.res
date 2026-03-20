open Xote

let content = () => {
  <div>
    <h2 id="signal-lifecycle">
      {Component.text("Are signals created inside components disposed when the component is removed?")}
    </h2>
    <p>
      <strong> {Component.text("Short answer:")} </strong>
      {Component.text(" Plain signals (")}
      <code> {Component.text("Signal.make()")} </code>
      {Component.text(") don't need explicit disposal. They are regular data objects that become eligible for garbage collection once nothing references them.")}
    </p>
    <p>
      {Component.text("When a component's DOM is removed, Xote's owner system disposes all effects and computeds attached to those elements. This severs the bidirectional links between signals and their subscribers. Once no effects or computeds reference the signal, it becomes unreachable and the garbage collector reclaims it.")}
    </p>
    <h3 id="what-the-owner-system-tracks"> {Component.text("What the owner system tracks")} </h3>
    <p>
      {Component.text("Each DOM element can have an ")}
      <em> {Component.text("owner")} </em>
      {Component.text(" (stored via ")}
      <code> {Component.text("__xote_owner__")} </code>
      {Component.text(") that tracks two things:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Effect disposers")} </strong>
        {Component.text(" \u2014 calling ")}
        <code> {Component.text("dispose()")} </code>
        {Component.text(" runs cleanup callbacks and unlinks the effect from all its signal dependencies")}
      </li>
      <li>
        <strong> {Component.text("Computed references")} </strong>
        {Component.text(" \u2014 calling ")}
        <code> {Component.text("Computed.dispose()")} </code>
        {Component.text(" unlinks the computed from its upstream signals")}
      </li>
    </ul>
    <p>
      {Component.text("Plain signals are ")}
      <strong> {Component.text("not")} </strong>
      {Component.text(" tracked by the owner system because they don't need to be. They hold no subscriptions to other reactive nodes.")}
    </p>
    <h3 id="why-signals-dont-leak"> {Component.text("Why signals don't leak")} </h3>
    <p>
      {Component.text("Consider a typical component:")}
    </p>
    <pre>
      <code>
        {Component.text(`let myComponent = () => {
  let count = Signal.make(0)

  let doubled = Computed.make(() => Signal.get(count) * 2)

  let disposer = Effect.run(() => {
    Console.log(Signal.get(count))
    None
  })

  <div>
    <p> {Component.reactiveInt(() => Signal.get(doubled))} </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Component.text("+")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <p>
      {Component.text("When the component's DOM is removed:")}
    </p>
    <ol>
      <li>
        {Component.text("The owner disposes the effect \u2192 ")}
        <code> {Component.text("clearDeps(observer)")} </code>
        {Component.text(" unlinks it from ")}
        <code> {Component.text("count")} </code>
        {Component.text("'s subscriber list")}
      </li>
      <li>
        {Component.text("The owner disposes the computed \u2192 unlinks ")}
        <code> {Component.text("doubled")} </code>
        {Component.text(" from ")}
        <code> {Component.text("count")} </code>
        {Component.text("'s subscriber list")}
      </li>
      <li>
        <code> {Component.text("count")} </code>
        {Component.text("'s subscriber list is now empty (")}
        <code> {Component.text("first: None, last: None")} </code>
        {Component.text(")")}
      </li>
      <li>
        {Component.text("Nothing references ")}
        <code> {Component.text("count")} </code>
        {Component.text(" anymore \u2192 garbage collected")}
      </li>
    </ol>
    <h3 id="when-signals-can-leak"> {Component.text("When signals can leak")} </h3>
    <p>
      {Component.text("A signal will stay alive if something outside the component still references it. Common cases:")}
    </p>
    <ul>
      <li>
        {Component.text("Stored in a module-level variable")}
      </li>
      <li>
        {Component.text("Captured in a closure passed to an external callback (e.g., ")}
        <code> {Component.text("setTimeout")} </code>
        {Component.text(", ")}
        <code> {Component.text("addEventListener")} </code>
        {Component.text(") that wasn't cleaned up")}
      </li>
      <li>
        {Component.text("Passed to another component that outlives this one")}
      </li>
    </ul>
    <p>
      {Component.text("These are standard JavaScript garbage collection considerations, not Xote-specific issues. The fix is to ensure external references are cleaned up, typically via effect cleanup callbacks:")}
    </p>
    <pre>
      <code>
        {Component.text(`Effect.run(() => {
  let timerId = setInterval(() => {
    Signal.update(count, n => n + 1)
  }, 1000)

  Some(() => clearInterval(timerId))
})`)}
      </code>
    </pre>

    <h2 id="effect-cleanup">
      {Component.text("Do I need to manually dispose effects inside components?")}
    </h2>
    <p>
      <strong> {Component.text("No.")} </strong>
      {Component.text(" Effects created during component rendering are automatically tracked by the owner system and disposed when the component's DOM elements are removed. You only need to manually dispose effects created outside of a component context (e.g., at the module level).")}
    </p>

    <h2 id="computed-auto-disposal">
      {Component.text("When are computed values auto-disposed?")}
    </h2>
    <p>
      {Component.text("Computed values have two disposal mechanisms:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Owner-based disposal:")} </strong>
        {Component.text(" When a component's DOM is removed, its owner disposes all tracked computeds.")}
      </li>
      <li>
        <strong> {Component.text("Auto-disposal:")} </strong>
        {Component.text(" When a computed loses all its subscribers (no effects or other computeds reading it), it is automatically disposed. This means standalone computeds that are only read once and never observed will clean themselves up.")}
      </li>
    </ul>

    <h2 id="signal-fragment-vs-keyed-list">
      {Component.text("When should I use keyedList vs SignalFragment?")}
    </h2>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("keyedList")} </code>
      {Component.text(" when rendering a list of items that have stable identities (e.g., database records with IDs). It preserves DOM elements across re-renders and only updates what changed.")}
    </p>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("SignalFragment")} </code>
      {Component.text(" (or ")}
      <code> {Component.text("Component.list")} </code>
      {Component.text(") for simple lists where items don't have stable keys or where the entire list is small enough that re-rendering everything is acceptable.")}
    </p>

    <h2 id="why-no-batching">
      {Component.text("Why don't signal updates batch automatically?")}
    </h2>
    <p>
      {Component.text("Xote's underlying reactive system (rescript-signals) uses synchronous scheduling. When you call ")}
      <code> {Component.text("Signal.set()")} </code>
      {Component.text(", all dependent effects and computeds run immediately. You can use ")}
      <code> {Component.text("Signal.batch()")} </code>
      {Component.text(" to group multiple updates so observers only run once after all updates are applied:")}
    </p>
    <pre>
      <code>
        {Component.text(`Signal.batch(() => {
  Signal.set(firstName, "Jane")
  Signal.set(lastName, "Smith")
  // Effects observing either signal run only once, after both are set
})`)}
      </code>
    </pre>
  </div>
}
