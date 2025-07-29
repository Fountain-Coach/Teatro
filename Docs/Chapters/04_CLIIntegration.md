## 4. CLI Integration

The Teatro View Engine includes a lightweight command-line interface (CLI) implementation for rendering any `Renderable` to a chosen output format. This enables scripting, automation, or integration with external developer tools.

---

### RenderCLI

```swift
public enum RenderTarget: String {
    case html, svg, png, markdown, codex, svgAnimated
}
```

This enum defines supported output formats.

```swift
public struct RenderCLI {
    public static func main(args: [String]) {
        let view = Stage(title: "CLI Demo") {
            VStack(alignment: .center, padding: 2) {
                TeatroIcon("🎭")
                Text("CLI Renderer", style: .bold)
            }
        }

        let target = RenderTarget(rawValue: args.first ?? "codex") ?? .codex

        switch target {
        case .html:
            print(HTMLRenderer.render(view))
        case .svg:
            print(SVGRenderer.render(view))
        case .png:
            ImageRenderer.renderToPNG(view)
        case .markdown:
            print(MarkdownRenderer.render(view))
        case .codex:
            print(CodexPreviewer.preview(view))
        case .svgAnimated:
            let storyboard = Storyboard {
                Scene("One") {
                    VStack(alignment: .center) {
                        Text("Teatro", style: .bold)
                        Text("SVG Animation Demo")
                    }
                }
                Transition(style: .crossfade, frames: 10)
                Scene("Two") {
                    VStack(alignment: .center) {
                        Text("Scene Two")
                    }
                }
            }

            print(SVGAnimator.renderAnimatedSVG(storyboard: storyboard))
        }
    }
}
```

---

### Usage

```bash
swift run RenderCLI html
swift run RenderCLI svg
swift run RenderCLI svgAnimated
swift run RenderCLI png
swift run RenderCLI markdown
swift run RenderCLI codex
```

If no argument is provided, the CLI defaults to the `codex` renderer.

The output width and height can be adjusted through environment variables:
`TEATRO_SVG_WIDTH`, `TEATRO_SVG_HEIGHT`, `TEATRO_IMAGE_WIDTH`, and `TEATRO_IMAGE_HEIGHT`.

The `svg-animated` target converts a multi-scene `Storyboard` into a single
animated `.svg` file. This differs from `svg` (static) and `png` (individual
frame images) by embedding `<animate>` elements directly in the output.

This CLI is ideal for:
- Previewing scenes, tests, or examples from terminal
- Connecting renderable output to other tools (e.g., orchestration logs, build pipelines)
- Rendering `.fountain`, `.mid`, or `.ly` views via CLI with extended routing


```
© 2025 Contexter alias Benedikt Eickhoff, https://fountain.coach. All rights reserved.
Unauthorized copying or distribution is strictly prohibited.
```



``````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
``````
