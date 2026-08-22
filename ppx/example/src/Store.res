/* A plain module in *another file*. The ppx only ever sees the call at the use
   site (`Store.waitingCount()`), never this body, so a signal read in here is
   the one form detection cannot follow. Used by Demo's hidden-read cases:
   `waitingCount`/`themeClass`/`isBusy` read signals; `title` does not, and must
   not be reported. */

let waiting = Signal.make(4)
let busy = Signal.make(false)
let tone = Signal.make("calm")

let waitingCount = () => Signal.get(waiting)
let themeClass = () => "tone-" ++ Signal.get(tone)
let isBusy = () => Signal.get(busy)

/* No signal read at all — the probe must stay silent on this one. */
let title = (prefix: string) => prefix ++ "!"
