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

// Expandable Object Display Component
module ExpandableValue = {
  type expandedState = Dict.t<bool>

  let parseValue = (value: string): Obj.t => {
    try {
      %raw(`JSON.parse(value)`)
    } catch {
    | _ => Obj.magic(value)
    }
  }

  let rec renderValue = (~value: Obj.t, ~path: string, ~expanded: expandedState, ~onToggle: string => unit, ~depth: int): Xote__Component.node => {
    let valueType: string = %raw(`typeof value`)

    switch valueType {
    | "string" => Component.text(`"${Obj.magic(value)}"`)
    | "number" | "boolean" => Component.text(Obj.magic(value)->String.make)
    | "object" =>
      if %raw(`value === null`) {
        Component.text("null")
      } else if %raw(`Array.isArray(value)`) {
        let arr: array<Obj.t> = Obj.magic(value)
        let isExpanded = expanded->Dict.get(path)->Option.getOr(false)

        if arr->Array.length == 0 {
          Component.text("[]")
        } else if isExpanded {
          <div>
            <span
              onClick={_ => onToggle(path)}
              style="cursor: pointer; color: #569cd6; user-select: none;">
              {Component.text("▼ ")}
            </span>
            <span style="color: #999;"> {Component.text("[")} </span>
            <div style="margin-left: 16px;">
              {Component.fragment(
                arr->Array.mapWithIndex((item, idx) => {
                  let itemPath = `${path}[${Int.toString(idx)}]`
                  <div key={itemPath}>
                    <span style="color: #999;"> {Component.text(`${Int.toString(idx)}: `)} </span>
                    {renderValue(~value=item, ~path=itemPath, ~expanded, ~onToggle, ~depth=depth + 1)}
                  </div>
                }),
              )}
            </div>
            <span style="color: #999;"> {Component.text("]")} </span>
          </div>
        } else {
          <span>
            <span
              onClick={_ => onToggle(path)}
              style="cursor: pointer; color: #569cd6; user-select: none;">
              {Component.text("▶ ")}
            </span>
            <span style="color: #999;">
              {Component.text(`[${Int.toString(arr->Array.length)} items]`)}
            </span>
          </span>
        }
      } else {
        let obj: Dict.t<Obj.t> = Obj.magic(value)
        let keys = obj->Dict.keysToArray
        let isExpanded = expanded->Dict.get(path)->Option.getOr(false)

        if keys->Array.length == 0 {
          Component.text("{}")
        } else if isExpanded {
          <div>
            <span
              onClick={_ => onToggle(path)}
              style="cursor: pointer; color: #569cd6; user-select: none;">
              {Component.text("▼ ")}
            </span>
            <span style="color: #999;"> {Component.text("{")} </span>
            <div style="margin-left: 16px;">
              {Component.fragment(
                keys->Array.map(key => {
                  let itemPath = `${path}.${key}`
                  let val = obj->Dict.get(key)->Option.getOr(Obj.magic("undefined"))
                  <div key={itemPath}>
                    <span style="color: #9cdcfe;"> {Component.text(`${key}: `)} </span>
                    {renderValue(~value=val, ~path=itemPath, ~expanded, ~onToggle, ~depth=depth + 1)}
                  </div>
                }),
              )}
            </div>
            <span style="color: #999;"> {Component.text("}")} </span>
          </div>
        } else {
          <span>
            <span
              onClick={_ => onToggle(path)}
              style="cursor: pointer; color: #569cd6; user-select: none;">
              {Component.text("▶ ")}
            </span>
            <span style="color: #999;">
              {Component.text(`{${Int.toString(keys->Array.length)} props}`)}
            </span>
          </span>
        }
      }
    | _ => Component.text(valueType)
    }
  }
}

