@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

type saveEntry = {
  id: int,
  text: string,
}

let draft = Signal.make("")
let saveStatus = Signal.make("Start typing to queue a save")
let savedDrafts: Signal.t<array<saveEntry>> = Signal.make([])
let saveCounter = ref(0)

let handleInput = (evt: Dom.event) => {
  let target: {"value": string} = (evt->Obj.magic)["target"]
  Signal.set(draft, target["value"])
}

Effect.run(() => {
  let currentDraft = Signal.get(draft)->String.trim

  if currentDraft == "" {
    Signal.set(saveStatus, "Start typing to queue a save")
    None
  } else {
    Signal.set(saveStatus, "Saving in 600ms")

    let timeoutId = setTimeout(() => {
      let id = saveCounter.contents
      saveCounter := id + 1
      Signal.set(saveStatus, "Saved")
      Signal.update(savedDrafts, entries => {
        let next = Array.concat([{id, text: currentDraft}], entries)
        Array.slice(next, ~start=0, ~end=4)
      })
    }, 600)

    Some(() => clearTimeout(timeoutId))
  }
})

@jsx.component
let make = () => {
  <div class="effect-autosave-demo">
    <div class="effect-autosave-demo-section">
      <div class="effect-autosave-demo-heading">
        <h3> {Node.text("Auto-save Draft")} </h3>
        <p>
          {Node.text("Each input change re-runs the effect, resets the timer, and only saves the latest draft after the pause.")}
        </p>
      </div>

      <div class="effect-autosave-demo-editor">
        <label class="effect-autosave-demo-label" for_="effect-autosave-input">
          {Node.text("Draft")}
        </label>
        <input
          id="effect-autosave-input"
          type_="text"
          class="effect-autosave-demo-input"
          placeholder="Write a short note..."
          value={() => Signal.get(draft)}
          onInput={handleInput}
        />
      </div>

      <div class="effect-autosave-demo-status-row">
        <span class="effect-autosave-demo-label"> {Node.text("Status")} </span>
        <span class="effect-autosave-demo-status">
          {Node.signalText(() => Signal.get(saveStatus))}
        </span>
      </div>
    </div>

    <div class="effect-autosave-demo-section">
      <div class="effect-autosave-demo-list-head">
        <span class="effect-autosave-demo-label"> {Node.text("Recent saves")} </span>
        <span class="effect-autosave-demo-hint">
          {Node.text("Cleanup cancels any pending save before the next run.")}
        </span>
      </div>

      {Node.signalFragment(
        Computed.make(() => {
          let entries = Signal.get(savedDrafts)
          if Array.length(entries) == 0 {
            [
              <div class="effect-autosave-demo-empty">
                {Node.text("No saves yet. Type, pause, and the latest draft will be recorded here.")}
              </div>,
            ]
          } else {
            [
              <ol class="effect-autosave-demo-list">
                {Node.keyedList(
                  savedDrafts,
                  entry => Int.toString(entry.id),
                  entry =>
                    <li class="effect-autosave-demo-item">
                      <span class="effect-autosave-demo-item-label">
                        {Node.text("Saved draft")}
                      </span>
                      <span class="effect-autosave-demo-item-text"> {Node.text(entry.text)} </span>
                    </li>,
                )}
              </ol>,
            ]
          }
        }),
      )}
    </div>
  </div>
}
