import Foundation
import ArgumentParser
import Teatro
import Dispatch
#if canImport(TSCBasic)
import TSCBasic
import TSCUtility
#endif
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public struct RenderCLI: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Render Teatro views from scripts, scores, and storyboards.",
        version: "0.1.0"
    )

    @Argument(help: "Input file path. Supported: .fountain, .ly, .mid/.midi, .ump, .csd, .storyboard, .session")
    public var positionalInput: String?

    @Option(name: [.short, .long], help: "Input file path")
    public var input: String?

    @Option(name: [.short, .long], help: ArgumentHelp("Output format", discussion: "Available: \(RenderTargetRegistry.shared.availableFormats.joined(separator: ", "))"))
    public var format: String?

    @Option(name: [.short, .long], help: "Destination file path")
    public var output: String?

    @Flag(name: [.short, .long], help: "Watch the input file for changes")
    public var watch: Bool = false

    @Flag(name: .long, help: "Ignore mismatched output extension and format")
    public var forceFormat: Bool = false

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
        if effectiveWidth == nil {
            let envSVG = ProcessInfo.processInfo.environment["TEATRO_SVG_WIDTH"].flatMap(Int.init)
            let envIMG = ProcessInfo.processInfo.environment["TEATRO_IMAGE_WIDTH"].flatMap(Int.init)
            effectiveWidth = envSVG ?? envIMG
        }
        if let w = effectiveWidth {
            setenv("TEATRO_SVG_WIDTH", String(w), 1)
            setenv("TEATRO_IMAGE_WIDTH", String(w), 1)
        }

        var effectiveHeight = height
        if effectiveHeight == nil {
            let envSVG = ProcessInfo.processInfo.environment["TEATRO_SVG_HEIGHT"].flatMap(Int.init)
            let envIMG = ProcessInfo.processInfo.environment["TEATRO_IMAGE_HEIGHT"].flatMap(Int.init)
            effectiveHeight = envSVG ?? envIMG
        }
        if let h = effectiveHeight {
            setenv("TEATRO_SVG_HEIGHT", String(h), 1)
            setenv("TEATRO_IMAGE_HEIGHT", String(h), 1)
        }

        let target = try determineTarget()
        try render(view: view, target: target, outputPath: output)

        if watch, let path = inputPath {
            _ = watchFile(path: path, target: target, outputPath: output)
            dispatchMain()
        }
    }

    private func determineTarget() throws -> RenderTargetProtocol.Type {
        if let fmt = format {
            guard let target = RenderTargetRegistry.shared.lookup(fmt) else {
                let available = RenderTargetRegistry.shared.availableFormats.joined(separator: ", ")
                throw ValidationError("Unsupported format \(fmt). Available: \(available)")
            }
            if let out = output {
                let ext = URL(fileURLWithPath: out).pathExtension.lowercased()
                if !forceFormat,
                   let inferred = Self.inferFormat(fromExtension: ext),
                   inferred.name != target.name,
                   !ext.isEmpty {
                    throw ValidationError("Output extension .\(ext) does not match format \(target.name). Use --force-format to override.")
                }
            }
            return target
        }
        if let out = output {
            let ext = URL(fileURLWithPath: out).pathExtension.lowercased()
            if let inferred = Self.inferFormat(fromExtension: ext) {
                return inferred
            }
            return RenderTargetRegistry.shared.lookup("png")!
        }
        return RenderTargetRegistry.shared.lookup("codex")!
    }

    private static func inferFormat(fromExtension ext: String) -> RenderTargetProtocol.Type? {
        RenderTargetRegistry.shared.lookup(ext)
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
            do {
                return try CSDParser.parse(text)
            } catch let err as ParserError {
                throw ValidationError(formatParserError(err, path: path))
            }
        case "storyboard":
            let text = String(decoding: fileData, as: UTF8.self)
            do {
                return try StoryboardParser.parse(text)
            } catch let err as ParserError {
                throw ValidationError(formatParserError(err, path: path))
            }
        case "mid", "midi":
            let events = try parseMidiFile(data: fileData)
            return MidiEventView(events: events)
        case "ump":
            let events = try parseUMPFile(data: fileData)
            return MidiEventView(events: events)
        case "session":
            let text = String(decoding: fileData, as: UTF8.self)
            return SessionParser.parse(text)
        default:
            if signature == Data([0x4d, 0x54, 0x68, 0x64]) { // "MThd"
                let events = try parseMidiFile(data: fileData)
                return MidiEventView(events: events)
            } else if fileData.count % 4 == 0 {
                let events = try parseUMPFile(data: fileData)
                return MidiEventView(events: events)
            } else {
                throw ValidationError("Unsupported input extension: .\(ext)")
            }
        }
    }

    private func formatParserError(_ error: ParserError, path: String) -> String {
        "\(path):\(error.line):\(error.column): \(error.message)\n\(error.snippet)"
    }

    private func parseMidiFile(data: Data) throws -> [any MidiEventProtocol] {
        do {
            return try MidiFileParser.parseFile(data: data)
        } catch {
            throw ValidationError("Failed to parse MIDI file: \(error)")
        }
    }

    private func parseUMPFile(data: Data) throws -> [any MidiEventProtocol] {
        do {
            return try UMPParser.parse(data: data)
        } catch {
            throw ValidationError("Failed to parse UMP file: \(error)")
        }
    }

    func render(view: Renderable, target: RenderTargetProtocol.Type, outputPath: String?) throws {
        try target.render(view: view, output: outputPath)
    }

    @discardableResult
    func watchFile(path: String, target: RenderTargetProtocol.Type, outputPath: String?, queue: DispatchQueue = .global()) -> WatchToken? {
        #if canImport(TSCBasic) && !os(Linux)
        let cwd = localFileSystem.currentWorkingDirectory ?? AbsolutePath(FileManager.default.currentDirectoryPath)
        let fileURL = URL(fileURLWithPath: path)
        let dirAbs = AbsolutePath(fileURL.deletingLastPathComponent().path, relativeTo: cwd)
        let fileName = fileURL.lastPathComponent
        let watcher = FSWatch(paths: [dirAbs], latency: 1.0) { [self] paths in
            if paths.contains(where: { $0.basename == fileName }) {
                queue.async {
                    if let view = try? loadInput(path: path) {
                        try? render(view: view, target: target, outputPath: outputPath)
                    }
                }
            }
        }
        try? watcher.start()
        return WatchToken(watcher)
        #else
        var last = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? Date.distantPast
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: .seconds(1))
        source.setEventHandler { [self] in
            let mod = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? last
            if mod > last {
                last = mod
                if let view = try? loadInput(path: path) {
                    try? render(view: view, target: target, outputPath: outputPath)
                }
            }
        }
        source.resume()
        return WatchToken(timer: source)
        #endif
    }
}

