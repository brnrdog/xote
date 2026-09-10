import UIKit

/// Reports a scroll view's offset back to the app.
final class XoteScrollReporter: NSObject, UIScrollViewDelegate {
  private let report: (CGPoint) -> Void

  init(_ report: @escaping (CGPoint) -> Void) {
    self.report = report
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    report(scrollView.contentOffset)
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
/// There are two trees, and they are deliberately not the same shape.
///
/// The **layout tree** has a `XoteLayoutNode` for every node the app made. The
/// **view tree** has a `UIView` only for the nodes that need one: a box that
/// exists to arrange its children is in the first and absent from the second
/// (`XoteFlatten`), and its children attach to the nearest ancestor that does
/// have a view. Views are taken from and returned to a pool (`XoteViewPool`),
/// so a list that churns rows stops allocating.
///
/// Frames come from the layout tree, so neither of those can move anything —
/// which is the property `xote-native/conformance/` pins, by comparing the frames
/// and the view tree separately.
///
/// A batch ends with a single layout pass that writes a `frame` onto every
/// view. Nothing here uses Auto Layout — flexbox and Auto Layout are two
/// constraint systems with different answers, and asking one to imitate the
/// other is what the first version of this host did.
///
/// Everything runs on the main thread; see `XoteBridge`.
final class XoteHost {
  /// The range of bundle protocol versions this host can apply.
  ///
  /// Declared to the JavaScript side through `XoteBridge`, which is where the
  /// handshake happens. `max` must keep step with `PROTOCOL_VERSION` in
  /// `xote-native/src/host/protocol.mjs`; `xote-native/test/protocol_test.mjs` reads both and
  /// fails if they drift. `min` moves only when this host genuinely drops
  /// support for an older bundle, which is the one case that is not survivable
  /// and the reason there is a floor at all.
  static let protocolMin = 1
  static let protocolMax = 1

  /// Called when a view reports something. `XoteBridge` forwards it to the app.
  var onEvent: ((Int, String, [String: Any]) -> Void)?

  /// Called with anything that went wrong and was skipped rather than thrown.
  var onError: ((String) -> Void)?

  /// A view only for the nodes that need one. A missing entry is a flattened
  /// box, not a mistake.
  private var views: [Int: UIView] = [:]
  private var nodes: [Int: XoteLayoutNode] = [:]
  /// A `scroll` lays its children out in an inner box that is free to be taller
  /// than the scroll view itself. That box is where its children go.
  private var contentNodes: [Int: XoteLayoutNode] = [:]
  private var runs: [Int: String] = [:]
  private var runViews: [Int: UILabel] = [:]
  private var labelRuns: [Int: [Int]] = [:]
  private var fonts: [Int: UIFont] = [:]
  /// Kept because `attributedPlaceholder` replaces `placeholder` wholesale, so
  /// the colour and the string have to be written together whichever arrives
  /// second.
  private var placeholderColors: [Int: UIColor] = [:]
  private var lineLimits: [Int: Int] = [:]
  private var actions: [Int: [XoteAction]] = [:]
  private var scrollReporters: [Int: XoteScrollReporter] = [:]
  /// Nodes that asked to hear about their own frame, and what they were last
  /// told, so a layout pass that changed nothing says nothing.
  private var layoutListeners: Set<Int> = []
  private var reportedFrames: [Int: CGRect] = [:]
  /// Every child of every node, runs included — the shape the conformance
  /// suite compares, and the only place the run order is recorded.
  private var childIds: [Int: [Int]] = [:]
  /// The other direction, which flattening needs: finding the nearest ancestor
  /// that has a view means walking up.
  private var parentIds: [Int: Int] = [:]
  private var idsByNode: [ObjectIdentifier: Int] = [:]
  private var idsByView: [ObjectIdentifier: Int] = [:]

  /// What the app said each node is, and what it last said about it. Kept
  /// whether or not there is a view to put it on, because a flattened box that
  /// gains a background has to be able to paint what it was already told.
  private var types: [Int: String] = [:]
  private var styles: [Int: XoteStyle] = [:]
  private var props: [Int: [String: Any]] = [:]
  private var eventNames: [Int: Set<String>] = [:]

  private let pool = XoteViewPool()

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
        types[id] = "#text"

      case let .setProp(id, key, value):
        record(prop: key, value: value, on: id)
        // A style or a prop can be the reason a box is on screen at all, so
        // this comes before painting: there may be nothing to paint on yet.
        reconcileView(id)
        if let view = views[id] {
          paint(prop: key, value: value, on: view, id: id)
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
        destroy(id: id)

      case let .listen(id, event):
        eventNames[id, default: []].insert(event)
        let hadView = views[id] != nil
        // A touch needs something to land on. A `layout` listener does not —
        // a frame comes from the layout tree, which a flattened node is in.
        reconcileView(id)
        if hadView, let view = views[id] {
          listen(view, id: id, event: event)
        } else if views[id] == nil, event == "layout" {
          layoutListeners.insert(id)
        }
        // The remaining case is a box that materialised *because* of this
        // listener. `materialize` replays everything in `eventNames`, so
        // registering here as well would deliver every press twice.
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
    reportLayouts()
  }

  /// Tell the nodes that asked where they ended up. Only when it changed: a
  /// list driven by its own `layout` event would otherwise never settle.
  private func reportLayouts() {
    guard !layoutListeners.isEmpty else { return }
    let snapshot = conformanceSnapshot().frames
    for id in layoutListeners {
      guard let frame = snapshot[id] else { continue }
      let rect = CGRect(x: frame[0], y: frame[1], width: frame[2], height: frame[3])
      if reportedFrames[id] == rect { continue }
      reportedFrames[id] = rect
      onEvent?(
        id, "layout",
        ["x": rect.origin.x, "y": rect.origin.y, "width": rect.width, "height": rect.height])
    }
  }

  /// Walk the layout tree and place the views.
  ///
  /// A box with no view of its own — a scroll's content box, or a flattened
  /// one — does not consume a coordinate space, so its children are placed
  /// relative to it instead. That single `else` is the whole of what flattening
  /// costs the layout pass.
  private func applyFrames(_ node: XoteLayoutNode, origin: CGPoint) {
    var childOrigin = CGPoint.zero
    if let view = node.view as? UIView {
      if view !== rootView {
        // Round the *edges*, not the position and size separately. Rounding a
        // size independently of where it starts lets two boxes that share an
        // edge in the layout end up a point apart on screen — a seam under one
        // row, an overlap under the next.
        let left = origin.x + node.frame.left
        let top = origin.y + node.frame.top
        let x = left.rounded()
        let y = top.rounded()
        view.frame = CGRect(
          x: x,
          y: y,
          width: (left + node.frame.width).rounded() - x,
          height: (top + node.frame.height).rounded() - y
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

  // MARK: - Creating

  private func create(id: Int, type: String) {
    types[id] = type

    if type == "root" {
      // The root already exists; the app is told about it like any other node.
      nodes[id] = rootNode
      views[id] = rootView
      idsByNode[ObjectIdentifier(rootNode)] = id
      idsByView[ObjectIdentifier(rootView)] = id
      return
    }

    let node = XoteLayoutNode()
    if type == "text" {
      node.measure = { [weak self] availableWidth, widthMode, _, _ in
        self?.measureText(id: id, availableWidth: availableWidth, widthMode: widthMode)
          ?? XoteSize(width: 0, height: 0)
      }
    }
    if type == "scroll" {
      let content = XoteLayoutNode()
      contentNodes[id] = content
      node.children = [content]
    }
    nodes[id] = node
    idsByNode[ObjectIdentifier(node)] = id

    // A flattening candidate gets no view until something asks for one. Every
    // other type draws, or owns behaviour, and gets its view now.
    if !XoteFlatten.flattenable.contains(type) {
      materialize(id, type: type, node: node)
    }
  }

  /// The class each primitive maps to, and the settings that are part of being
  /// that primitive rather than part of a style.
  private func makeView(_ type: String) -> UIView {
    switch type {
    case "text", "#text":
      return UILabel()
    case "image":
      return UIImageView()
    case "input":
      return UITextField()
    case "scroll":
      return UIScrollView()
    default:
      // `view`, `pressable`, and any primitive this host does not know by name.
      return UIView()
    }
  }

  /// Re-applied on every acquire, because a pooled view has been reset and a
  /// fresh one has not been configured. Everything here is a property of the
  /// primitive, not of the app's style.
  private func configure(_ view: UIView, type: String) {
    switch type {
    case "text", "#text":
      (view as? UILabel)?.numberOfLines = 0
    case "image":
      let image = view as? UIImageView
      image?.contentMode = .scaleAspectFill
      image?.clipsToBounds = true
    case "scroll":
      // Every frame in the tree is computed by the layout engine, so UIKit must
      // not add safe-area insets of its own on top of them — that shifts the
      // content by the notch and nothing else knows it happened.
      (view as? UIScrollView)?.contentInsetAdjustmentBehavior = .never
    default:
      break
    }
  }

  private func acquireView(_ id: Int, type: String) -> UIView {
    let view = pool.acquire(type) { [weak self] in
      self?.makeView(type) ?? UIView()
    }
    configure(view, type: type)
    idsByView[ObjectIdentifier(view)] = id
    return view
  }

  // MARK: - The view tree
  //
  // Kept incrementally, the way it has to be: there is no pass at the end of a
  // batch that rebuilds it from the layout tree, because that would cost more
  // than flattening saves. It is spliced, and a splice is a thing to get wrong,
  // which is why the conformance suite compares the result.

  /// The nearest ancestor holding a view, or nil when this subtree is detached.
  private func nativeHost(of id: Int) -> Int? {
    var current = parentIds[id]
    while let candidate = current {
      if views[candidate] != nil { return candidate }
      current = parentIds[candidate]
    }
    return nil
  }

  /// The views at the top of `id`'s subtree — its own if it has one, otherwise
  /// the frontier just below the flattened boxes covering it.
  private func renderedRoots(of id: Int, into out: inout [UIView]) {
    if let view = views[id] {
      out.append(view)
      return
    }
    for child in childIds[id] ?? [] {
      renderedRoots(of: child, into: &out)
    }
  }

  private func renderedRoots(of id: Int) -> [UIView] {
    var out: [UIView] = []
    renderedRoots(of: id, into: &out)
    return out
  }

  /// How many views precede `id` inside `host` — its index among subviews.
  private func nativeIndex(of id: Int, under host: Int) -> Int {
    var count = 0
    func walk(_ parent: Int) -> Bool {
      for child in childIds[parent] ?? [] {
        if child == id { return true }
        if views[child] != nil {
          count += 1
        } else if walk(child) {
          return true
        }
      }
      return false
    }
    _ = walk(host)
    return count
  }

  /// Put `id`'s views into the tree at the position its node occupies.
  private func attachViews(of id: Int) {
    guard let host = nativeHost(of: id), let hostView = views[host] else { return }
    var index = nativeIndex(of: id, under: host)
    for view in renderedRoots(of: id) {
      hostView.insertSubview(view, at: min(index, hostView.subviews.count))
      index += 1
    }
  }

  private func detachViews(of id: Int) {
    for view in renderedRoots(of: id) { view.removeFromSuperview() }
  }

  private func materialize(_ id: Int, type: String, node: XoteLayoutNode) {
    let host = nativeHost(of: id)
    let index = host.map { nativeIndex(of: id, under: $0) } ?? 0
    // Whatever was standing in for this node in its host moves inside the new
    // view, in the order it was standing in.
    let standingIn = renderedRoots(of: id)

    let view = acquireView(id, type: type)
    for sub in standingIn { sub.removeFromSuperview() }
    for (at, sub) in standingIn.enumerated() { view.insertSubview(sub, at: at) }

    views[id] = view
    node.view = view

    // Everything the app already said about this node, now that there is
    // somewhere to put it.
    if let style = styles[id] { paint(style: style, on: view, id: id) }
    for (key, value) in props[id] ?? [:] { paint(prop: key, value: value, on: view, id: id) }
    for event in eventNames[id] ?? [] { listen(view, id: id, event: event) }

    if let host = host, let hostView = views[host] {
      hostView.insertSubview(view, at: min(index, hostView.subviews.count))
    }
  }

  private func dematerialize(_ id: Int, type: String, node: XoteLayoutNode) {
    guard let view = views[id] else { return }
    let host = nativeHost(of: id)
    let index = host.map { nativeIndex(of: id, under: $0) } ?? 0

    // Its children take its place in the host, in its position.
    let inner = view.subviews
    for sub in inner { sub.removeFromSuperview() }
    view.removeFromSuperview()

    views[id] = nil
    node.view = nil
    idsByView[ObjectIdentifier(view)] = nil
    // The handlers went with the view; a later materialise re-registers them
    // from `eventNames`, and leaving them here would double-register.
    actions[id] = nil
    scrollReporters[id] = nil
    pool.release(type, view)

    if let host = host, let hostView = views[host] {
      for (at, sub) in inner.enumerated() {
        hostView.insertSubview(sub, at: min(index + at, hostView.subviews.count))
      }
    }
  }

  /// Bring a node's view presence back in line with what it now needs.
  ///
  /// Both directions are rare — a box does not usually start painting halfway
  /// through its life — and both have to be right, because getting one wrong
  /// reorders a screen rather than merely slowing it down.
  private func reconcileView(_ id: Int) {
    guard
      let type = types[id],
      XoteFlatten.flattenable.contains(type),
      let node = nodes[id]
    else { return }

    let want = XoteFlatten.needsView(
      type: type,
      style: styles[id] ?? XoteStyle(nil),
      props: Set((props[id] ?? [:]).keys),
      events: eventNames[id] ?? []
    )
    let has = views[id] != nil
    if want == has { return }

    if want {
      materialize(id, type: type, node: node)
    } else {
      dematerialize(id, type: type, node: node)
    }
  }

  // MARK: - Tree

  /// Where a node's children go in the *layout* tree. Not the same question as
  /// which view holds them — see `nativeHost(of:)` for that one.
  private func layoutContainer(of id: Int) -> XoteLayoutNode? {
    if let content = contentNodes[id] { return content }
    return nodes[id]
  }

  private func insert(child: Int, into parent: Int, at index: Int) {
    // Whether a run gets a view of its own depends on what it landed in, so it
    // is decided here rather than when it was created — and a run can move
    // between the two, which is why both directions are handled.
    if let text = runs[child] {
      if views[parent] is UILabel {
        // Inside a `text`, a run is a piece of the label's string. If it was
        // standing on its own until now, its label goes back to the pool.
        if views[child] != nil { releaseRunView(child: child) }
        var ordered = labelRuns[parent] ?? []
        ordered.insert(child, at: min(index, ordered.count))
        labelRuns[parent] = ordered
        if let previous = parentIds[child], previous != parent {
          childIds[previous]?.removeAll { $0 == child }
        }
        parentIds[child] = parent
        record(child: child, in: parent, at: index)
        renderLabel(parent)
        return
      }

      // Anywhere else it is a node in its own right, and it has to occupy its
      // index whether or not it draws anything — the placeholder a reactive
      // region renders for an absent branch is an empty text node, and dropping
      // it would put every later sibling one slot out of step.
      if nodes[child] == nil {
        if let previous = parentIds[child] {
          labelRuns[previous]?.removeAll { $0 == child }
          renderLabel(previous)
        }
        let label = acquireView(child, type: "#text") as? UILabel ?? UILabel()
        label.text = text
        label.isHidden = text.isEmpty
        runViews[child] = label

        let node = XoteLayoutNode()
        node.view = label
        node.measure = { [weak self] availableWidth, widthMode, _, _ in
          self?.measureText(id: child, availableWidth: availableWidth, widthMode: widthMode)
            ?? XoteSize(width: 0, height: 0)
        }
        nodes[child] = node
        views[child] = label
        idsByNode[ObjectIdentifier(node)] = child
      }
    }

    guard nodes[child] != nil else { return }
    attach(childId: child, to: parent, at: index)
  }

  /// Give a bare run's label back — it has become a piece of someone's string.
  private func releaseRunView(child: Int) {
    guard let view = views[child] else { return }
    view.removeFromSuperview()
    idsByView[ObjectIdentifier(view)] = nil
    if let node = nodes[child] { idsByNode[ObjectIdentifier(node)] = nil }
    if let parent = parentIds[child], let parentNode = layoutContainer(of: parent),
      let node = nodes[child],
      let at = parentNode.children.firstIndex(where: { $0 === node })
    {
      parentNode.children.remove(at: at)
    }
    views[child] = nil
    nodes[child] = nil
    runViews[child] = nil
    pool.release("#text", view)
  }

  private func attach(childId: Int, to parent: Int, at index: Int) {
    guard
      let parentNode = layoutContainer(of: parent),
      let childNode = nodes[childId]
    else { return }

    // Detach first, and while the old host is still reachable: an insert of an
    // already-parented node is a move, and the reconciler does exactly that
    // when a keyed row changes position.
    if parentIds[childId] != nil { detachViews(of: childId) }
    if let previous = parentIds[childId] {
      childIds[previous]?.removeAll { $0 == childId }
    }

    if let existing = parentNode.children.firstIndex(where: { $0 === childNode }) {
      parentNode.children.remove(at: existing)
    }
    let at = min(index, parentNode.children.count)
    parentNode.children.insert(childNode, at: at)

    parentIds[childId] = parent
    record(child: childId, in: parent, at: index)
    attachViews(of: childId)
  }

  private func record(child: Int, in parent: Int, at index: Int) {
    var ordered = childIds[parent] ?? []
    ordered.removeAll { $0 == child }
    ordered.insert(child, at: min(index, ordered.count))
    childIds[parent] = ordered
  }

  private func remove(child: Int, from parent: Int) {
    detachViews(of: child)
    childIds[parent]?.removeAll { $0 == child }
    parentIds[child] = nil

    if runs[child] != nil, runViews[child] == nil {
      labelRuns[parent]?.removeAll { $0 == child }
      renderLabel(parent)
      return
    }
    guard let parentNode = layoutContainer(of: parent) else { return }
    if let childNode = nodes[child],
      let index = parentNode.children.firstIndex(where: { $0 === childNode })
    {
      parentNode.children.remove(at: index)
    }
  }

  private func destroy(id: Int) {
    // A well-behaved bundle removes before it destroys. Detaching here anyway
    // means one that does not cannot leave a view in the tree pointing at an id
    // nothing owns.
    detachViews(of: id)
    // Event targets are retained by hand, so they are released by hand: a list
    // that churns rows would otherwise grow a closure per row per pass. This
    // has to happen before the view goes into the pool, or the pool holds the
    // closure and the closure holds the screen.
    actions[id] = nil
    scrollReporters[id] = nil

    if let view = views[id], let type = types[id] {
      idsByView[ObjectIdentifier(view)] = nil
      // The protocol guarantees the id is never referenced again, which is
      // exactly the guarantee a pool needs to take the view back.
      if view !== rootView { pool.release(type, view) }
    }

    if let node = nodes[id] { idsByNode[ObjectIdentifier(node)] = nil }
    if let parent = parentIds[id] { childIds[parent]?.removeAll { $0 == id } }

    views[id] = nil
    nodes[id] = nil
    contentNodes[id] = nil
    runs[id] = nil
    runViews[id] = nil
    labelRuns[id] = nil
    fonts[id] = nil
    placeholderColors[id] = nil
    lineLimits[id] = nil
    childIds[id] = nil
    parentIds[id] = nil
    types[id] = nil
    styles[id] = nil
    props[id] = nil
    eventNames[id] = nil
    layoutListeners.remove(id)
    reportedFrames[id] = nil
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

  /// Remember what the app said, and give the layout tree the half it needs.
  ///
  /// Separate from painting because a flattened box has nothing to paint on and
  /// still has to lay out — and because a box that later materialises has to be
  /// able to paint what it was told while it had no view.
  private func record(prop key: String, value: Any?, on id: Int) {
    if key == "style" {
      let style = XoteStyle(value as? [String: Any])
      styles[id] = style
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
      return
    }
    if key == "numberOfLines" {
      lineLimits[id] = (value as? Int) ?? 0
    }
    if let value = value {
      props[id, default: [:]][key] = value
    } else {
      props[id]?[key] = nil
    }
  }

  private func paint(prop key: String, value: Any?, on view: UIView, id: Int) {
    switch key {
    case "style":
      paint(style: styles[id] ?? XoteStyle(value as? [String: Any]), on: view, id: id)
    case "value":
      (view as? UITextField)?.text = value as? String
    case "placeholder":
      (view as? UITextField)?.placeholder = value as? String
      refreshPlaceholder(view as? UITextField, id: id)
    case "placeholderTextColor":
      placeholderColors[id] = (value as? String).flatMap { XoteStyle.color(fromHex: $0) }
      refreshPlaceholder(view as? UITextField, id: id)
    case "secureTextEntry":
      (view as? UITextField)?.isSecureTextEntry = (value as? Bool) ?? false
    case "editable":
      (view as? UITextField)?.isEnabled = (value as? Bool) ?? true
    case "numberOfLines":
      (view as? UILabel)?.numberOfLines = (value as? Int) ?? 0
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

  /// `attributedPlaceholder` and `placeholder` are the same storage read two
  /// ways, so setting either alone loses the other. Both go through here.
  private func refreshPlaceholder(_ field: UITextField?, id: Int) {
    guard
      let field = field,
      let color = placeholderColors[id],
      let text = field.placeholder,
      !text.isEmpty
    else { return }
    field.attributedPlaceholder = NSAttributedString(
      string: text, attributes: [.foregroundColor: color])
  }

  private func paint(style: XoteStyle, on view: UIView, id: Int) {
    // Layout reads the style off the node, which `record(prop:value:on:)` has
    // already done. This only has to paint.
    view.alpha = style.number("opacity") ?? 1
    view.backgroundColor = style.color("backgroundColor")

    let radius = style.number("borderRadius") ?? 0
    view.layer.cornerRadius = radius
    view.layer.borderWidth = style.number("borderWidth") ?? 0
    view.layer.borderColor = style.color("borderColor")?.cgColor

    // `overflow: visible` is the flexbox default and the right default for a
    // box — but a scroll view is not a box. It clips as a condition of working:
    // its content is larger than its frame by definition, and the parts that
    // have scrolled out are still drawn, over whatever is above it. Turning
    // that off is how a list ends up painted across the header.
    if view is UIScrollView {
      view.clipsToBounds = true
    } else {
      view.clipsToBounds = radius > 0 || style.string("overflow") == "hidden"
    }

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

    case "scroll":
      guard let scroll = view as? UIScrollView else { return }
      let reporter = XoteScrollReporter { [weak self] offset in
        self?.onEvent?(id, "scroll", ["x": offset.x, "y": offset.y])
      }
      scrollReporters[id] = reporter
      scroll.delegate = reporter

    case "layout":
      layoutListeners.insert(id)

    // The four `UITextField` events are the same three lines with a different
    // `UIControl.Event`. `addTarget` holds its target weakly, and `actions[id]`
    // holds it strongly until `destroy`, so the closure capturing `field` is
    // not a cycle.
    case "changeText":
      guard let field = view as? UITextField else { return }
      let action = XoteAction { [weak self] in
        self?.onEvent?(id, "changeText", ["value": field.text ?? ""])
      }
      actions[id, default: []].append(action)
      field.addTarget(action, action: #selector(XoteAction.fire), for: .editingChanged)

    case "submit":
      guard let field = view as? UITextField else { return }
      let action = XoteAction { [weak self] in
        self?.onEvent?(id, "submit", ["value": field.text ?? ""])
      }
      actions[id, default: []].append(action)
      field.addTarget(action, action: #selector(XoteAction.fire), for: .editingDidEndOnExit)

    case "focus":
      guard let field = view as? UITextField else { return }
      let action = XoteAction { [weak self] in
        self?.onEvent?(id, "focus", ["value": field.text ?? ""])
      }
      actions[id, default: []].append(action)
      field.addTarget(action, action: #selector(XoteAction.fire), for: .editingDidBegin)

    case "blur":
      guard let field = view as? UITextField else { return }
      let action = XoteAction { [weak self] in
        self?.onEvent?(id, "blur", ["value": field.text ?? ""])
      }
      actions[id, default: []].append(action)
      field.addTarget(action, action: #selector(XoteAction.fire), for: .editingDidEnd)

    default:
      // An event this host does not raise yet. The app is never told, which is
      // indistinguishable from it not happening.
      break
    }
  }

  // MARK: - Inspection

  /// What the conformance suite compares: the node tree, every frame in root
  /// coordinates, the text as it would be shown, and — separately — the *view*
  /// tree, which is the only place a flattening disagreement shows up.
  func conformanceSnapshot() -> (
    structure: [Int: [Int]], frames: [Int: [CGFloat]], texts: [Int: String],
    views: [Int: [Int]]
  ) {
    // Frames are in **root coordinates**, which is what makes them comparable
    // against a host that arranges its views differently — and, now, against
    // this one, which arranges them differently depending on what it flattened.
    // So every node passes its own absolute position down, whether or not it
    // has a view and whether or not it has an id. This is not the same walk as
    // `applyFrames`, which writes UIKit frames and those are relative to a
    // superview; conflating the two produces frames that are correct on screen
    // and wrong in every comparison.
    var frames: [Int: [CGFloat]] = [:]
    func walk(_ node: XoteLayoutNode, _ originX: CGFloat, _ originY: CGFloat) {
      let left = originX + node.frame.left
      let top = originY + node.frame.top
      if let id = idsByNode[ObjectIdentifier(node)] {
        frames[id] = [left, top, node.frame.width, node.frame.height]
      }
      // A scroll's content box has no id of its own and still contributes its
      // offset, which is why this is outside the `if`.
      for child in node.children { walk(child, left, top) }
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

    var viewTree: [Int: [Int]] = [:]
    func walkViews(_ view: UIView) {
      guard let id = idsByView[ObjectIdentifier(view)] else { return }
      viewTree[id] = view.subviews.compactMap { idsByView[ObjectIdentifier($0)] }
      for sub in view.subviews { walkViews(sub) }
    }
    walkViews(rootView)

    return (childIds, frames, texts, viewTree)
  }

  /// Allocation behaviour, for tests and for anyone measuring a real screen.
  func poolStats() -> (created: Int, reused: Int, dropped: Int, pooled: Int) {
    (pool.created, pool.reused, pool.dropped, pool.pooled)
  }
}
