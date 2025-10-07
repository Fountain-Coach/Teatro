import Foundation
import Teatro
import TeatroGUI
import ScoreKit

// swiftlint:disable function_body_length
public enum ScoreKitPreview {
    public static func attach(to controller: TeatroPreviewController, events: [NotatedEvent]) {
        var zoom: Double = 1.0
        var selected: Int = 0
        var quarterAdvance: Double = 28
        let staffSpacing0: Double = 10
        let paddingTop0: Double = 20
        let paddingLeft0: Double = 20

        var layoutXPositions: [Double] = []
        var layoutYPositions: [Double] = []
        var barXPositions: [Double] = []

        func diatonicIndex(_ pitch: Pitch) -> Int {
            let stepIndex: Int
            switch pitch.step {
            case .C: stepIndex = 0
            case .D: stepIndex = 1
            case .E: stepIndex = 2
            case .F: stepIndex = 3
            case .G: stepIndex = 4
            case .A: stepIndex = 5
            case .B: stepIndex = 6
            }
            return pitch.octave * 7 + stepIndex
        }
        func topLineDI(for clef: ClefType) -> Int { clef == .treble ? 38 : 26 }
        func yForPitch(_ pitch: Pitch, clef: ClefType, originY: Double, staffSpacing: Double) -> Double {
            let diatonic = diatonicIndex(pitch)
            let topIndex = topLineDI(for: clef)
            let stepOffset = topIndex - diatonic
            return originY + Double(stepOffset) * (staffSpacing / 2.0)
        }

        func computeLayout(staffSpacing: Double, paddingTop: Double, paddingLeft: Double, beatsPerBar: Int = 4, beatUnit: Int = 4) {
            layoutXPositions = Array(repeating: 0, count: events.count)
            layoutYPositions = Array(repeating: 0, count: events.count)
            barXPositions = []
            var xPosition = paddingLeft
            var barProgress = 0.0
            for (index, event) in events.enumerated() {
                switch event.base {
                case let .note(pitch, _):
                    let yPosition = yForPitch(pitch, clef: ClefType.treble, originY: paddingTop, staffSpacing: staffSpacing)
                    layoutXPositions[index] = xPosition
                    layoutYPositions[index] = yPosition
                    xPosition += quarterAdvance
                case .rest:
                    xPosition += quarterAdvance
                }
                let frac: Double = Double(beatUnit)/4.0 // crude
                barProgress += frac
                if barProgress >= Double(beatsPerBar) {
                    barProgress -= Double(beatsPerBar)
                    barXPositions.append(xPosition)
                }
            }
        }

        computeLayout(staffSpacing: staffSpacing0, paddingTop: paddingTop0, paddingLeft: paddingLeft0)

        func drawScene(_ renderer: SDLRenderer, _ frame: Int) {
            let width = renderer.width
            renderer.clear(color: 0xFFFFFFFF)
            let staffSpacing = staffSpacing0 * zoom
            let paddingTop = paddingTop0 * zoom
            let paddingLeft = paddingLeft0 * zoom
            computeLayout(staffSpacing: staffSpacing, paddingTop: paddingTop, paddingLeft: paddingLeft)
            // Staff lines
            let left = Int(paddingLeft)
            let right = width - Int(paddingLeft)
            for lineIndex in 0..<5 {
                let yPosition = Int(paddingTop + staffSpacing * Double(lineIndex))
                renderer.drawLine(x0: left, y0: yPosition, x1: right, y1: yPosition, color: 0x000000FF)
            }
            // Notes and stems
            for (index, event) in events.enumerated() {
                guard case .note = event.base else { continue }
                let xPosition = layoutXPositions[index]
                let yPosition = layoutYPositions[index]
                let radiusX = Int(4.8 * zoom)
                let radiusY = Int(3.2 * zoom)
                renderer.fillEllipse(cx: Int(xPosition), cy: Int(yPosition), rx: radiusX, ry: radiusY, color: index == selected ? 0xFF3366FF : 0x000000FF)
                let midY = paddingTop + staffSpacing * 2.0
                let stemUp = yPosition >= midY
                let stemLength = staffSpacing * 3.5
                let xStart = stemUp ? (Int(xPosition) + radiusX - 1) : (Int(xPosition) - radiusX + 1)
                let yStart = Int(yPosition)
                let yEnd = stemUp ? Int(yPosition - stemLength) : Int(yPosition + stemLength)
                renderer.drawLine(x0: xStart, y0: yStart, x1: xStart, y1: yEnd, color: 0x000000FF)
            }
            // Barlines
            let topY = Int(paddingTop - staffSpacing * 0.5)
            let bottomY = Int(paddingTop + staffSpacing * 4.0 + staffSpacing * 0.5)
            for barXPosition in barXPositions { renderer.drawLine(x0: Int(barXPosition), y0: topY, x1: Int(barXPosition), y1: bottomY, color: 0x000000FF) }
            renderer.present()
        }

        controller.draw = { renderer, frame in drawScene(renderer, frame) }
        controller.onEvent = { event in
            switch event {
            case let .keyDown(keyCode: code):
                switch code {
                case 37: // Left
                    selected = max(0, selected - 1)
                case 39: // Right
                    selected = min(max(0, events.count - 1), selected + 1)
                case 187: // '+' zoom in
                    zoom = min(2.0, zoom + 0.1)
                case 189: // '-' zoom out
                    zoom = max(0.5, zoom - 0.1)
                default:
                    break
                }
            default:
                break
            }
        }
    }
}
// swiftlint:enable function_body_length
