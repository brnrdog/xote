import UIKit

/// Hosts one Xote app. The container it creates is the node the app knows as
/// `"root"`, so mounting is the same call a web app makes.
final class XoteViewController: UIViewController {
  private let container = XoteBox()
  private var bridge: XoteBridge?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black
    container.axis = .vertical
    container.alignment = .fill
    container.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(container)

    // Pinned to the full view rather than the safe area, so the app's own
    // padding decides where content starts — the same as in the web preview.
    NSLayoutConstraint.activate([
      container.topAnchor.constraint(equalTo: view.topAnchor),
      container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])

    let bridge = XoteBridge(host: XoteHost(rootView: container))
    self.bridge = bridge
    bridge.start()
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    .lightContent
  }
}
