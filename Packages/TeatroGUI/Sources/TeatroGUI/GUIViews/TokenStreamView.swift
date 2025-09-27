#if canImport(SwiftUI)
import SwiftUI

/// Renders a stream of SSE tokens. When `showBeatGrid` is enabled the view
/// overlays simple beat markers behind the tokens. This is intentionally
/// lightweight and serves as the foundation for richer timing alignment.
@available(macOS 13, *)
public struct TokenStreamView: View {
    /// Tokens to display in the order they were received.
    public var tokens: [String]
    /// Enables a rudimentary beat grid behind the tokens.
    public var showBeatGrid: Bool

    /// Creates a new token stream view.
    /// - Parameters:
    ///   - tokens: The textual tokens to render.
    ///   - showBeatGrid: Whether to overlay beat markers.
    public init(tokens: [String] = [], showBeatGrid: Bool = false) {
        self.tokens = tokens
        self.showBeatGrid = showBeatGrid
    }

    public var body: some View {
        SwiftUI.ZStack(alignment: .bottomLeading) {
            if showBeatGrid {
                SwiftUI.HStack(spacing: 4) {
                    SwiftUI.ForEach(tokens.indices, id: \.self) { _ in
                        SwiftUI.VStack {
                            SwiftUI.Rectangle()
                                .fill(SwiftUI.Color.gray.opacity(0.3))
                                .frame(width: 1, height: 20)
                            SwiftUI.Spacer()
                        }
                    }
                }
            }
            SwiftUI.HStack(spacing: 4) {
                SwiftUI.ForEach(Array(tokens.enumerated()), id: \.0) { _, token in
                    SwiftUI.Text(token)
                        .font(SwiftUI.Font.system(size: 12, weight: .regular, design: .monospaced))
                }
            }
        }
        .padding(4)
    }
}
#endif

