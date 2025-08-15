#if canImport(SwiftUI) && canImport(WebKit) && os(macOS)
import SwiftUI
import WebKit
import Foundation

/// Minimal SwiftUI view that previews an SVG document (and future timeline data).
///
/// This hook is intentionally lightweight so downstream macOS apps can embed
/// Teatro's renderer without depending on the full engine. Timeline playback
/// will be wired up in subsequent iterations.
@available(macOS 13, *)
public struct TeatroPlayerView: NSViewRepresentable {
    private let svg: Data
    private let timeline: Data?

    /// Creates a preview view for the provided SVG data.
    /// - Parameters:
    ///   - svg: Rendered SVG bytes to display.
    ///   - timeline: Optional timeline data for future animation support.
    public init(svg: Data, timeline: Data? = nil) {
        self.svg = svg
        self.timeline = timeline
    }

    public func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        loadSVG(into: webView)
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        loadSVG(into: nsView)
    }

    private func loadSVG(into webView: WKWebView) {
        // Use a blank base URL to allow relative references if any.
        webView.load(svg,
                     mimeType: "image/svg+xml",
                     characterEncodingName: "utf-8",
                     baseURL: URL(fileURLWithPath: "/"))
    }
}
#endif
