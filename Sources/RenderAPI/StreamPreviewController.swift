import Foundation
import Teatro

/// Bridges incoming Universal MIDI Packet (UMP) fragments into `FountainSSEEnvelope`
/// events and exposes the reassembled token stream for preview purposes.
public actor StreamPreviewController {
    private let dispatcher = FountainSSEDispatcher()
    private let reliability = FountainSSEReliability()
    private var tokenBuffer: [String] = []

    public init() {
        // Consume dispatcher events and accumulate tokens.
        Task {
            for await env in dispatcher.events {
                await self.handle(env)
            }
        }
    }

    /// Ingest a UMP flex data fragment carrying an SSE envelope.
    public func ingestFlex(_ data: Data) async throws {
        try await dispatcher.receiveFlex(data)
    }

    /// Ingest a UMP SysEx8 fragment carrying an SSE envelope.
    public func ingestSysEx8(_ data: Data) async throws {
        try await dispatcher.receiveSysEx8(data)
    }

    private func handle(_ env: FountainSSEEnvelope) async {
        if env.ev == .message,
           let data = env.data,
           let token = String(data: data, encoding: .utf8) {
            tokenBuffer.append(token)
        } else if env.ev == .ctrl,
                  let payload = env.data,
                  let json = try? JSONSerialization.jsonObject(with: payload) as? [String: Any],
                  let ack = json["ack"] as? UInt64 {
            await self.reliability.ack(ack)
        }
        _ = await reliability.receive(env.seq)
    }

    /// Current list of received tokens in order of arrival.
    public func tokens() -> [String] {
        tokenBuffer
    }
}

#if canImport(SwiftUI) && canImport(WebKit) && os(macOS)
import SwiftUI
import TeatroRenderAPI

/// SwiftUI helper that overlays streaming diagnostics onto the `TeatroPlayerView`.
public extension StreamPreviewController {
    @MainActor
    func playerView(svg: Data, timeline: Data? = nil) -> some View {
        TeatroPlayerView(svg: svg, timeline: timeline)
            .overlay(alignment: .topLeading) {
                VStack {
                    TokenStreamView(tokens: tokenBuffer)
                    Spacer()
                    StreamStatusView()
                }
                .padding()
            }
    }
}
#endif
