import UIKit

/// Hosts one Xote app. The container it creates is the node the app knows as
/// `"root"`, so mounting is the same call a web app makes.
final class XoteViewController: UIViewController {
  private let container = UIView()
  private var host: XoteHost?
  private var bridge: XoteBridge?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black
    // Pinned to the full view rather than the safe area, so the app's own
    // padding decides where content starts — the same as in the web preview.
    container.frame = view.bounds
    container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(container)

    let host = XoteHost(rootView: container)
    self.host = host
    let bridge = XoteBridge(host: host)
    self.bridge = bridge
    bridge.start()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // Rotation, a split-screen resize, the first pass after the view has a
    // size: the tree is laid out again against whatever the root is now.
    host?.layoutNow()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    .lightContent
  }
}
