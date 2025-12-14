// Update Timeline Tracking
open XoteDevTools__Types

// Global timeline state - using signals for reactivity
let eventsSignal = Signals.Signal.make([], ~name="DevTools.Timeline.events")
let maxEvents = ref(100) // Keep last 100 events
let nextEventId = ref(0)

// Export signal for direct access by UI
let getEventsSignal = () => eventsSignal

// Generate unique event ID
let generateEventId = () => {
  let id = nextEventId.contents
  nextEventId := id + 1
  `event_${Int.toString(id)}`
}

// Log an update event
let logUpdate = (~itemId, ~itemLabel=?, ~oldValue=?, ~newValue, ~triggerCount=0, ()) => {
  let event = {
    id: generateEventId(),
    timestamp: Date.now(),
    itemId,
    itemLabel,
    oldValue,
    newValue,
    triggerCount,
  }

  // Add to front of array (newest first)
  Signals.Signal.update(eventsSignal, evts => {
    let newEvents = Array.concat([event], evts)

    // Keep only maxEvents
    if newEvents->Array.length > maxEvents.contents {
      newEvents->Array.slice(~start=0, ~end=maxEvents.contents)
    } else {
      newEvents
    }
  })
}

// Get all events (newest first)
let getEvents = () => Signals.Signal.get(eventsSignal)

// Get events for a specific item
let getEventsFor = itemId => {
  Signals.Signal.get(eventsSignal)->Array.filter(event => event.itemId == itemId)
}

// Clear timeline
let clear = () => {
  Signals.Signal.set(eventsSignal, [])
  nextEventId := 0
}

// Set max events to keep
let setMaxEvents = max => {
  maxEvents := max
  // Trim if needed
  Signals.Signal.update(eventsSignal, evts => {
    if evts->Array.length > max {
      evts->Array.slice(~start=0, ~end=max)
    } else {
      evts
    }
  })
}

// Filter events by search term and item types
let filterEvents = (events: array<updateEvent>, ~searchTerm: string, ~itemTypes: array<itemType>) => {
  events->Array.filter(event => {
    // Filter by search term
    let searchMatch = if searchTerm == "" {
      true
    } else {
      let term = searchTerm->String.toLowerCase
      let labelMatch = switch event.itemLabel {
      | Some(label) => label->String.toLowerCase->String.includes(term)
      | None => false
      }
      let idMatch = event.itemId->String.toLowerCase->String.includes(term)
      let valueMatch =
        event.newValue->String.toLowerCase->String.includes(term) ||
        switch event.oldValue {
        | Some(old) => old->String.toLowerCase->String.includes(term)
        | None => false
        }

      labelMatch || idMatch || valueMatch
    }

    // Filter by item type
    let typeMatch = if itemTypes->Array.length == 0 {
      true
    } else {
      // Look up the item type from Registry
      switch XoteDevTools__Registry.getItem(event.itemId) {
      | Some(item) => itemTypes->Array.includes(item.itemType)
      | None => true // Include events for items that no longer exist
      }
    }

    searchMatch && typeMatch
  })
}
