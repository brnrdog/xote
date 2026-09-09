import UIKit

/// A pool of views, so a list that churns rows stops allocating.
///
/// A transliteration of `native/host/pool.mjs`. **Keep the two in step.**
///
/// `destroy` is the natural place to return a view: the protocol guarantees the
/// id will never be referenced again, which is exactly the guarantee a pool
/// needs. `create` is the natural place to take one back out. Nothing in the
/// command stream changes; the host simply stops asking UIKit for an object it
/// already has.
///
/// Three decisions worth stating:
///
/// **Pools are keyed by kind.** A `UILabel` cannot stand in for a `UIView`. The
/// kind is the node type, which is what decides the class to allocate.
///
/// **Each pool is bounded.** A screen that destroys five thousand rows must not
/// hold five thousand views alive waiting for a sixth thousand that never comes.
///
/// **A view is reset on release, not on acquire.** Releasing already is a
/// teardown; acquiring is on the path trying to be fast. It also means a parked
/// view never holds a reference — a string, an image, a delegate, a gesture
/// recogniser closure — to the screen that put it there, which is the leak this
/// would otherwise introduce.
final class XoteViewPool {
  private var free: [String: [UIView]] = [:]
  private let limit: Int

  private(set) var created = 0
  private(set) var reused = 0
  private(set) var dropped = 0

  init(limit: Int = 64) {
    self.limit = limit
  }

  func acquire(_ kind: String, _ make: () -> UIView) -> UIView {
    if var available = free[kind], !available.isEmpty {
      let view = available.removeLast()
      free[kind] = available
      reused += 1
      return view
    }
    created += 1
    return make()
  }

  /// Hand a view back. Returns whether it was kept, so a caller that needs to
  /// release platform resources on the ones that are not can act on it.
  @discardableResult
  func release(_ kind: String, _ view: UIView) -> Bool {
    var available = free[kind] ?? []
    guard available.count < limit else {
      dropped += 1
      return false
    }
    reset(view)
    available.append(view)
    free[kind] = available
    return true
  }

  var pooled: Int {
    free.values.reduce(0) { $0 + $1.count }
  }

  func clear() {
    free.removeAll()
  }

  /// Everything the host may have written onto a view, put back the way UIKit
  /// hands one over. Anything missed here is a value that leaks into the next
  /// node to be handed this view, which shows up as a row wearing the colour of
  /// a row that scrolled away.
  private func reset(_ view: UIView) {
    view.removeFromSuperview()
    view.isHidden = false
    view.alpha = 1
    view.backgroundColor = nil
    view.clipsToBounds = false
    view.layer.cornerRadius = 0
    view.layer.borderWidth = 0
    view.layer.borderColor = nil
    view.accessibilityIdentifier = nil
    view.accessibilityLabel = nil
    // Not a blanket `true`: `UILabel` and `UIImageView` ship with it off, and a
    // recycled label that swallows touches is a row that stops responding.
    view.isUserInteractionEnabled = !(view is UILabel || view is UIImageView)
    for recognizer in view.gestureRecognizers ?? [] {
      view.removeGestureRecognizer(recognizer)
    }

    if let label = view as? UILabel {
      label.text = nil
      label.numberOfLines = 0
      label.textAlignment = .natural
      label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
      label.textColor = .label
    }
    if let image = view as? UIImageView {
      image.image = nil
    }
    if let field = view as? UITextField {
      // Targets are the ones this host added for `changeText`; the action
      // objects themselves are released alongside, on `destroy`.
      field.removeTarget(nil, action: nil, for: .allEvents)
      field.text = nil
      field.placeholder = nil
      field.isSecureTextEntry = false
      field.isEnabled = true
      field.font = nil
      field.textColor = nil
    }
    if let scroll = view as? UIScrollView {
      scroll.delegate = nil
      scroll.contentOffset = .zero
      scroll.contentSize = .zero
      scroll.alwaysBounceHorizontal = false
    }
  }
}
