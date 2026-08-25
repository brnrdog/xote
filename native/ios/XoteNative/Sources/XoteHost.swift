import UIKit

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
/// There are two trees: the views, and a `XoteLayoutNode` shadowing each one.
/// The bridge mutates both, and a batch ends with a single layout pass that
/// writes a `frame` onto every view. Nothing here uses Auto Layout — flexbox
/// and Auto Layout are two constraint systems with different answers, and
/// asking one to imitate the other is what the first version of this host did.
///
/// Everything runs on the main thread; see `XoteBridge`.
final class XoteHost {
  /// Called when a view reports something. `XoteBridge` forwards it to the app.
  var onEvent: ((Int, String, [String: Any]) -> Void)?

  /// Called with anything that went wrong and was skipped rather than thrown.
  var onError: ((String) -> Void)?

  private var views: [Int: UIView] = [:]
  private var nodes: [Int: XoteLayoutNode] = [:]
  /// A `scroll` lays its children out in an inner box that is free to be taller
  /// than the scroll view itself. That box is where its children go.
  private var contentNodes: [Int: XoteLayoutNode] = [:]
  private var runs: [Int: String] = [:]
  private var runViews: [Int: UILabel] = [:]
  private var labelRuns: [Int: [Int]] = [:]
  private var fonts: [Int: UIFont] = [:]
  private var lineLimits: [Int: Int] = [:]
  private var actions: [Int: [XoteAction]] = [:]
  /// Every child of every node, runs included — the shape the conformance
  /// suite compares, and the only place the run order is recorded.
  private var childIds: [Int: [Int]] = [:]
  private var idsByNode: [ObjectIdentifier: Int] = [:]

  private let rootView: UIView
  private let rootNode = XoteLayoutNode()

  /// Replaces real font metrics while running the conformance suite. Two hosts
  /// can agree on layout; `UILabel` and Chromium will never agree on fonts.
  var measureOverride: ((String, CGFloat?, XoteMeasureMode) -> XoteSize)?

  init(rootView: UIView) {
    self.rootView = rootView
    rootNode.view = rootView
  }

  // MARK: - Applying a batch

  func apply(_ json: String) {
    let (commands, problems) = XoteCommand.decodeBatch(json)
    for problem in problems { onError?(problem) }
    for command in commands {
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
        nodes[id] = nil
        contentNodes[id] = nil
        runs[id] = nil
        runViews[id] = nil
        labelRuns[id] = nil
        fonts[id] = nil
        lineLimits[id] = nil
        childIds[id] = nil
        if let node = nodes[id] { idsByNode[ObjectIdentifier(node)] = nil }
        // Event targets are retained by hand, so they are released by hand: a
        // list that churns rows would otherwise grow a closure per row per pass.
        actions[id] = nil

      case let .listen(id, event):
        if let view = views[id] {
          listen(view, id: id, event: event)
        }
      }
    }

