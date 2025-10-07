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

    private func diatonicIndex(_ p: Pitch) -> Int {
        let stepIndex: Int
        switch p.step { case .C: stepIndex = 0; case .D: stepIndex = 1; case .E: stepIndex = 2; case .F: stepIndex = 3; case .G: stepIndex = 4; case .A: stepIndex = 5; case .B: stepIndex = 6 }
        return p.octave * 7 + stepIndex
    }
    private func topLineDI() -> Int { 38 } // treble
    private func yForPitch(_ p: Pitch, originY: Double, staffSpacing: Double) -> Double {
        let pos = topLineDI() - diatonicIndex(p)
        return originY + Double(pos) * (staffSpacing / 2.0)
    }

    private func layout(size: CGSize) -> (xs: [Double], ys: [Double], bars: [Double]) {
        let paddingTop = paddingTop0 * zoom
        let paddingLeft = paddingLeft0 * zoom
        let staffSpacing = staffSpacing0 * zoom
        var xs = Array(repeating: 0.0, count: events.count)
        var ys = Array(repeating: 0.0, count: events.count)
        var bars: [Double] = []
        var x = paddingLeft
        var barProgress = 0.0
        for (i,e) in events.enumerated() {
            switch e.base {
            case let .note(p, _):
                ys[i] = yForPitch(p, originY: paddingTop, staffSpacing: staffSpacing)
                xs[i] = x
                x += 28 * zoom
            case .rest:
                xs[i] = x
                x += 28 * zoom
            }
            let frac = Double(beatUnit)/4.0
            barProgress += frac
            if barProgress >= Double(beatsPerBar) {
                barProgress -= Double(beatsPerBar)
                bars.append(x)
            }
        }
        return (xs, ys, bars)
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let (xs, ys, bars) = layout(size: size)
                let paddingTop = paddingTop0 * zoom
                let paddingLeft = paddingLeft0 * zoom
                let staffSpacing = staffSpacing0 * zoom
                // Staff lines
                let left = paddingLeft
                let right = size.width - paddingLeft
                var path = Path()
                for i in 0..<5 {
                    let y = paddingTop + staffSpacing * Double(i)
                    path.move(to: CGPoint(x: left, y: y))
                    path.addLine(to: CGPoint(x: right, y: y))
                }
                ctx.stroke(path, with: .color(.black), lineWidth: 1)

                // Notes
                for (i, ev) in events.enumerated() {
                    guard case .note = ev.base else { continue }
                    let x = xs[i]; let y = ys[i]
                    let rx = 4.8 * zoom
                    let ry = 3.2 * zoom
                    var head = Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx*2, height: ry*2))
                    // Use an explicit Double for pi to avoid ambiguity across Float/Double/CGFloat
                    let angle = CGFloat(-20.0 * Double.pi / 180.0)
                    var transform = CGAffineTransform(translationX: x, y: y)
                        .rotated(by: angle)
                        .translatedBy(x: -x, y: -y)
                    head = head.applying(transform)
                    ctx.fill(head, with: .color(i == selection ? .red : .black))
                    // Stem
                    let midY = paddingTop + staffSpacing * 2.0
                    let stemUp = y >= midY
                    let stemLen = staffSpacing * 3.5
                    let x1 = stemUp ? (x + rx - 1) : (x - rx + 1)
                    let y1 = y
                    let y2 = stemUp ? (y - stemLen) : (y + stemLen)
                    var stem = Path()
                    stem.move(to: CGPoint(x: x1, y: y1))
                    stem.addLine(to: CGPoint(x: x1, y: y2))
                    ctx.stroke(stem, with: .color(.black), lineWidth: 1)
                }

                // Barlines
                let topY = paddingTop - staffSpacing * 0.5
                let bottomY = paddingTop + staffSpacing * 4.0 + staffSpacing * 0.5
                var barsPath = Path()
                for bx in bars {
                    barsPath.move(to: CGPoint(x: bx, y: topY))
                    barsPath.addLine(to: CGPoint(x: bx, y: bottomY))
                }
                ctx.stroke(barsPath, with: .color(.black), lineWidth: 1)
            }
            .background(Color.white)
        }
    }
}
