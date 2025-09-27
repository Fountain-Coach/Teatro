#if canImport(SwiftUI)
import SwiftUI

/// Visualizes basic stream metrics such as connection state, ACK/NACK counters
/// and latency. These values are placeholders for now but provide the
/// foundation for wiring real telemetry later on.
@available(macOS 13, *)
public struct StreamStatusView: View {
    public var connected: Bool
    public var acks: Int
    public var nacks: Int
    public var rtt: Double
    public var window: Int
    public var loss: Double

    public init(
        connected: Bool = false,
        acks: Int = 0,
        nacks: Int = 0,
        rtt: Double = 0,
        window: Int = 0,
        loss: Double = 0
    ) {
        self.connected = connected
        self.acks = acks
        self.nacks = nacks
        self.rtt = rtt
        self.window = window
        self.loss = loss
    }

    public var body: some View {
        SwiftUI.HStack(spacing: 8) {
            SwiftUI.Circle()
                .fill(connected ? SwiftUI.Color.green : SwiftUI.Color.red)
                .frame(width: 10, height: 10)
            SwiftUI.Text("ACK \(acks)")
            SwiftUI.Text("NACK \(nacks)")
            SwiftUI.Text(String(format: "RTT %.0fms", rtt))
            SwiftUI.Text("WIN \(window)")
            SwiftUI.Text(String(format: "LOSS %.1f%%", loss))
        }
        .font(SwiftUI.Font.caption.monospaced())
        .padding(4)
        .background(SwiftUI.Color.black.opacity(0.1))
        .cornerRadius(4)
    }
}
#endif

