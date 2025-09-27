import Foundation

/// Lightweight orchestrator for preview playback that keeps core logic
/// deterministic and UI-agnostic. It advances a timeline at a target frame rate
/// and emits MIDI hooks on play/pause/scrub events. Rendering is delegated via
/// the `onFrame` callback.
public final class TeatroPlayer: @unchecked Sendable {
    public struct Config: Sendable { public var fps: Int; public init(fps: Int = 60) { self.fps = fps } }

    public enum State: Equatable { case stopped, playing, paused }

    public var state: State {
        stateLock.lock(); defer { stateLock.unlock() }
        return _state
    }
    public private(set) var frameIndex: Int = 0

    public var onFrame: (@Sendable (_ frame: Int, _ dt: TimeInterval) -> Void)?
    public var onPlay: (@Sendable () -> Void)?
    public var onPause: (@Sendable () -> Void)?
    public var onStop: (@Sendable () -> Void)?

    private let config: Config
    private let stateLock = NSLock()
    private var _state: State = .stopped
    private var shouldRun = false

    public init(config: Config = .init()) {
        self.config = config
    }

    public func play() {
        transition(to: .playing)
        shouldRun = true
        onPlay?()
        Task.detached { [weak self] in await self?.runLoop() }
    }

    public func pause() {
        shouldRun = false
        transition(to: .paused)
        onPause?()
    }

    public func stop() {
        shouldRun = false
        transition(to: .stopped)
        frameIndex = 0
        onStop?()
    }

    public func scrub(to frame: Int) {
        frameIndex = max(0, frame)
    }

    private func runLoop() async {
        let frameDuration = 1.0 / Double(max(1, config.fps))
        var last = DispatchTime.now()
        while shouldRun {
            let now = DispatchTime.now()
            let dt = Double(now.uptimeNanoseconds - last.uptimeNanoseconds) / 1_000_000_000
            if dt >= frameDuration {
                last = now
                frameIndex &+= 1
                onFrame?(frameIndex, dt)
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
    }

    private func transition(to new: State) {
        stateLock.lock(); defer { stateLock.unlock() }
        _state = new
    }
}
