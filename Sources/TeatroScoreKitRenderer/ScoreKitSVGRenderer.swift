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
    // Tunable layout parameters for optimization/learning.
    public struct LayoutParams: Sendable {
        public var advanceForDenom: [Int: Double]
        public var defaultAdvance: Double
        public var noteRadius: Double
        public init(advanceForDenom: [Int: Double] = [1: 60, 2: 40, 4: 28, 8: 22, 16: 18], defaultAdvance: Double = 20, noteRadius: Double = 4.0) {
            self.advanceForDenom = advanceForDenom
            self.defaultAdvance = defaultAdvance
            self.noteRadius = noteRadius
        }
    }
    public let events: [NotatedEvent]
    public let clef: ClefType
    public let beatsPerBar: Int
    public let beatUnit: Int
    public let staffSpacing: Double
    public let paddingTop: Double
    public let paddingLeft: Double
    public let width: Int
    public let height: Int
    public var noteRadius: Double { params.noteRadius }
    private var layoutX: [Double] = []
    private var layoutY: [Double] = []
    public var params: LayoutParams

    public init(events: [NotatedEvent], clef: ClefType = .treble, beatsPerBar: Int = 4, beatUnit: Int = 4, staffSpacing: Double = 10, paddingTop: Double = 20, paddingLeft: Double = 20, width: Int = 800, height: Int = 200, params: LayoutParams = .init()) {
        self.events = events
        self.clef = clef
        self.beatsPerBar = beatsPerBar
        self.beatUnit = beatUnit
        self.staffSpacing = staffSpacing
        self.paddingTop = paddingTop
        self.paddingLeft = paddingLeft
        self.width = width
        self.height = height
        self.params = params
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
                let y = ScoreKit.StaffCoords.y(for: p, clef: clef, originY: paddingTop, staffSpacing: staffSpacing)
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
            return params.advanceForDenom[d.den] ?? params.defaultAdvance
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
// Expose for same-package access by rasterizer and CLI
extension ScoreView {
    public func layoutPoint(at i: Int) -> (Double, Double) { self.pointForIndex(i) }
}

// (StaffCoords now provided by ScoreKit.core)
