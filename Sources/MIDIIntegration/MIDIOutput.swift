import Foundation

/// Minimal MIDI output facade for preview. Currently a stub that records the
/// latest command for visualization/testing without performing real IO.
public final class MIDIOutput: @unchecked Sendable {
    public enum Command: Equatable, Sendable {
        case noteOn(channel: UInt8, note: UInt8, velocity: UInt8)
        case noteOff(channel: UInt8, note: UInt8, velocity: UInt8)
        case controlChange(channel: UInt8, controller: UInt8, value: UInt8)
    }

    private var lastCommandLock = NSLock()
    private var _lastCommand: Command? = nil

    public init() {}

    public var lastCommand: Command? {
        lastCommandLock.lock(); defer { lastCommandLock.unlock() }
        return _lastCommand
    }

    public func noteOn(channel: UInt8, note: UInt8, velocity: UInt8) { record(.noteOn(channel: channel, note: note, velocity: velocity)) }
    public func noteOff(channel: UInt8, note: UInt8, velocity: UInt8) { record(.noteOff(channel: channel, note: note, velocity: velocity)) }
    public func controlChange(channel: UInt8, controller: UInt8, value: UInt8) { record(.controlChange(channel: channel, controller: controller, value: value)) }

    private func record(_ cmd: Command) {
        lastCommandLock.lock(); defer { lastCommandLock.unlock() }
        _lastCommand = cmd
    }
}
