import Foundation
import Teatro
import TeatroGUI
import ScoreKit

public enum ScoreKitPreview {
    public static func attach(to controller: TeatroPreviewController, events: [NotatedEvent]) {
        var zoom: Double = 1.0
        var selected: Int = 0
        var quarterAdvance: Double = 28
        let staffSpacing0: Double = 10
        let paddingTop0: Double = 20
        let paddingLeft0: Double = 20

        var layoutX: [Double] = []
        var layoutY: [Double] = []
        var barX: [Double] = []

        func computeLayout(staffSpacing: Double, paddingTop: Double, paddingLeft: Double, beatsPerBar: Int = 4, beatUnit: Int = 4) {
            layoutX = Array(repeating: 0, count: events.count)
            layoutY = Array(repeating: 0, count: events.count)
            barX = []
            var x = paddingLeft
            var barProgress = 0.0
            for (i, e) in events.enumerated() {
                switch e.base {
                case let .note(p, _):
                    let y = StaffCoords.y(for: p, clef: .treble, originY: paddingTop, staffSpacing: staffSpacing)
                    layoutX[i] = x
                    layoutY[i] = y
                    x += quarterAdvance
                case .rest:
                    x += quarterAdvance
                }
                let frac: Double = Double(beatUnit)/4.0 // crude
                barProgress += frac
                if barProgress >= Double(beatsPerBar) {
                    barProgress -= Double(beatsPerBar)
                    barX.append(x)
                }
            }
        }

        computeLayout(staffSpacing: staffSpacing0, paddingTop: paddingTop0, paddingLeft: paddingLeft0)

        func drawScene(_ r: SDLRenderer, _ frame: Int) {
            let width = r.width
            r.clear(color: 0xFFFFFFFF)
            let staffSpacing = staffSpacing0 * zoom
            let paddingTop = paddingTop0 * zoom
            let paddingLeft = paddingLeft0 * zoom
            computeLayout(staffSpacing: staffSpacing, paddingTop: paddingTop, paddingLeft: paddingLeft)
            // Staff lines
            let left = Int(paddingLeft)
            let right = width - Int(paddingLeft)
            for i in 0..<5 {
                let y = Int(paddingTop + staffSpacing * Double(i))
                r.drawLine(x0: left, y0: y, x1: right, y1: y, color: 0x000000FF)
            }
            // Notes and stems
            for (i, ev) in events.enumerated() {
                guard case .note = ev.base else { continue }
                let x = layoutX[i]
                let y = layoutY[i]
                let rx = Int(4.8 * zoom)
                let ry = Int(3.2 * zoom)
                r.fillEllipse(cx: Int(x), cy: Int(y), rx: rx, ry: ry, color: i == selected ? 0xFF3366FF : 0x000000FF)
                let midY = paddingTop + staffSpacing * 2.0
                let stemUp = y >= midY
                let stemLen = staffSpacing * 3.5
                let x1 = stemUp ? (Int(x) + rx - 1) : (Int(x) - rx + 1)
                let y1 = Int(y)
                let y2 = stemUp ? Int(y - stemLen) : Int(y + stemLen)
                r.drawLine(x0: x1, y0: y1, x1: x1, y1: y2, color: 0x000000FF)
            }
            // Barlines
            let topY = Int(paddingTop - staffSpacing * 0.5)
            let bottomY = Int(paddingTop + staffSpacing * 4.0 + staffSpacing * 0.5)
            for bx in barX { r.drawLine(x0: Int(bx), y0: topY, x1: Int(bx), y1: bottomY, color: 0x000000FF) }
            r.present()
        }

        controller.draw = { r, frame in drawScene(r, frame) }
        controller.onEvent = { ev in
            switch ev {
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
