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

    @Option(name: [.short, .long], help: "Input LilyPond .ly file (or use --fixtures-dir)")
    var lyPath: String?

    @Option(name: [.short, .long], help: "Output directory")
    var outDir: String = "compare_out"

    @Option(name: [.customShort("W"), .long], help: "Target width for outputs")
    var width: Int = 800
    
    @Option(name: .long, help: "Directory of .ly fixtures to batch compare")
    var fixturesDir: String?
    
    @Flag(name: .long, help: "Run simple parameter optimization to minimize RMSE")
    var optimize: Bool = false

    @Flag(name: .long, help: "Reduce logging; only print summaries")
    var quiet: Bool = false

    @Flag(name: .long, help: "Keep artifacts produced during optimization grid search")
    var keepOptArtifacts: Bool = false

    @Flag(name: .long, help: "Open output directory in Finder when done")
    var open: Bool = false

    func run() throws {
        let outURL = URL(fileURLWithPath: outDir)
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)

        let lyFiles: [URL]
        if let dir = fixturesDir {
            let dirURL = URL(fileURLWithPath: dir)
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil).filter { $0.pathExtension.lowercased() == "ly" }
                guard !contents.isEmpty else { throw ValidationError("No .ly files in \(dir)") }
                lyFiles = contents.sorted { $0.lastPathComponent < $1.lastPathComponent }
            } catch {
                // Helpful guidance when launched from a different CWD
                let cwd = FileManager.default.currentDirectoryPath
                let suggestion = URL(fileURLWithPath: cwd).appendingPathComponent("../AudioTalk/ScoreKit/Fixtures/Lily").standardized.path
                throw ValidationError("Failed to open fixtures dir: \(dir) (cwd=\(cwd)). If you're in Github-Desktop/Teatro, try --fixtures-dir \(suggestion)")
            }
        } else if let lyPath = lyPath {
            lyFiles = [URL(fileURLWithPath: lyPath)]
        } else {
            throw ValidationError("Provide --ly or --fixtures-dir")
        }

        var params = ScoreView.LayoutParams()
        if optimize {
            if let learned = try optimizeParams(files: lyFiles, width: width, outURL: outURL) {
                params = learned
                try saveParams(learned, to: outURL.appendingPathComponent("params.json"))
                print("Saved learned params to params.json")
            }
        }

        var results: [(name: String, rmse: Double?)] = []
        for file in lyFiles {
            do {
                let resultValue = try processSingle(lyURL: file,
                                            width: width,
                                            outURL: outURL.appendingPathComponent(file.deletingPathExtension().lastPathComponent),
                                            params: params,
                                            log: !quiet)
                results.append((file.lastPathComponent, resultValue))
            } catch {
                print("[WARN] Failed \(file.lastPathComponent): \(error)")
            }
        }
        if !results.isEmpty {
            let valid = results.compactMap { $0.rmse }
            if !valid.isEmpty {
                let averageRmse = valid.reduce(0, +) / Double(valid.count)
                print(String(format: "Average RMSE over %d files: %.6f", valid.count, averageRmse))
                // Persist metrics for later analysis
                let metricsPath = outURL.appendingPathComponent("metrics.json")
                let metricsDict = Dictionary(uniqueKeysWithValues: results.compactMap { name, maybeRmse in maybeRmse.map { (name, $0) } })
                try? writeJSON(metricsDict, to: metricsPath)
                print("Wrote metrics to \(metricsPath.path)")
            }
        }
        #if os(macOS)
        if open {
            _ = shell(["/usr/bin/open", outURL.path])
        }
        #endif
    }

    private func processSingle(lyURL: URL, width: Int, outURL: URL, params: ScoreView.LayoutParams, log: Bool) throws -> Double? {
        try FileManager.default.createDirectory(at: outURL, withIntermediateDirectories: true)
        let lyText = try String(contentsOf: lyURL, encoding: .utf8)
        let events = LilyParser.parse(source: lyText)
        let staffSpacing = 10.0
        let height = Int(20 + staffSpacing * 5 + 40)
        let scoreView = ScoreView(events: events, width: width, height: height, params: params)
        let scorekitSVG = ScoreKitSVGRenderer.renderScore(scoreView)
        let scorekitSVGPath = outURL.appendingPathComponent("scorekit.svg").path
        try scorekitSVG.write(toFile: scorekitSVGPath, atomically: true, encoding: .utf8)
        let scorekitPNGPath = outURL.appendingPathComponent("scorekit.png").path
        try ScoreKitPNGRasterizer.renderPNG(score: scoreView, to: scorekitPNGPath)

        var lilySVGPath: String? = nil
        do {
            let artifacts = try LilySession().render(lySource: lyText, execute: true, formats: [.svg])
            lilySVGPath = artifacts.svgURLs.first?.path
        } catch {
            if !quiet { print("[WARN] LilyPond execution failed: \(error). Skipping Lily reference for \(lyURL.lastPathComponent).") }
        }
        var lilyPNGPath: String? = nil
        if let lilySVG = lilySVGPath, let rsvg = which("rsvg-convert") ?? which("/opt/homebrew/bin/rsvg-convert") {
            let outPNG = outURL.appendingPathComponent("lily.png").path
            _ = shell([rsvg, "-w", String(width), "-h", String(height), "-o", outPNG, lilySVG])
            if FileManager.default.fileExists(atPath: outPNG) { lilyPNGPath = outPNG }
        } else if lilySVGPath != nil {
            if log { print("[INFO] rsvg-convert not found. Lily SVG available at \(lilySVGPath!). Convert to PNG manually for RMSE.") }
        }
        var rmse: Double? = nil
        if let lilyPNG = lilyPNGPath {
            if let (val, heat) = try compareRMSE(aPath: lilyPNG, bPath: scorekitPNGPath) {
                rmse = val
                try savePNG(image: heat, to: outURL.appendingPathComponent("heatmap.png").path)
            }
        }
        if log {
            print("Outputs in \(outURL.path)")
            if let rmse = rmse { print(String(format: "RMSE: %.6f", rmse)) }
        }
        return rmse
    }

    private func optimizeParams(files: [URL], width: Int, outURL: URL) throws -> ScoreView.LayoutParams? {
        let quarters: [Double] = [26, 28, 30]
        let eighths: [Double] = [20, 22, 24]
        let sixteenths: [Double] = [16, 18, 20]
        let radii: [Double] = [3.5, 4.0, 4.5]
        var best: (params: ScoreView.LayoutParams, rmse: Double)? = nil
        let subset = Array(files.prefix(5))
        let total = quarters.count * eighths.count * sixteenths.count * radii.count
        var iterationIndex = 0
        for quartersAdvance in quarters {
            for eighthsAdvance in eighths {
                for sixteenthsAdvance in sixteenths {
                    for radius in radii {
                        iterationIndex += 1
                        var params = ScoreView.LayoutParams()
                        params.advanceForDenom[4] = quartersAdvance
                        params.advanceForDenom[8] = eighthsAdvance
                        params.advanceForDenom[16] = sixteenthsAdvance
                        params.noteRadius = radius
                        if !quiet { print(String(format: "[opt] %d/%d q=%.1f e=%.1f s=%.1f r=%.1f", iterationIndex, total, quartersAdvance, eighthsAdvance, sixteenthsAdvance, radius)) }
                        let average = try averageRMSE(files: subset, width: width, params: params, outURL: outURL)
                        if let currentBest = best {
                            if let average = average, average < currentBest.rmse { best = (params, average) }
                        } else if let average = average {
                            best = (params, average)
                        }
                    }
                }
            }
        }
        if let bestResult = best {
            print(String(
                format: "Best RMSE: %.6f with params: q=%.1f e=%.1f s=%.1f r=%.1f",
                bestResult.rmse,
                bestResult.params.advanceForDenom[4] ?? 0,
                bestResult.params.advanceForDenom[8] ?? 0,
                bestResult.params.advanceForDenom[16] ?? 0,
                bestResult.params.noteRadius
            ))
            return bestResult.params
        }
        return nil
    }

    private func averageRMSE(files: [URL], width: Int, params: ScoreView.LayoutParams, outURL: URL) throws -> Double? {
        var accumulator: Double = 0
        var count: Int = 0
        for file in files {
            let base: URL
            if keepOptArtifacts {
                base = outURL.appendingPathComponent("__opt__")
            } else {
                base = FileManager.default.temporaryDirectory.appendingPathComponent("teatro-opt-\(UUID().uuidString)")
            }
            let tempDir = base.appendingPathComponent(file.deletingPathExtension().lastPathComponent)
            try? FileManager.default.removeItem(at: tempDir)
            let resultValue = try processSingle(lyURL: file, width: width, outURL: tempDir, params: params, log: false)
            if let value = resultValue { accumulator += value; count += 1 }
            if !keepOptArtifacts {
                try? FileManager.default.removeItem(at: base)
            }
        }
        guard count > 0 else { return nil }
        return accumulator / Double(count)
    }
}

private func saveParams(_ params: ScoreView.LayoutParams, to url: URL) throws {
    struct Enc: Codable { let advanceForDenom: [Int: Double]; let defaultAdvance: Double; let noteRadius: Double }
    let e = Enc(advanceForDenom: params.advanceForDenom, defaultAdvance: params.defaultAdvance, noteRadius: params.noteRadius)
    let data = try JSONEncoder().encode(e)
    try data.write(to: url)
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

// MARK: - JSON helper
private func writeJSON(_ dictionary: [String: Double], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}
