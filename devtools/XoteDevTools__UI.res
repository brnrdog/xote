// DevTools UI Component
open Xote__Component
open Xote__JSX
open XoteDevTools__Types

// Styles
let modalOverlayStyle = "position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 10000; display: flex; align-items: center; justify-content: center;"

let modalStyle = "background: #1e1e1e; color: #d4d4d4; width: 90%; max-width: 1200px; height: 80%; border-radius: 8px; display: flex; flex-direction: column; font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace; font-size: 13px; box-shadow: 0 10px 40px rgba(0,0,0,0.3);"

let headerStyle = "padding: 16px 20px; border-bottom: 1px solid #333; display: flex; justify-content: space-between; align-items: center;"

let tabsStyle = "display: flex; gap: 4px; padding: 8px 20px; border-bottom: 1px solid #333; background: #252525;"

let tabStyle = (~active) =>
  active
    ? "padding: 8px 16px; background: #007acc; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500;"
    : "padding: 8px 16px; background: transparent; color: #999; border: none; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500;"

let contentStyle = "flex: 1; overflow-y: auto; padding: 20px;"

let closeButtonStyle = "background: #c00; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 12px; font-weight: 500;"

let searchInputStyle = "width: 100%; padding: 8px 12px; background: #252525; border: 1px solid #333; border-radius: 4px; color: #d4d4d4; font-size: 13px; margin-bottom: 16px; font-family: inherit;"

// Format timestamp
let formatTime = timestamp => {
  let date = Date.fromTime(timestamp)
  let hours = date->Date.getHours->Int.toString->String.padStart(2, "0")
  let minutes = date->Date.getMinutes->Int.toString->String.padStart(2, "0")
  let seconds = date->Date.getSeconds->Int.toString->String.padStart(2, "0")
  let ms = date->Date.getMilliseconds->Int.toString->String.padStart(3, "0")
  `${hours}:${minutes}:${seconds}.${ms}`
}

// Format item type
let formatItemType = itemType =>
  switch itemType {
  | Signal => "Signal"
  | Computed => "Computed"
  | Effect => "Effect"
  }

// Get color for item type
let getTypeColor = itemType =>
  switch itemType {
  | Signal => "#4ec9b0"
  | Computed => "#dcdcaa"
  | Effect => "#c586c0"
  }

// Registry View Component
let registryView = (~searchTerm: Signals.Signal.t<string>) => {
  let contentSignal = Signals.Computed.make(() => {
    // Access version signal to trigger updates when any tracked signal value changes
    let _ = Signals.Signal.get(XoteDevTools__Registry.getVersionSignal())

    // Directly access the items signal for reactivity
    let itemsDict = Signals.Signal.get(XoteDevTools__Registry.getItemsSignal())
    let items = itemsDict->Dict.valuesToArray
    let filter = {
      searchTerm: Signals.Signal.get(searchTerm),
      itemTypes: [],
    }
    let filtered = XoteDevTools__Registry.filterItems(items, ~filter)

    [
      <div style="margin-bottom: 16px; color: #999;">
        {text(`${Int.toString(filtered->Array.length)} items`)}
      </div>,
      ...filtered->Array.map(item => {
        let label = switch item.label {
        | Some(l) => l
        | None => item.id
        }

        let value = switch item.getValue {
        | Some(fn) => fn()
        | None => "-"
        }

        let opacity = item.disposed ? "0.5" : "1"
        let textDecoration = item.disposed ? "line-through" : "none"

        <div
          key={item.id}
          style="background: #252525; padding: 12px; margin-bottom: 8px; border-radius: 4px; border-left: 3px solid; border-left-color: {getTypeColor(
              item.itemType,
            )}; opacity: {opacity}; position: relative;">
          {item.disposed
            ? <div
                style="position: absolute; top: 8px; right: 8px; background: #ff6b6b; color: white; padding: 2px 6px; border-radius: 3px; font-size: 10px; font-weight: 600;">
                {text("DISPOSED")}
              </div>
            : fragment([])}
          <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
            <span
              style="font-weight: 500; color: {getTypeColor(
                  item.itemType,
                )}; text-decoration: {textDecoration};">
              {text(label)}
            </span>
            <span style="color: #999; font-size: 11px;">
              {text(formatItemType(item.itemType))}
            </span>
          </div>
          <div style="color: #9cdcfe; font-size: 12px; margin-bottom: 2px; text-decoration: {textDecoration};">
            {text(value)}
          </div>
          <div style="color: #666; font-size: 11px;">
            {text(`ID: ${item.id} • Created: ${formatTime(item.createdAt)}`)}
          </div>
        </div>
      }),
    ]
  })

  <div>
    <input
      type_="text"
      placeholder="Search signals..."
      value={Signals.Signal.peek(searchTerm)}
      onInput={evt => {
        let value = (evt->Obj.magic)["target"]["value"]
        Signals.Signal.set(searchTerm, value)
      }}
      style={searchInputStyle}
    />
    {signalFragment(contentSignal)}
  </div>
}

