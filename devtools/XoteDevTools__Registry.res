// Signal/Observer Registry
open XoteDevTools__Types

// Global state - using signals for reactivity
let itemsSignal = Signals.Signal.make(Dict.make(), ~name="DevTools.Registry.items")
let dependenciesSignal = Signals.Signal.make([], ~name="DevTools.Registry.dependencies")
let versionSignal = Signals.Signal.make(0, ~name="DevTools.Registry.version")
let nextId = ref(0)

// Export signals for direct access by UI
let getItemsSignal = () => itemsSignal
let getDependenciesSignal = () => dependenciesSignal
let getVersionSignal = () => versionSignal

// Increment version to trigger UI updates
let incrementVersion = () => {
  Signals.Signal.update(versionSignal, v => v + 1)
}

// Generate unique ID
let generateId = () => {
  let id = nextId.contents
  nextId := id + 1
  `item_${Int.toString(id)}`
}

// Register a new signal
let registerSignal = (~label=?, ~getValue=?, ()) => {
  let id = generateId()
  let item = {
    id,
    itemType: Signal,
    label,
    createdAt: Date.now(),
    getValue,
    disposed: false,
  }
  Signals.Signal.update(itemsSignal, dict => {
    dict->Dict.set(id, item)
    dict
  })
  id
}

// Register a new computed
let registerComputed = (~label=?, ~getValue=?, ()) => {
  let id = generateId()
  let item = {
    id,
    itemType: Computed,
    label,
    createdAt: Date.now(),
    getValue,
    disposed: false,
  }
  Signals.Signal.update(itemsSignal, dict => {
    dict->Dict.set(id, item)
    dict
  })
  id
}

// Register a new effect
let registerEffect = (~label=?, ()) => {
  let id = generateId()
  let item = {
    id,
    itemType: Effect,
    label,
    createdAt: Date.now(),
    getValue: None,
    disposed: false,
  }
  Signals.Signal.update(itemsSignal, dict => {
    dict->Dict.set(id, item)
    dict
  })
  id
}

// Register a dependency relationship
let registerDependency = (~observerId, ~signalId) => {
  // Check if dependency already exists
  let exists =
    Signals.Signal.peek(dependenciesSignal)->Array.some(dep =>
      dep.observerId == observerId && dep.signalId == signalId
    )

  if !exists {
    Signals.Signal.update(dependenciesSignal, deps =>
      Array.concat(deps, [{observerId, signalId}])
    )
  }
}

// Clear dependencies for an observer (called when re-tracking)
let clearDependencies = observerId => {
  Signals.Signal.update(dependenciesSignal, deps =>
    deps->Array.filter(dep => dep.observerId != observerId)
  )
}

// Get all items
let getItems = () => Signals.Signal.get(itemsSignal)->Dict.valuesToArray

// Get item by ID
let getItem = id => Signals.Signal.get(itemsSignal)->Dict.get(id)

// Get all dependencies
let getDependencies = () => Signals.Signal.get(dependenciesSignal)

// Get dependencies for a specific observer
let getDependenciesFor = observerId => {
  Signals.Signal.get(dependenciesSignal)->Array.filter(dep => dep.observerId == observerId)
}

// Get observers that depend on a signal
let getObserversFor = signalId => {
  Signals.Signal.get(dependenciesSignal)
  ->Array.filter(dep => dep.signalId == signalId)
  ->Array.map(dep => dep.observerId)
}

// Mark an item as disposed
let markAsDisposed = (id: string) => {
  Signals.Signal.update(itemsSignal, dict => {
    switch dict->Dict.get(id) {
    | Some(item) => dict->Dict.set(id, {...item, disposed: true})
    | None => ()
    }
    dict
  })

  // Clear dependencies for this item (observers can't track if disposed)
  clearDependencies(id)

  // Increment version to trigger UI update
  incrementVersion()
}

// Clear all tracked data
let clear = () => {
  Signals.Signal.set(itemsSignal, Dict.make())
  Signals.Signal.set(dependenciesSignal, [])
  nextId := 0
}

// Filter items
let filterItems = (items: array<trackedItem>, ~filter: filter) => {
  items->Array.filter(item => {
    // Filter by type
    let typeMatch =
      filter.itemTypes->Array.length == 0 || filter.itemTypes->Array.includes(item.itemType)

    // Filter by search term
    let searchMatch = if filter.searchTerm == "" {
      true
    } else {
      let term = filter.searchTerm->String.toLowerCase
      switch item.label {
      | Some(label) => label->String.toLowerCase->String.includes(term)
      | None => item.id->String.toLowerCase->String.includes(term)
      }
    }

    typeMatch && searchMatch
  })
}
