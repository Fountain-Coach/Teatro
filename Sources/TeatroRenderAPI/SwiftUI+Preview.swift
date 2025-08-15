#if canImport(SwiftUI) && os(macOS)
import SwiftUI
import Foundation

@available(macOS 14, *)
public struct TeatroPlayerView: View {
    private let svg: Data

    public init(svg: Data) {
        self.svg = svg
    }

    public var body: some View {
        // Stub preview view; actual SVG rendering will be implemented later.
        Text("TeatroPlayerView stub")
    }
}
#endif
