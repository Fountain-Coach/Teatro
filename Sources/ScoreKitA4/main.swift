import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import UniformTypeIdentifiers
import ArgumentParser
import ScoreKit
import ScoreKitUI

@main
struct ScoreKitA4: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Generate A4 page fixtures with multi-line staffs (ScoreKit + Lily)")

    @Option(name: [.short, .long], help: "Input LilyPond file (.ly)")
    var ly: String

    @Option(name: [.short, .long], help: "Output directory")
    var outDir: String = "a4_out"

    @Option(name: .long, help: "Systems (lines) per page")
    var systems: Int = 4

    @Option(name: .long, help: "Left/right margin (pt)")
    var marginX: Int = 36

    @Option(name: .long, help: "Top/bottom margin (pt)")
    var marginY: Int = 48

    func run() throws {
        let inputURL = URL(fileURLWithPath: ly)
        let outputURL = URL(fileURLWithPath: outDir)
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        let lyText = try String(contentsOf: inputURL, encoding: .utf8)
        let events = LilyParser.parse(source: lyText)

        // --- ScoreKit → A4 PNG ---
        let a4Width: Int = 595 // points at 72 DPI
        let a4Height: Int = 842
        let printableWidth = max(100, a4Width - 2 * marginX)
        let printableHeight = max(100, a4Height - 2 * marginY)
        let systemHeight = max(120, printableHeight / systems)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = a4Width * bytesPerPixel
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
        guard let ctx = CGContext(data: nil,
                                  width: a4Width,
                                  height: a4Height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow,
                                  space: colorSpace,
                                  bitmapInfo: bitmapInfo.rawValue) else {
            throw RuntimeError("Failed to create A4 CGContext")
        }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: a4Width, height: a4Height))

        let renderer = SimpleRenderer()
        var opts = LayoutOptions()
        opts.padding = .init(width: 16, height: 16)

        // Naive split: divide events evenly across systems for now.
        // Later we can split on bar boundaries using beat fractions.
        let perSystem = max(1, events.count / max(1, systems))
        for line in 0..<systems {
            let lo = line * perSystem
            let hi = min(events.count, (line + 1) * perSystem)
            guard lo < hi else { continue }
            let slice = Array(events[lo..<hi])
            let localRect = CGRect(x: 0, y: 0, width: printableWidth, height: systemHeight)
            let tree = renderer.layout(events: slice, in: localRect, options: opts)
            ctx.saveGState()
            let originX = CGFloat(marginX)
            let originY = CGFloat(marginY + line * systemHeight)
            ctx.translateBy(x: originX, y: originY)
            renderer.draw(tree, in: ctx, options: opts)
            ctx.restoreGState()
        }

        let scoreOut = outputURL.appendingPathComponent(inputURL.deletingPathExtension().lastPathComponent + "_scorekit_a4.png")
        try writePNG(ctx.makeImage()!, to: scoreOut)

        // --- Lily → A4 PDF + PNG ---
        let lyA4 = """
        \\version \"2.24.0\"
        \\paper { #(set-paper-size \"a4\") }
        { 
        \(lyText)
        }
        """
        do {
            let artifacts = try LilySession().render(lySource: lyA4, execute: true, formats: [.pdf])
            if let pdf = artifacts.pdfURL {
                let png = outputURL.appendingPathComponent(inputURL.deletingPathExtension().lastPathComponent + "_lily_a4.png")
                if let image = rasterizePDF(pdfURL: pdf, width: a4Width, height: a4Height) {
                    try writePNG(image, to: png)
                }
            }
        } catch {
            // If LilyPond unavailable, skip
        }
        print("Wrote A4 fixtures to \(outputURL.path)")
    }
}

// MARK: - Helpers

struct RuntimeError: Error, CustomStringConvertible { let description: String; init(_ m: String){ description = m } }

private func writePNG(_ image: CGImage, to url: URL) throws {
    let uti: CFString = UTType.png.identifier as CFString
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else {
        throw RuntimeError("Failed to create image destination")
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) { throw RuntimeError("Failed to write PNG") }
}

private func rasterizePDF(pdfURL: URL, width: Int, height: Int) -> CGImage? {
    guard let doc = PDFDocument(url: pdfURL), let page = doc.page(at: 0) else { return nil }
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let bounds = page.bounds(for: .mediaBox)
    let scaleX = CGFloat(width) / bounds.width
    let scaleY = CGFloat(height) / bounds.height
    let scale = min(scaleX, scaleY)
    let scaledSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
    let origin = CGPoint(x: (CGFloat(width) - scaledSize.width) / 2.0, y: (CGFloat(height) - scaledSize.height) / 2.0)
    ctx.saveGState()
    ctx.translateBy(x: origin.x, y: origin.y)
    ctx.scaleBy(x: scale, y: scale)
    page.draw(with: .mediaBox, to: ctx)
    ctx.restoreGState()
    return ctx.makeImage()
}

