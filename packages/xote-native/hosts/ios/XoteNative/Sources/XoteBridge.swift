import Foundation
import JavaScriptCore

/// The app thread, and the crossing to the UI thread.
///
/// A `JSContext` is a JavaScript realm with the language built-ins and nothing
/// else — no DOM, no timers, no `console`. That is exactly what the shadow
/// document needs, and it is why the bundle can be dropped in unchanged.
///
/// The app runs on its own serial queue, not the main one. Everything a
/// `Signal.set` sets off — the effects, the renderer, the batch — happens
/// there, and only the finished batch crosses to the main queue to be applied.
/// A slow update then costs a late frame rather than a frozen one. Both queues
/// are serial and every hop is `async`, so batches arrive in the order they
/// were produced and events in the order they happened.
///
/// The `JSContext` must only ever be touched from `jsQueue`; the two `dispatch`
/// hops below are the whole of that discipline.
public final class XoteBridge {
  /// Something went wrong that was contained rather than propagated: a
  /// JavaScript exception, a batch the host could not apply, a malformed
  /// command. An app can show something; by default it is logged.
  public var onError: ((String) -> Void)?

  private let context = JSContext()!
  private let host: XoteHost
  private let jsQueue = DispatchQueue(label: "dev.xote.native.js")

  init(host: XoteHost) {
    self.host = host

    context.exceptionHandler = { [weak self] _, exception in
      self?.report("JavaScript exception — \(exception?.toString() ?? "unknown")")
    }

    installHostObject()
    installConsole()

    host.onError = { [weak self] message in
      self?.report(message)
    }
    host.onEvent = { [weak self] id, name, payload in
      self?.dispatch(id: id, name: name, payload: payload)
    }
  }

  /// Load the bundle and mount the app. Returns immediately; the first batch
  /// arrives on the main queue once the app has rendered.
  func start() {
    jsQueue.async { [weak self] in
      guard let self = self else { return }
      guard
        let url = Bundle.main.url(forResource: "xote-app", withExtension: "js"),
        let source = try? String(contentsOf: url, encoding: .utf8)
      else {
        // Nothing to contain here: there is no app, and no amount of
        // continuing will produce one.
        fatalError("Xote: xote-app.js is not in the bundle — run `npm run native:ios:build`")
      }

      self.context.evaluateScript(source, withSourceURL: url)
      self.context.objectForKeyedSubscript("xoteStart")?.call(withArguments: [])
    }
  }

  // MARK: - Crossings

  /// JavaScript produced a batch. Apply it on the main queue, where UIKit is.
  private func installHostObject() {
    let apply: @convention(block) (String) -> Void = { [weak self] json in
      DispatchQueue.main.async {
        self?.host.apply(json)
      }
    }
    let hostObject = JSValue(newObjectIn: context)
    hostObject?.setObject(apply, forKeyedSubscript: "apply" as NSString)

    // What this host can apply. `install()` on the other side compares it
    // against the version the bundle emits and refuses, warns, or says nothing.
    // The two halves ship separately, so this is the only place either learns
    // that it is talking to the other one's future.
    let supported = JSValue(newObjectIn: context)
    supported?.setObject(XoteHost.protocolMin, forKeyedSubscript: "min" as NSString)
    supported?.setObject(XoteHost.protocolMax, forKeyedSubscript: "max" as NSString)
    hostObject?.setObject(supported, forKeyedSubscript: "protocol" as NSString)

    context.setObject(hostObject, forKeyedSubscript: "XoteHost" as NSString)
  }

  /// A view reported something. Deliver it on the app queue, where the app is.
  private func dispatch(id: Int, name: String, payload: [String: Any]) {
    let json =
      (try? JSONSerialization.data(withJSONObject: payload))
      .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    jsQueue.async { [weak self] in
      self?.context.objectForKeyedSubscript("xoteDispatchEvent")?
        .call(withArguments: [id, name, json])
    }
  }

  private func report(_ message: String) {
    if let onError = onError {
      DispatchQueue.main.async { onError(message) }
    } else {
      print("Xote: \(message)")
    }
  }

  /// The bundle does not use `console`, but anything added to the app while
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
