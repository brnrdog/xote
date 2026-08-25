import UIKit

/// A style object off the bridge, read with the types UIKit wants.
///
/// The vocabulary is flexbox (see `native/NativeStyle.res`). This host maps the
/// subset it needs onto `UIStackView`, which is an approximation and is meant to
/// be one — see the note in `native/ios/README.md`. A host built to ship embeds
/// Yoga and lays out real frames.
struct XoteStyle {
  let values: [String: Any]

  init(_ values: [String: Any]?) {
    self.values = values ?? [:]
  }

  func number(_ key: String) -> CGFloat? {
    // A size is either points (a number) or a percentage/`auto` (a string).
    // Percentages are not supported by this host; they are simply ignored.
    guard let value = values[key] as? NSNumber else { return nil }
    return CGFloat(value.doubleValue)
  }

  func string(_ key: String) -> String? {
    values[key] as? String
  }

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

  var isRow: Bool {
    let direction = string("flexDirection") ?? "column"
    return direction == "row" || direction == "row-reverse"
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

  /// Padding, with the `*Horizontal` / `*Vertical` shorthands folded in. The
  /// longhand wins, matching how the style object is merged on the other side.
  func insets(_ prefix: String) -> NSDirectionalEdgeInsets {
    let all = number(prefix) ?? 0
    let horizontal = number("\(prefix)Horizontal") ?? all
    let vertical = number("\(prefix)Vertical") ?? all
    return NSDirectionalEdgeInsets(
      top: number("\(prefix)Top") ?? vertical,
      leading: number("\(prefix)Left") ?? horizontal,
      bottom: number("\(prefix)Bottom") ?? vertical,
      trailing: number("\(prefix)Right") ?? horizontal
    )
  }

  func alignment(isRow: Bool) -> UIStackView.Alignment {
    switch string("alignItems") ?? "stretch" {
    case "center": return .center
    case "flex-start": return isRow ? .top : .leading
    case "flex-end": return isRow ? .bottom : .trailing
    case "baseline": return .firstBaseline
    default: return .fill
    }
  }

  var distribution: UIStackView.Distribution {
    switch string("justifyContent") ?? "flex-start" {
    case "space-between": return .equalSpacing
    case "space-around", "space-evenly": return .equalCentering
    default: return .fill
    }
  }
}
