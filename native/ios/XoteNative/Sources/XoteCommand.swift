import Foundation

/// One entry of a batch, decoded from the wire format in `native/host/protocol.mjs`.
///
/// The wire format is a JSON array of arrays with the opcode first, which is
/// why this is `JSONSerialization` and a switch rather than `Codable`: the
/// elements are deliberately heterogeneous, and a style prop is an arbitrary
/// object.
enum XoteCommand {
  case create(id: Int, type: String)
  case createText(id: Int, text: String)
  case setProp(id: Int, key: String, value: Any?)
  case setText(id: Int, text: String)
  case insert(parent: Int, child: Int, index: Int)
  case remove(parent: Int, child: Int)
  case destroy(id: Int)
  case listen(id: Int, event: String)

  /// How many slots a command of each opcode occupies, opcode included.
  private static func arity(of op: Int) -> Int {
    switch op {
    case 1, 2, 4, 8: return 3
    case 3, 5: return 4
    case 6: return 3
    case 7: return 2
    default: return Int.max
    }
  }

  /// Decode a batch, skipping anything that cannot be read rather than
  /// discarding the whole thing.
  ///
  /// The two halves of this bridge are versioned separately — a JavaScript
  /// bundle can be newer than the app around it — so an opcode this host does
  /// not know is a thing to skip and report, not a reason to drop every other
  /// command in the batch alongside it.
  static func decodeBatch(_ json: String) -> (commands: [XoteCommand], problems: [String]) {
    guard
      let data = json.data(using: .utf8),
      let raw = try? JSONSerialization.jsonObject(with: data) as? [[Any]]
    else {
      return ([], ["a batch arrived that is not an array of commands"])
    }

    var commands: [XoteCommand] = []
    var problems: [String] = []
    for entry in raw {
      if let command = decode(entry) {
        commands.append(command)
      } else {
        problems.append("skipped a command this host cannot read: \(entry)")
      }
    }
    return (commands, problems)
  }

  private static func decode(_ command: [Any]) -> XoteCommand? {
    // Every access below is guarded by the arity check: an index out of range
    // is a trap, not an error, and a truncated batch would take the app down.
    guard let op = command.first as? Int, command.count >= arity(of: op) else { return nil }
    switch op {
    case 1:
      guard let id = command[1] as? Int, let type = command[2] as? String else { return nil }
      return .create(id: id, type: type)
    case 2:
      guard let id = command[1] as? Int, let text = command[2] as? String else { return nil }
      return .createText(id: id, text: text)
    case 3:
      guard let id = command[1] as? Int, let key = command[2] as? String else { return nil }
      // `null` clears the prop, and NSNull is how it survives JSONSerialization.
      let value = command[3] is NSNull ? nil : command[3]
      return .setProp(id: id, key: key, value: value)
    case 4:
      guard let id = command[1] as? Int, let text = command[2] as? String else { return nil }
      return .setText(id: id, text: text)
    case 5:
      guard let parent = command[1] as? Int, let child = command[2] as? Int,
        let index = command[3] as? Int
      else { return nil }
      return .insert(parent: parent, child: child, index: index)
    case 6:
      guard let parent = command[1] as? Int, let child = command[2] as? Int else { return nil }
      return .remove(parent: parent, child: child)
    case 7:
      guard let id = command[1] as? Int else { return nil }
      return .destroy(id: id)
    case 8:
      guard let id = command[1] as? Int, let event = command[2] as? String else { return nil }
      return .listen(id: id, event: event)
    default:
      return nil
    }
  }
}
