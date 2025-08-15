import XCTest
@testable import TeatroRenderAPI

final class SessionRenderingTests: XCTestCase {
    func testRenderSessionMatchesSnapshot() throws {
        let log = """
$ echo hi
hi
$ ls
file
"""
        let input = SimpleSessionInput(logText: log)
        let result = try TeatroRenderer.renderSession(input)

        let snapshots = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("__snapshots__", isDirectory: true)
        try FileManager.default.createDirectory(at: snapshots, withIntermediateDirectories: true)
        let mdURL = snapshots.appendingPathComponent("Session.md")

        if !FileManager.default.fileExists(atPath: mdURL.path) {
            try result.markdown?.write(to: mdURL, atomically: true, encoding: .utf8)
            XCTFail("Snapshot file created; re-run tests")
        } else {
            let expected = try String(contentsOf: mdURL)
            XCTAssertEqual(result.markdown, expected)
        }
    }
}
