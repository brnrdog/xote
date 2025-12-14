# XoteDevTools Integration

The Xote website now includes integrated DevTools for debugging and inspecting reactive state in real-time.

## How to Use

### Opening DevTools

**Option 1: Click the floating button**
- Look for the blue "🔍 DevTools" button in the bottom-right corner
- Click it to open the DevTools modal

**Option 2: Keyboard shortcut**
- Press `Ctrl+Shift+D` (Windows/Linux) or `Cmd+Shift+D` (Mac)
- Press again to close

**Option 3: Browser console**
- Open your browser's developer console (F12)
- Type `XoteDevTools.open()` to open
- Type `XoteDevTools.close()` to close
- Type `XoteDevTools.toggle()` to toggle
- Type `XoteDevTools.clear()` to clear all tracked data

## Tracked Signals

The following signals are tracked across the website:

### Layout Signals
- **`theme`**: Current theme ("light" or "dark")
- **`isScrolled`**: Whether the page has scrolled past 50px (controls header style)

### Todo App Demo Signals
- **`todos`**: Array of todo items with their state
- **`todoInput`**: Current value of the todo input field

## DevTools Features

### 📊 Registry Tab
- View all active signals, computeds, and effects
- See current values updated in real-time
- Search and filter by name
- Color-coded by type (Signal: teal, Computed: yellow, Effect: purple)

### ⏱️ Timeline Tab
- Chronological log of all signal updates
- See old → new value transitions
- Track which observers were triggered
- Search through update history
- Keeps last 100 events

### 🔍 Graph Tab
- Visualize signal → computed → effect relationships
- See what each observer depends on
- See what signals are used by which observers
- Automatic cycle detection and warnings

## Implementation Details

The DevTools are completely isolated in the `../devtools/` directory and don't affect the core Xote library. They use Xote itself for the UI, demonstrating Xote's capabilities while being self-documenting.

### Tracked Code Locations

**Layout.res:**
```rescript
let theme = XoteDevTools.trackSignal(
  Signal.make("light"),
  ~label="theme",
  ~toString=x => x,
)

let isScrolled = XoteDevTools.trackSignal(
  Signal.make(false),
  ~label="isScrolled",
  ~toString=b => b ? "true" : "false",
)
```

**TodoApp.res:**
```rescript
let todos = XoteDevTools.trackSignal(
  Signal.make([]),
  ~label="todos",
  ~toString=arr => `[${Int.toString(arr->Array.length)} items]`,
)

let inputValue = XoteDevTools.trackSignal(
  Signal.make(""),
  ~label="todoInput",
  ~toString=x => `"${x}"`,
)
```

## Tips

1. **Watch signal updates in real-time**: Keep the DevTools open while interacting with the website to see how signals update
2. **Debug scroll behavior**: Watch the `isScrolled` signal to see when the header style changes
3. **Track todo operations**: See how `todos` and `todoInput` change as you add, toggle, or delete items
4. **Explore dependencies**: Use the Graph tab to understand how signals, computeds, and effects are connected
5. **Timeline for debugging**: Use the Timeline tab to trace back through changes when investigating unexpected behavior

## Development

To add tracking to new signals:

```rescript
// Instead of:
let mySignal = Signal.make(initialValue)

// Use:
let mySignal = XoteDevTools.trackSignal(
  Signal.make(initialValue),
  ~label="mySignal",
  ~toString=value => // convert value to string for display
)
```

For complex types, provide a custom `toString` function to make the DevTools display meaningful:

```rescript
type user = {name: string, age: int}

let currentUser = XoteDevTools.trackSignal(
  Signal.make({name: "Alice", age: 30}),
  ~label="currentUser",
  ~toString=user => `${user.name} (${Int.toString(user.age)})`,
)
```

## Future Enhancements

The DevTools are designed to eventually become a browser extension with additional features:
- Automatic signal detection (no manual tracking needed)
- Time-travel debugging
- State snapshots and restore
- Performance profiling
- Hot signal detection
- Better graph visualization
