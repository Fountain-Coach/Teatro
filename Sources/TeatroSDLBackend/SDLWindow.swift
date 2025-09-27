import Foundation

public struct SDLWindowConfig: Sendable {
    public var title: String
    public var width: Int
    public var height: Int
    public var vsync: Bool

    public init(title: String = "Teatro Preview",
                width: Int = 1280,
                height: Int = 720,
                vsync: Bool = true) {
        self.title = title
        self.width = width
        self.height = height
        self.vsync = vsync
    }
}

/// A minimal window abstraction. This is a stub when SDL3 is not available.
/// It satisfies tests and enables incremental integration under a feature flag.
public final class SDLWindow: @unchecked Sendable {
    public let config: SDLWindowConfig
    private var isOpen = false
    private let eventQueue = DispatchQueue(label: "teatro.sdl.event")
    private var pendingEvents: [SDLEvent] = []

    public init(config: SDLWindowConfig) {
        self.config = config
    }

    public func open() throws {
        isOpen = true
    }

    public func close() {
        isOpen = false
    }

    public var openState: Bool { isOpen }

    /// Poll one event if available (non-blocking).
    public func pollEvent() -> SDLEvent? {
        var ev: SDLEvent?
        eventQueue.sync {
            if !pendingEvents.isEmpty {
                ev = pendingEvents.removeFirst()
            } else {
                ev = nil
            }
        }
        return ev
    }

    /// Inject a synthetic event (used by tests and demo without real SDL).
    public func pushEvent(_ ev: SDLEvent) {
        eventQueue.async {
            self.pendingEvents.append(ev)
        }
    }
}

