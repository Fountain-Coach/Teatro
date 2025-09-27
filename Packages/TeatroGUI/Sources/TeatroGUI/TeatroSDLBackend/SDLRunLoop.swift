import Foundation

public final class SDLRunLoop: @unchecked Sendable {
    public struct Config: Sendable {
        public var targetFPS: Int
        public init(targetFPS: Int = 60) { self.targetFPS = targetFPS }
    }

    public let config: Config
    private var isRunning = false
    private var frameCount: UInt64 = 0

    public init(config: Config = .init()) {
        self.config = config
    }

    /// Run a loop invoking `tick` until `shouldContinue` returns false.
    public func run(tick: @escaping (_ dt: TimeInterval) -> Void,
                    shouldContinue: @escaping () -> Bool) {
        guard !isRunning else { return }
        isRunning = true
        let frameDuration = 1.0 / Double(max(1, config.targetFPS))
        var last = DispatchTime.now()
        while shouldContinue() {
            let now = DispatchTime.now()
            let dt = Double(now.uptimeNanoseconds - last.uptimeNanoseconds) / 1_000_000_000
            if dt >= frameDuration {
                last = now
                frameCount &+= 1
                tick(dt)
            } else {
                let sleepNS = UInt64((frameDuration - dt) * 1_000_000_000)
                if sleepNS > 0 {
                    var ns = timespec(tv_sec: 0, tv_nsec: Int(sleepNS))
                    withUnsafeMutablePointer(to: &ns) { ptr in
                        _ = nanosleep(ptr, nil)
                    }
                }
            }
        }
        isRunning = false
    }

    public var frames: UInt64 { frameCount }
}
