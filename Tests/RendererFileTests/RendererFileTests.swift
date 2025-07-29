import XCTest
@testable import Teatro

final class RendererFileTests: XCTestCase {
    func testSVGRendererWritesFile() throws {
        let view = Text("Hi")
        let svg = SVGRenderer.render(view)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("svg")
        try svg.write(to: url, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url)
        XCTAssertTrue(content.contains("<svg"))
    }

    func testImageRendererProducesFile() throws {
        let view = Text("Img")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        ImageRenderer.renderToPNG(view, to: url.path)
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            XCTAssertFalse(data.isEmpty)
        } else {
            let alt = URL(fileURLWithPath: url.path.replacingOccurrences(of: ".png", with: ".svg"))
            XCTAssertTrue(FileManager.default.fileExists(atPath: alt.path))
            let content = try String(contentsOf: alt)
            XCTAssertTrue(content.contains("<svg"))
        }
    }
}
