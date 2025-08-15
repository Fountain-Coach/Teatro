import XCTest
@testable import TeatroRenderAPI

final class StoryboardRenderingTests: XCTestCase {
    func testRenderStoryboardDSLProducesSVG() throws {
        let dsl = """
        Scene: Start
        Text: Hello
        """
        let input = SimpleStoryboardInput(storyboardDSL: dsl)
        let result = try TeatroRenderer.renderStoryboard(input)
        let svgString = String(data: try XCTUnwrap(result.svg), encoding: .utf8)
        XCTAssertNotNil(svgString)
        XCTAssertTrue(svgString?.contains("<svg") ?? false)
        XCTAssertNil(result.ump)
    }

    func testRenderStoryboardUMPProducesNormalizedOutput() throws {
        let words: [UInt32] = [0x40903C00, 0x7FFF0000]
        var bytes: [UInt8] = []
        for w in words {
            bytes.append(UInt8((w >> 24) & 0xFF))
            bytes.append(UInt8((w >> 16) & 0xFF))
            bytes.append(UInt8((w >> 8) & 0xFF))
            bytes.append(UInt8(w & 0xFF))
        }
        let data = Data(bytes)
        let input = SimpleStoryboardInput(umpData: data)
        let result = try TeatroRenderer.renderStoryboard(input)
        XCTAssertEqual(result.ump, data)
        let svgString = String(data: try XCTUnwrap(result.svg), encoding: .utf8)
        XCTAssertTrue(svgString?.contains("<svg") ?? false)
    }
}
