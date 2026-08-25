import Foundation
import JavaScriptCore

/// The app thread.
///
/// A `JSContext` is a JavaScript realm with the language built-ins and nothing
/// else — no DOM, no timers, no `console`. That is exactly what the shadow
/// document needs, and it is why the bundle can be dropped in unchanged.
///
/// Both directions are synchronous. `apply` is called from inside the
/// JavaScript call that produced the batch, so a press has already been applied
/// to the view tree by the time `dispatch` returns.
final class XoteBridge {
  private let context = JSContext()!
  private let host: XoteHost

  init(host: XoteHost) {
    self.host = host

    context.exceptionHandler = { _, exception in
      print("Xote: JavaScript exception — \(exception?.toString() ?? "unknown")")
    }

    installHostObject()
    installConsole()

    host.onEvent = { [weak self] id, name, payload in
      self?.dispatch(id: id, name: name, payload: payload)
    }
  }

  /// Evaluate the bundle and mount the app. Call on the main thread: every
  /// batch it produces is applied before this returns.
  func start() {
    guard
      let url = Bundle.main.url(forResource: "xote-app", withExtension: "js"),
      let source = try? String(contentsOf: url, encoding: .utf8)
    else {
      fatalError("Xote: xote-app.js is not in the bundle — run `npm run native:ios:build`")
    }

    context.evaluateScript(source, withSourceURL: url)
    context.objectForKeyedSubscript("xoteStart")?.call(withArguments: [])
  }

  private func dispatch(id: Int, name: String, payload: [String: Any]) {
    let json =
      (try? JSONSerialization.data(withJSONObject: payload))
      .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    context.objectForKeyedSubscript("xoteDispatchEvent")?
      .call(withArguments: [id, name, json])
  }

  private func installHostObject() {
    let apply: @convention(block) (String) -> Void = { [weak self] json in
      self?.host.apply(json)
    }
    let hostObject = JSValue(newObjectIn: context)
    hostObject?.setObject(apply, forKeyedSubscript: "apply" as NSString)
    context.setObject(hostObject, forKeyedSubscript: "XoteHost" as NSString)
  }

  /// The bundle does not use `console`, but anything you add to the app while
  /// debugging will, and a missing global is a confusing way to find that out.
  private func installConsole() {
    let log: @convention(block) (String) -> Void = { message in
      print("Xote JS: \(message)")
    }
    let console = JSValue(newObjectIn: context)
    console?.setObject(log, forKeyedSubscript: "log" as NSString)
    console?.setObject(log, forKeyedSubscript: "warn" as NSString)
    console?.setObject(log, forKeyedSubscript: "error" as NSString)
    context.setObject(console, forKeyedSubscript: "console" as NSString)
  }
}
