## 12. SSE over MIDI 2.0

_Streaming server‑sent events with MIDI 2.0 Flex Data and SysEx8._

### Overview

Teatro can consume Server‑Sent Events (SSE) that are transported inside Universal MIDI Packets (UMP). Small envelopes travel in **Flex Data** packets while larger payloads use **SysEx8**. Each envelope follows the FountainAI JSON schema and maps directly onto UMP groups.

See `assets/sse-demo.ump` for a minimal capture.

### Envelope Model

`FountainSSEEnvelope` stores the payload in a `Data` field. This avoids extra string copies when reassembling large envelopes. The field encodes as UTF-8 text in the on-wire JSON or CBOR representation.

### Timing

Every SSE envelope may carry a JR Timestamp. The player aligns frames using that timestamp and a small jitter buffer so live streams remain beat‑synchronized even across RTP‑MIDI links. Wired LAN profiles default this buffer to approximately 3 ms to balance stability and latency.

### Reliability

Streams negotiate a lightweight window with MIDI‑CI property exchange and acknowledge received envelopes. A retransmit buffer and NACK tracking close short gaps without stalling the pipeline.

### GUI

`TeatroPlayerView` surfaces stream status overlays for group activity, RTT estimates, and retransmission counts. Tokens emitted by the stream appear in dedicated subviews that scroll in time with the score.

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
