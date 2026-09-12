import UIKit

/// Navigation: `stack` and `screen`, backed by a real `UINavigationController`.
///
/// The design and the rules it has to keep are in
/// `xote-native/src/host/navigation.mjs`, which is the specification this is a
/// transliteration of. The short version: push and pop are `INSERT` and
/// `REMOVE` of a `screen` in a `stack`, and the one case where UIKit moves
/// first — a back swipe — is reported to the app as `stackChange` rather than
/// acted on behind its back.
///
/// Using the real thing rather than imitating it is the whole point. The slide
/// transition, the interactive edge-swipe with its rubber-banding and its
/// cancel, and the focus order VoiceOver expects when a screen changes are all
/// several months of work to reproduce and none of them would be right.

/// One screen: a view controller whose view is the box the app rendered.
///
/// It owns nothing else. The view comes from the pool like any other, the
/// frames come from the flexbox engine, and this exists so that UIKit has a
/// view controller to push — which is the unit a navigation controller deals
/// in, and the unit its transitions and its gesture are written against.
final class XoteScreenController: UIViewController {
  /// The node id of the `screen` this is showing. The host looks it up on the
  /// way back out of a pop, which is the only thing it is read for.
  let nodeID: Int

  private let content: UIView

  init(nodeID: Int, content: UIView) {
    self.nodeID = nodeID
    self.content = content
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("XoteScreenController is created in code")
  }

  override func loadView() {
    // The app's box *is* the controller's view rather than a subview of one.
    // A wrapper would be a second view per screen for nothing, and it would
    // put a coordinate space between the engine's frames and the screen.
    view = content
  }
}

/// One `stack`.
///
/// A `UINavigationController` with its bar hidden — screens draw their own
/// headers for now, which keeps this change about the stack and leaves the
/// title/back-button/large-title surface for when it is designed rather than
/// inherited by accident.
final class XoteStackController: UINavigationController, UINavigationControllerDelegate,
  UIGestureRecognizerDelegate
{
  /// Called when *the platform* popped — a back swipe, or a back button —
  /// with the screens still on the stack afterwards.
  ///
  /// Not called for a pop the host performed itself: those the app already
  /// knows about, and reporting them would send it round the loop again.
  var onPlatformPop: ((_ poppedScreen: Int, _ depth: Int) -> Void)?

  /// Set while the host is applying a batch, so `didShow` can tell a pop the
  /// app asked for from one the person performed.
  var isApplyingHostChange = false

  /// Whether the app registered `stackChange`. Without it the platform is not
  /// allowed to pop at all — see `navigation.mjs` — which keeps an app that
  /// has not opted in one where nothing but the app moves the tree.
  var platformPopEnabled = false {
    didSet { interactivePopGestureRecognizer?.isEnabled = platformPopEnabled }
  }

  /// What UIKit was showing last time it settled, so a pop can be recognised by
  /// what left rather than by being told.
  private var lastShown: [Int] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    isNavigationBarHidden = true
    delegate = self
    // UIKit disables the edge swipe when the bar is hidden, so it is re-enabled
    // here and gated on `platformPopEnabled` instead.
    interactivePopGestureRecognizer?.delegate = self
    interactivePopGestureRecognizer?.isEnabled = platformPopEnabled
  }

  /// The screens on the stack, bottom to top — the comparable form, and what
  /// `stackScreens` means in `navigation.mjs`.
  var screenIDs: [Int] {
    viewControllers.compactMap { ($0 as? XoteScreenController)?.nodeID }
  }

  func navigationController(
    _ navigationController: UINavigationController,
    didShow viewController: UIViewController,
    animated: Bool
  ) {
    let now = screenIDs
    defer { lastShown = now }
    guard !isApplyingHostChange else { return }

    // Anything that left the stack without the host asking. Normally one
    // screen; a `popTo` from a long-press on the back button is several, and
    // reporting the depth rather than the screen is what makes both the same
    // message.
    let departed = lastShown.filter { !now.contains($0) }
    guard let popped = departed.last else { return }
    onPlatformPop?(popped, now.count)
  }

  /// Only ever the interactive pop, and only when the app asked to hear about
  /// it. Returning `true` unconditionally is the well-known way to make the
  /// edge swipe work with a hidden bar, and the well-known way to hang the app
  /// on the root screen, where there is nothing to pop to.
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard gestureRecognizer === interactivePopGestureRecognizer else { return true }
    return platformPopEnabled && viewControllers.count > 1
  }

  /// Bring the stack to exactly `screens`, animating only when it is the kind
  /// of change a person reads as navigation.
  ///
  /// One screen appearing on top of what is already there is a push; one
  /// leaving the top is a pop. Anything else — a deep link, a sign-out, the
  /// first batch — is a state the app is asserting rather than a journey, and
  /// animating it produces a slide between two screens that were never next to
  /// each other.
  func setScreens(_ wanted: [XoteScreenController], animated: Bool) {
    isApplyingHostChange = true
    defer {
      isApplyingHostChange = false
      lastShown = screenIDs
    }

    let current = viewControllers.compactMap { $0 as? XoteScreenController }
    guard animated, !current.isEmpty, !wanted.isEmpty else {
      setViewControllers(wanted, animated: false)
      return
    }

    let isPush =
      wanted.count == current.count + 1
      && zip(current, wanted).allSatisfy { $0 === $1 }
    if isPush, let top = wanted.last {
      pushViewController(top, animated: true)
      return
    }

    let isPop = wanted.count < current.count && zip(wanted, current).allSatisfy { $0 === $1 }
    if isPop, let top = wanted.last {
      popToViewController(top, animated: true)
      return
    }

    setViewControllers(wanted, animated: false)
  }
}
