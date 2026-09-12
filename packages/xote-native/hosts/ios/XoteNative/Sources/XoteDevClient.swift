import Foundation
import UIKit

/// Development: the app runs on your machine, this device draws it.
///
/// There is no JavaScript engine in this path and no bundle on the device. The
/// dev server (`xote-native/dev/server.mjs`) runs the real app in Node, and what
/// crosses the network is the same command batch that would otherwise cross
/// `XoteBridge`'s JavaScriptCore boundary — because the bridge was always a
/// wire format, and a socket is as good a wire as a function call.
///
/// So a save on your machine is a reload here in about a second, with nothing
/// transferred but commands and no Xcode in the loop. **It is the inner loop,
/// not the measurement**: the app is running in Node, so this cannot show you
/// JavaScriptCore behaviour, real startup cost, or what a batch costs to apply
/// under a thermal budget. Build without a dev server configured for that.
///
/// ## The transport
///
/// Newline-delimited JSON over one long-lived chunked response downward, and a
/// POST per event upward. No WebSocket: framing would be three
/// implementations' worth of masking and fragmentation to carry lines that
/// HTTP carries already, and `curl -N` is a working client of this one.
final class XoteDevClient: NSObject, URLSessionDataDelegate {
  private let host: XoteHost
  private let baseURL: URL

  /// Anything that went wrong and was contained. `XoteViewController` shows it.
  var onError: ((String) -> Void)?

  private lazy var session: URLSession = URLSession(
    configuration: {
      let configuration = URLSessionConfiguration.default
      // The stream is meant to stay open for as long as you are working.
      configuration.timeoutIntervalForRequest = TimeInterval(INT_MAX)
      configuration.timeoutIntervalForResource = TimeInterval(INT_MAX)
      return configuration
    }(),
    delegate: self,
    delegateQueue: nil
  )

  private var task: URLSessionDataTask?
  /// Bytes received but not yet ending in a newline — a message split across
  /// two packets, which is ordinary and not an error.
  private var partial = Data()
  private var stopped = false
  private var retryDelay: TimeInterval = 0.5

  init(host: XoteHost, baseURL: URL) {
    self.host = host
    self.baseURL = baseURL
    super.init()
    host.onEvent = { [weak self] id, name, payload in
      self?.report(event: id, name: name, payload: payload)
    }
  }

  func start() {
    stopped = false
    connect()
  }

  func stop() {
    stopped = true
    task?.cancel()
    task = nil
  }

  private func connect() {
    guard !stopped else { return }
    partial.removeAll()
    var request = URLRequest(url: baseURL.appendingPathComponent("stream"))
    request.setValue("application/x-ndjson", forHTTPHeaderField: "accept")
    let task = session.dataTask(with: request)
    self.task = task
    task.resume()
  }

  /// Reconnect, backing off to a second or two so a server that is not running
  /// yet costs a line of log rather than a spin.
  private func reconnect() {
    guard !stopped else { return }
    let delay = retryDelay
    retryDelay = min(retryDelay * 2, 2)
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
      self?.connect()
    }
  }

  // MARK: - Down the wire

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    retryDelay = 0.5
    partial.append(data)
    while let newline = partial.firstIndex(of: UInt8(ascii: "\n")) {
      let line = partial[partial.startIndex..<newline]
      partial = partial[partial.index(after: newline)...]
      handle(line: Data(line))
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard !stopped else { return }
    if let error = error, (error as NSError).code != NSURLErrorCancelled {
      onError?("Xote dev: \(error.localizedDescription) — is `npm run native:dev` running?")
    }
    reconnect()
  }

  private func handle(line: Data) {
    guard
      let message = try? JSONSerialization.jsonObject(with: line) as? [String: Any],
      let type = message["type"] as? String
    else { return }

    switch type {
    case "reset":
      // The app restarted, so every id it was using is meaningless now.
      DispatchQueue.main.async { [weak self] in self?.host.reset() }

    case "batch":
      guard
        let commands = message["commands"],
        let json = try? JSONSerialization.data(withJSONObject: commands),
        let text = String(data: json, encoding: .utf8)
      else { return }
      DispatchQueue.main.async { [weak self] in
        self?.host.apply(text)
      }

    case "error":
      let text = message["message"] as? String ?? "unknown error"
      DispatchQueue.main.async { [weak self] in self?.onError?(text) }

    default:
      break
    }
  }

  // MARK: - Back up the wire

  private func report(event id: Int, name: String, payload: [String: Any]) {
    var request = URLRequest(url: baseURL.appendingPathComponent("event"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    request.httpBody = try? JSONSerialization.data(
      withJSONObject: ["id": id, "name": name, "payload": payload])
    session.dataTask(with: request).resume()
  }
}

extension XoteDevClient {
  /// Where the dev server is, or nil for an ordinary build.
  ///
  /// `XoteDevServer` in `Info.plist`, or the `XOTE_DEV_SERVER` environment
  /// variable so a scheme can turn it on without editing anything. A simulator
  /// shares your Mac's network, so `http://localhost:8081` reaches it; a real
  /// device needs your Mac's address on the LAN.
  static func configuredURL() -> URL? {
    let fromEnvironment = ProcessInfo.processInfo.environment["XOTE_DEV_SERVER"]
    let fromPlist = Bundle.main.object(forInfoDictionaryKey: "XoteDevServer") as? String
    guard let value = fromEnvironment ?? fromPlist, !value.isEmpty else { return nil }
    return URL(string: value)
  }
}
