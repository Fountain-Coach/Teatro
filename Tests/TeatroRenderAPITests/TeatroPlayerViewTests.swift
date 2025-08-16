#if canImport(SwiftUI) && os(macOS)
import XCTest
@testable import TeatroRenderAPI
import SwiftUI

@available(macOS 13, *)
@MainActor
final class TeatroPlayerViewTests: XCTestCase {
    func testInstantiation() {
        let svg = "<svg xmlns='http://www.w3.org/2000/svg' width='1' height='1'></svg>"
        _ = TeatroPlayerView(svg: Data(svg.utf8))
    }
}
#endif
