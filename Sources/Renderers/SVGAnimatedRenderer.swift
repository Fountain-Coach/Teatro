import Foundation

public struct SVGAnimatedRenderer: RendererPlugin {
    public static let identifier = "svgAnimated"
    public static let fileExtensions: [String] = []

    public static func render(view: Renderable, output: String?) throws {
        guard let storyboard = view as? Storyboard else { throw RendererError.unsupportedInput("Animated SVG requires a Storyboard input") }
        let result = SVGAnimator.renderAnimatedSVG(storyboard: storyboard)
        try write(result, to: output, defaultName: "output.svg")
    }
}
