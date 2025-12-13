// XoteDevTools - Public API
//
// Usage:
//   1. Track signals, computeds, and effects using the track* functions
//   2. Open the devtools modal with XoteDevTools.openDevTools()
//   3. Close with XoteDevTools.closeDevTools()

// Re-export types
module Types = XoteDevTools__Types

// Global state for modal
let isOpen = Signals.Signal.make(false, ~name="DevTools.isOpen")
let modalContainer: ref<option<Dom.element>> = ref(None)

// DOM helpers
@val @scope("document") external createElement: string => Dom.element = "createElement"
@val @scope("document") external body: Dom.element = "body"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"

// Create modal container if it doesn't exist
let ensureModalContainer = () => {
  switch modalContainer.contents {
  | Some(container) => container
  | None => {
      let container = createElement("div")
      container->setAttribute("id", "xote-devtools-root")
      body->appendChild(container)
      modalContainer := Some(container)
      container
    }
  }
}

// Mount devtools modal
let mountModal = () => {
  let container = ensureModalContainer()
  let modalNode = XoteDevTools__UI.modal(
    ~isOpen,
    ~onClose=() => Signals.Signal.set(isOpen, false),
  )
  Xote__Component.mount(modalNode, container)
}

// Open DevTools
let openDevTools = () => {
  if Signals.Signal.peek(isOpen) == false {
    mountModal()
  }
  Signals.Signal.set(isOpen, true)
}

// Close DevTools
let closeDevTools = () => {
  Signals.Signal.set(isOpen, false)
}

// Toggle DevTools
let toggleDevTools = () => {
  if Signals.Signal.peek(isOpen) {
    closeDevTools()
  } else {
    openDevTools()
  }
}

// Track a signal
let trackSignal = (~label=?, signal: Signals.Signal.t<'a>, ~toString=?) => {
  let getValue = switch toString {
  | Some(fn) => Some(() => fn(Signals.Signal.peek(signal)))
  | None => Some(() => {
      // Try to stringify the value
      let value = Signals.Signal.peek(signal)
      // This is a simple fallback - users should provide toString for complex types
      switch Obj.magic(value) {
      | v if Js.typeof(v) == "string" => v
      | v if Js.typeof(v) == "number" => Float.toString(v)
      | v if Js.typeof(v) == "boolean" => v ? "true" : "false"
      | _ => "[object]"
      }
    })
  }

  let id = XoteDevTools__Registry.registerSignal(~label?, ~getValue?, ())

  // Track updates
  let _ = Signals.Effect.run(() => {
    let newValue = switch getValue {
    | Some(fn) => fn()
    | None => "[no toString]"
    }

    // Log the update (skip initial run)
    if Signals.Signal.peek(signal) !== Obj.magic(undefined) {
      XoteDevTools__Timeline.logUpdate(~itemId=id, ~itemLabel=?label, ~newValue, ())
    }

    None
  })

  signal
}

// Track a computed
let trackComputed = (~label=?, computed: Signals.Signal.t<'a>, ~toString=?) => {
  let getValue = switch toString {
  | Some(fn) => Some(() => fn(Signals.Signal.peek(computed)))
  | None => Some(() => {
      let value = Signals.Signal.peek(computed)
      switch Obj.magic(value) {
      | v if Js.typeof(v) == "string" => v
      | v if Js.typeof(v) == "number" => Float.toString(v)
      | v if Js.typeof(v) == "boolean" => v ? "true" : "false"
      | _ => "[object]"
      }
    })
  }

  let id = XoteDevTools__Registry.registerComputed(~label?, ~getValue?, ())

  // Track updates
  let _ = Signals.Effect.run(() => {
    let newValue = switch getValue {
    | Some(fn) => fn()
    | None => "[no toString]"
    }

    XoteDevTools__Timeline.logUpdate(~itemId=id, ~itemLabel=?label, ~newValue, ())
    None
  })

  computed
}

// Track an effect
let trackEffect = (~label=?, effect: unit => option<unit => unit>) => {
  let id = XoteDevTools__Registry.registerEffect(~label?, ())

  // Wrap the effect to track executions
  let wrappedEffect = () => {
    XoteDevTools__Timeline.logUpdate(
      ~itemId=id,
      ~itemLabel=?label,
      ~newValue="executed",
      (),
    )
    effect()
  }

  Signals.Effect.run(wrappedEffect)
}

// Clear all tracking data
let clear = () => {
  XoteDevTools__Registry.clear()
  XoteDevTools__Timeline.clear()
}

// Export Registry functions for advanced usage
module Registry = {
  let registerSignal = XoteDevTools__Registry.registerSignal
  let registerComputed = XoteDevTools__Registry.registerComputed
  let registerEffect = XoteDevTools__Registry.registerEffect
  let registerDependency = XoteDevTools__Registry.registerDependency
  let clearDependencies = XoteDevTools__Registry.clearDependencies
  let getItems = XoteDevTools__Registry.getItems
  let getItem = XoteDevTools__Registry.getItem
}

// Export Timeline functions for advanced usage
module Timeline = {
  let logUpdate = XoteDevTools__Timeline.logUpdate
  let getEvents = XoteDevTools__Timeline.getEvents
  let setMaxEvents = XoteDevTools__Timeline.setMaxEvents
}

// Export Graph functions for advanced usage
module Graph = {
  let buildGraph = XoteDevTools__Graph.buildGraph
  let detectCycles = XoteDevTools__Graph.detectCycles
  let getRootNodes = XoteDevTools__Graph.getRootNodes
  let getLeafNodes = XoteDevTools__Graph.getLeafNodes
}

// Auto-tracking - automatically track all signals without manual wrapping
module AutoTrack = {
  let enable = XoteDevTools__AutoTrack.enable
  let disable = XoteDevTools__AutoTrack.disable
}

// Make it available globally (optional - for console access)
let initGlobal = () => {
  %raw(`(function() {
    if (typeof window !== 'undefined') {
      window.XoteDevTools = {
        open: () => openDevTools(),
        close: () => closeDevTools(),
        toggle: () => toggleDevTools(),
        clear: () => clear(),
      };
    }
  })()`)
}
