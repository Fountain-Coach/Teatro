#if canImport(SwiftUI) && canImport(WebKit) && os(macOS)
import SwiftUI
import WebKit
import Foundation
import Teatro

/// SwiftUI based preview player that shows an SVG and overlays streaming
/// diagnostics. It also exposes simple record and replay controls to prepare
/// for future wiring of MIDI/SSE streams.
@available(macOS 13, *)
public struct TeatroPlayerView: View {
    private let svg: Data
    private let timeline: Data?

    @State private var isRecording = false
    @State private var isReplaying = false

    public init(svg: Data, timeline: Data? = nil) {
        self.svg = svg
        self.timeline = timeline
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            SVGWebView(svg: svg, timeline: timeline)

            // Token output and stream status overlays.
            VStack {
                TokenStreamView()
                Spacer()
                StreamStatusView()
            }
            .padding()

            // Record / replay controls placed at the bottom-right.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Button(isRecording ? "Stop" : "Record") {
                            isRecording.toggle()
                        }
                        Button(isReplaying ? "Stop" : "Replay") {
                            isReplaying.toggle()
                        }
                    }
                    .font(.caption)
                    .padding(6)
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding()
        }
    }
}

/// Internal `NSViewRepresentable` wrapper around `WKWebView` that renders the
/// provided SVG data. Separated so the higher level `TeatroPlayerView` can be a
/// pure SwiftUI container with overlays.
@available(macOS 13, *)
private struct SVGWebView: NSViewRepresentable {
    let svg: Data
    let timeline: Data?

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        loadSVG(into: webView)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        loadSVG(into: nsView)
    }

    private func loadSVG(into webView: WKWebView) {
        webView.load(
            svg,
            mimeType: "image/svg+xml",
            characterEncodingName: "utf-8",
            baseURL: URL(fileURLWithPath: "/")
        )
    }
}
#endif

