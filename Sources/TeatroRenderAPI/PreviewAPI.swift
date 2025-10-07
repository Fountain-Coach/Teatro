import Foundation
import Teatro

/// Non-breaking preview API additions. All types avoid leaking SDL details.
public final class TeatroPreviewController: @unchecked Sendable {
    public struct Config: Sendable {
        public var window: SDLWindowConfig
        public var fps: Int
        public init(window: SDLWindowConfig = .init(), fps: Int = 60) {
            self.window = window
            self.fps = fps
        }
    }

    private let config: Config
    private let window: SDLWindow
    private let renderer: SDLRenderer
    private let runLoop: SDLRunLoop
    private let player: TeatroPlayer
    public var onEvent: ((SDLEvent) -> Void)? = nil
    public var draw: ((SDLRenderer, Int) -> Void)? = nil
    private var running = false

    public init(config: Config = .init()) {
        self.config = config
        self.window = SDLWindow(config: config.window)
        self.renderer = SDLRenderer(width: config.window.width, height: config.window.height)
        self.runLoop = SDLRunLoop(config: .init(targetFPS: config.fps))
        self.player = TeatroPlayer(config: .init(fps: config.fps))
    }

    /// Launches the preview until the demo loop quits or `stop()` is called.
    public func start() throws {
        guard !running else { return }
        try window.open()
        running = true
        player.onFrame = { [weak self] frame, _ in
            guard let self else { return }
            if let draw = self.draw {
                draw(self.renderer, frame)
            } else {
                self.renderer.clear(color: 0x151515FF)
                // Simple animated demo rectangle.
                let x = (frame % max(1, self.config.window.width - 100))
                self.renderer.drawRect(x: x, y: 32, w: 100, h: 100, color: 0x33CC99FF)
                self.renderer.present()
            }
        }
        player.play()

        runLoop.run(tick: { [weak self] _ in
            guard let self else { return }
            // Pump synthetic events; pass to handler
            if let ev = self.window.pollEvent() {
                if ev == .quit { self.stop() }
                self.onEvent?(ev)
            }
        }, shouldContinue: { [weak self] in self?.running ?? false })
    }

    public func stop() {
        guard running else { return }
        running = false
        player.stop()
        window.close()
    }

    /// Convenience helper for demos/tests: run the preview for a fixed duration.
    public func runFor(seconds: TimeInterval) throws {
        try start()
        // Schedule a quit event after `seconds` to unwind the loop.
        let deadline = DispatchTime.now() + seconds
        DispatchQueue.global().asyncAfter(deadline: deadline) { [weak self] in
            self?.window.pushEvent(.quit)
        }
    }
}

public enum TeatroPreviewAPI {
    public static func launchPreview(config: TeatroPreviewController.Config = .init()) throws -> TeatroPreviewController {
        let controller = TeatroPreviewController(config: config)
        // Start asynchronously for API convenience; callers can stop later.
        DispatchQueue.global().async {
            try? controller.start()
        }
        return controller
    }
}
