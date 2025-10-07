import SwiftUI
import Foundation
import CoreGraphics
import ImageIO
import PDFKit
import UniformTypeIdentifiers
import ScoreKit
import ScoreKitUI
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
    @State private var exportingAll: Bool = false

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
                Button(exportingAll ? "Exporting…" : "Render All (A4)") {
                    Task { await renderAllA4() }
                }.disabled(fixturesDirectory == nil || exportingAll)
            }
            .padding(.horizontal, 8)

            if !message.isEmpty {
                Text(message).foregroundColor(.secondary).font(.caption)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack {
                    Text("ScoreKit (\(scorekitImage == nil ? "no image" : "rendered"))").font(.caption)
                    PaperPage(image: scorekitImage)
                }
                VStack {
                    Text(lilyCaption()).font(.caption)
                    PaperPage(image: showHeatmap ? heatmapImage : lilyImage)
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

    private func lilyCaption() -> String {
        if lilyImage == nil { return "LilyPond (unavailable)" }
        return "LilyPond (rendered)"
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

    // MARK: - Export all fixtures to A4 PNGs beside the fixtures folder
    @MainActor
    private func renderAllA4() async {
        guard let dir = fixturesDirectory else { return }
        exportingAll = true; message = "Exporting all (A4)…"
        let out = dir.appendingPathComponent("A4", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let files = lilyFiles
        let width = 595, height = 842 // A4 at 72 DPI
        for f in files {
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    defer { cont.resume() }
                    do {
                        let text = try String(contentsOf: f, encoding: .utf8)
                        // ScoreKit A4
                        if let img = renderScoreKitA4(text: text, width: width, height: height, systems: 4, marginX: 36, marginY: 48) {
                            let outURL = out.appendingPathComponent(f.deletingPathExtension().lastPathComponent + "_scorekit_a4.png")
                            try? writePNG(img, to: outURL)
                        }
                        // Lily A4
                        if let lily = renderLilyA4(text: text, width: width, height: height) {
                            let outURL = out.appendingPathComponent(f.deletingPathExtension().lastPathComponent + "_lily_a4.png")
                            try? writePNG(lily, to: outURL)
                        }
                    } catch {
                        // ignore and continue
                    }
                }
            }
        }
        exportingAll = false; message = "Exported A4 PNGs to \(out.path)"
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

// A4 paper view that draws a page with aspect ratio sqrt(2) and fits the CGImage inside.
private struct PaperPage: View {
    let image: CGImage?
    private let aspect: CGFloat = 1.41421356237
    var body: some View {
        GeometryReader { geo in
            let avail = geo.size
            let pageWidth = min(avail.width, avail.height / aspect)
            let pageHeight = pageWidth * aspect
            let pageSize = CGSize(width: pageWidth, height: pageHeight)
            ZStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 1, x: 0, y: 1)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black.opacity(0.12), lineWidth: 1))
                    .frame(width: pageSize.width, height: pageSize.height)
                if let image {
                    let ns = NSImage(cgImage: image, size: .init(width: image.width, height: image.height))
                    Image(nsImage: ns)
                        .resizable()
                        .scaledToFit()
                        .frame(width: pageSize.width - 4, height: pageSize.height - 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(minHeight: 200)
    }
}

// MARK: - Utilities

private func loadPNG(_ path: String) -> CGImage? {
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

private func writePNG(_ image: CGImage, to url: URL) throws {
    let uti: CFString = UTType.png.identifier as CFString
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, uti, 1, nil) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    _ = CGImageDestinationFinalize(dest)
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

// MARK: - A4 helpers (in-app)
private func renderScoreKitA4(text: String, width: Int, height: Int, systems: Int, marginX: Int, marginY: Int) -> CGImage? {
    let events = LilyParser.parse(source: text)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue))
    guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else { return nil }
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let printableWidth = max(100, width - 2 * marginX)
    let printableHeight = max(100, height - 2 * marginY)
    let systemHeight = max(120, printableHeight / max(1, systems))
    let renderer = SimpleRenderer(); var opts = LayoutOptions(); opts.padding = .init(width: 16, height: 16)
    let ts = inferTimeSignature(from: text) ?? (4,4)
    let slices = splitByBars(events: events, systems: systems, beatsPerBar: ts.0, beatUnit: ts.1)
    for (line, slice) in slices.enumerated() {
        let tree = renderer.layout(events: slice, in: CGRect(x: 0, y: 0, width: printableWidth, height: systemHeight), options: opts)
        ctx.saveGState(); ctx.translateBy(x: CGFloat(marginX), y: CGFloat(marginY + line * systemHeight));
        renderer.draw(tree, in: ctx, options: opts)
        ctx.restoreGState()
    }
    return ctx.makeImage()
}

private func renderLilyA4(text: String, width: Int, height: Int) -> CGImage? {
    let lyA4 = """
    \\version \"2.24.0\"
    \\paper { #(set-paper-size \"a4\") }
    { 
    \(text)
    }
    """
    do {
        let artifacts = try LilySession().render(lySource: lyA4, execute: true, formats: [.pdf])
        if let pdf = artifacts.pdfURL { return rasterizePDF(pdfURL: pdf, width: width, height: height) }
    } catch { }
    return nil
}

// Shared helpers (simple copies used here to avoid cross-target deps)
private func inferTimeSignature(from text: String) -> (Int, Int)? {
    guard let r = text.range(of: "\\time ") else { return nil }
    let tail = text[r.upperBound...]
    var nums = ""; var dens = ""; var sawSlash = false
    for ch in tail {
        if ch.isNumber { if sawSlash { dens.append(ch) } else { nums.append(ch) } }
        else if ch == "/" { sawSlash = true }
        else if !ch.isWhitespace { break }
    }
    if let n = Int(nums), let d = Int(dens), n > 0, d > 0 { return (n, d) }
    return nil
}

private func splitByBars(events: [NotatedEvent], systems: Int, beatsPerBar: Int, beatUnit: Int) -> [[NotatedEvent]] {
    guard !events.isEmpty, systems > 0 else { return [] }
    var totalBars = 0
    var acc: Double = 0
    for e in events { acc += eventBeats(e, beatUnit: beatUnit); while acc + 1e-9 >= Double(beatsPerBar) { totalBars += 1; acc -= Double(beatsPerBar) } }
    if acc > 1e-9 { totalBars += 1 }
    let barsPerSystem = max(1, Int(ceil(Double(totalBars) / Double(systems))))
    var slices: [[NotatedEvent]] = []
    var curr: [NotatedEvent] = []; var barsInCurr = 0; acc = 0
    for e in events {
        curr.append(e); acc += eventBeats(e, beatUnit: beatUnit)
        if acc + 1e-9 >= Double(beatsPerBar) { barsInCurr += 1; acc -= Double(beatsPerBar); if barsInCurr >= barsPerSystem { slices.append(curr); curr = []; barsInCurr = 0 } }
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
