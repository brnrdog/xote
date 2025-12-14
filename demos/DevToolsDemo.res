// DevTools Demo - Example usage of XoteDevTools
open Xote__Component
open Xote__JSX

let app = () => {
  // Create some signals and track them
  let count = XoteDevTools.trackSignal(
    Signals.Signal.make(0),
    ~label="count",
    ~toString=n => Int.toString(n),
  )

  let doubled = XoteDevTools.trackComputed(
    Signals.Computed.make(() => Signals.Signal.get(count) * 2),
    ~label="doubled",
    ~toString=n => Int.toString(n),
  )

  let message = XoteDevTools.trackSignal(
    Signals.Signal.make("Hello"),
    ~label="message",
    ~toString=x => x,
  )

  let isActive = XoteDevTools.trackSignal(
    Signals.Signal.make(false),
    ~label="isActive",
    ~toString=b => b ? "true" : "false",
  )

  // Track an effect
  let _ = XoteDevTools.trackEffect(~label="logger", () => {
    Console.log(`Count is now: ${Signals.Signal.get(count)->Int.toString}`)
    None
  })

  // Initialize global devtools (allows window.XoteDevTools.open() in console)
  XoteDevTools.initGlobal()

  <div style="padding: 40px; font-family: system-ui, -apple-system, sans-serif; max-width: 600px; margin: 0 auto;">
    <h1 style="margin-bottom: 24px;"> {text("XoteDevTools Demo")} </h1>
    <div style="background: #f5f5f5; padding: 20px; border-radius: 8px; margin-bottom: 24px;">
      <h2 style="margin-top: 0; font-size: 18px;"> {text("Signals")} </h2>
      <div style="display: grid; gap: 12px;">
        <div>
          <strong> {text("Count:")} </strong>
          {textSignal(() => ` ${Signals.Signal.get(count)->Int.toString}`)}
        </div>
        <div>
          <strong> {text("Doubled:")} </strong>
          {textSignal(() => ` ${Signals.Signal.get(doubled)->Int.toString}`)}
        </div>
        <div>
          <strong> {text("Message:")} </strong>
          {textSignal(() => ` ${Signals.Signal.get(message)}`)}
        </div>
        <div>
          <strong> {text("Active:")} </strong>
          {textSignal(() => ` ${Signals.Signal.get(isActive) ? "Yes" : "No"}`)}
        </div>
      </div>
    </div>
    <div style="display: flex; flex-direction: column; gap: 12px; margin-bottom: 24px;">
      <button
        onClick={_ => Signals.Signal.update(count, n => n + 1)}
        style="padding: 12px 24px; background: #007acc; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
        {text("Increment Count")}
      </button>
      <button
        onClick={_ => Signals.Signal.update(count, n => n - 1)}
        style="padding: 12px 24px; background: #c00; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
        {text("Decrement Count")}
      </button>
      <button
        onClick={_ => Signals.Signal.set(message, "Updated at " ++ Date.now()->Float.toString)}
        style="padding: 12px 24px; background: #0a0; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
        {text("Update Message")}
      </button>
      <button
        onClick={_ => Signals.Signal.update(isActive, b => !b)}
        style="padding: 12px 24px; background: #f80; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 500;">
        {text("Toggle Active")}
      </button>
    </div>
    <div style="border-top: 2px solid #ddd; padding-top: 24px;">
      <button
        onClick={_ => XoteDevTools.openDevTools()}
        style="padding: 16px 32px; background: #2d2d2d; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 16px; font-weight: 600; width: 100%;">
        {text("🔍 Open DevTools")}
      </button>
      <div style="margin-top: 12px; color: #666; font-size: 14px; text-align: center;">
        {text("Or press F12 and type: ")}
        <code style="background: #f0f0f0; padding: 2px 6px; border-radius: 3px;">
          {text("XoteDevTools.open()")}
        </code>
      </div>
    </div>
  </div>
}

// Mount the app
@val @scope("document") external getElementById: string => Null.t<Dom.element> = "getElementById"

switch getElementById("root")->Null.toOption {
| Some(root) => mount(app(), root)
| None => Console.error("Root element not found")
}
