import Teatro
public enum RenderTarget: String {
    case html, svg, png, markdown, codex, svgAnimated, csound, ump
}

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
        case .csound:
            let cs = CsoundScore(orchestra: "f 1 0 0 10 1", score: "i1 0 1 0.5")
            CsoundRenderer.renderToFile(cs)
            print("Csound file written")
        case .ump:
            let notes = [MIDI2Note(channel: 0, note: 60, velocity: 0.8, duration: 1.0)]
            let packets = notes.flatMap { UMPEncoder.encode($0) }
            print(packets)
        }
    }
}
