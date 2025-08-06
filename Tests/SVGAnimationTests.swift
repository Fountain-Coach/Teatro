import XCTest
@testable import Teatro

final class SVGAnimationTests: XCTestCase {
    func testSVGAnimateRendersAttributes() {
        let anim = SVGAnimate(attributeName: "opacity", from: "0", to: "1", dur: 2.0, repeatCount: "indefinite")
        let rendered = anim.render()
        XCTAssertTrue(rendered.contains("<animate"))
        XCTAssertTrue(rendered.contains("attributeName=\"opacity\""))
        XCTAssertTrue(rendered.contains("repeatCount=\"indefinite\""))
    }

    func testSVGAnimateTransformRenders() {
        let anim = SVGAnimateTransform(type: "translate", from: "0 0", to: "10 10", dur: 1.5)
        let rendered = anim.render()
        XCTAssertTrue(rendered.contains("<animateTransform"))
        XCTAssertTrue(rendered.contains("type=\"translate\""))
        XCTAssertTrue(rendered.contains("dur=\"1.5s\""))
    }

    func testSVGDeltaRenderJoinsAnimations() {
        let delta = SVGDelta(id: "d", animations: ["a", "b"])
        XCTAssertEqual(delta.render(), "a\nb")
    }

    func testSVGAnimatorDiffReturnsEmpty() {
        let diff = SVGAnimator.diff(from: Text("A"), to: Text("B"))
        XCTAssertTrue(diff.isEmpty)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
