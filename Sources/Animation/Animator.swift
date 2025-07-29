import Foundation

@MainActor
public struct Animator {
    public static func renderFrames(_ frames: [Renderable], baseName: String = "frame") {
        for (i, frame) in frames.enumerated() {
            let path = "Animations/\(baseName)_\(i).png"
            ImageRenderer.renderToPNG(frame, to: path)
        }
    }
}
