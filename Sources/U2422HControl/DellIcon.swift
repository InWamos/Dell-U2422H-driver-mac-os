import AppKit

extension NSImage {
    /// "DELL" with the E tilted, as a template image so the menu bar tints it for light and dark mode.
    @MainActor static let dellWordmark: NSImage = {
        let attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 13, weight: .heavy)]
        let letterD = NSAttributedString(string: "D", attributes: attributes)
        let letterE = NSAttributedString(string: "E", attributes: attributes)
        let lettersLL = NSAttributedString(string: "LL", attributes: attributes)
        let gap: CGFloat = 1.5
        let height: CGFloat = 18
        let width = letterD.size().width + gap + letterE.size().width + gap + lettersLL.size().width

        let image = NSImage(size: NSSize(width: ceil(width), height: height), flipped: false) { _ in
            let baseline = (height - letterD.size().height) / 2
            letterD.draw(at: NSPoint(x: 0, y: baseline))

            let eCenterX = letterD.size().width + gap + letterE.size().width / 2
            let tilt = NSAffineTransform()
            tilt.translateX(by: eCenterX, yBy: height / 2)
            tilt.rotate(byDegrees: 30)
            NSGraphicsContext.saveGraphicsState()
            tilt.concat()
            letterE.draw(at: NSPoint(x: -letterE.size().width / 2, y: -letterE.size().height / 2))
            NSGraphicsContext.restoreGraphicsState()

            lettersLL.draw(at: NSPoint(x: width - lettersLL.size().width, y: baseline))
            return true
        }
        image.isTemplate = true
        return image
    }()
}
