import UIKit

/// A size in the style vocabulary: points, a percentage of something, or
/// nothing at all. `auto` and an absent value are the same thing here.
enum XoteDimension {
  case points(CGFloat)
  case percent(CGFloat)
  case auto

  func resolve(_ base: CGFloat?) -> CGFloat? {
    switch self {
    case .points(let value):
      return value
    case .percent(let percent):
      guard let base = base else { return nil }
      return base * percent / 100
    case .auto:
      return nil
    }
  }

  /// Resolvable without knowing what it is a percentage of.
  var isDefinite: Bool {
    if case .points = self { return true }
    return false
  }
}

/// A style object off the bridge, read with the types layout and UIKit want.
///
/// The vocabulary is `native/NativeStyle.res`; the reader is deliberately dumb,
/// because the wire format is already the shape ReScript wrote.
struct XoteStyle {
  let values: [String: Any]

  init(_ values: [String: Any]?) {
    self.values = values ?? [:]
  }

  // MARK: - Reading

  func number(_ key: String) -> CGFloat? {
    guard let value = values[key] as? NSNumber else { return nil }
    return CGFloat(value.doubleValue)
  }

  func string(_ key: String) -> String? {
    values[key] as? String
  }

  func dimension(_ key: String) -> XoteDimension {
    if let points = number(key) { return .points(points) }
    if let text = string(key), text.hasSuffix("%"), let percent = Double(text.dropLast()) {
      return .percent(CGFloat(percent))
    }
    return .auto
  }

  // MARK: - Box model

  /// One edge of `margin` / `padding`, with the shorthands folded in.
  private func edge(_ prefix: String, _ side: String) -> CGFloat {
    if let longhand = number(prefix + side) { return longhand }
    let axis = (side == "Left" || side == "Right") ? "Horizontal" : "Vertical"
    if let shorthand = number(prefix + axis) { return shorthand }
    return number(prefix) ?? 0
  }

  func edges(_ prefix: String) -> XoteEdges {
    XoteEdges(
      left: edge(prefix, "Left"),
      right: edge(prefix, "Right"),
      top: edge(prefix, "Top"),
      bottom: edge(prefix, "Bottom")
    )
  }

  /// Padding plus border — the inset from a node's box to its content.
  var inset: XoteEdges {
    let padding = edges("padding")
    let border = number("borderWidth") ?? 0
    return XoteEdges(
      left: padding.left + border,
      right: padding.right + border,
      top: padding.top + border,
      bottom: padding.bottom + border
    )
  }

  func gap(isRow: Bool) -> CGFloat {
    if let specific = number(isRow ? "columnGap" : "rowGap") { return specific }
    return number("gap") ?? 0
  }

  // MARK: - Flex

  /// `flex: n` is `flexGrow: n, flexShrink: 1, flexBasis: 0`, as in CSS and RN.
  var flexGrow: CGFloat {
    if let grow = number("flexGrow") { return grow }
    if let flex = number("flex"), flex > 0 { return flex }
    return 0
  }

  var flexShrink: CGFloat {
    if let shrink = number("flexShrink") { return shrink }
    return number("flex") != nil ? 1 : 0
  }

  var flexBasis: XoteDimension {
    if values["flexBasis"] != nil, string("flexBasis") != "auto" {
      return dimension("flexBasis")
    }
    if let flex = number("flex"), flex > 0 { return .points(0) }
    return .auto
  }

  // MARK: - Paint

  func color(_ key: String) -> UIColor? {
    guard let hex = string(key) else { return nil }
    return XoteStyle.color(fromHex: hex)
  }

  /// `#rgb`, `#rrggbb` and `#rrggbbaa`.
  static func color(fromHex hex: String) -> UIColor? {
    var digits = hex.trimmingCharacters(in: .whitespaces)
    guard digits.hasPrefix("#") else { return nil }
    digits.removeFirst()

    if digits.count == 3 {
      digits = digits.map { "\($0)\($0)" }.joined()
    }
    guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else {
      return nil
    }

    let hasAlpha = digits.count == 8
    let r = CGFloat((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
    let g = CGFloat((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
    let b = CGFloat((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
    let a = hasAlpha ? CGFloat(value & 0xFF) / 255 : 1
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }

  var font: UIFont {
    let size = number("fontSize") ?? UIFont.systemFontSize
    let weight: UIFont.Weight
    switch string("fontWeight") ?? "regular" {
    case "thin": weight = .thin
    case "light": weight = .light
    case "medium": weight = .medium
    case "semibold": weight = .semibold
    case "bold": weight = .bold
    case "heavy": weight = .heavy
    default: weight = .regular
    }
    if let family = string("fontFamily"), let custom = UIFont(name: family, size: size) {
      return custom
    }
    return .systemFont(ofSize: size, weight: weight)
  }

  var textAlignment: NSTextAlignment {
    switch string("textAlign") ?? "auto" {
    case "center": return .center
    case "right": return .right
    case "justify": return .justified
    default: return .natural
    }
  }
}
