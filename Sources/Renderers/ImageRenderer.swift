#if canImport(Cairo)
import Cairo
#endif

import Foundation

public struct ImageRenderer: RendererPlugin {
    public static let identifier = "png"
    public static let fileExtensions = ["png"]
    // Default image width in points. Override with `TEATRO_IMAGE_WIDTH`.
    static var width: Int {
        Int(ProcessInfo.processInfo.environment["TEATRO_IMAGE_WIDTH"] ?? "800") ?? 800
    }

    // Default image height in points. Override with `TEATRO_IMAGE_HEIGHT`.
    static var height: Int {
        Int(ProcessInfo.processInfo.environment["TEATRO_IMAGE_HEIGHT"] ?? "600") ?? 600
    }

    public static func renderToPNG(_ view: Renderable, to path: String = "output.png") {
#if canImport(Cairo)
        let surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, Int32(width), Int32(height))
        let cr = cairo_create(surface)

        cairo_set_source_rgb(cr, 1, 1, 1)
        cairo_paint(cr)

        cairo_set_source_rgb(cr, 0, 0, 0)
        cairo_select_font_face(cr, "monospace", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)
        cairo_set_font_size(cr, 16)

        let lines = view.render().components(separatedBy: "\n")
        for (i, line) in lines.enumerated() {
            cairo_move_to(cr, 10, Double(30 + i * 20))
            cairo_show_text(cr, line)
        }

        cairo_surface_write_to_png(surface, path)
        cairo_destroy(cr)
        cairo_surface_destroy(surface)
#else
        // Fallback when Cairo is unavailable: generate an SVG next to the desired PNG path.
        let requestedURL = URL(fileURLWithPath: path)
        let svgURL: URL
        if requestedURL.pathExtension.lowercased() == "png" {
            svgURL = requestedURL.deletingPathExtension().appendingPathExtension("svg")
        } else {
            svgURL = requestedURL
        }
        let svg = SVGRenderer.render(view)
        try? svg.write(toFile: svgURL.path, atomically: true, encoding: .utf8)
#endif
    }

    public static func render(view: Renderable, output: String?) throws {
        let path = output ?? "output.png"
        renderToPNG(view, to: path)
        if output != nil {
            print("Wrote \(path)")
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
