import XCTest
@testable import RenderCLI
import Teatro

// A fake render target used to verify plugin-based registration.
private struct FakeTarget: RenderTargetProtocol {
    static let name = "fake"
    static let aliases: [String] = []
    static func render(view: Renderable, output: String?) throws {
        try write("FAKE:" + view.render(), to: output, defaultName: "fake.txt")
    }
}

// Plugin that registers the fake target.
private enum FakePlugin: RenderTargetPlugin {
    static func registerTargets(in registry: RenderTargetRegistry) {
        registry.register(FakeTarget.self)
    }
}

final class RenderTargetPluginTests: XCTestCase {
    override func setUp() {
        super.setUp()
        RenderTargetRegistry.register(plugin: FakePlugin.self)
    }

    func testDynamicPluginRegistration() {
        let target = RenderTargetRegistry.shared.lookup("fake")
        XCTAssertNotNil(target)
    }

    func testRenderingWithPluginTarget() throws {
        guard let target = RenderTargetRegistry.shared.lookup("fake") else {
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
