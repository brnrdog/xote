import UIKit

/// Hosts one Xote app. The container it creates is the node the app knows as
/// `"root"`, so mounting is the same call a web app makes.
final class XoteViewController: UIViewController {
  private let container = UIView()
  private var host: XoteHost?
  private var bridge: XoteBridge?
  private var dev: XoteDevClient?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black
    view.addSubview(container)

    let host = XoteHost(rootView: container)
    // A `stack` parents its navigation controller here. Without it the stack
    // still renders and neither the transition nor the back swipe works.
    host.presenter = self
    self.host = host

    // Two ways to get an app. With a dev server configured the app runs on
    // your machine and this device only draws it; otherwise the bundle is in
    // the app and JavaScriptCore runs it, which is how it really ships. See
    // `XoteDevClient`.
    if let url = XoteDevClient.configuredURL() {
      let dev = XoteDevClient(host: host, baseURL: url)
      dev.onError = { message in NSLog("%@", message) }
      self.dev = dev
      dev.start()
      return
    }

    let bridge = XoteBridge(host: host)
    self.bridge = bridge
    bridge.start()
  }

  deinit {
    dev?.stop()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // The container is sized here rather than in `viewDidLoad`, where the
    // view's own bounds are not final yet. It covers the whole view rather
    // than the safe area, so the app's own padding decides where content
    // starts — the same as in the web preview.
    container.frame = view.bounds
    // Rotation, a split-screen resize, the first pass after the view has a
    // size: the tree is laid out again against whatever the root is now.
    host?.layoutNow()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    .lightContent
  }
}
