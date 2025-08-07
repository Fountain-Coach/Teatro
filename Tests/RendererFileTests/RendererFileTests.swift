import XCTest
@testable import Teatro

final class RendererFileTests: XCTestCase {
    func testSVGRendererWritesFile() throws {
        let view = Text("Hi")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("svg")
        guard let renderer = RendererRegistry.shared.plugin(for: "svg") else {
            XCTFail("SVG renderer missing")
            return
        }
        try renderer.render(view: view, output: url.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("<svg"))
    }

    func testImageRendererProducesFile() throws {
        let view = Text("Img")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("png")
        guard let renderer = RendererRegistry.shared.plugin(for: "png") as? ImageRenderer.Type else {
            XCTFail("PNG renderer missing")
            return
        }
        try renderer.render(view: view, output: url.path)
        if FileManager.default.fileExists(atPath: url.path) {
            let data = try Data(contentsOf: url)
            XCTAssertFalse(data.isEmpty)
        } else {
            let alt = url.deletingPathExtension().appendingPathExtension("svg")
            XCTAssertTrue(FileManager.default.fileExists(atPath: alt.path))
            let content = try String(contentsOf: alt, encoding: .utf8)
            XCTAssertTrue(content.contains("<svg"))
        }
    }

    func testImageRendererFallbackWithoutPNGExtension() throws {
        let view = Text("Plain")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        guard let renderer = RendererRegistry.shared.plugin(for: "png") as? ImageRenderer.Type else {
            XCTFail("PNG renderer missing")
            return
        }
        try renderer.render(view: view, output: url.path)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(content.contains("<svg"))
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
