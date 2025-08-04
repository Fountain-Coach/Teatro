import Foundation
import ArgumentParser
import Teatro
import Dispatch
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public enum RenderTarget: String, ExpressibleByArgument {
    case html, svg, png, markdown, codex, svgAnimated, csound, ump
}

public struct RenderCLI: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Render Teatro views from scripts, scores, and storyboards.",
        version: "0.1.0"
    )

    @Argument(help: "Input file path. Supported: .fountain, .ly, .mid/.midi, .ump, .csd, .storyboard, .session")
    public var positionalInput: String?

    @Option(name: [.short, .long], help: "Input file path")
    public var input: String?

    @Option(name: [.short, .long], help: "Output format")
    public var format: RenderTarget?

    @Option(name: [.short, .long], help: "Destination file path")
    public var output: String?

    @Flag(name: [.short, .long], help: "Watch the input file for changes")
    public var watch: Bool = false

    @Option(name: [.customShort("W"), .long], help: "Override output width")
    public var width: Int?

    @Option(name: [.customShort("H"), .long], help: "Override output height")
    public var height: Int?

    public init() {}

    public func run() throws {
        let inputPath = input ?? positionalInput
        var view: Renderable = defaultView()
        if let path = inputPath {
            view = try loadInput(path: path)
        }

        var effectiveWidth = width
        if effectiveWidth == nil,
           let env = ProcessInfo.processInfo.environment["TEATRO_WIDTH"],
           let value = Int(env) {
            effectiveWidth = value
        }
        if let w = effectiveWidth {
            setenv("TEATRO_SVG_WIDTH", String(w), 1)
            setenv("TEATRO_IMAGE_WIDTH", String(w), 1)
        }

        var effectiveHeight = height
        if effectiveHeight == nil,
           let env = ProcessInfo.processInfo.environment["TEATRO_HEIGHT"],
           let value = Int(env) {
            effectiveHeight = value
        }
        if let h = effectiveHeight {
            setenv("TEATRO_SVG_HEIGHT", String(h), 1)
            setenv("TEATRO_IMAGE_HEIGHT", String(h), 1)
        }

        let target = format ?? (output == nil ? .codex : .png)
        try render(view: view, target: target, outputPath: output)

        if watch, let path = inputPath {
            watchFile(path: path, target: target, outputPath: output)
        }
    }

    private func defaultView() -> Renderable {
        Stage(title: "CLI Demo") {
            VStack(alignment: .center, padding: 2) {
                TeatroIcon("🎭")
                Text("CLI Renderer", style: .bold)
            }
        }
    }

    private func loadInput(path: String) throws -> Renderable {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        let fileData = try Data(contentsOf: url)
        let signature = fileData.prefix(4)
        switch ext {
        case "fountain":
            let text = String(decoding: fileData, as: UTF8.self)
            return FountainSceneView(fountainText: text)
        case "ly":
            let text = String(decoding: fileData, as: UTF8.self)
            return LilyScore(text)
        case "csd":
            let text = String(decoding: fileData, as: UTF8.self)
            return CsoundScore(orchestra: "", score: text)
        case "storyboard":
            throw ValidationError("Storyboard DSL parsing is not implemented")
        case "mid", "midi":
            throw ValidationError("Parsing for MIDI files is not implemented")
        case "ump":
            throw ValidationError("Parsing for UMP files is not implemented")
        case "session":
            throw ValidationError("Parsing for .session files is not implemented")
        default:
            if signature == Data([0x4d, 0x54, 0x68, 0x64]) { // "MThd"
                throw ValidationError("Parsing for MIDI files is not implemented")
            } else if fileData.count % 4 == 0 {
                throw ValidationError("Parsing for UMP files is not implemented")
            } else {
                throw ValidationError("Unsupported input extension: .\(ext)")
            }
        }
    }

    private func render(view: Renderable, target: RenderTarget, outputPath: String?) throws {
        let isStdout = outputPath == nil
        switch target {
        case .html:
            let result = HTMLRenderer.render(view)
            try write(result, to: outputPath ?? "output.html", isStdout: isStdout)
        case .svg:
            let result = SVGRenderer.render(view)
            try write(result, to: outputPath ?? "output.svg", isStdout: isStdout)
        case .png:
            ImageRenderer.renderToPNG(view, to: outputPath ?? "output.png")
        case .markdown:
            let result = MarkdownRenderer.render(view)
            try write(result, to: outputPath ?? "output.md", isStdout: isStdout)
        case .codex:
            let result = CodexPreviewer.preview(view)
            try write(result, to: outputPath ?? "output.codex", isStdout: isStdout)
        case .svgAnimated:
            guard let storyboard = view as? Storyboard else {
                throw ValidationError("Animated SVG requires a Storyboard input")
            }
            let result = SVGAnimator.renderAnimatedSVG(storyboard: storyboard)
            try write(result, to: outputPath ?? "output.svg", isStdout: isStdout)
        case .csound:
            guard let score = view as? CsoundScore else {
                throw ValidationError("Csound output requires a Csound score input")
            }
            CsoundRenderer.renderToFile(score, to: outputPath ?? "output.csd")
        case .ump:
            throw ValidationError("UMP rendering not implemented")
        }
    }

    private func write(_ string: String, to path: String, isStdout: Bool) throws {
        if isStdout {
            print(string)
        } else {
            try string.write(toFile: path, atomically: true, encoding: .utf8)
            print("Wrote \(path)")
        }
    }

    private func watchFile(path: String, target: RenderTarget, outputPath: String?) {
#if canImport(Darwin)
        let descriptor = open(path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let queue = DispatchQueue.global()
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: DispatchSource.FileSystemEvent.write, queue: queue)
        source.setEventHandler {
            if let view = try? loadInput(path: path) {
                try? render(view: view, target: target, outputPath: outputPath)
            }
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
        dispatchMain()
#else
        var last = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? Date.distantPast
        while true {
            sleep(1)
            let mod = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? last
            if mod > last {
                last = mod
                if let view = try? loadInput(path: path) {
                    try? render(view: view, target: target, outputPath: outputPath)
                }
            }
        }
#endif
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

