import UIKit

/// A stack view that also draws, and that knows how to leave slack alone.
///
/// Every `view`, `pressable`, and the inside of a `scroll` is one of these.
/// `UIStackView` renders its own background from iOS 14, so a box needs no
/// wrapper view.
final class XoteBox: UIStackView {
  /// A zero-content view that soaks up leftover space when nothing else will.
  ///
  /// `justifyContent: flex-start` is the flexbox default and the one thing
  /// `UIStackView` has no spelling for: with `.fill` distribution it must
  /// consume its whole axis, so a column of intrinsically-sized children ends
  /// up with one of them stretched instead of the column being top-packed.
  /// A trailing view that wants space less than anything else fixes that.
  private let slack = UIView()

  /// False for `space-between` and friends, where `UIStackView` distributes the
  /// leftover space itself and a slack view would eat it first.
  var packsToStart = true {
    didSet { updateSlack() }
  }

  var childCount: Int {
    arrangedSubviews.count - (slack.superview === self ? 1 : 0)
  }

  func insertChild(_ view: UIView, at index: Int) {
    insertArrangedSubview(view, at: min(index, childCount))
    updateSlack()
  }

  func removeChild(_ view: UIView) {
    removeArrangedSubview(view)
    view.removeFromSuperview()
    updateSlack()
  }

  /// Call after a child's hugging priority changes — a child that became
  /// flexible makes the slack view unnecessary.
  func updateSlack() {
    let children = arrangedSubviews.filter { $0 !== slack }
    let hasFlexibleChild = children.contains {
      $0.contentHuggingPriority(for: axis) < UILayoutPriority.defaultLow
    }
    let wanted = packsToStart && !children.isEmpty && !hasFlexibleChild

    if wanted {
      slack.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
      slack.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
      if slack.superview !== self {
        addArrangedSubview(slack)
      } else if arrangedSubviews.last !== slack {
        removeArrangedSubview(slack)
        addArrangedSubview(slack)
      }
    } else if slack.superview === self {
      removeArrangedSubview(slack)
      slack.removeFromSuperview()
    }
  }
}

/// A label that tells Auto Layout how wide it is allowed to wrap.
///
/// A multi-line `UILabel` has no intrinsic height until it knows its width, and
/// inside a stack view it learns its width only after being laid out — so the
/// first pass measures it as one line and the text is clipped or the row is the
/// wrong height. Feeding the resolved width back is the standard fix.
final class XoteLabel: UILabel {
  override func layoutSubviews() {
    super.layoutSubviews()
    guard numberOfLines != 1, preferredMaxLayoutWidth != bounds.width else { return }
    preferredMaxLayoutWidth = bounds.width
    setNeedsUpdateConstraints()
  }
}

/// `scroll` is a scroll view wrapped around one box; children land in the box.
final class XoteScroll: UIScrollView {
  let content = XoteBox()

