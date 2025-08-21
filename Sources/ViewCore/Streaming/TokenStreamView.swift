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
        ZStack(alignment: .bottomLeading) {
            if showBeatGrid {
                HStack(spacing: 4) {
                    ForEach(tokens.indices, id: \.self) { _ in
                        VStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 20)
                            Spacer()
                        }
                    }
                }
            }
            HStack(spacing: 4) {
                ForEach(Array(tokens.enumerated()), id: \.0) { _, token in
                    Text(token)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                }
            }
        }
        .padding(4)
    }
}
#endif