extension RenderCLI: Sendable {}

final class WatchToken {
    #if canImport(TSCUtility) && !os(Linux)
    private var watcher: FSWatch?
    init(_ watcher: FSWatch) {
        self.watcher = watcher
    }
    func cancel() {
        watcher?.stop()
        watcher = nil
    }
    #else
    private var timer: DispatchSourceTimer?
    init(timer: DispatchSourceTimer) {
        self.timer = timer
    }
    func cancel() {
        timer?.cancel()
        timer = nil
    }
    #endif
}

struct MidiEventView: Renderable {
    let events: [any MidiEventProtocol]

    func layout() -> LayoutNode {
        let lines = events.map { event -> String in
            var parts: [String] = ["t\(event.timestamp)"]
            if let ch = event.channel { parts.append("ch\(ch)") }
            switch event.type {
            case .noteOn:
                parts.append("noteOn \(event.noteNumber ?? 0) v\(event.velocity ?? 0)")
            case .noteOff:
                parts.append("noteOff \(event.noteNumber ?? 0)")
            case .controlChange:
                parts.append("cc \(event.noteNumber ?? 0) \(event.controllerValue ?? 0)")
            case .programChange:
                parts.append("program \(event.controllerValue ?? 0)")
            case .pitchBend:
                parts.append("pitch \(event.controllerValue ?? 0)")
            case .channelPressure:
                parts.append("pressure \(event.controllerValue ?? 0)")
            case .polyphonicKeyPressure:
                parts.append("polyPressure \(event.noteNumber ?? 0) v\(event.velocity ?? 0)")
            case .meta:
                let meta = event.metaType.map { String(format: "%02X", $0) } ?? "??"
                parts.append("meta \(meta)")
            case .sysEx:
                parts.append("sysex \(event.rawData?.count ?? 0) bytes")
            case .unknown:
                parts.append("unknown")
            }
            return parts.joined(separator: " ")
        }.joined(separator: "\n")
        return .raw(lines)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

