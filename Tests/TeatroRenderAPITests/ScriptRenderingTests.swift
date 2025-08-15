import XCTest
@testable import TeatroRenderAPI

final class ScriptRenderingTests: XCTestCase {
    func testRenderScriptMatchesSnapshots() throws {
        let script = """
        = Opening scene
        INT. HOUSE - DAY

        JOHN
        Hello there.
        """
        let input = SimpleScriptInput(fountainText: script)
        let result = try TeatroRenderer.renderScript(input)

        let snapshots = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__snapshots__", isDirectory: true)
        try FileManager.default.createDirectory(at: snapshots, withIntermediateDirectories: true)
        let svgURL = snapshots.appendingPathComponent("Script.svg")
        let mdURL = snapshots.appendingPathComponent("Script.md")

        if !FileManager.default.fileExists(atPath: svgURL.path) ||
            !FileManager.default.fileExists(atPath: mdURL.path) {
            try result.svg?.write(to: svgURL)
            try result.markdown?.write(to: mdURL, atomically: true, encoding: .utf8)
            XCTFail("Snapshot files created; re-run tests")
        } else {
            let expectedSVG = try Data(contentsOf: svgURL)
            XCTAssertEqual(result.svg, expectedSVG)
            let expectedMD = try String(contentsOf: mdURL)
            XCTAssertEqual(result.markdown, expectedMD)
        }
    }
}
