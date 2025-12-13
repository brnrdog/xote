# XoteDevTools

A comprehensive debugging and inspection tool for Xote applications. Visualize your signals, computeds, effects, dependency graphs, and update timelines in real-time.

## Features

### 📊 Signal Registry
- View all active signals, computeds, and effects
- See current values in real-time
- Search and filter by name or type
- Type-color coding (Signals: teal, Computeds: yellow, Effects: purple)

### ⏱️ Update Timeline
- Chronological log of all signal updates
- See old → new value transitions
- Track which observers were triggered
- Search through update history

### 🔍 Dependency Graph
- Visualize signal → computed → effect relationships
- See what each observer depends on
- See what signals are used by which observers
- Cycle detection and warnings

## Installation

The devtools are isolated in the `devtools/` directory and don't affect the core Xote library.

## Usage

### Basic Setup

```rescript
open Xote

// Track signals, computeds, and effects
let count = XoteDevTools.trackSignal(
  Signal.make(0),
  ~label="count",
  ~toString=Int.toString,
)

let doubled = XoteDevTools.trackComputed(
  Computed.make(() => Signal.get(count) * 2),
  ~label="doubled",
  ~toString=Int.toString,
)

let _ = XoteDevTools.trackEffect(~label="logger", () => {
  Console.log(`Count: ${Signal.get(count)->Int.toString}`)
  None
})

// Initialize global API (optional)
XoteDevTools.initGlobal()
```

### Opening the DevTools

**Option 1: Programmatically**
```rescript
// Open
XoteDevTools.openDevTools()

// Close
XoteDevTools.closeDevTools()

// Toggle
XoteDevTools.toggleDevTools()
```

**Option 2: From Browser Console**
```javascript
// First call initGlobal() in your app
XoteDevTools.initGlobal()

// Then use from console:
XoteDevTools.open()
XoteDevTools.close()
XoteDevTools.toggle()
XoteDevTools.clear()
```

**Option 3: Add a Button**
```rescript
<button onClick={_ => XoteDevTools.openDevTools()}>
  {Component.text("Open DevTools")}
</button>
```

### Tracking Signals

**Track a signal:**
```rescript
let count = XoteDevTools.trackSignal(
  Signal.make(0),
  ~label="userCount",           // Optional: display name
  ~toString=Int.toString,        // Optional: convert value to string
)
```

**Track a computed:**
```rescript
let doubled = XoteDevTools.trackComputed(
  Computed.make(() => Signal.get(count) * 2),
  ~label="doubledCount",
  ~toString=Int.toString,
)
```

**Track an effect:**
```rescript
let _ = XoteDevTools.trackEffect(~label="sideEffect", () => {
  // Your effect logic
  None
})
```

### Custom toString Functions

For complex types, provide a `toString` function:

```rescript
type user = {name: string, age: int}

let currentUser = XoteDevTools.trackSignal(
  Signal.make({name: "Alice", age: 30}),
  ~label="currentUser",
  ~toString=user => `${user.name} (${Int.toString(user.age)})`,
)

// Arrays
let items = XoteDevTools.trackSignal(
  Signal.make([1, 2, 3]),
  ~label="items",
  ~toString=arr => `[${arr->Array.map(Int.toString)->Array.join(", ")}]`,
)

// Options
let maybeValue = XoteDevTools.trackSignal(
  Signal.make(Some(42)),
  ~label="maybeValue",
  ~toString=opt => switch opt {
    | Some(v) => `Some(${Int.toString(v)})`
    | None => "None"
  },
)
```

## UI Features

### Registry Tab
- **Search**: Filter signals by label or ID
- **Live updates**: Values update in real-time
- **Metadata**: Shows creation time and item ID
- **Color coding**: Different colors for Signal/Computed/Effect types

### Timeline Tab
- **Chronological log**: Newest updates first
- **Value diffs**: Shows old → new value changes
- **Observer counts**: How many observers were triggered
- **Search**: Filter updates by signal name or value
- **Limited history**: Keeps last 100 events (configurable)

### Graph Tab
- **Dependency visualization**: See "depends on" and "used by" relationships
- **Cycle detection**: Warns about circular dependencies
- **Interactive search**: Filter nodes by name
- **Hierarchical view**: Clear parent-child relationships

## Advanced Usage

### Manually Register Items

```rescript
// Register without tracking wrapper
let signalId = XoteDevTools.Registry.registerSignal(
  ~label="mySignal",
  ~getValue=Some(() => "current value"),
  ()
)

// Register dependencies
XoteDevTools.Registry.registerDependency(
  ~observerId="computed_1",
  ~signalId="signal_1",
)
```

### Log Updates Manually

```rescript
XoteDevTools.Timeline.logUpdate(
  ~itemId="my_signal",
  ~itemLabel=Some("My Signal"),
  ~oldValue=Some("42"),
  ~newValue="43",
  ~triggerCount=2,
  ()
)
```

### Configure Timeline

```rescript
// Keep last 500 events instead of 100
XoteDevTools.Timeline.setMaxEvents(500)
```

### Clear All Data

```rescript
// Clear registry and timeline
XoteDevTools.clear()
```

## Architecture

### Module Structure

```
devtools/
├── XoteDevTools__Types.res       # Type definitions
├── XoteDevTools__Registry.res    # Signal/observer tracking
├── XoteDevTools__Timeline.res    # Update event logging
├── XoteDevTools__Graph.res       # Dependency graph utilities
├── XoteDevTools__UI.res          # Modal UI component
└── XoteDevTools.res              # Public API
```

### Design Principles

1. **Isolated**: Completely separate from core Xote library
2. **Optional**: Only includes what you explicitly track
3. **Non-intrusive**: Doesn't modify signal behavior
4. **Self-contained**: Uses Xote itself for UI rendering
5. **Type-safe**: Full ReScript type safety

## Limitations

1. **Manual tracking**: You must explicitly track signals (not automatic)
2. **No time-travel**: Can't restore previous states (yet)
3. **Simple stringification**: Default toString is basic (provide custom ones)
4. **No persistence**: Data is lost on page refresh
5. **Single app**: Doesn't support multiple Xote apps on same page

## Future Enhancements

### Planned for Browser Extension

- Automatic signal detection (no manual tracking needed)
- Chrome DevTools panel integration
- Persistent settings and history
- Time-travel debugging
- State snapshots and restore
- Performance profiling
- Hot signal detection
- React DevTools-style overlay
- Export/import debugging sessions

### Potential Features

- Breakpoints (pause on signal value)
- Conditional watches
- Execution metrics
- Memory leak detection
- Bundle size analysis
- Component tree mapping
- Better graph visualization (force-directed layout)

## Demo

Run the demo to see XoteDevTools in action:

```bash
npm run res:build
npm run dev
# Open demos/devtools-demo.html
```

## Keyboard Shortcuts (Future)

- `Ctrl/Cmd + Shift + D` - Toggle DevTools
- `Escape` - Close DevTools
- `Ctrl/Cmd + F` - Focus search

## Contributing

The devtools are designed to be extensible. To add new features:

1. Add types to `XoteDevTools__Types.res`
2. Implement logic in appropriate module
3. Update UI in `XoteDevTools__UI.res`
4. Expose API in `XoteDevTools.res`

## License

Same as Xote (MIT)
