import XCTest
import Foundation
@testable import RenderCLI
import Teatro

final class RenderCLIRenderTests: XCTestCase {
    func testRenderOutputsSVGToStdout() throws {
        let cli = RenderCLI()
        let view = Text("Render Test")
        let output = try captureStdout {
            try cli.render(view: view, target: .svg, outputPath: nil)
        }
        XCTAssertTrue(output.contains("<svg"))
        XCTAssertTrue(output.contains("Render Test"))
    }
}