    layoutNow()
  }

  /// Lay the tree out and write every frame. Called at the end of each batch,
  /// and again by the view controller when the root's size changes.
  func layoutNow() {
    let size = rootView.bounds.size
    guard size.width > 0, size.height > 0 else { return }
    XoteLayout.layout(rootNode, width: size.width, height: size.height)
    applyFrames(rootNode, origin: .zero)
  }

  /// Walk the layout tree and place the views.
  ///
  /// A box with no view of its own — a scroll's content box — does not consume
  /// a coordinate space, so its children are placed relative to it instead.
  private func applyFrames(_ node: XoteLayoutNode, origin: CGPoint) {
    var childOrigin = CGPoint.zero
    if let view = node.view as? UIView {
      if view !== rootView {
        view.frame = CGRect(
          x: (origin.x + node.frame.left).rounded(),
          y: (origin.y + node.frame.top).rounded(),
          width: node.frame.width.rounded(),
          height: node.frame.height.rounded()
        )
      }
      if let scroll = view as? UIScrollView, let content = node.children.first {
        scroll.contentSize = CGSize(width: content.frame.width, height: content.frame.height)
      }
    } else {
      childOrigin = CGPoint(x: origin.x + node.frame.left, y: origin.y + node.frame.top)
    }
    for child in node.children {
      applyFrames(child, origin: childOrigin)
    }
  }

  private func create(id: Int, type: String) {
    let node = XoteLayoutNode()
    let view: UIView

    switch type {
    case "root":
      // The root already exists; the app is told about it like any other node.
      nodes[id] = rootNode
      views[id] = rootView
      idsByNode[ObjectIdentifier(rootNode)] = id
      return
    case "text":
      let label = UILabel()
      label.numberOfLines = 0
      view = label
      node.measure = { [weak self] availableWidth, widthMode, _, _ in
        self?.measureText(id: id, availableWidth: availableWidth, widthMode: widthMode)
          ?? XoteSize(width: 0, height: 0)
      }
    case "image":
      let image = UIImageView()
      image.contentMode = .scaleAspectFill
      image.clipsToBounds = true
      view = image
    case "input":
      view = UITextField()
    case "scroll":
      let scroll = UIScrollView()
      let content = XoteLayoutNode()
      contentNodes[id] = content
      node.children = [content]
      view = scroll
    default:
      // `view`, `pressable`, and any primitive this host does not know by name.
      view = UIView()
    }

    node.view = view
    views[id] = view
    nodes[id] = node
    idsByNode[ObjectIdentifier(node)] = id
  }

  // MARK: - Tree

  /// Where a node's children go, and which view holds them.
  private func container(of id: Int) -> (node: XoteLayoutNode, view: UIView)? {
    guard let view = views[id], let node = nodes[id] else { return nil }
    if let content = contentNodes[id] { return (content, view) }
    return (node, view)
  }

  private func insert(child: Int, into parent: Int, at index: Int) {
    guard let parentView = views[parent] else { return }

    if let text = runs[child] {
      // Inside a `text`, a run is a piece of the label's string.
      if parentView is UILabel {
        var ordered = labelRuns[parent] ?? []
        ordered.insert(child, at: min(index, ordered.count))
        labelRuns[parent] = ordered
        record(child: child, in: parent, at: index)
        renderLabel(parent)
        return
      }
      // Anywhere else it is a node in its own right, and it has to occupy its
      // index whether or not it draws anything — the placeholder a reactive
      // region renders for an absent branch is an empty text node, and dropping
      // it would put every later sibling one slot out of step.
      let label = runViews[child] ?? UILabel()
      label.numberOfLines = 0
      label.text = text
      label.isHidden = text.isEmpty
      runViews[child] = label

      let node = nodes[child] ?? XoteLayoutNode()
      node.view = label
      node.measure = { [weak self] availableWidth, widthMode, _, _ in
        self?.measureText(id: child, availableWidth: availableWidth, widthMode: widthMode)
          ?? XoteSize(width: 0, height: 0)
      }
      nodes[child] = node
      views[child] = label
      idsByNode[ObjectIdentifier(node)] = child
      attach(childId: child, to: parent, at: index)
      return
    }

    guard views[child] != nil else { return }
    attach(childId: child, to: parent, at: index)
  }

  private func attach(childId: Int, to parent: Int, at index: Int) {
    guard
      let (parentNode, parentView) = container(of: parent),
      let childNode = nodes[childId],
      let childView = views[childId]
    else { return }

    // Detach first: an insert of an already-parented node is a move, and the
    // reconciler does exactly that when a keyed row changes position.
    if let existing = parentNode.children.firstIndex(where: { $0 === childNode }) {
      parentNode.children.remove(at: existing)
    }
    let at = min(index, parentNode.children.count)
    parentNode.children.insert(childNode, at: at)
    parentView.insertSubview(childView, at: at)
    record(child: childId, in: parent, at: index)
  }

  private func record(child: Int, in parent: Int, at index: Int) {
    var ordered = childIds[parent] ?? []
    ordered.removeAll { $0 == child }
    ordered.insert(child, at: min(index, ordered.count))
    childIds[parent] = ordered
  }

  private func remove(child: Int, from parent: Int) {
    childIds[parent]?.removeAll { $0 == child }
    guard let (parentNode, _) = container(of: parent) else { return }
    if let childNode = nodes[child],
      let index = parentNode.children.firstIndex(where: { $0 === childNode })
    {
      parentNode.children.remove(at: index)
    }
    if runs[child] != nil, runViews[child] == nil {
      labelRuns[parent]?.removeAll { $0 == child }
      renderLabel(parent)
      return
    }
    views[child]?.removeFromSuperview()
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

  // MARK: - Text measurement

  /// The one thing the host knows and the layout engine cannot: how big a piece
  /// of text is at a given width.
  private func measureText(
    id: Int,
    availableWidth: CGFloat?,
    widthMode: XoteMeasureMode
  ) -> XoteSize {
    let text = (views[id] as? UILabel)?.text ?? ""
    if let override = measureOverride {
      return override(text, availableWidth, widthMode)
    }
    if text.isEmpty { return XoteSize(width: 0, height: 0) }

    let font = fonts[id] ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
    let constraint: CGFloat
    if widthMode == .undefined || availableWidth == nil {
      constraint = .greatestFiniteMagnitude
    } else {
      constraint = availableWidth!
    }

    var bounds = (text as NSString).boundingRect(
      with: CGSize(width: constraint, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    )

    if let limit = lineLimits[id], limit > 0 {
      bounds.size.height = min(bounds.size.height, font.lineHeight * CGFloat(limit))
    }

    return XoteSize(
      width: widthMode == .exactly ? (availableWidth ?? 0) : ceil(bounds.width),
      height: ceil(bounds.height)
    )
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
      let limit = (value as? Int) ?? 0
      lineLimits[id] = limit
      (view as? UILabel)?.numberOfLines = limit
    case "horizontal":
      // Redundant with `flexDirection` on the content box, which is what
      // actually decides which way the content runs.
      (view as? UIScrollView)?.alwaysBounceHorizontal = (value as? Bool) ?? false
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
    // Layout reads the style straight off the node, so this only has to paint.
    if let content = contentNodes[id] {
      // A scroll view is two boxes: the frame its parent positions, and the
      // content its children are arranged in, which is free to be longer. The
      // style is split between them accordingly.
      let split = splitScrollStyle(style.values)
      nodes[id]?.style = XoteStyle(split.frame)
      content.style = XoteStyle(split.content)
    } else {
      nodes[id]?.style = style
    }

    view.alpha = style.number("opacity") ?? 1
    view.backgroundColor = style.color("backgroundColor")

    let radius = style.number("borderRadius") ?? 0
    view.layer.cornerRadius = radius
    view.clipsToBounds = radius > 0 || style.string("overflow") == "hidden"
    view.layer.borderWidth = style.number("borderWidth") ?? 0
    view.layer.borderColor = style.color("borderColor")?.cgColor

    if let label = view as? UILabel {
      fonts[id] = style.font
      label.font = style.font
      label.textAlignment = style.textAlignment
      label.textColor = style.color("color") ?? label.textColor
    }

    if let field = view as? UITextField {
      fonts[id] = style.font
      field.font = style.font
      field.textColor = style.color("color") ?? field.textColor
    }
  }

  /// Everything about how children are arranged belongs to the content box;
  /// everything about how big the scroll view is belongs to the frame.
  private func splitScrollStyle(
    _ values: [String: Any]
  ) -> (frame: [String: Any], content: [String: Any]) {
    let arrangement = [
      "flexDirection", "justifyContent", "alignItems", "gap", "rowGap", "columnGap",
      "padding", "paddingTop", "paddingRight", "paddingBottom", "paddingLeft",
      "paddingHorizontal", "paddingVertical",
    ]
    var frame = values
    var content: [String: Any] = [:]
    for key in arrangement where values[key] != nil {
      content[key] = values[key]
      frame[key] = nil
    }
    return (frame, content)
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

  // MARK: - Inspection

  /// What the conformance suite compares: the tree, every frame in root
  /// coordinates, and the text as it would be shown.
  func conformanceSnapshot() -> (
    structure: [Int: [Int]], frames: [Int: [CGFloat]], texts: [Int: String]
  ) {
    var frames: [Int: [CGFloat]] = [:]
    func walk(_ node: XoteLayoutNode, _ originX: CGFloat, _ originY: CGFloat) {
      let left = originX + node.frame.left
      let top = originY + node.frame.top
      var childOriginX = CGFloat(0)
      var childOriginY = CGFloat(0)
      if let id = idsByNode[ObjectIdentifier(node)] {
        frames[id] = [left, top, node.frame.width, node.frame.height]
      } else {
        // A scroll's content box has no id and no coordinate space of its own.
        childOriginX = left
        childOriginY = top
      }
      for child in node.children { walk(child, childOriginX, childOriginY) }
    }
    walk(rootNode, 0, 0)

    var texts: [Int: String] = [:]
    for (id, view) in views {
      if let label = view as? UILabel, runViews[id] == nil || labelRuns[id] != nil {
        texts[id] = label.text ?? ""
      }
    }
    for (id, label) in runViews {
      texts[id] = label.text ?? ""
    }

    return (childIds, frames, texts)
  }
}
