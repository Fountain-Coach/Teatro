import Foundation
import ArgumentParser
import Teatro

struct HTMLTarget: RenderTargetProtocol {
    static let name = "html"
    static let aliases: [String] = []
    static func render(view: Renderable, output: String?) throws {
        let result = HTMLRenderer.render(view)
        try write(result, to: output, defaultName: "output.html")
    }
}

struct SVGTarget: RenderTargetProtocol {
    static let name = "svg"
    static let aliases: [String] = []
    static func render(view: Renderable, output: String?) throws {
        let result = SVGRenderer.render(view)
        try write(result, to: output, defaultName: "output.svg")
    }
}

struct PNGTarget: RenderTargetProtocol {
    static let name = "png"
    static let aliases: [String] = []
    static func render(view: Renderable, output: String?) throws {
        ImageRenderer.renderToPNG(view, to: output ?? "output.png")
    }
}

struct MarkdownTarget: RenderTargetProtocol {
    static let name = "markdown"
    static let aliases: [String] = ["md"]
    static func render(view: Renderable, output: String?) throws {
        let result = MarkdownRenderer.render(view)
        try write(result, to: output, defaultName: "output.md")
    }
}

struct CodexTarget: RenderTargetProtocol {
    static let name = "codex"
    static let aliases: [String] = []
    static func render(view: Renderable, output: String?) throws {
        let result = CodexPreviewer.preview(view)
        try write(result, to: output, defaultName: "output.codex")
    }
}

struct SVGAnimatedTarget: RenderTargetProtocol {
    static let name = "svgAnimated"
    static let aliases: [String] = ["svg-animated"]
    static func render(view: Renderable, output: String?) throws {
        guard let storyboard = view as? Storyboard else {
            throw ValidationError("Animated SVG requires a Storyboard input")
        }
        let result = SVGAnimator.renderAnimatedSVG(storyboard: storyboard)
        try write(result, to: output, defaultName: "output.svg")
    }
}

struct CsoundTarget: RenderTargetProtocol {
    static let name = "csound"
    static let aliases: [String] = ["csd"]
    static func render(view: Renderable, output: String?) throws {
        guard let score = view as? CsoundScore else {
            throw ValidationError("Csound output requires a Csound score input")
        }
        CSDRenderer.renderToFile(score, to: output ?? "output.csd")
    }
}

struct UMPTarget: RenderTargetProtocol {
    static let name = "ump"
    static let aliases: [String] = []
    static func render(view: Renderable, output: String?) throws {
        guard let midiView = view as? MidiEventView else {
            throw ValidationError("UMP output requires MIDI or UMP input")
        }
        let words = UMPEncoder.encodeEvents(midiView.events)
        var data = Data()
        for word in words {
            var be = word.bigEndian
            withUnsafeBytes(of: &be) { data.append(contentsOf: $0) }
        }
        try writeData(data, to: output, defaultName: "output.ump")
    }
}
