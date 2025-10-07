import Foundation
import TeatroCore
import ScoreKit

// Minimal ScoreKit → SVG renderer plugin.
// Goal: provide a deterministic, calibrated coordinate space and draw staff + noteheads.
public struct ScoreKitSVGRenderer: RendererPlugin {
    public static let identifier = "scorekit-svg"
    // Do not hijack the generic SVG extension; require explicit --format scorekit-svg
    public static let fileExtensions: [String] = []

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
        for staffLineIndex in 0..<5 {
            let yPosition = Double(score.paddingTop + score.staffSpacing * Double(staffLineIndex))
            body.append("<line x1=\"\(left)\" y1=\"\(yPosition)\" x2=\"\(right)\" y2=\"\(yPosition)\" stroke=\"black\" stroke-width=\"1\"/>")
        }
        // Notes (ellipse heads + stems + optional dynamics)
        for (eventIndex, notatedEvent) in score.events.enumerated() {
            switch notatedEvent.base {
            case .note:
                let (xPosition, yPosition) = score.pointForIndex(eventIndex)
                let radiusX = score.noteRadius * 1.2
                let radiusY = score.noteRadius * 0.8
                body.append("<ellipse cx=\"\(xPosition)\" cy=\"\(yPosition)\" rx=\"\(radiusX)\" ry=\"\(radiusY)\" transform=\"rotate(-20 \(xPosition) \(yPosition))\" fill=\"black\"/>")
                // Stem
                let midY = score.paddingTop + score.staffSpacing * 2.0
                let stemUp = yPosition >= midY
                let stemLength = score.staffSpacing * 3.5
                let xStart = stemUp ? (xPosition + radiusX - 0.5) : (xPosition - radiusX + 0.5)
                let yStart = yPosition
                let xEnd = xStart
                let yEnd = stemUp ? (yPosition - stemLength) : (yPosition + stemLength)
                body.append("<line x1=\"\(xStart)\" y1=\"\(yStart)\" x2=\"\(xEnd)\" y2=\"\(yEnd)\" stroke=\"black\" stroke-width=\"1\"/>")
                if let dynamicText = score.events[eventIndex].dynamic?.rawValue {
                    let dynamicY = score.paddingTop + score.staffSpacing * 6.2
                    body.append("<text x=\"\(xPosition)\" y=\"\(dynamicY)\" font-family=\"Serif\" font-size=\"12\" text-anchor=\"middle\">\(dynamicText)</text>")
                }
            case .rest:
                continue
            }
        }
        // Bar lines across the staff
        let topY = Double(score.paddingTop) - score.staffSpacing * 0.5
        let bottomY = Double(score.paddingTop + score.staffSpacing * 4.0) + score.staffSpacing * 0.5
        for barX in score.barlines() {
            body.append("<line x1=\"\(barX)\" y1=\"\(topY)\" x2=\"\(barX)\" y2=\"\(bottomY)\" stroke=\"black\" stroke-width=\"1\"/>")
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
    private var barX: [Double] = []
    public var params: LayoutParams

    public init(
        events: [NotatedEvent],
        clef: ClefType = .treble,
        beatsPerBar: Int = 4,
        beatUnit: Int = 4,
        staffSpacing: Double = 10,
        paddingTop: Double = 20,
        paddingLeft: Double = 20,
        width: Int = 800,
        height: Int = 200,
        params: LayoutParams = .init()
    ) {
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
        var xPosition = paddingLeft
        var barProgress = 0.0
        layoutX = Array(repeating: 0, count: events.count)
        layoutY = Array(repeating: 0, count: events.count)
        barX = []
        for eventIndex in 0..<events.count {
            let event = events[eventIndex]
            switch event.base {
            case .note(let pitch, _):
                let yPosition = ScoreKit.StaffCoords.y(for: pitch, clef: clef, originY: paddingTop, staffSpacing: staffSpacing)
                layoutX[eventIndex] = xPosition
                layoutY[eventIndex] = yPosition
                xPosition += advance(for: event)
            case .rest:
                xPosition += advance(for: event)
            }
            barProgress += beatFraction(for: event)
            if barProgress >= Double(beatsPerBar) {
                barProgress -= Double(beatsPerBar)
                barX.append(xPosition)
            }
        }
    }

    private func advance(for event: NotatedEvent) -> Double {
        switch event.base {
        case .note(_, let duration), .rest(let duration):
            return params.advanceForDenom[duration.den] ?? params.defaultAdvance
        }
    }
    private func beatFraction(for event: NotatedEvent) -> Double {
        switch event.base {
        case .note(_, let duration): return Double(beatUnit)/Double(max(1, duration.den))
        case .rest(let duration): return Double(beatUnit)/Double(max(1, duration.den))
        }
    }

    public func layout() -> LayoutNode { .raw("") }

    fileprivate func pointForIndex(_ index: Int) -> (Double, Double) {
        if index < layoutX.count { return (layoutX[index], layoutY[index]) }
        return (0,0)
    }
    fileprivate func _barlines() -> [Double] { barX }
}

// no extensions
// Expose for same-package access by rasterizer and CLI
extension ScoreView {
    public func layoutPoint(at index: Int) -> (Double, Double) { self.pointForIndex(index) }
    public func barlines() -> [Double] { self._barlines() }
}

// (StaffCoords now provided by ScoreKit.core)
