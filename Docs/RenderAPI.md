# Render API

`TeatroRenderAPI` exposes stable entry points for rendering text-based inputs into SVG or Markdown artifacts.

## Usage

```swift
import TeatroRenderAPI

let script = """
= Opening scene
INT. HOUSE - DAY

JOHN
Hello there.
"""
let result = try TeatroRenderer.renderScript(SimpleScriptInput(fountainText: script))
let svgData = result.svg       // SVG of the scene
let synopsis = result.markdown // "- Opening scene"
```

The API also includes helpers for storyboard UMP data and session logs. Outputs are deterministic to enable snapshot testing.

### SwiftUI Preview

`TeatroPlayerView` provides a lightweight SwiftUI view for displaying rendered SVG on macOS:

```swift
import SwiftUI
import TeatroRenderAPI

@available(macOS 13, *)
struct Preview: View {
    let svg: Data
    var body: some View {
        TeatroPlayerView(svg: svg)
    }
}
```

