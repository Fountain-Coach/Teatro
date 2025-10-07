import SwiftUI
import Foundation
import ScoreKit

@main
struct ScoreKitPreviewApp: App {
    @State private var events: [NotatedEvent] = []
    @State private var selection: Int = 0
    @State private var zoom: Double = 1.0

    init() {
        self._events = State(initialValue: Self.loadEvents())
    }

    var body: some Scene {
        WindowGroup("ScoreKit Preview") {
            VStack(spacing: 8) {
                ScoreCanvas(events: events, selection: $selection, zoom: $zoom)
                    .frame(minWidth: 900, minHeight: 240)
                HStack {
                    Button("Prev") { selection = max(0, selection - 1) }
                    Button("Next") { selection = min(max(0, events.count - 1), selection + 1) }
                    Spacer()
                    Text("Zoom")
                    Slider(value: $zoom, in: 0.5...2.0)
                        .frame(width: 200)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }

    static func loadEvents() -> [NotatedEvent] {
        let args = CommandLine.arguments
        if let lyIdx = args.firstIndex(of: "--ly"), lyIdx + 1 < args.count {
            let path = args[lyIdx + 1]
            if let s = try? String(contentsOfFile: path), !s.isEmpty {
                return LilyParser.parse(source: s)
            }
        }
        // Try common fixture path relative to Teatro
        let cwd = FileManager.default.currentDirectoryPath
        let guess = URL(fileURLWithPath: cwd).appendingPathComponent("../ScoreKit/Fixtures/Lily/baseline_quarters.ly").standardized
        if let s = try? String(contentsOf: guess), !s.isEmpty {
            return LilyParser.parse(source: s)
        }
        // Fallback: C-D-E-F
        return [
            .init(base: .note(pitch: .init(step: .C, alter: 0, octave: 4), duration: .init(1,4))),
            .init(base: .note(pitch: .init(step: .D, alter: 0, octave: 4), duration: .init(1,4))),
            .init(base: .note(pitch: .init(step: .E, alter: 0, octave: 4), duration: .init(1,4))),
            .init(base: .note(pitch: .init(step: .F, alter: 0, octave: 4), duration: .init(1,4)))
        ]
    }
}

struct ScoreCanvas: View {
    let events: [NotatedEvent]
    @Binding var selection: Int
    @Binding var zoom: Double

    private let paddingTop0: Double = 20
    private let paddingLeft0: Double = 20
    private let staffSpacing0: Double = 10
    private let beatsPerBar: Int = 4
    private let beatUnit: Int = 4

    private func diatonicIndex(_ pitch: Pitch) -> Int {
        let stepIndex: Int
        switch pitch.step { case .C: stepIndex = 0; case .D: stepIndex = 1; case .E: stepIndex = 2; case .F: stepIndex = 3; case .G: stepIndex = 4; case .A: stepIndex = 5; case .B: stepIndex = 6 }
        return pitch.octave * 7 + stepIndex
    }
    private func topLineDI() -> Int { 38 } // treble
    private func yForPitch(_ pitch: Pitch, originY: Double, staffSpacing: Double) -> Double {
        let stepOffset = topLineDI() - diatonicIndex(pitch)
        return originY + Double(stepOffset) * (staffSpacing / 2.0)
    }

    private func layout(size: CGSize) -> (xs: [Double], ys: [Double], bars: [Double]) {
        let paddingTop = paddingTop0 * zoom
        let paddingLeft = paddingLeft0 * zoom
        let staffSpacing = staffSpacing0 * zoom
        var xPositions = Array(repeating: 0.0, count: events.count)
        var yPositions = Array(repeating: 0.0, count: events.count)
        var barPositions: [Double] = []
        var xPosition = paddingLeft
        var barProgress = 0.0
        for (index, event) in events.enumerated() {
            switch event.base {
            case let .note(pitch, _):
                yPositions[index] = yForPitch(pitch, originY: paddingTop, staffSpacing: staffSpacing)
                xPositions[index] = xPosition
                xPosition += 28 * zoom
            case .rest:
                xPositions[index] = xPosition
                xPosition += 28 * zoom
            }
            let frac = Double(beatUnit)/4.0
            barProgress += frac
            if barProgress >= Double(beatsPerBar) {
                barProgress -= Double(beatsPerBar)
                barPositions.append(xPosition)
            }
        }
        return (xPositions, yPositions, barPositions)
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let (xPositions, yPositions, barPositions) = layout(size: size)
                let paddingTop = paddingTop0 * zoom
                let paddingLeft = paddingLeft0 * zoom
                let staffSpacing = staffSpacing0 * zoom
                // Staff lines
                let left = paddingLeft
                let right = size.width - paddingLeft
                var path = Path()
                for staffLineIndex in 0..<5 {
                    let yPosition = paddingTop + staffSpacing * Double(staffLineIndex)
                    path.move(to: CGPoint(x: left, y: yPosition))
                    path.addLine(to: CGPoint(x: right, y: yPosition))
                }
                ctx.stroke(path, with: .color(.black), lineWidth: 1)

                // Notes
                for (index, notatedEvent) in events.enumerated() {
                    guard case .note = notatedEvent.base else { continue }
                    let xPosition = xPositions[index]; let yPosition = yPositions[index]
                    let radiusX = 4.8 * zoom
                    let radiusY = 3.2 * zoom
                    var head = Path(ellipseIn: CGRect(x: xPosition - radiusX, y: yPosition - radiusY, width: radiusX*2, height: radiusY*2))
                    // Use an explicit Double for pi to avoid ambiguity across Float/Double/CGFloat
                    let angle = CGFloat(-20.0 * Double.pi / 180.0)
                    var transform = CGAffineTransform(translationX: xPosition, y: yPosition)
                        .rotated(by: angle)
                        .translatedBy(x: -xPosition, y: -yPosition)
                    head = head.applying(transform)
                    ctx.fill(head, with: .color(index == selection ? .red : .black))
                    // Stem
                    let midY = paddingTop + staffSpacing * 2.0
                    let stemUp = yPosition >= midY
                    let stemLen = staffSpacing * 3.5
                    let xStart = stemUp ? (xPosition + radiusX - 1) : (xPosition - radiusX + 1)
                    let yStart = yPosition
                    let yEnd = stemUp ? (yPosition - stemLen) : (yPosition + stemLen)
                    var stem = Path()
                    stem.move(to: CGPoint(x: xStart, y: yStart))
                    stem.addLine(to: CGPoint(x: xStart, y: yEnd))
                    ctx.stroke(stem, with: .color(.black), lineWidth: 1)
                }

                // Barlines
                let topY = paddingTop - staffSpacing * 0.5
                let bottomY = paddingTop + staffSpacing * 4.0 + staffSpacing * 0.5
                var barsPath = Path()
                for barX in barPositions {
                    barsPath.move(to: CGPoint(x: barX, y: topY))
                    barsPath.addLine(to: CGPoint(x: barX, y: bottomY))
                }
                ctx.stroke(barsPath, with: .color(.black), lineWidth: 1)
            }
            .background(Color.white)
        }
    }
}
