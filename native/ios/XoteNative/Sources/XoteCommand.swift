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

  static func decodeBatch(_ json: String) -> [XoteCommand] {
    guard
      let data = json.data(using: .utf8),
      let raw = try? JSONSerialization.jsonObject(with: data) as? [[Any]]
    else {
      assertionFailure("Xote: could not decode a batch")
      return []
    }
    return raw.compactMap(decode)
  }

  private static func decode(_ command: [Any]) -> XoteCommand? {
    guard let op = command.first as? Int else { return nil }
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
      assertionFailure("Xote: unknown opcode \(op)")
      return nil
    }
  }
}
