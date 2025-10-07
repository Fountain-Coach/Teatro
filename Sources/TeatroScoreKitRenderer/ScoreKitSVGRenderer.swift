import Foundation
import TeatroCore
import ScoreKit

// Minimal ScoreKit → SVG renderer plugin.
// Goal: provide a deterministic, calibrated coordinate space and draw staff + noteheads.
public struct ScoreKitSVGRenderer: RendererPlugin {
    public static let identifier = "scorekit-svg"
    public static let fileExtensions = ["svg"]

    public static func render(view: Renderable, output: String?) throws {
        guard let score = (view as? ScoreView) else {
            throw RendererError.unsupportedInput("ScoreKitSVGRenderer requires ScoreView")
        }
        let svg = renderScore(score)
        try write(svg, to: output, defaultName: "scorekit.svg")
    }

    public static func renderScore(_ score: ScoreView) -> String {
        let width = max(score.width, 200)
        let height = max(score.height, Int(score.paddingTop + score.staffSpacing * 5 + 40))

        var body: [String] = []
        // Staff lines
        let left: Double = Double(score.paddingLeft)
        let right: Double = Double(width) - score.paddingLeft
        for i in 0..<5 {
            let y = Double(score.paddingTop + score.staffSpacing * Double(i))
            body.append("<line x1=\"\(left)\" y1=\"\(y)\" x2=\"\(right)\" y2=\"\(y)\" stroke=\"black\" stroke-width=\"1\"/>")
        }
        // Notes (simple circles for now)
        for (i, ev) in score.events.enumerated() {
            switch ev.base {
            case .note:
                let (x, y) = score.pointForIndex(i)
                body.append("<circle cx=\"\(x)\" cy=\"\(y)\" r=\"\(score.noteRadius)\" fill=\"black\"/>")
            case .rest:
                continue
            }
        }

        let svg = """
        <svg xmlns=\"http://www.w3.org/2000/svg\" width=\"\(width)\" height=\"\(height)\">
        \(body.joined(separator: "\n"))
        </svg>
        """
        return svg
    }
}

// Renderable wrapper for ScoreKit events with calibrated layout positions.
public final class ScoreView: Renderable {
    public let events: [NotatedEvent]
    public let clef: ClefType
    public let beatsPerBar: Int
    public let beatUnit: Int
    public let staffSpacing: Double
    public let paddingTop: Double
    public let paddingLeft: Double
    public let width: Int
    public let height: Int
    public let noteRadius: Double = 4.0
    private var layoutX: [Double] = []
    private var layoutY: [Double] = []

    public init(events: [NotatedEvent], clef: ClefType = .treble, beatsPerBar: Int = 4, beatUnit: Int = 4, staffSpacing: Double = 10, paddingTop: Double = 20, paddingLeft: Double = 20, width: Int = 800, height: Int = 200) {
        self.events = events
        self.clef = clef
        self.beatsPerBar = beatsPerBar
        self.beatUnit = beatUnit
        self.staffSpacing = staffSpacing
        self.paddingTop = paddingTop
        self.paddingLeft = paddingLeft
        self.width = width
        self.height = height
        computeLayout()
    }

    // Store layout positions parallel to events
    private func computeLayout() {
        var x = paddingLeft
        var barProgress = 0.0
        layoutX = Array(repeating: 0, count: events.count)
        layoutY = Array(repeating: 0, count: events.count)
        for i in 0..<events.count {
            let e = events[i]
            switch e.base {
            case .note(let p, _):
                let y = yForPitch(p, clef: clef, originY: paddingTop, staffSpacing: staffSpacing)
                layoutX[i] = x
                layoutY[i] = y
                x += advance(for: e)
            case .rest:
                x += advance(for: e)
            }
            barProgress += beatFraction(for: e)
            if barProgress >= Double(beatsPerBar) {
                barProgress -= Double(beatsPerBar)
            }
        }
    }

    private func advance(for e: NotatedEvent) -> Double {
        switch e.base {
        case .note(_, let d), .rest(let d):
            switch d.den { case 1: return 60; case 2: return 40; case 4: return 28; case 8: return 22; case 16: return 18; default: return 20 }
        }
    }
    private func beatFraction(for e: NotatedEvent) -> Double {
        switch e.base {
        case .note(_, let d): return Double(beatUnit)/Double(max(1, d.den))
        case .rest(let d): return Double(beatUnit)/Double(max(1, d.den))
        }
    }

    public func layout() -> LayoutNode { .raw("") }

    fileprivate func pointForIndex(_ i: Int) -> (Double, Double) {
        if i < layoutX.count { return (layoutX[i], layoutY[i]) }
        return (0,0)
    }
}

// no extensions

// MARK: - Minimal staff coordinate mapping (duplicate of ScoreKitUI/Rendering/Coords.swift semantics)
extension ScoreView {
    private func diatonicIndex(_ p: Pitch) -> Int {
        let stepIndex: Int
        switch p.step {
        case .C: stepIndex = 0
        case .D: stepIndex = 1
        case .E: stepIndex = 2
        case .F: stepIndex = 3
        case .G: stepIndex = 4
        case .A: stepIndex = 5
        case .B: stepIndex = 6
        }
        return p.octave * 7 + stepIndex
    }

    private func topLineDI(for clef: ClefType) -> Int {
        switch clef {
        case .treble:
            return 38 // F5
        case .bass:
            return 26 // A3
        }
    }

    private func yForPitch(_ p: Pitch, clef: ClefType, originY: Double, staffSpacing: Double) -> Double {
        let di = diatonicIndex(p)
        let top = topLineDI(for: clef)
        let pos = top - di // diatonic steps from top line
        return originY + Double(pos) * (staffSpacing / 2.0)
    }
}