  override init(frame: CGRect) {
    super.init(frame: frame)
    content.axis = .vertical
    content.alignment = .fill
    content.translatesAutoresizingMaskIntoConstraints = false
    addSubview(content)
    NSLayoutConstraint.activate([
      content.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
      content.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
      content.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
      content.widthAnchor.constraint(equalTo: frameLayoutGuide.widthAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("XoteScroll is built in code, not a nib")
  }
}

/// Retains a closure so it can be a target for a gesture recogniser or a control.
final class XoteAction: NSObject {
  private let run: () -> Void

  init(_ run: @escaping () -> Void) {
    self.run = run
  }

  @objc func fire() {
    run()
  }
}

/// Applies the bridge protocol to UIKit.
///
/// Everything here runs on the main thread. JavaScriptCore calls `apply`
/// synchronously on whichever thread called into JavaScript, and this host is
/// only ever driven from the main thread — see `XoteBridge`.
final class XoteHost {
  /// Called when a view reports something. `XoteBridge` forwards it to the app.
  var onEvent: ((Int, String, [String: Any]) -> Void)?

  private var views: [Int: UIView] = [:]
  private var runs: [Int: String] = [:]
  private var labelRuns: [Int: [Int]] = [:]
  private var runViews: [Int: UILabel] = [:]
  private var widths: [Int: NSLayoutConstraint] = [:]
  private var heights: [Int: NSLayoutConstraint] = [:]
  private var actions: [Int: [XoteAction]] = [:]

  private let rootView: XoteBox

  init(rootView: XoteBox) {
    self.rootView = rootView
  }

  // MARK: - Applying a batch

  func apply(_ json: String) {
    for command in XoteCommand.decodeBatch(json) {
      switch command {
      case let .create(id, type):
        create(id: id, type: type)

      case let .createText(id, text):
        runs[id] = text

      case let .setProp(id, key, value):
        if let view = views[id] {
          setProp(view, id: id, key: key, value: value)
        }

      case let .setText(id, text):
        runs[id] = text
        if let label = runViews[id] {
          label.text = text
          label.isHidden = text.isEmpty
        }
        renderLabels(containing: id)

      case let .insert(parent, child, index):
        insert(child: child, into: parent, at: index)

      case let .remove(parent, child):
        remove(child: child, from: parent)

      case let .destroy(id):
        views[id] = nil
        runs[id] = nil
        runViews[id] = nil
        labelRuns[id] = nil
        widths[id] = nil
        heights[id] = nil
        // Event targets have to be retained by hand, so they have to be
        // released by hand: a list that churns rows would otherwise grow one
        // closure per row per pass, for the life of the app.
        actions[id] = nil

      case let .listen(id, event):
        if let view = views[id] {
          listen(view, id: id, event: event)
        }
      }
    }
  }

  private func create(id: Int, type: String) {
    let view: UIView
    switch type {
    case "root":
      // The root already exists; the app is told about it like any other node.
      view = rootView
    case "text":
      let label = XoteLabel()
      label.numberOfLines = 0
      view = label
    case "image":
      let image = UIImageView()
      image.contentMode = .scaleAspectFill
      image.clipsToBounds = true
      view = image
    case "input":
      view = UITextField()
    case "scroll":
      view = XoteScroll()
    default:
      // `view`, `pressable`, and any primitive this host does not know by name.
      let box = XoteBox()
      box.axis = .vertical
      box.alignment = .fill
      view = box
    }
    if view !== rootView {
      view.translatesAutoresizingMaskIntoConstraints = false
    }
    views[id] = view
  }

  // MARK: - Tree

  /// Where a node's children go. Only a box (or a scroll's box) holds views; a
  /// label holds text runs instead.
  private func box(of view: UIView) -> XoteBox? {
    if let scroll = view as? XoteScroll {
      return scroll.content
    }
    return view as? XoteBox
  }

  private func insert(child: Int, into parent: Int, at index: Int) {
    guard let parentView = views[parent] else { return }

    if let text = runs[child] {
      // Inside a `text`, a run is a piece of the label's string.
      if parentView is UILabel {
        var ordered = labelRuns[parent] ?? []
        ordered.insert(child, at: min(index, ordered.count))
        labelRuns[parent] = ordered
        renderLabel(parent)
        return
      }
      // Anywhere else it is a node in its own right, and it has to occupy its
      // index whether or not it draws anything — the reactive placeholder that
      // stands in for an absent branch is an empty text node, and dropping it
      // would put every later sibling one slot out of step.
      let label = runViews[child] ?? XoteLabel()
      label.numberOfLines = 0
      label.translatesAutoresizingMaskIntoConstraints = false
      label.text = text
      label.isHidden = text.isEmpty
      runViews[child] = label
      box(of: parentView)?.insertChild(label, at: index)
      return
    }

    guard let childView = views[child] else { return }

    guard let box = box(of: parentView) else {
      // Nothing in the current vocabulary produces this, so it is worth hearing
      // about in a debug build rather than silently dropping the child.
      assertionFailure("Xote: \(type(of: parentView)) cannot hold child views")
      return
    }
    box.insertChild(childView, at: index)
  }

  private func remove(child: Int, from parent: Int) {
    guard let parentView = views[parent] else { return }

    if runs[child] != nil {
      if let label = runViews[child] {
        box(of: parentView)?.removeChild(label)
      } else {
        labelRuns[parent]?.removeAll { $0 == child }
        renderLabel(parent)
      }
      return
    }
    guard let childView = views[child] else { return }
    box(of: parentView)?.removeChild(childView)
  }

  private func renderLabel(_ id: Int) {
    guard let label = views[id] as? UILabel else { return }
    label.text = (labelRuns[id] ?? []).compactMap { runs[$0] }.joined()
  }

  private func renderLabels(containing run: Int) {
    for (id, ordered) in labelRuns where ordered.contains(run) {
      renderLabel(id)
    }
  }

  // MARK: - Props

  private func setProp(_ view: UIView, id: Int, key: String, value: Any?) {
    switch key {
    case "style":
      apply(style: XoteStyle(value as? [String: Any]), to: view, id: id)
    case "value":
      (view as? UITextField)?.text = value as? String
    case "placeholder":
      (view as? UITextField)?.placeholder = value as? String
    case "secureTextEntry":
      (view as? UITextField)?.isSecureTextEntry = (value as? Bool) ?? false
    case "editable":
      (view as? UITextField)?.isEnabled = (value as? Bool) ?? true
    case "numberOfLines":
      (view as? UILabel)?.numberOfLines = (value as? Int) ?? 0
    case "horizontal":
      (view as? XoteScroll)?.content.axis = (value as? Bool) == true ? .horizontal : .vertical
    case "source":
      load(source: value, into: view as? UIImageView)
    case "testID":
      view.accessibilityIdentifier = value as? String
    case "accessibilityLabel":
      view.accessibilityLabel = value as? String
    default:
      break
    }
  }

  private func apply(style: XoteStyle, to view: UIView, id: Int) {
    view.alpha = style.number("opacity") ?? 1

    if let background = style.color("backgroundColor") {
      view.backgroundColor = background
    }
    if let radius = style.number("borderRadius") {
      view.layer.cornerRadius = radius
      view.clipsToBounds = true
    }
    if let width = style.number("borderWidth") {
      view.layer.borderWidth = width
    }
    if let color = style.color("borderColor") {
      view.layer.borderColor = color.cgColor
    }

    if let label = view as? UILabel {
      label.font = style.font
      label.textAlignment = style.textAlignment
      if let color = style.color("color") {
        label.textColor = color
      }
    }

    if let field = view as? UITextField {
      field.font = style.font
      if let color = style.color("color") {
        field.textColor = color
      }
    }

    if let box = box(of: view) {
      let isRow = style.isRow
      box.axis = isRow ? .horizontal : .vertical
      box.spacing = style.number("gap") ?? 0
      box.alignment = style.alignment(isRow: isRow)
      box.distribution = style.distribution
      box.packsToStart = box.distribution == .fill
      box.isLayoutMarginsRelativeArrangement = true
      box.directionalLayoutMargins = style.insets("padding")
    }

    size(view, id: id, width: style.number("width"), height: style.number("height"))

    // `flex` grows a child along its parent's axis. UIStackView gives slack to
    // whichever arranged subview hugs its content least, so a flexible child
    // only has to want its size less than its siblings do.
    //
    // A view with no `flex` is left at UIKit's own hugging priority rather than
    // pushed down to `.defaultLow`. That distinction matters for leaves: a
    // `UILabel` defaults to 251 — one point above `.defaultLow` — which is
    // precisely how it says "I am as big as my text". Overriding that to 250
    // makes every label the most stretchable thing in its row, and the text
    // ends up in a box the wrong size.
    let flex = style.number("flex") ?? style.number("flexGrow") ?? 0
    if flex > 0 {
      view.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
      view.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
    } else if view is XoteBox || view is XoteScroll {
      // A box has no content of its own to hug, so it takes the default that
      // says so — and this restores it if the view used to be flexible.
      view.setContentHuggingPriority(.defaultLow, for: .horizontal)
      view.setContentHuggingPriority(.defaultLow, for: .vertical)
    }
    (view.superview as? XoteBox)?.updateSlack()
  }

  private func size(_ view: UIView, id: Int, width: CGFloat?, height: CGFloat?) {
    if let width = width {
      let constraint = widths[id] ?? view.widthAnchor.constraint(equalToConstant: width)
      constraint.constant = width
      constraint.isActive = true
      widths[id] = constraint
    }
    if let height = height {
      let constraint = heights[id] ?? view.heightAnchor.constraint(equalToConstant: height)
      constraint.constant = height
      constraint.isActive = true
      heights[id] = constraint
    }
  }

  private func load(source: Any?, into imageView: UIImageView?) {
    guard let imageView = imageView else { return }
    let uri = (source as? String) ?? ((source as? [String: Any])?["uri"] as? String)
    guard let uri = uri, let url = URL(string: uri) else { return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data = data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async { imageView.image = image }
    }.resume()
  }

  // MARK: - Events

  private func listen(_ view: UIView, id: Int, event: String) {
    switch event {
    case "press":
      let action = XoteAction { [weak self] in self?.onEvent?(id, "press", [:]) }
      actions[id, default: []].append(action)
      view.addGestureRecognizer(
        UITapGestureRecognizer(target: action, action: #selector(XoteAction.fire)))
      view.isUserInteractionEnabled = true

    case "longPress":
      let action = XoteAction { [weak self] in self?.onEvent?(id, "longPress", [:]) }
      actions[id, default: []].append(action)
      view.addGestureRecognizer(
        UILongPressGestureRecognizer(target: action, action: #selector(XoteAction.fire)))
      view.isUserInteractionEnabled = true

    case "changeText":
      guard let field = view as? UITextField else { return }
      let action = XoteAction { [weak self] in
        self?.onEvent?(id, "changeText", ["value": field.text ?? ""])
      }
      actions[id, default: []].append(action)
      field.addTarget(action, action: #selector(XoteAction.fire), for: .editingChanged)

    default:
      // An event this host does not raise yet. The app is never told, which is
      // indistinguishable from it not happening.
      break
    }
  }
}
