import Foundation
import ArgumentParser
import Teatro
import ScoreKit
import TeatroScoreKitRenderer
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@main
struct CompareCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compare Lily (ground truth) vs ScoreKit renderer outputs and compute RMSE."
    )

    @Option(name: [.short, .long], help: "Input LilyPond .ly file")
    var ly: String

    @Option(name: [.short, .long], help: "Output directory")
    var outDir: String = "compare_out"

    @Option(name: [.customShort("W"), .long], help: "Target width for outputs")
    var width: Int = 800

    func run() throws {
        let outURL = URL(fileURLWithPath: outDir)
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)

        // Load Lily source
        let lyURL = URL(fileURLWithPath: ly)
        let lyText = try String(contentsOf: lyURL, encoding: .utf8)

        // Parse using ScoreKit and build a ScoreView
        let events = LilyParser.parse(source: lyText)
        let scoreView = ScoreView(events: events, width: width, height: 200)

        // Produce ScoreKit SVG and PNG
        let scorekitSVG = ScoreKitSVGRenderer.renderScore(scoreView)
        let scorekitSVGPath = outURL.appendingPathComponent("scorekit.svg").path
        try scorekitSVG.write(toFile: scorekitSVGPath, atomically: true, encoding: .utf8)

        let scorekitPNGPath = outURL.appendingPathComponent("scorekit.png").path
        try ScoreKitPNGRasterizer.renderPNG(score: scoreView, to: scorekitPNGPath)

        // Produce Lily SVG via LilySession (if lilypond available)
        var lilySVGPath: String? = nil
        do {
            let artifacts = try LilySession().render(lySource: lyText, execute: true, formats: [.svg])
            lilySVGPath = artifacts.svgURLs.first?.path
        } catch {
            print("[WARN] LilyPond execution failed: \(error). Skipping Lily reference.")
        }

        // If rsvg-convert available and Lily SVG exists, produce Lily PNG with matching dimensions
        var lilyPNGPath: String? = nil
        if let lilySVG = lilySVGPath, let rsvg = which("rsvg-convert") ?? which("/opt/homebrew/bin/rsvg-convert") {
            let outPNG = outURL.appendingPathComponent("lily.png").path
            let h = 200 // crude default height; match ScoreKitPNGRasterizer's default for empty score
            _ = shell([rsvg, "-w", String(width), "-h", String(h), "-o", outPNG, lilySVG])
            if FileManager.default.fileExists(atPath: outPNG) {
                lilyPNGPath = outPNG
            }
        } else {
            if lilySVGPath != nil {
                print("[INFO] rsvg-convert not found. Lily SVG available at \(lilySVGPath!). Convert to PNG manually for RMSE.")
            }
        }

        // Compute RMSE if both PNGs are present
        if let lilyPNG = lilyPNGPath {
            if let (rmse, heat) = try compareRMSE(aPath: lilyPNG, bPath: scorekitPNGPath) {
                let heatPath = outURL.appendingPathComponent("heatmap.png").path
                try savePNG(image: heat, to: heatPath)
                print(String(format: "RMSE: %.6f", rmse))
                print("Wrote heatmap to \(heatPath)")
            } else {
                print("[WARN] Could not load PNGs for RMSE.")
            }
        } else {
            print("[INFO] Skipped RMSE — Lily PNG missing.")
        }

        print("Outputs in \(outURL.path)")
    }
}

// MARK: - Utilities

@discardableResult
func shell(_ args: [String]) -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: args[0])
    task.arguments = Array(args.dropFirst())
    try? task.run()
    task.waitUntilExit()
    return task.terminationStatus
}

func which(_ name: String) -> String? {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    task.arguments = [name]
    let pipe = Pipe(); task.standardOutput = pipe
    try? task.run()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (path?.isEmpty == false) ? path : nil
}

func loadPNG(_ path: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func savePNG(image: CGImage, to path: String) throws {
    let uti: CFString = UTType.png.identifier as CFString
    guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, uti, 1, nil) else {
        throw NSError(domain: "CompareCLI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image destination"])
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        throw NSError(domain: "CompareCLI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to write PNG"])
    }
}

func compareRMSE(aPath: String, bPath: String) throws -> (Double, CGImage)? {
    guard let a = loadPNG(aPath), let b = loadPNG(bPath), a.width == b.width, a.height == b.height else { return nil }
    let width = a.width, height = a.height
    let bytesPerPixel = 4
    let count = width * height

    func pixels(from image: CGImage) -> [UInt8]? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var data = [UInt8](repeating: 0, count: count * bytesPerPixel)
        data.withUnsafeMutableBytes { ptr in
            let info = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
            let ctx = CGContext(data: ptr.baseAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: width * bytesPerPixel,
                                space: colorSpace,
                                bitmapInfo: info.rawValue)
            ctx?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return data
    }

    guard let abuf = pixels(from: a), let bbuf = pixels(from: b) else { return nil }
    var sumSq: Double = 0
    var heat = [UInt8](repeating: 0, count: count * bytesPerPixel)
    for i in 0..<count {
        let idx = i * bytesPerPixel
        let dr = Int(abuf[idx]) - Int(bbuf[idx])
        let dg = Int(abuf[idx+1]) - Int(bbuf[idx+1])
        let db = Int(abuf[idx+2]) - Int(bbuf[idx+2])
        let diff = (dr*dr + dg*dg + db*db) / 3
        sumSq += Double(diff)
        let mag = min(255, Int(sqrt(Double(diff))))
        heat[idx] = UInt8(mag)     // R
        heat[idx+1] = 0            // G
        heat[idx+2] = 0            // B
        heat[idx+3] = 255          // A
    }
    let rmse = sqrt(sumSq / Double(count))

    // Build heatmap image
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let provider = CGDataProvider(data: Data(heat) as CFData)!
    let heatInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    let heatImage = CGImage(width: width,
                            height: height,
                            bitsPerComponent: 8,
                            bitsPerPixel: 32,
                            bytesPerRow: width * bytesPerPixel,
                            space: colorSpace,
                            bitmapInfo: heatInfo,
                            provider: provider,
                            decode: nil,
                            shouldInterpolate: false,
                            intent: .defaultIntent)!

    return (rmse, heatImage)
}
