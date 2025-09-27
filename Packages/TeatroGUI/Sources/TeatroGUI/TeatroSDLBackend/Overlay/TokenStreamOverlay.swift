import Foundation

/// Placeholder for a future on-screen overlay to visualize token streams.
/// Kept separate from SwiftUI-based views to avoid UI framework coupling.
public struct TokenStreamOverlay: Sendable {
    public var recentTokens: [String] = []
    public init() {}
    public mutating func append(_ token: String) { recentTokens.append(token) }
}

