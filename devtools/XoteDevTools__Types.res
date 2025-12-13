// Types for XoteDevTools

// Unique identifier for signals/observers
type id = string

// Type of tracked item
type itemType =
  | Signal
  | Computed
  | Effect

// Tracked signal/observer metadata
type trackedItem = {
  id: id,
  itemType: itemType,
  label: option<string>,
  createdAt: float,
  getValue: option<unit => string>, // Function to get current value as string
  disposed: bool, // Whether this item has been disposed
}

// Dependency relationship
type dependency = {
  observerId: id, // The computed/effect that depends on something
  signalId: id, // The signal it depends on
}

// Update event in timeline
type updateEvent = {
  id: string,
  timestamp: float,
  itemId: id,
  itemLabel: option<string>,
  oldValue: option<string>,
  newValue: string,
  triggerCount: int, // How many observers were triggered
}

// Filter state
type filter = {
  searchTerm: string,
  itemTypes: array<itemType>,
}

// Tab state
type tab =
  | Registry
  | Timeline
  | Graph
