import UIKit
import XCTest

@testable import XoteNativeExample

/// The host conformance suite, replayed against UIKit.
///
/// The cases and the answers live in `native/conformance/suite.json`, shared
/// with the JavaScript hosts. A host passes by applying the real wire format
/// and ending up with the same tree, the same frames and the same text — not by
/// being written any particular way.
///
/// Text is measured by the same stub the reference host uses, because two hosts
/// can agree on layout and will never agree on font metrics.
final class XoteConformanceTests: XCTestCase {
  private struct Case: Decodable {
    struct Viewport: Decodable {
      let width: CGFloat
      let height: CGFloat
    }
    struct Expectation: Decodable {
      let structure: [String: [Int]]
      let frames: [String: [CGFloat]]
      let texts: [String: String]
      /// The *view* tree — which nodes got a `UIView` and which view holds
      /// which. Not the same as `structure`: a layout-only box is in one and
      /// not the other. Two hosts can agree on every frame and still draw the
      /// same content into different surfaces, with different clipping and
      /// different hit testing, so this is compared separately.
      let views: [String: [Int]]
    }
    let name: String
    let viewport: Viewport
    let steps: [[[AnyCodableValue]]]
    let expected: [Expectation]
  }

  /// The wire format is heterogeneous by design, so decoding is by hand.
  private enum AnyCodableValue: Decodable {
    case number(Double)
    case text(String)
    case object([String: Any])
    case null

    init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      if container.decodeNil() {
        self = .null
      } else if let value = try? container.decode(Double.self) {
        self = .number(value)
      } else if let value = try? container.decode(String.self) {
        self = .text(value)
      } else if let value = try? container.decode([String: AnyCodableValue].self) {
        var out: [String: Any] = [:]
        for (key, entry) in value { out[key] = entry.json }
        self = .object(out)
      } else {
        self = .null
      }
    }

    var json: Any {
      switch self {
      case .number(let value): return value
      case .text(let value): return value
      case .object(let value): return value
      case .null: return NSNull()
      }
    }
  }

  private static let stubCharWidth: CGFloat = 7
  private static let stubLineHeight: CGFloat = 16

  /// A fixed-width font that wraps on whole characters. Must stay identical to
  /// `stubMeasure` in `native/host/reference.mjs`.
  private func stubMeasure(
    _ text: String,
    _ availableWidth: CGFloat?,
    _ widthMode: XoteMeasureMode
  ) -> XoteSize {
    if text.isEmpty { return XoteSize(width: 0, height: 0) }
    let natural = CGFloat(text.count) * Self.stubCharWidth
    guard widthMode != .undefined, let available = availableWidth else {
      return XoteSize(width: natural, height: Self.stubLineHeight)
    }
    let usable = widthMode == .exactly ? available : min(available, natural)
    let perLine = max(1, floor(usable / Self.stubCharWidth))
    return XoteSize(
      width: widthMode == .exactly ? available : min(natural, usable),
      height: ceil(CGFloat(text.count) / perLine) * Self.stubLineHeight
    )
  }

  func testConformance() throws {
    let url = try XCTUnwrap(
      Bundle(for: Self.self).url(forResource: "suite", withExtension: "json"),
      "suite.json is not in the test bundle — check the resources phase"
    )
    let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: url))
    XCTAssertFalse(cases.isEmpty)

    for testCase in cases {
      let root = UIView(
        frame: CGRect(x: 0, y: 0, width: testCase.viewport.width, height: testCase.viewport.height))
      let host = XoteHost(rootView: root)
      host.measureOverride = stubMeasure

      for (index, batch) in testCase.steps.enumerated() {
        let commands = batch.map { $0.map(\.json) }
        let json = String(
          data: try JSONSerialization.data(withJSONObject: commands), encoding: .utf8)!
        host.apply(json)

        let snapshot = host.conformanceSnapshot()
        let expected = testCase.expected[index]
        let step = "\(testCase.name) step \(index)"

        for (id, children) in expected.structure {
          XCTAssertEqual(
            snapshot.structure[Int(id)!] ?? [], children, "\(step): children of \(id)")
        }
        for (id, text) in expected.texts {
          XCTAssertEqual(snapshot.texts[Int(id)!], text, "\(step): text of \(id)")
        }

        XCTAssertEqual(
          Set(snapshot.frames.keys), Set(expected.frames.keys.map { Int($0)! }),
          "\(step): the set of boxes on screen")

        for (id, frame) in expected.frames {
          let got = try XCTUnwrap(snapshot.frames[Int(id)!], "\(step): node \(id) has no frame")
          for axis in 0..<4 {
            XCTAssertEqual(
              got[axis], frame[axis], accuracy: 0.5,
              "\(step): node \(id) frame \(got) should be \(frame)")
          }
        }

        // Flattening: which boxes became views, and where they ended up in the
        // hierarchy. The `flattening` case moves a box into and out of the view
        // tree while every frame stays put, which is the pair of directions
        // that is easy to get wrong and impossible to see in a frame.
        XCTAssertEqual(
          Set(snapshot.views.keys), Set(expected.views.keys.map { Int($0)! }),
          "\(step): the set of nodes with a view of their own")
        for (id, children) in expected.views {
          XCTAssertEqual(
            snapshot.views[Int(id)!] ?? [], children, "\(step): subviews of \(id)")
        }
      }
    }
  }
}
