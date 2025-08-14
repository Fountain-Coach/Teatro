import Foundation
import MIDI2

/// Unified representation of Universal MIDI Packets used by Teatro.
/// This facade wraps packet types from `Fountain-Coach/midi2` and provides
/// a stable surface for future integration.
public enum UMPEvent {
    case channelVoice
    case utility
    case systemExclusive7
    case systemExclusive8
    case flexEnvelope(FlexEnvelope)
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