// Registry View Component
let registryView = (~searchTerm: Signals.Signal.t<string>) => {
  let filterSignals = Signals.Signal.make(true, ~name="DevTools.UI.Registry.filterSignals")
  let filterComputeds = Signals.Signal.make(true, ~name="DevTools.UI.Registry.filterComputeds")
  let filterEffects = Signals.Signal.make(true, ~name="DevTools.UI.Registry.filterEffects")
  let expandedItems = Signals.Signal.make(Dict.make(), ~name="DevTools.UI.Registry.expandedItems")

  let contentSignal = Signals.Computed.make(() => {
    // Access version signal to trigger updates when any tracked signal value changes
    let _ = Signals.Signal.get(XoteDevTools__Registry.getVersionSignal())

    // Directly access the items signal for reactivity
    let itemsDict = Signals.Signal.get(XoteDevTools__Registry.getItemsSignal())
    let items = itemsDict->Dict.valuesToArray

    // Build filter types array based on checkboxes
    let itemTypes = []
    if Signals.Signal.get(filterSignals) {
      itemTypes->Array.push(Signal)->ignore
    }
    if Signals.Signal.get(filterComputeds) {
      itemTypes->Array.push(Computed)->ignore
    }
    if Signals.Signal.get(filterEffects) {
      itemTypes->Array.push(Effect)->ignore
    }

    let filter = {
      searchTerm: Signals.Signal.get(searchTerm),
      itemTypes: itemTypes,
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

        let valueStr = switch item.getValue {
        | Some(fn) => fn()
        | None => "-"
        }

        let opacity = item.disposed ? "0.5" : "1"
        let textDecoration = item.disposed ? "line-through" : "none"

        let expanded = Signals.Signal.get(expandedItems)
        let onToggle = path => {
          Signals.Signal.update(expandedItems, exp => {
            let newExp = exp->Dict.toArray->Dict.fromArray
            let current = newExp->Dict.get(path)->Option.getOr(false)
            newExp->Dict.set(path, !current)
            newExp
          })
        }

        let parsedValue = ExpandableValue.parseValue(valueStr)
        let valuePath = `item_${item.id}`

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
            {ExpandableValue.renderValue(
              ~value=parsedValue,
              ~path=valuePath,
              ~expanded,
              ~onToggle,
              ~depth=0,
            )}
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
    {signalFragment(
      Signals.Computed.make(() => {
        let _ = Signals.Signal.get(filterSignals)
        let _ = Signals.Signal.get(filterComputeds)
        let _ = Signals.Signal.get(filterEffects)

        [
          <div style="display: flex; gap: 12px; margin-bottom: 16px; padding: 8px; background: #1e1e1e; border-radius: 4px;">
            <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
              <input
                type_="checkbox"
                checked={Signals.Signal.peek(filterSignals)}
                onChange={_ => Signals.Signal.update(filterSignals, v => !v)}
                style="cursor: pointer;"
              />
              <span style="color: {getTypeColor(Signal)}; font-size: 13px;">
                {text("Signals")}
              </span>
            </label>
            <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
              <input
                type_="checkbox"
                checked={Signals.Signal.peek(filterComputeds)}
                onChange={_ => Signals.Signal.update(filterComputeds, v => !v)}
                style="cursor: pointer;"
              />
              <span style="color: {getTypeColor(Computed)}; font-size: 13px;">
                {text("Computeds")}
              </span>
            </label>
            <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
              <input
                type_="checkbox"
                checked={Signals.Signal.peek(filterEffects)}
                onChange={_ => Signals.Signal.update(filterEffects, v => !v)}
                style="cursor: pointer;"
              />
              <span style="color: {getTypeColor(Effect)}; font-size: 13px;">
                {text("Effects")}
              </span>
            </label>
          </div>,
        ]
      }),
    )}
    {signalFragment(contentSignal)}
  </div>
}

// Timeline View Component
let timelineView = (~searchTerm: Signals.Signal.t<string>) => {
  let filterSignals = Signals.Signal.make(true, ~name="DevTools.UI.Timeline.filterSignals")
  let filterComputeds = Signals.Signal.make(true, ~name="DevTools.UI.Timeline.filterComputeds")
  let filterEffects = Signals.Signal.make(true, ~name="DevTools.UI.Timeline.filterEffects")

  let contentSignal = Signals.Computed.make(() => {
    // Directly access the events signal for reactivity
    let events = Signals.Signal.get(XoteDevTools__Timeline.getEventsSignal())

    // Build filter types array based on checkboxes
    let itemTypes = []
    if Signals.Signal.get(filterSignals) {
      itemTypes->Array.push(Signal)->ignore
    }
    if Signals.Signal.get(filterComputeds) {
      itemTypes->Array.push(Computed)->ignore
    }
    if Signals.Signal.get(filterEffects) {
      itemTypes->Array.push(Effect)->ignore
    }

    let filtered = XoteDevTools__Timeline.filterEvents(
      events,
      ~searchTerm=Signals.Signal.get(searchTerm),
      ~itemTypes,
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
    {signalFragment(
      Signals.Computed.make(() => {
        let _ = Signals.Signal.get(filterSignals)
        let _ = Signals.Signal.get(filterComputeds)
        let _ = Signals.Signal.get(filterEffects)

        [
          <div style="display: flex; gap: 12px; margin-bottom: 16px; padding: 8px; background: #1e1e1e; border-radius: 4px;">
            <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
              <input
                type_="checkbox"
                checked={Signals.Signal.peek(filterSignals)}
                onChange={_ => Signals.Signal.update(filterSignals, v => !v)}
                style="cursor: pointer;"
              />
              <span style={`color: ${getTypeColor(Signal)}; font-size: 13px;`}>
                {text("Signals")}
              </span>
            </label>
            <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
              <input
                type_="checkbox"
                checked={Signals.Signal.peek(filterComputeds)}
                onChange={_ => Signals.Signal.update(filterComputeds, v => !v)}
                style="cursor: pointer;"
              />
              <span style={`color: ${getTypeColor(Computed)}; font-size: 13px;`}>
                {text("Computeds")}
              </span>
            </label>
            <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
              <input
                type_="checkbox"
                checked={Signals.Signal.peek(filterEffects)}
                onChange={_ => Signals.Signal.update(filterEffects, v => !v)}
                style="cursor: pointer;"
              />
              <span style={`color: ${getTypeColor(Effect)}; font-size: 13px;`}>
                {text("Effects")}
              </span>
            </label>
          </div>,
        ]
      }),
    )}
    {signalFragment(contentSignal)}
  </div>
}

// Graph Visual Layout Types
type graphViewMode = ListView | VisualView

type nodePosition = {
  x: float,
  y: float,
  width: float,
  height: float,
}

type layoutNode = {
  id: id,
  label: string,
  itemType: itemType,
  position: nodePosition,
  dependsOn: array<id>,
  dependents: array<id>,
}

// Calculate hierarchical layout for graph visualization
let calculateGraphLayout = (nodes: array<XoteDevTools__Graph.graphNode>): array<layoutNode> => {
  // Build layers using topological sort
  let layers = ref([])
  let nodeToLayer = Dict.make()
  let processed = Dict.make()

  // Recursive function to calculate layer depth
  let rec calculateLayer = (nodeId: id): int => {
    switch nodeToLayer->Dict.get(nodeId) {
    | Some(layer) => layer
    | None => {
        let node = nodes->Array.find(n => n.id == nodeId)
        switch node {
        | None => 0
        | Some(n) => {
            if n.dependsOn->Array.length == 0 {
              // Signals (no dependencies) go to layer 0
              nodeToLayer->Dict.set(nodeId, 0)
              0
            } else {
              // Calculate max layer of dependencies + 1
              let maxDepLayer = n.dependsOn
                ->Array.map(calculateLayer)
                ->Array.reduce(0, (max, layer) => max > layer ? max : layer)
              let layer = maxDepLayer + 1
              nodeToLayer->Dict.set(nodeId, layer)
              layer
            }
          }
        }
      }
    }
  }

  // Calculate layer for each node
  nodes->Array.forEach(node => {
    calculateLayer(node.id)->ignore
  })

  // Group nodes by layer
  let layerArrays = []
  nodes->Array.forEach(node => {
    let layer = nodeToLayer->Dict.get(node.id)->Option.getOr(0)
    // Ensure layer array exists
    while layerArrays->Array.length <= layer {
      layerArrays->Array.push([])->ignore
    }
    layerArrays->Array.getUnsafe(layer)->Array.push(node)->ignore
  })

  // Calculate positions
  let nodeWidth = 120.0
  let nodeHeight = 40.0
  let horizontalSpacing = 180.0
  let verticalSpacing = 60.0
  let paddingX = 20.0
  let paddingY = 20.0

  let layoutNodes = []
  layerArrays->Array.forEachWithIndex((layerNodes, layerIndex) => {
    let x = paddingX +. Float.fromInt(layerIndex) *. horizontalSpacing

    layerNodes->Array.forEachWithIndex((node, nodeIndexInLayer) => {
      let y = paddingY +. Float.fromInt(nodeIndexInLayer) *. verticalSpacing

      layoutNodes->Array.push({
        id: node.id,
        label: node.label,
        itemType: node.itemType,
        position: {
          x,
          y,
          width: nodeWidth,
          height: nodeHeight,
        },
        dependsOn: node.dependsOn,
        dependents: node.dependents,
      })->ignore
    })
  })

  layoutNodes
}

// Graph View Component
let graphView = (~searchTerm: Signals.Signal.t<string>) => {
  let filterSignals = Signals.Signal.make(true, ~name="DevTools.UI.Graph.filterSignals")
  let filterComputeds = Signals.Signal.make(true, ~name="DevTools.UI.Graph.filterComputeds")
  let filterEffects = Signals.Signal.make(true, ~name="DevTools.UI.Graph.filterEffects")
  let viewMode = Signals.Signal.make(VisualView, ~name="DevTools.UI.Graph.viewMode")

  let contentSignal = Signals.Computed.make(() => {
    let nodes = XoteDevTools__Graph.buildGraph()
    let cycles = XoteDevTools__Graph.detectCycles()
    let mode = Signals.Signal.get(viewMode)

    // Build filter types array based on checkboxes
    let itemTypes = []
    if Signals.Signal.get(filterSignals) {
      itemTypes->Array.push(Signal)->ignore
    }
    if Signals.Signal.get(filterComputeds) {
      itemTypes->Array.push(Computed)->ignore
    }
    if Signals.Signal.get(filterEffects) {
      itemTypes->Array.push(Effect)->ignore
    }

    let term = Signals.Signal.get(searchTerm)->String.toLowerCase
    let filtered = nodes->Array.filter(node => {
      // Filter by search term
      let searchMatch = if term == "" {
        true
      } else {
        node.label->String.toLowerCase->String.includes(term)
      }

      // Filter by item type
      let typeMatch = if itemTypes->Array.length == 0 {
        true
      } else {
        itemTypes->Array.includes(node.itemType)
      }

      searchMatch && typeMatch
    })

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

    switch mode {
    | ListView => [
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
    | VisualView => {
        // Calculate layout for visual graph
        let layoutNodes = calculateGraphLayout(filtered)

        // Calculate SVG dimensions
        let maxX = layoutNodes
          ->Array.map(n => n.position.x +. n.position.width)
          ->Array.reduce(0.0, (max, x) => max > x ? max : x)
        let maxY = layoutNodes
          ->Array.map(n => n.position.y +. n.position.height)
          ->Array.reduce(0.0, (max, y) => max > y ? max : y)
        let svgWidth = maxX +. 40.0
        let svgHeight = maxY +. 40.0

        // Build edges array
        let edges = []
        layoutNodes->Array.forEach(node => {
          node.dependsOn->Array.forEach(depId => {
            // Find the dependency node position
            layoutNodes->Array.forEach(depNode => {
              if depNode.id == depId {
                edges->Array.push((node, depNode))->ignore
              }
            })
          })
        })

        // Build edge SVG elements
        let edgeElements = edges->Array.map(((fromNode, toNode)) => {
          let fromX = fromNode.position.x +. fromNode.position.width
          let fromY = fromNode.position.y +. fromNode.position.height /. 2.0
          let toX = toNode.position.x
          let toY = toNode.position.y +. toNode.position.height /. 2.0

          `<line x1="${Float.toString(fromX)}" y1="${Float.toString(fromY)}" x2="${Float.toString(toX)}" y2="${Float.toString(toY)}" stroke="#666" stroke-width="2" marker-end="url(#arrowhead)" />`
        })

        // Build node SVG elements
        let nodeElements = layoutNodes->Array.map(node => {
          let color = switch node.itemType {
          | Signal => "#4fc1ff"
          | Computed => "#4ec9b0"
          | Effect => "#c586c0"
          }
          let x = node.position.x
          let y = node.position.y
          let width = node.position.width
          let height = node.position.height
          let textX = x +. width /. 2.0
          let textY = y +. height /. 2.0
          let displayLabel = if node.label->String.length > 14 {
            node.label->String.substring(~start=0, ~end=12) ++ "..."
          } else {
            node.label
          }

          `<g><rect x="${Float.toString(x)}" y="${Float.toString(y)}" width="${Float.toString(width)}" height="${Float.toString(height)}" fill="#252525" stroke="${color}" stroke-width="2" rx="4" /><text x="${Float.toString(textX)}" y="${Float.toString(textY)}" text-anchor="middle" dominant-baseline="middle" fill="${color}" font-size="12" font-family="monospace">${displayLabel}</text></g>`
        })

        // Build SVG HTML string
        let edgesHtml = edgeElements->Array.joinWith("")
        let nodesHtml = nodeElements->Array.joinWith("")
        let svgHtml = `<svg width="${Float.toString(svgWidth)}" height="${Float.toString(svgHeight)}" style="display: block;"><defs><marker id="arrowhead" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto"><polygon points="0 0, 10 3, 0 6" fill="#666" /></marker></defs>${edgesHtml}${nodesHtml}</svg>`

        // Create a unique container ID based on the SVG content hash
        let containerId = "xote-devtools-graph-svg-" ++ Int.toString(String.length(svgHtml))

        // Schedule DOM update after render
        let _ = %raw(`
          setTimeout(() => {
            const container = document.getElementById(containerId);
            if (container !== null && container.innerHTML !== svgHtml) {
              container.innerHTML = svgHtml;
            }
          }, 0)
        `)

        [
          cycleWarning,
          [
            <div style="margin-bottom: 16px; color: #999;">
              {text(`${Int.toString(filtered->Array.length)} nodes`)}
            </div>,
          ],
          [
            <div
              id={containerId}
              style="overflow: auto; background: #1a1a1a; border-radius: 4px; padding: 20px;"
            />,
          ],
        ]->Array.flat
      }
    }
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
    {signalFragment(
      Signals.Computed.make(() => {
        let _ = Signals.Signal.get(filterSignals)
        let _ = Signals.Signal.get(filterComputeds)
        let _ = Signals.Signal.get(filterEffects)
        let _ = Signals.Signal.get(viewMode)

        let mode = Signals.Signal.peek(viewMode)

        [
          <div style="display: flex; gap: 12px; margin-bottom: 16px; padding: 8px; background: #1e1e1e; border-radius: 4px; align-items: center; justify-content: space-between;">
            <div style="display: flex; gap: 12px;">
              <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
                <input
                  type_="checkbox"
                  checked={Signals.Signal.peek(filterSignals)}
                  onChange={_ => Signals.Signal.update(filterSignals, v => !v)}
                  style="cursor: pointer;"
                />
                <span style={`color: ${getTypeColor(Signal)}; font-size: 13px;`}>
                  {text("Signals")}
                </span>
              </label>
              <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
                <input
                  type_="checkbox"
                  checked={Signals.Signal.peek(filterComputeds)}
                  onChange={_ => Signals.Signal.update(filterComputeds, v => !v)}
                  style="cursor: pointer;"
                />
                <span style={`color: ${getTypeColor(Computed)}; font-size: 13px;`}>
                  {text("Computeds")}
                </span>
              </label>
              <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; user-select: none;">
                <input
                  type_="checkbox"
                  checked={Signals.Signal.peek(filterEffects)}
                  onChange={_ => Signals.Signal.update(filterEffects, v => !v)}
                  style="cursor: pointer;"
                />
                <span style={`color: ${getTypeColor(Effect)}; font-size: 13px;`}>
                  {text("Effects")}
                </span>
              </label>
            </div>
            <div style="display: flex; gap: 4px;">
              <button
                onClick={_ => Signals.Signal.set(viewMode, ListView)}
                style={`padding: 4px 12px; border-radius: 4px; border: 1px solid ${mode == ListView ? "#4fc1ff" : "#444"}; background: ${mode == ListView ? "#1a3a52" : "#252525"}; color: ${mode == ListView ? "#4fc1ff" : "#999"}; cursor: pointer; font-size: 12px;`}>
                {text("List")}
              </button>
              <button
                onClick={_ => Signals.Signal.set(viewMode, VisualView)}
                style={`padding: 4px 12px; border-radius: 4px; border: 1px solid ${mode == VisualView ? "#4fc1ff" : "#444"}; background: ${mode == VisualView ? "#1a3a52" : "#252525"}; color: ${mode == VisualView ? "#4fc1ff" : "#999"}; cursor: pointer; font-size: 12px;`}>
                {text("Visual")}
              </button>
            </div>
          </div>,
        ]
      }),
    )}
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
