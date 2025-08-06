import XCTest
@testable import Teatro

final class RendererTests: XCTestCase {
    func testHTMLRenderer() {
        let text = Text("Hi")
        let html = HTMLRenderer.render(text)
        XCTAssertTrue(html.contains("<pre>\nHi\n</pre>"))
    }

    func testSVGRenderer() {
        let text = Text("Hi")
        let svg = SVGRenderer.render(text)
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("Hi"))
    }

    func testMarkdownRenderer() {
        let text = Text("Hi")
        let md = MarkdownRenderer.render(text)
        XCTAssertTrue(md.contains("```"))
        XCTAssertTrue(md.contains("Hi"))
    }

    func testAnimatedSVGRenderer() {
        let sb = Storyboard {
            Scene("One") { Text("A") }
            Transition(style: .crossfade, frames: 1)
            Scene("Two") { Text("B") }
        }

        let svg = SVGAnimator.renderAnimatedSVG(storyboard: sb)

        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("scene0"))
        XCTAssertTrue(svg.contains("begin=\"0s\""))
        XCTAssertTrue(svg.contains("begin=\"1s\""))
    }

    func testSVGAnimatedStoryboardProducesExpectedOutput() {
        let storyboard = Storyboard {
            Scene("Intro") {
                VStack(alignment: .center) {
                    Text("Hello")
                }
            }
            Transition(style: .crossfade, frames: 10)
            Scene("End") {
                VStack {
                    Text("Goodbye")
                }
            }
        }

        let svg = SVGAnimator.renderAnimatedSVG(storyboard: storyboard)

        XCTAssertTrue(svg.contains("<svg"), "Output should contain <svg> root element")
        XCTAssertTrue(svg.contains("<g id=\"scene0\""), "First scene should have ID scene0")
        XCTAssertTrue(svg.contains("<g id=\"scene1\""), "Second scene should have ID scene1")
        XCTAssertTrue(svg.contains("attributeName=\"opacity\""), "Should include opacity animations")
        XCTAssertTrue(svg.contains("begin=\"0s\""), "First scene should begin at 0s")
        XCTAssertTrue(svg.contains("begin=\"1s\""), "Fade out or second scene should begin at 1s")
    }

    func testImageRendererDimensionEnvironmentOverrides() {
        setenv("TEATRO_IMAGE_WIDTH", "1024", 1)
        setenv("TEATRO_IMAGE_HEIGHT", "768", 1)
        XCTAssertEqual(ImageRenderer.width, 1024)
        XCTAssertEqual(ImageRenderer.height, 768)
        unsetenv("TEATRO_IMAGE_WIDTH")
        unsetenv("TEATRO_IMAGE_HEIGHT")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