// Timeline View Component
let timelineView = (~searchTerm: Signals.Signal.t<string>) => {
  let contentSignal = Signals.Computed.make(() => {
    // Directly access the events signal for reactivity
    let events = Signals.Signal.get(XoteDevTools__Timeline.getEventsSignal())
    let filtered = XoteDevTools__Timeline.filterEvents(
      events,
      ~searchTerm=Signals.Signal.get(searchTerm),
    )

    [
      <div style="margin-bottom: 16px; color: #999;">
        {text(`${Int.toString(filtered->Array.length)} events`)}
      </div>,
      ...filtered->Array.map(event => {
        let label = switch event.itemLabel {
        | Some(l) => l
        | None => event.itemId
        }

        <div
          key={event.id}
          style="background: #252525; padding: 12px; margin-bottom: 8px; border-radius: 4px; border-left: 3px solid #007acc;">
          <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
            <span style="font-weight: 500; color: #4fc1ff;">
              {text(label)}
            </span>
            <span style="color: #999; font-size: 11px;">
              {text(formatTime(event.timestamp))}
            </span>
          </div>
          {switch event.oldValue {
          | Some(old) =>
            <div style="color: #f48771; font-size: 12px; margin-bottom: 2px;">
              {text(`- ${old}`)}
            </div>
          | None => fragment([])
          }}
          <div style="color: #b5cea8; font-size: 12px; margin-bottom: 2px;">
            {text(`+ ${event.newValue}`)}
          </div>
          {event.triggerCount > 0
            ? <div style="color: #666; font-size: 11px;">
                {text(`Triggered ${Int.toString(event.triggerCount)} observers`)}
              </div>
            : fragment([])}
        </div>
      }),
    ]
  })

  <div>
    <input
      type_="text"
      placeholder="Search timeline..."
      value={Signals.Signal.peek(searchTerm)}
      onInput={evt => {
        let value = (evt->Obj.magic)["target"]["value"]
        Signals.Signal.set(searchTerm, value)
      }}
      style={searchInputStyle}
    />
    {signalFragment(contentSignal)}
  </div>
}

