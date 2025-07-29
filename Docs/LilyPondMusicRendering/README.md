## 6. LilyPond Music Rendering

The Teatro View Engine supports musical score composition and PDF rendering using the LilyPond typesetting system. This allows GPT or Codex agents to declaratively construct musical ideas and export them as print-ready sheet music.

---

### 6.1 LilyScore

```swift
import Foundation

public struct LilyScore: Renderable {
    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public func render() -> String {
        content
    }

    public func renderToPDF(filename: String = "score") {
        let tempPath = "/tmp/\(filename).ly"
        try? content.write(toFile: tempPath, atomically: true, encoding: .utf8)

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["lilypond", "-o", filename, tempPath]
        try? task.run()
        task.waitUntilExit()
    }
}
```

---

### Example

```swift
let score = LilyScore("""
\\version "2.24.2"
\\relative c' {
  c4 d e f | g a b c
}
""")

score.renderToPDF(filename: "teatro_theme")
```

This will produce:
```
teatro_theme.pdf
teatro_theme.ps
```

---

### Integration Points

- `LilyScore` is fully compatible with `Stage` or `Animator`
- Codex can generate LilyPond DSL fragments and immediately preview them
- This renderer can be used to seed training prompts or music composition environments
- LilyPond-generated files are suitable for formal printing, digital annotation, or score playback

---

### Notes

- LilyPond must be installed on the system (`lilypond` must be on `$PATH`)
- If needed, Codex can be prompted to emit safe `.ly` fragments
- Combine with GPT output templates to embed titles, composer metadata, lyrics, and spacing settings


```
© 2025 Contexter alias Benedikt Eickhoff, https://fountain.coach. All rights reserved.
Unauthorized copying or distribution is strictly prohibited.
```
