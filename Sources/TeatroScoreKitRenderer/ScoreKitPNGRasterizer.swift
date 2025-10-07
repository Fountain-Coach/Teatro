import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import TeatroCore
import ScoreKit

public struct ScoreKitPNGRasterizer: RendererPlugin {
    public static let identifier = "scorekit-png"
    public static let fileExtensions = ["png"]

    public static func render(view: Renderable, output: String?) throws {
        guard let score = (view as? ScoreView) else {
            throw RendererError.unsupportedInput("ScoreKitPNGRasterizer requires ScoreView")
        }
        let path = output ?? "scorekit.png"
        try renderPNG(score: score, to: path)
    }

    public static func renderPNG(score: ScoreView, to path: String) throws {
        let width = max(score.width, 200)
        let height = max(score.height, Int(score.paddingTop + score.staffSpacing * 5 + 40))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            throw RendererError.unsupportedInput("Failed to create CGContext for PNG rasterization")
        }

        // White background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw staff lines
        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(1)
        let left = CGFloat(score.paddingLeft)
        let right = CGFloat(Double(width) - score.paddingLeft)
        for i in 0..<5 {
            let y = CGFloat(score.paddingTop + score.staffSpacing * Double(i))
            context.move(to: CGPoint(x: left, y: y))
            context.addLine(to: CGPoint(x: right, y: y))
            context.strokePath()
        }

        // Draw notes as ellipse + stems
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        for i in 0..<score.events.count {
            let (x, y) = score.layoutPoint(at: i)
            let rx = CGFloat(score.noteRadius * 1.2)
            let ry = CGFloat(score.noteRadius * 0.8)
            let rect = CGRect(x: CGFloat(x) - rx, y: CGFloat(y) - ry, width: 2*rx, height: 2*ry)
            context.saveGState()
            context.translateBy(x: CGFloat(x), y: CGFloat(y))
            context.rotate(by: CGFloat(-20.0 * .pi / 180.0))
            context.translateBy(x: -CGFloat(x), y: -CGFloat(y))
            context.fillEllipse(in: rect)
            context.restoreGState()
            let midY = CGFloat(score.paddingTop + score.staffSpacing * 2.0)
            let stemUp = CGFloat(y) >= midY
            let stemLen = CGFloat(score.staffSpacing * 3.5)
            let x1 = stemUp ? (CGFloat(x) + rx - 0.5) : (CGFloat(x) - rx + 0.5)
            let y1 = CGFloat(y)
            let x2 = x1
            let y2 = stemUp ? (CGFloat(y) - stemLen) : (CGFloat(y) + stemLen)
            context.move(to: CGPoint(x: x1, y: y1))
            context.addLine(to: CGPoint(x: x2, y: y2))
            context.strokePath()
        }

        // Barlines
        let topY = CGFloat(score.paddingTop) - CGFloat(score.staffSpacing * 0.5)
        let bottomY = CGFloat(score.paddingTop + score.staffSpacing * 4.0 + score.staffSpacing * 0.5)
        for bx in score.barlines() {
            let x = CGFloat(bx)
            context.move(to: CGPoint(x: x, y: topY))
            context.addLine(to: CGPoint(x: x, y: bottomY))
            context.strokePath()
        }

        guard let image = context.makeImage() else {
            throw RendererError.unsupportedInput("Failed to make CGImage")
        }
        let url = URL(fileURLWithPath: path)
        let uti: CFString = UTType.png.identifier as CFString
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
            throw RendererError.unsupportedInput("Failed to create image destination")
        }
        CGImageDestinationAddImage(dest, image, nil)
        if !CGImageDestinationFinalize(dest) {
            throw RendererError.unsupportedInput("Failed to write PNG")
        }
    }
}
