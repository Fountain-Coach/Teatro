import Foundation

// Lightweight, internal event abstraction to avoid leaking SDL types.
public enum SDLEvent: Equatable, Sendable {
    case quit
    case keyDown(keyCode: Int)
    case keyUp(keyCode: Int)
    case mouseDown(x: Int, y: Int)
    case mouseUp(x: Int, y: Int)
    case mouseMove(x: Int, y: Int)
}
