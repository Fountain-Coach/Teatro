# Test Coverage Gaps

| Feature | File(s) or Area | Action | Status | Blockers | Tags |
|---|---|---|---|---|---|
| loadInstrument | Sources/Audio/Samplers/CsoundSampler.swift | Add test that loads a Csound instrument file to cover line 33 | ❌ |  | Audio |
| deinit | Sources/Audio/Samplers/FluidSynthSampler.swift | Trigger sampler deallocation to cover lines 13,14,15 | ❌ |  | Audio |
| loadInstrument | Sources/Audio/Samplers/FluidSynthSampler.swift | Load a FluidSynth soundfont to cover lines 23,27,29 | ❌ |  | Audio |
| noteOff | Sources/Audio/Samplers/FluidSynthSampler.swift | Send note-off event to cover line 54 | ❌ |  | Audio |
| init | Sources/Audio/TeatroSampler.swift | Initialize sampler with audio client to cover lines 21,22,23,25,27,29,31 | ❌ |  | Audio |
| render | Sources/CLI/RenderCLI.swift | Execute CLI render with output path to cover lines 191,194,196,199,208,213 | ❌ |  | CLI |
| run | Sources/CLI/RenderCLI.swift | Run CLI without arguments to cover line 79 | ❌ |  | CLI |
| watchFile | Sources/CLI/RenderCLI.swift | Watch a file for changes to cover lines 249,268,272,282 | ❌ |  | CLI |
| encodeEvent | Sources/MIDI/UMPEncoder.swift | Encode diverse MIDI events to cover lines 51,52,56,57,61,62,66,67,71,75,79,83 | ❌ |  | MIDI |
| MidiEventType | Sources/Parsers/MidiEvents.swift | Exercise all MIDI event types to cover lines 137,151,165,179,196,214,229,244 | ❌ |  | Parsers |
| parseFile | Sources/Parsers/MidiFileParser.swift | Parse a sample MIDI file to cover lines 209,213 | ❌ |  | Parsers |
| parseHeader | Sources/Parsers/MidiFileParser.swift | Provide MIDI header bytes to cover lines 25,27 | ❌ |  | Parsers |
| parseTrack | Sources/Parsers/MidiFileParser.swift | Parse track events to cover lines 38,51,69,82,88,93,100,106,112,116,169,178,182,185,193 | ❌ |  | Parsers |
| readVariableLengthQuantity | Sources/Parsers/MidiFileParser.swift | Test variable-length quantity parsing for line 225 | ❌ |  | Parsers |
| decode | Sources/Parsers/UMPParser.swift | Decode UMP packets to cover lines 65,74,76,81,89,91,115 | ❌ |  | Parsers |
| packetLength | Sources/Parsers/UMPParser.swift | Provide various packet types to cover line 51 | ❌ |  | Parsers |
| renderToPNG | Sources/Renderers/ImageRenderer.swift | Render a simple view to PNG to cover lines 19,50 | ❌ |  | Renderers |
| canvasHeight | Sources/Renderers/SVGRenderer.swift | Supply canvas height to cover line 11 | ❌ |  | Renderers |
| canvasWidth | Sources/Renderers/SVGRenderer.swift | Supply canvas width to cover line 6 | ❌ |  | Renderers |
| isAllCaps | Sources/ViewCore/FountainParser.swift | Parse uppercase lines to cover line 274 | ❌ |  | ViewCore |
| isParenthetical | Sources/ViewCore/FountainParser.swift | Parse parenthetical tokens to cover line 300 | ❌ |  | ViewCore |
| isTransition | Sources/ViewCore/FountainParser.swift | Parse transition lines to cover lines 259,260 | ❌ |  | ViewCore |
| parse | Sources/ViewCore/FountainParser.swift | Parse a Fountain script to cover lines 122,124,127,135,140,142,145,151,167,176,185,193,195 | ❌ |  | ViewCore |
| parseInline | Sources/ViewCore/FountainParser.swift | Test inline element parsing for line 374 | ❌ |  | ViewCore |
| parse | Sources/ViewCore/Fountain.swift | Parse Fountain elements to cover lines 28,33 | ❌ |  | ViewCore |
