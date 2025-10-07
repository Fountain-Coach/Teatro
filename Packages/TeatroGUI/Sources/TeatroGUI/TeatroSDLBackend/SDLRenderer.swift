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

    // Basic primitives for interactive previews
    public func drawLine(x0: Int, y0: Int, x1: Int, y1: Int, color: UInt32) {
        var x0 = x0, y0 = y0, x1 = x1, y1 = y1
        let dx = abs(x1 - x0), dy = -abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx + dy
        while true {
            if x0 >= 0 && x0 < width && y0 >= 0 && y0 < height {
                pixels[y0*width + x0] = color
            }
            if x0 == x1 && y0 == y1 { break }
            let e2 = 2*err
            if e2 >= dy { err += dy; x0 += sx }
            if e2 <= dx { err += dx; y0 += sy }
        }
    }

    public func fillEllipse(cx: Int, cy: Int, rx: Int, ry: Int, color: UInt32) {
        guard rx > 0, ry > 0 else { return }
        let rx2 = rx*rx
        let ry2 = ry*ry
        var x = 0
        var y = ry
        var px = 0
        var py = 2 * rx2 * y
        // Region 1
        var p = Int(round(Double(ry2) - Double(rx2)*Double(ry) + 0.25*Double(rx2)))
        while px < py {
            drawHSpan(cx: cx, cy: cy, x: x, y: y, color: color)
            x += 1
            px += 2 * ry2
            if p < 0 {
                p += ry2 + px
            } else {
                y -= 1
                py -= 2 * rx2
                p += ry2 + px - py
            }
        }
        // Region 2
        let dx2 = Double(x) + 0.5
        let dy1 = Double(y - 1)
        let term1 = Double(ry2) * dx2 * dx2
        let term2 = Double(rx2) * dy1 * dy1
        let term3 = Double(rx2 * ry2)
        p = Int(round(term1 + term2 - term3))
        while y >= 0 {
            drawHSpan(cx: cx, cy: cy, x: x, y: y, color: color)
            y -= 1
            py -= 2 * rx2
            if p > 0 {
                p += rx2 - py
            } else {
                x += 1
                px += 2 * ry2
                p += rx2 - py + px
            }
        }
    }

    private func drawHSpan(cx: Int, cy: Int, x: Int, y: Int, color: UInt32) {
        let xa = cx - x
        let xb = cx + x
        let y0 = cy + y
        let y1 = cy - y
        if y0 >= 0 && y0 < height {
            let row = y0 * width
            for xx in max(0, xa)..<min(width, xb+1) { pixels[row + xx] = color }
        }
        if y1 >= 0 && y1 < height && y1 != y0 {
            let row = y1 * width
            for xx in max(0, xa)..<min(width, xb+1) { pixels[row + xx] = color }
        }
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
