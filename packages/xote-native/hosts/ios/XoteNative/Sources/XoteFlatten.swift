import UIKit

/// Which nodes need a view of their own.
///
/// A transliteration of `xote-native/src/host/flatten.mjs`. **Keep the two in step**: a
/// change here that is not also a change there is a change nothing tests, and
/// two hosts that flatten differently draw the same content into different
/// surfaces — with different clipping and different hit testing — while every
/// frame still agrees. `xote-native/conformance/` compares the view tree for exactly
/// that reason.
///
/// Most boxes on a screen exist only to arrange their children: a column with a
/// gap, a row with padding, a wrapper carrying `flex: 1`. They have to be in the
/// layout tree because they do arrange things. They do not have to be on screen,
/// because they draw nothing.
enum XoteFlatten {
  /// The only type that is ever flattened.
  ///
  /// An allow-list rather than a deny-list, deliberately: everything else either
  /// paints something itself, owns platform behaviour, exists to receive
  /// touches, is the mount point, or is a primitive this host has never heard
  /// of — and a deny-list would have to be right about every tag that has not
  /// been invented yet.
  static let flattenable: Set<String> = ["view"]

  /// Props that need something on screen to hang off, even when nothing is
  /// painted: an accessibility element is a view, and so is a hit-test target.
  static let renderingProps: Set<String> = [
    "testID", "accessibilityLabel", "accessible", "pointerEvents",
  ]

  /// Events that need a view to be delivered from.
  ///
  /// `layout` is the exception that matters: it reports a node's frame, and a
  /// frame comes from the layout tree, which a flattened node is still in. A
  /// list that measures its own viewport therefore costs no view.
  static let renderingEvents: Set<String> = [
    "press", "longPress", "pressIn", "pressOut", "focus", "blur", "changeText", "scroll",
  ]

  /// Does anything in this style paint?
  ///
  /// Presence, not parseability: a `backgroundColor` this host cannot read is
  /// still the app saying the box is meant to be seen, and answering "no view"
  /// would turn an unreadable colour into a missing element.
  static func stylePaints(_ style: XoteStyle) -> Bool {
    if style.values["backgroundColor"] != nil { return true }
    if let width = style.number("borderWidth"), width > 0 { return true }
    if let radius = style.number("borderRadius"), radius > 0 { return true }
    // Only a *reduced* opacity is a reason to exist. `opacity: 1` is the
    // default written down.
    if let opacity = style.number("opacity"), opacity < 1 { return true }
    // Clipping is drawing: it decides what the children look like.
    let overflow = style.string("overflow")
    if overflow == "hidden" || overflow == "scroll" { return true }
    return false
  }

  static func needsView(
    type: String,
    style: XoteStyle,
    props: Set<String>,
    events: Set<String>
  ) -> Bool {
    if !flattenable.contains(type) { return true }
    if stylePaints(style) { return true }
    if !props.isDisjoint(with: renderingProps) { return true }
    if !events.isDisjoint(with: renderingEvents) { return true }
    return false
  }
}
