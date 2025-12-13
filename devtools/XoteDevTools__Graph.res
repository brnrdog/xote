// Dependency Graph Utilities
open XoteDevTools__Types

// Graph node for visualization
type graphNode = {
  id: id,
  label: string,
  itemType: itemType,
  dependsOn: array<id>, // IDs this node depends on
  dependents: array<id>, // IDs that depend on this node
}

// Build graph from registry
let buildGraph = () => {
  let items = XoteDevTools__Registry.getItems()
  let dependencies = XoteDevTools__Registry.getDependencies()

  // Create nodes
  items->Array.map(item => {
    let label = switch item.label {
    | Some(l) => l
    | None => item.id
    }

    let dependsOn = if item.itemType == Signal {
      [] // Signals don't depend on anything
    } else {
      // Find what this observer depends on
      dependencies
      ->Array.filter(dep => dep.observerId == item.id)
      ->Array.map(dep => dep.signalId)
    }

    let dependents =
      dependencies
      ->Array.filter(dep => dep.signalId == item.id)
      ->Array.map(dep => dep.observerId)

    {
      id: item.id,
      label,
      itemType: item.itemType,
      dependsOn,
      dependents,
    }
  })
}

// Get subgraph starting from a specific node
let getSubgraph = (~nodeId, ~depth=2) => {
  let allNodes = buildGraph()
  let visited = ref(Dict.make())
  let result = ref([])

  let rec traverse = (id, currentDepth) => {
    if currentDepth > depth || visited.contents->Dict.get(id)->Option.isSome {
      ()
    } else {
      visited.contents->Dict.set(id, true)

      switch allNodes->Array.find(n => n.id == id) {
      | Some(node) => {
          result := Array.concat(result.contents, [node])

          // Traverse dependencies
          node.dependsOn->Array.forEach(depId => traverse(depId, currentDepth + 1))

          // Traverse dependents
          node.dependents->Array.forEach(depId => traverse(depId, currentDepth + 1))
        }
      | None => ()
      }
    }
  }

  traverse(nodeId, 0)
  result.contents
}

// Detect cycles in the graph
let detectCycles = () => {
  let nodes = buildGraph()
  let visited = ref(Dict.make())
  let recStack = ref(Dict.make())
  let cycles = ref([])

  let rec visit = (nodeId, path) => {
    if recStack.contents->Dict.get(nodeId)->Option.isSome {
      // Found a cycle
      cycles := Array.concat(cycles.contents, [path])
      true
    } else if visited.contents->Dict.get(nodeId)->Option.isSome {
      false
    } else {
      visited.contents->Dict.set(nodeId, true)
      recStack.contents->Dict.set(nodeId, true)

      let newPath = Array.concat(path, [nodeId])

      switch nodes->Array.find(n => n.id == nodeId) {
      | Some(node) => {
          node.dependsOn->Array.forEach(depId => {
            visit(depId, newPath)->ignore
          })
        }
      | None => ()
      }

      recStack.contents->Dict.delete(nodeId)
      false
    }
  }

  // Check each node
  nodes->Array.forEach(node => {
    if !(visited.contents->Dict.get(node.id)->Option.isSome) {
      visit(node.id, [])->ignore
    }
  })

  cycles.contents
}

// Get root nodes (signals with no dependencies)
let getRootNodes = () => {
  buildGraph()->Array.filter(node => node.dependsOn->Array.length == 0)
}

// Get leaf nodes (items with no dependents)
let getLeafNodes = () => {
  buildGraph()->Array.filter(node => node.dependents->Array.length == 0)
}
