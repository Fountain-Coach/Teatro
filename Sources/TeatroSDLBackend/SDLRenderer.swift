import Foundation
import CoreGraphics

/// Very small renderer abstraction. In SDL-enabled builds, this would wrap the
/// GPU context. For now it maintains an offscreen pixel buffer for tests.
public final class SDLRenderer: @unchecked Sendable {
    public let width: Int
    public let height: Int
    private var pixels: [UInt32]

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixels = Array(repeating: 0x00000000, count: width * height)
    }

    public func clear(color: UInt32 = 0x000000FF) {
        pixels = Array(repeating: color, count: width * height)
    }

    public func drawRect(x: Int, y: Int, w: Int, h: Int, color: UInt32) {
        guard w > 0, h > 0 else { return }
        let x0 = max(0, x)
        let y0 = max(0, y)
        let x1 = min(width, x + w)
        let y1 = min(height, y + h)
        if x0 >= x1 || y0 >= y1 { return }
        for yy in y0..<y1 {
            let row = yy * width
            for xx in x0..<x1 {
                pixels[row + xx] = color
            }
        }
    }

    public func present() {
        // No-op for stub. In SDL path we would swap buffers.
    }

    public func snapshotHash() -> UInt64 {
        // Simple rolling hash for snapshot tests
        var h: UInt64 = 1469598103934665603
        for p in pixels {
            h ^= UInt64(p)
            h &+= h << 1
        }
        return h
    }
}

