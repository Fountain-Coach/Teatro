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

        // Bar-aware split using simple 4/4 default or first \time in the Lily source
        let ts = inferTimeSignature(from: lyText) ?? (4,4)
        let slices = splitByBars(events: events, systems: systems, beatsPerBar: ts.0, beatUnit: ts.1)
        for (line, slice) in slices.enumerated() {
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

// Parse first \time X/Y from lily text
private func inferTimeSignature(from text: String) -> (Int, Int)? {
    guard let r = text.range(of: "\\time ") else { return nil }
    let tail = text[r.upperBound...]
    var nums = ""; var dens = ""; var sawSlash = false
    for ch in tail {
        if ch.isNumber {
            if sawSlash { dens.append(ch) } else { nums.append(ch) }
        } else if ch == "/" { sawSlash = true }
        else if !ch.isWhitespace { break }
        if !sawSlash && nums.count > 3 { break }
        if sawSlash && dens.count > 3 { break }
    }
    if let n = Int(nums), let d = Int(dens), n > 0, d > 0 { return (n, d) }
    return nil
}

// Split events into systems at bar boundaries
private func splitByBars(events: [NotatedEvent], systems: Int, beatsPerBar: Int, beatUnit: Int) -> [[NotatedEvent]] {
    guard !events.isEmpty, systems > 0 else { return [] }
    // Compute bar count
    var totalBars = 0
    var acc: Double = 0
    for e in events {
        let f = eventBeats(e, beatUnit: beatUnit)
        acc += f
        while acc + 1e-9 >= Double(beatsPerBar) { totalBars += 1; acc -= Double(beatsPerBar) }
    }
    if acc > 1e-9 { totalBars += 1 }
    let barsPerSystem = max(1, Int(ceil(Double(totalBars) / Double(systems))))
    var slices: [[NotatedEvent]] = []
    var curr: [NotatedEvent] = []
    var barsInCurr = 0
    acc = 0
    for e in events {
        curr.append(e)
        acc += eventBeats(e, beatUnit: beatUnit)
        if acc + 1e-9 >= Double(beatsPerBar) {
            barsInCurr += 1; acc -= Double(beatsPerBar)
            if barsInCurr >= barsPerSystem {
                slices.append(curr)
                curr = []; barsInCurr = 0
            }
        }
    }
    if !curr.isEmpty { slices.append(curr) }
    return slices
}

private func eventBeats(_ e: NotatedEvent, beatUnit: Int) -> Double {
    switch e.base {
    case .note(_, let d): return Double(max(1, d.num)) * Double(beatUnit) / Double(max(1, d.den))
    case .rest(let d): return Double(max(1, d.num)) * Double(beatUnit) / Double(max(1, d.den))
    }
}
