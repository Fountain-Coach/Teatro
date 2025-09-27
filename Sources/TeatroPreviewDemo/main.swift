import Foundation
import TeatroRenderAPI

// Minimal demo: launches the preview controller for ~2 seconds and exits.
@main
struct TeatroPreviewDemoApp {
    static func main() throws {
        let controller = try TeatroPreviewAPI.launchPreview(config: .init(window: .init(title: "Teatro Preview Demo", width: 640, height: 360), fps: 60))
        try controller.runFor(seconds: 2.0)
        // Block the main thread for a tad longer than runFor() to let it quit
        Thread.sleep(forTimeInterval: 2.5)
    }
}
