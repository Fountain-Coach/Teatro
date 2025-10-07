import SwiftUI
import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import UniformTypeIdentifiers
import ScoreKit
import TeatroRenderAPI
import TeatroScoreKitRenderer

@main
struct ScoreKitCompareApp: App {
    var body: some Scene {
        WindowGroup("ScoreKit Compare") {
            CompareView()
                .frame(minWidth: 980, minHeight: 520)
        }
    }
}

struct CompareView: View {
    @State private var fixturesDirectory: URL? = nil
    @State private var lilyFiles: [URL] = []
    @State private var selectedIndex: Int = 0
    @State private var targetWidth: Int = 800
    @State private var scorekitImage: CGImage? = nil
    @State private var lilyImage: CGImage? = nil
    @State private var heatmapImage: CGImage? = nil
    @State private var rmseValue: Double? = nil
    @State private var busy: Bool = false
    @State private var showHeatmap: Bool = false
    @State private var message: String = ""

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Open Fixtures…", action: pickDirectory)
                if let dir = fixturesDirectory { Text(dir.path).font(.caption).foregroundColor(.secondary) }
                Spacer()
                Stepper(value: $targetWidth, in: 400...2000, step: 20) {
                    Text("Width: \(targetWidth) px")
                }.frame(width: 220)
                Toggle("Heatmap", isOn: $showHeatmap).toggleStyle(.switch)
                Button("Prev", action: prevFile)
                Button("Next", action: nextFile)
                Button("Render", action: renderSelected)
            }
            .padding(.horizontal, 8)

            if !message.isEmpty {
                Text(message).foregroundColor(.secondary).font(.caption)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack {
                    Text("ScoreKit (\(scorekitImage == nil ? "no image" : "rendered"))").font(.caption)
                    ZStack {
                        ImageView(image: scorekitImage)
                        if busy { ProgressView().controlSize(.large) }
                    }
                }
                VStack {
                    Text("LilyPond (\(lilyImage == nil ? "no image" : "rendered"))").font(.caption)
                    ImageView(image: showHeatmap ? heatmapImage : lilyImage)
                }
            }
            .background(Color(nsColor: .textBackgroundColor))
            .padding(8)

            HStack {
                Text(currentFileName()).font(.caption)
                Spacer()
                if let rmseValue { Text(String(format: "RMSE: %.6f", rmseValue)) }
            }
            .padding(.horizontal, 8)
        }
        .onAppear(perform: bootstrapDefaultFixtures)
    }

    private func currentFileName() -> String {
        guard selectedIndex < lilyFiles.count else { return "" }
        return lilyFiles[selectedIndex].lastPathComponent
    }

    private func pickDirectory() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            fixturesDirectory = url
            refreshFileList()
            renderSelected()
        }
        #endif
    }

    private func bootstrapDefaultFixtures() {
        guard fixturesDirectory == nil else { return }
        // Try relative path: ../ScoreKit/Fixtures/Lily
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let guess = cwd.appendingPathComponent("../ScoreKit/Fixtures/Lily").standardized
        if FileManager.default.fileExists(atPath: guess.path) {
            fixturesDirectory = guess
            refreshFileList()
        }
    }

    private func refreshFileList() {
        guard let dir = fixturesDirectory else { lilyFiles = []; return }
        let files = (try? FileManager.default
            .contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        lilyFiles = files.filter { $0.pathExtension.lowercased() == "ly" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        selectedIndex = 0
        renderSelected()
    }

    private func prevFile() { guard !lilyFiles.isEmpty else { return }; selectedIndex = max(0, selectedIndex - 1); renderSelected() }
    private func nextFile() { guard !lilyFiles.isEmpty else { return }; selectedIndex = min(lilyFiles.count - 1, selectedIndex + 1); renderSelected() }

    private func renderSelected() {
        guard selectedIndex < lilyFiles.count else { return }
        busy = true; message = "Rendering…"
        let widthValue = targetWidth
        let filesSnapshot = lilyFiles
        let idxSnapshot = selectedIndex
        DispatchQueue.global(qos: .userInitiated).async {
            defer { DispatchQueue.main.async { busy = false } }
            guard idxSnapshot < filesSnapshot.count else { return }
            let url = filesSnapshot[idxSnapshot]
            do {
                // Load lily text
                let text = try String(contentsOf: url, encoding: .utf8)
                // ScoreKit events
                let events = LilyParser.parse(source: text)
                // Render ScoreKit → PNG (via rasterizer) to temp, then load CGImage
                let staffSpacing = 10.0
                let height = Int(20 + staffSpacing * 5 + 40)
                let score = ScoreView(events: events, width: widthValue, height: height)
                let tempScorePath = FileManager.default.temporaryDirectory
                    .appendingPathComponent("scorekit-\(UUID().uuidString).png").path
                try ScoreKitPNGRasterizer.renderPNG(score: score, to: tempScorePath)
                let scoreImage = loadPNG(tempScorePath)

                // Render Lily → PDF, rasterize first page to CGImage at target size
                let session = LilySession()
                var lilyCG: CGImage? = nil
                do {
                    let artifacts = try session.render(lySource: text, execute: true, formats: [.pdf])
                    if let pdf = artifacts.pdfURL, let cg = rasterizePDF(pdfURL: pdf, width: widthValue, height: height) {
                        lilyCG = cg
                    }
                } catch {
                    // Lily not found or render failed — keep nil and set message
                    lilyCG = nil
                }

                var rmse: Double? = nil
                var heat: CGImage? = nil
                if let lilyCG, let scoreImage {
                    if let result = compareRMSE(lhs: lilyCG, rhs: scoreImage) {
                        rmse = result.value; heat = result.heatmap
                    }
                }

                DispatchQueue.main.async {
                    scorekitImage = scoreImage
                    lilyImage = lilyCG
                    heatmapImage = heat
                    rmseValue = rmse
                    message = lilyCG == nil ? "LilyPond render unavailable (PDF not produced)" : ""
                }
            } catch {
                DispatchQueue.main.async { message = "Failed: \(error)" }
            }
        }
    }
}

private struct ImageView: NSViewRepresentable {
    let image: CGImage?
    func makeNSView(context: Context) -> NSImageView { NSImageView() }
    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let image {
            nsView.image = NSImage(cgImage: image, size: .zero)
        } else {
            nsView.image = nil
        }
        nsView.imageScaling = .scaleProportionallyUpOrDown
    }
}

// MARK: - Utilities

private func loadPNG(_ path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
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
    // Fit PDF page into target rect preserving aspect by scaling
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

private func compareRMSE(lhs: CGImage, rhs: CGImage) -> (value: Double, heatmap: CGImage)? {
    guard lhs.width == rhs.width, lhs.height == rhs.height else { return nil }
    let width = lhs.width, height = lhs.height
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

    guard let abuf = pixels(from: lhs), let bbuf = pixels(from: rhs) else { return nil }
    var sumSq: Double = 0
    var heat = [UInt8](repeating: 0, count: count * bytesPerPixel)
    for i in 0..<count {
        let idx = i * bytesPerPixel
        let dr = Int(abuf[idx]) - Int(bbuf[idx])
        let dg = Int(abuf[idx+1]) - Int(bbuf[idx+1])
        let db = Int(abuf[idx+2]) - Int(bbuf[idx+2])
        let diff = (dr*dr + dg*dg + db*db) / 3
        sumSq += Double(diff)
        let magnitude = min(255, Int(sqrt(Double(diff))))
        heat[idx] = UInt8(magnitude)
        heat[idx+1] = 0
        heat[idx+2] = 0
        heat[idx+3] = 255
    }
    let rmse = sqrt(sumSq / Double(count))

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
