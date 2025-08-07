import XCTest
@testable import RenderCLI
import Teatro

// A fake renderer used to verify plugin-based registration.
private struct FakeRenderer: RendererPlugin {
    static let identifier = "fake"
    static let fileExtensions: [String] = []
    static func render(view: Renderable, output: String?) throws {
        try write("FAKE:" + view.render(), to: output, defaultName: "fake.txt")
    }
}

final class RendererPluginTests: XCTestCase {
    override func setUp() {
        super.setUp()
        RendererRegistry.register(FakeRenderer.self)
    }

    func testDynamicPluginRegistration() {
        let target = RendererRegistry.shared.plugin(for: "fake")
        XCTAssertNotNil(target)
    }

    func testRenderingWithPluginTarget() throws {
        guard let target = RendererRegistry.shared.plugin(for: "fake") else {
            XCTFail("target not registered")
            return
        }
        let cli = RenderCLI()
        let view = Text("Hello")
        let output = try captureStdout {
            try cli.render(view: view, target: target, outputPath: nil)
        }
        XCTAssertTrue(output.contains("FAKE:Hello"))
    }
}
