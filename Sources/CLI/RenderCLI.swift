import Foundation
import ArgumentParser
import Teatro
import Dispatch
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public struct Debounce: Sendable {
    public static let none = Debounce.milliseconds(0)
    public static func milliseconds(_ ms: Int) -> Debounce { Debounce(interval: .milliseconds(ms)) }
    public let interval: DispatchTimeInterval
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

    @Option(name: [.short, .long], help: ArgumentHelp("Output format", discussion: "Available: \(RendererRegistry.shared.availableIdentifiers.joined(separator: ", "))"))
    public var format: String?

    @Option(name: [.short, .long], help: "Destination file path")
    public var output: String?

    @Flag(name: [.short, .long], help: "Watch the input file for changes")
    public var watch: Bool = false

    @Flag(name: .long, help: "Ignore mismatched output extension and format")
    public var forceFormat: Bool = false

    @Flag(name: .long, help: "Bridge UMP input to MIDI 1.0 byte stream for legacy devices")
    public var midi1Bridge: Bool = false

    @Flag(name: .customLong("watch-rtpmidi"), help: "Subscribe to RTP-MIDI UMP packets and forward them to stdout")
    public var watchRTPMIDI: Bool = false // Refs: teatro-root

    @Option(name: .customLong("sse-group"), help: "Filter incoming UMP stream by group")
    public var sseGroup: Int?

    @Option(name: .customLong("save-ump"), help: "Persist received UMP packets to the given file")
    public var saveUMP: String?

    @Option(name: .customLong("replay-ump"), help: "Replay UMP packets from file")
    public var replayUMP: String?

    @Option(name: [.customShort("W"), .long], help: "Override output width")
    public var width: Int?

    @Option(name: [.customShort("H"), .long], help: "Override output height")
    public var height: Int?

    public init() {}

    public func run() throws {
        let inputPath = input ?? positionalInput

        if let replay = replayUMP {
            let url = URL(fileURLWithPath: replay)
            let data = try Data(contentsOf: url)
            if let save = saveUMP {
                try data.write(to: URL(fileURLWithPath: save))
            }
            if midi1Bridge {
                let bridged = try MIDI1Bridge.umpToMIDI1(data)
                FileHandle.standardOutput.write(bridged)
            } else {
                FileHandle.standardOutput.write(data)
            }
            return
        }

        if watchRTPMIDI {
            _ = try watchRTPMIDI(group: sseGroup ?? 0, savePath: saveUMP)
            dispatchMain()
        }

        if midi1Bridge {
            guard let path = inputPath else {
                throw ValidationError("MIDI1 bridge requires an input file")
            }
            let url = URL(fileURLWithPath: path)
            let fileData = try Data(contentsOf: url)
            guard fileData.count % 4 == 0 else {
                throw ValidationError("MIDI1 bridge requires UMP input")
            }
            let midi1Data = try MIDI1Bridge.umpToMIDI1(fileData)
            if let out = output {
                try midi1Data.write(to: URL(fileURLWithPath: out))
            } else {
                FileHandle.standardOutput.write(midi1Data)
            }
            return
        }

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
            _ = try watchFile(path: path, target: target, outputPath: output)
            dispatchMain()
        }
    }

    private func determineTarget() throws -> RendererPlugin.Type {
        if let fmt = format {
            guard let target = RendererRegistry.shared.plugin(for: fmt) else {
                let available = RendererRegistry.shared.availableIdentifiers.joined(separator: ", ")
                throw ValidationError("Unsupported format \(fmt). Available: \(available)")
            }
            if let out = output {
                let ext = URL(fileURLWithPath: out).pathExtension.lowercased()
                if !forceFormat,
                   let inferred = Self.inferFormat(fromExtension: ext),
                   inferred.identifier != target.identifier,
                   !ext.isEmpty {
                    throw ValidationError("Output extension .\(ext) does not match format \(target.identifier). Use --force-format to override.")
                }
            }
            return target
        }
        if let out = output {
            let ext = URL(fileURLWithPath: out).pathExtension.lowercased()
            if let inferred = Self.inferFormat(fromExtension: ext) {
                return inferred
            }
            return RendererRegistry.shared.plugin(for: "png")!
        }
        return RendererRegistry.shared.plugin(for: "codex")!
    }

    private static func inferFormat(fromExtension ext: String) -> RendererPlugin.Type? {
        RendererRegistry.shared.pluginForExtension(ext)
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

    func render(view: Renderable, target: RendererPlugin.Type, outputPath: String?) throws {
        do {
            try target.render(view: view, output: outputPath)
        } catch RendererError.unsupportedInput(let msg) {
            throw ValidationError(msg)
        }
    }

    @discardableResult
    func watchRTPMIDI(group: Int, savePath: String?) throws -> AnyObject {
        #if os(Linux)
        let sock = Glibc.socket(AF_INET, Int32(SOCK_DGRAM.rawValue), 0)
        #else
        let sock = Darwin.socket(AF_INET, SOCK_DGRAM, 0)
        #endif
        guard sock >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = in_port_t(UInt16(5004).bigEndian)
        addr.sin_addr = in_addr(s_addr: INADDR_ANY)
        let bindRes = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { ptr in
                bind(sock, ptr, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindRes == 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil) }

        let queue = DispatchQueue(label: "teatro.rtpmidi.\(UUID().uuidString)")
        let source = DispatchSource.makeReadSource(fileDescriptor: sock, queue: queue)
        var saveHandle: FileHandle?
        if let path = savePath {
            _ = FileManager.default.createFile(atPath: path, contents: nil)
            saveHandle = FileHandle(forWritingAtPath: path)
        }
        source.setEventHandler { [self] in
            var buffer = [UInt8](repeating: 0, count: 2048)
            let n = read(sock, &buffer, buffer.count)
            if n > 0 {
                let data = Data(buffer[0..<n])
                if Int(buffer[0] & 0x0F) == group {
                    if let saveHandle = saveHandle {
                        saveHandle.write(data)
                    }
                    if midi1Bridge {
                        if let bridged = try? MIDI1Bridge.umpToMIDI1(data) {
                            FileHandle.standardOutput.write(bridged)
                        }
                    } else {
                        FileHandle.standardOutput.write(data)
                    }
                }
            }
        }
        source.setCancelHandler {
            close(sock)
            saveHandle?.closeFile()
        }
        source.resume()
        return source as AnyObject
    }

    @discardableResult
    func watchFile(path: String, target: RendererPlugin.Type, outputPath: String?, debounce: Debounce = .milliseconds(300), onChange: @escaping @Sendable (URL) -> Void = { _ in }) throws -> AnyObject {
        #if os(Linux)
        var last = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? Date.distantPast
        let queue = DispatchQueue(label: "teatro.watch.\(UUID().uuidString)")
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now(), repeating: .seconds(1))
        source.setEventHandler { [self] in
            let mod = (try? FileManager.default.attributesOfItem(atPath: path)[.modificationDate] as? Date) ?? last
            if mod > last {
                last = mod
                if let view = try? loadInput(path: path) {
                    try? render(view: view, target: target, outputPath: outputPath)
                }
                onChange(URL(fileURLWithPath: path))
            }
        }
        source.resume()
        return WatchToken(timer: source)
        #else
        let fileURL = URL(fileURLWithPath: path)
        let dirURL = fileURL.deletingLastPathComponent()
        let fd = open(dirURL.path, O_EVTONLY)
        guard fd >= 0 else { throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno), userInfo: nil) }
        let queue = DispatchQueue(label: "teatro.watch.\(UUID().uuidString)")
        let mask: DispatchSource.FileSystemEvent = [.write, .rename, .delete]
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: mask, queue: queue)
        var workItem: DispatchWorkItem?
        source.setEventHandler { [self] in
            workItem?.cancel()
            let item = DispatchWorkItem { [self] in
                if let view = try? loadInput(path: path) {
                    try? render(view: view, target: target, outputPath: outputPath)
                }
                onChange(fileURL)
            }
            workItem = item
            queue.asyncAfter(deadline: .now() + debounce.interval, execute: item)
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        return WatchToken(source: source)
        #endif
    }
}

extension RenderCLI: Sendable {}

#if os(Linux)
final class WatchToken {
    private var timer: DispatchSourceTimer?
    init(timer: DispatchSourceTimer) {
        self.timer = timer
    }
    func cancel() {
        timer?.cancel()
        timer = nil
    }
}
#else
final class WatchToken {
    private var source: DispatchSourceFileSystemObject?
    init(source: DispatchSourceFileSystemObject) {
        self.source = source
    }
    func cancel() {
        source?.cancel()
        source = nil
    }
}
#endif

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

