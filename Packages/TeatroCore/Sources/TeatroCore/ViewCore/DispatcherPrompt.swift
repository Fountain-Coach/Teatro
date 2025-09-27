import Foundation

typealias HorizontalAlignment = Alignment

public struct DispatcherPrompt: Renderable {
    public init() {}

    public func layout() -> LayoutNode {
        Stage(title: "Dispatcher") {
            Panel(width: 640, height: 900, cornerRadius: 12) {
                VStack(alignment: HorizontalAlignment.leading) {
                    Dot(color: "green", diameter: 10)
                    Rule()
                    Text("<content>")
                    Rule()
                    InputCursor()
                }
            }
        }.layout()
    }
}