// Graph View Component
let graphView = (~searchTerm: Signals.Signal.t<string>) => {
  let contentSignal = Signals.Computed.make(() => {
    let nodes = XoteDevTools__Graph.buildGraph()
    let cycles = XoteDevTools__Graph.detectCycles()

    let term = Signals.Signal.get(searchTerm)->String.toLowerCase
    let filtered = if term == "" {
      nodes
    } else {
      nodes->Array.filter(node => node.label->String.toLowerCase->String.includes(term))
    }

    let cycleWarning = if cycles->Array.length > 0 {
      [
        <div
          style="background: #5a1e1e; color: #f48771; padding: 12px; margin-bottom: 16px; border-radius: 4px; border-left: 3px solid #f48771;">
          <div style="font-weight: 500; margin-bottom: 4px;">
            {text(`⚠️ ${Int.toString(cycles->Array.length)} cycles detected`)}
          </div>
          <div style="font-size: 11px;">
            {text("Circular dependencies can cause infinite loops")}
          </div>
        </div>,
      ]
    } else {
      []
    }

    [
      cycleWarning,
      [
        <div style="margin-bottom: 16px; color: #999;">
          {text(`${Int.toString(filtered->Array.length)} nodes`)}
        </div>,
      ],
      filtered->Array.map(node => {
        <div
          key={node.id}
          style="background: #252525; padding: 12px; margin-bottom: 8px; border-radius: 4px; border-left: 3px solid; border-left-color: {getTypeColor(
              node.itemType,
            )};">
          <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
            <span style="font-weight: 500; color: {getTypeColor(node.itemType)};">
              {text(node.label)}
            </span>
            <span style="color: #999; font-size: 11px;">
              {text(formatItemType(node.itemType))}
            </span>
          </div>
          {if node.dependsOn->Array.length > 0 {
            fragment([
              <div style="margin-bottom: 4px;">
                <div style="color: #999; font-size: 11px; margin-bottom: 4px;">
                  {text("Depends on:")}
                </div>
                {fragment(
                  node.dependsOn->Array.map(depId => {
                    switch XoteDevTools__Registry.getItem(depId) {
                    | Some(item) => {
                        let label = switch item.label {
                        | Some(l) => l
                        | None => item.id
                        }
                        <div
                          key={depId}
                          style="color: #4ec9b0; font-size: 12px; padding: 2px 8px; margin-bottom: 2px;">
                          {text(`→ ${label}`)}
                        </div>
                      }
                    | None => fragment([])
                    }
                  }),
                )}
              </div>,
            ])
          } else {
            fragment([])
          }}
          {if node.dependents->Array.length > 0 {
            fragment([
              <div>
                <div style="color: #999; font-size: 11px; margin-bottom: 4px;">
                  {text("Used by:")}
                </div>
                {fragment(
                  node.dependents->Array.map(depId => {
                    switch XoteDevTools__Registry.getItem(depId) {
                    | Some(item) => {
                        let label = switch item.label {
                        | Some(l) => l
                        | None => item.id
                        }
                        <div
                          key={depId}
                          style="color: #c586c0; font-size: 12px; padding: 2px 8px; margin-bottom: 2px;">
                          {text(`← ${label}`)}
                        </div>
                      }
                    | None => fragment([])
                    }
                  }),
                )}
              </div>,
            ])
          } else {
            fragment([])
          }}
        </div>
      }),
    ]->Array.flat
  })

  <div>
    <input
      type_="text"
      placeholder="Search graph..."
      value={Signals.Signal.peek(searchTerm)}
      onInput={evt => {
        let value = (evt->Obj.magic)["target"]["value"]
        Signals.Signal.set(searchTerm, value)
      }}
      style={searchInputStyle}
    />
    {signalFragment(contentSignal)}
  </div>
}

// Main Modal Component
let modal = (~isOpen: Signals.Signal.t<bool>, ~onClose) => {
  let activeTab = Signals.Signal.make(Registry, ~name="DevTools.UI.activeTab")
  let searchTerm = Signals.Signal.make("", ~name="DevTools.UI.searchTerm")

  let modalContentSignal = Signals.Computed.make(() => {
    if !Signals.Signal.get(isOpen) {
      []
    } else {
      [
        <div style={modalOverlayStyle} onClick={_ => onClose()}>
          <div style={modalStyle} onClick={evt => (evt->Obj.magic)["stopPropagation"]()}>
            <div style={headerStyle}>
              <h2 style="margin: 0; font-size: 16px; font-weight: 600;">
                {text("Xote DevTools")}
              </h2>
              <button style={closeButtonStyle} onClick={_ => onClose()}>
                {text("Close")}
              </button>
            </div>
            <div style={tabsStyle}>
              {signalFragment(
                Signals.Computed.make(() => {
                  let active = Signals.Signal.get(activeTab)
                  [
                    <button
                      style={tabStyle(~active=active == Registry)}
                      onClick={_ => {
                        Signals.Signal.set(activeTab, Registry)
                        Signals.Signal.set(searchTerm, "")
                      }}>
                      {text("Registry")}
                    </button>,
                    <button
                      style={tabStyle(~active=active == Timeline)}
                      onClick={_ => {
                        Signals.Signal.set(activeTab, Timeline)
                        Signals.Signal.set(searchTerm, "")
                      }}>
                      {text("Timeline")}
                    </button>,
                    <button
                      style={tabStyle(~active=active == Graph)}
                      onClick={_ => {
                        Signals.Signal.set(activeTab, Graph)
                        Signals.Signal.set(searchTerm, "")
                      }}>
                      {text("Graph")}
                    </button>,
                  ]
                }),
              )}
            </div>
            <div style={contentStyle}>
              {signalFragment(
                Signals.Computed.make(() => {
                  switch Signals.Signal.get(activeTab) {
                  | Registry => [registryView(~searchTerm)]
                  | Timeline => [timelineView(~searchTerm)]
                  | Graph => [graphView(~searchTerm)]
                  }
                }),
              )}
            </div>
          </div>
        </div>,
      ]
    }
  })

  signalFragment(modalContentSignal)
}
