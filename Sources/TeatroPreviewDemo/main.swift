import Foundation
import TeatroRenderAPI
import ScoreKit

// Minimal demo: launches the preview controller for ~2 seconds and exits.
@main
struct TeatroPreviewDemoApp {
    static func main() throws {
        let controller = try TeatroPreviewAPI.launchPreview(config: .init(window: .init(title: "ScoreKit Interactive Preview", width: 960, height: 240), fps: 60))
        // Load a small default fixture (falls back to a hard-coded sequence)
        let cwd = FileManager.default.currentDirectoryPath
        let defaultFixture = URL(fileURLWithPath: cwd).appendingPathComponent("../ScoreKit/Fixtures/Lily/baseline_quarters.ly").standardized
        let events: [NotatedEvent]
        if let s = try? String(contentsOf: defaultFixture), !s.isEmpty {
            events = LilyParser.parse(source: s)
        } else {
            events = [
                .init(base: .note(pitch: .init(step: .C, alter: 0, octave: 4), duration: .init(1,4))),
                .init(base: .note(pitch: .init(step: .D, alter: 0, octave: 4), duration: .init(1,4))),
                .init(base: .note(pitch: .init(step: .E, alter: 0, octave: 4), duration: .init(1,4))),
                .init(base: .note(pitch: .init(step: .F, alter: 0, octave: 4), duration: .init(1,4)))
            ]
        }
        ScoreKitPreview.attach(to: controller, events: events)
        try controller.runFor(seconds: 6.0)
        Thread.sleep(forTimeInterval: 6.5)
    }
}
