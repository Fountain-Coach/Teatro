import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import TeatroCore
import ScoreKit

public struct ScoreKitPNGRasterizer: RendererPlugin {
    public static let identifier = "scorekit-png"
    // Do not hijack the generic PNG extension; require explicit --format scorekit-png
    public static let fileExtensions: [String] = []

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
        for staffLineIndex in 0..<5 {
            let yPosition = CGFloat(score.paddingTop + score.staffSpacing * Double(staffLineIndex))
            context.move(to: CGPoint(x: left, y: yPosition))
            context.addLine(to: CGPoint(x: right, y: yPosition))
            context.strokePath()
        }

        // Draw notes as ellipse + stems
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        for eventIndex in 0..<score.events.count {
            let (xPosition, yPosition) = score.layoutPoint(at: eventIndex)
            let radiusX = CGFloat(score.noteRadius * 1.2)
            let radiusY = CGFloat(score.noteRadius * 0.8)
            let rect = CGRect(x: CGFloat(xPosition) - radiusX, y: CGFloat(yPosition) - radiusY, width: 2*radiusX, height: 2*radiusY)
            context.saveGState()
            context.translateBy(x: CGFloat(xPosition), y: CGFloat(yPosition))
            context.rotate(by: CGFloat(-20.0 * .pi / 180.0))
            context.translateBy(x: -CGFloat(xPosition), y: -CGFloat(yPosition))
            context.fillEllipse(in: rect)
            context.restoreGState()
            let midY = CGFloat(score.paddingTop + score.staffSpacing * 2.0)
            let stemUp = CGFloat(yPosition) >= midY
            let stemLength = CGFloat(score.staffSpacing * 3.5)
            let xStart = stemUp ? (CGFloat(xPosition) + radiusX - 0.5) : (CGFloat(xPosition) - radiusX + 0.5)
            let yStart = CGFloat(yPosition)
            let xEnd = xStart
            let yEnd = stemUp ? (CGFloat(yPosition) - stemLength) : (CGFloat(yPosition) + stemLength)
            context.move(to: CGPoint(x: xStart, y: yStart))
            context.addLine(to: CGPoint(x: xEnd, y: yEnd))
            context.strokePath()
        }

        // Barlines
        let topY = CGFloat(score.paddingTop) - CGFloat(score.staffSpacing * 0.5)
        let bottomY = CGFloat(score.paddingTop + score.staffSpacing * 4.0 + score.staffSpacing * 0.5)
        for barX in score.barlines() {
            let xPosition = CGFloat(barX)
            context.move(to: CGPoint(x: xPosition, y: topY))
            context.addLine(to: CGPoint(x: xPosition, y: bottomY))
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
