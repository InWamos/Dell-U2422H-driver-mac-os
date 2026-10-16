import AppKit

extension NSImage {
    /// "DELL" with the E tilted, as a template image so the menu bar tints it for light and dark mode.
    @MainActor static let dellWordmark: NSImage = {
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .heavy)]
        let d = NSAttributedString(string: "D", attributes: attributes)
        let e = NSAttributedString(string: "E", attributes: attributes)
        let ll = NSAttributedString(string: "LL", attributes: attributes)
        let tiltGap: CGFloat = 1.5
        let width = d.size().width + tiltGap + e.size().width + tiltGap + ll.size().width
        let height: CGFloat = 18

        let image = NSImage(size: NSSize(width: ceil(width), height: height), flipped: false) { _ in
            let baselineY = (height - d.size().height) / 2
            var x: CGFloat = 0
            d.draw(at: NSPoint(x: x, y: baselineY))
            x += d.size().width + tiltGap

            let eCenter = NSPoint(x: x + e.size().width / 2, y: height / 2)
            let tilt = NSAffineTransform()
            tilt.translateX(by: eCenter.x, yBy: eCenter.y)
            tilt.rotate(byDegrees: 30)
            NSGraphicsContext.saveGraphicsState()
            tilt.concat()
            e.draw(at: NSPoint(x: -e.size().width / 2, y: -e.size().height / 2))
            NSGraphicsContext.restoreGraphicsState()
            x += e.size().width + tiltGap

            ll.draw(at: NSPoint(x: x, y: baselineY))
            return true
        }
        image.isTemplate = true
        return image
    }()
}
