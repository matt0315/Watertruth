import UIKit
import SwiftUI

/// Composes watermarked before/after (or single) share images for the system share sheet.
/// Watermark is applied ONLY on export — never on in-app photos.
enum ShareCardService {
    static let tagline = "Check Soil. Water Smarter."

    /// Build a shareable card. Prefer before+after side-by-side; falls back to a single photo.
    static func makeShareImage(
        before: UIImage?,
        after: UIImage?,
        plantName: String
    ) -> UIImage? {
        if let before, let after {
            return composeSideBySide(before: before, after: after, plantName: plantName)
        }
        if let single = after ?? before {
            return composeSingle(single, plantName: plantName)
        }
        return nil
    }

    // MARK: - Composition

    private static func composeSideBySide(before: UIImage, after: UIImage, plantName: String) -> UIImage {
        let panelW: CGFloat = 540
        let panelH: CGFloat = 720
        let gap: CGFloat = 16
        let headerH: CGFloat = 72
        let footerH: CGFloat = 56
        let canvasW = panelW * 2 + gap + 48
        let canvasH = headerH + panelH + footerH + 48

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: canvasW, height: canvasH), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1).setFill()
            cg.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))

            let title = plantName as NSString
            title.draw(at: CGPoint(x: 24, y: 22), withAttributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: UIColor(red: 0.18, green: 0.20, blue: 0.18, alpha: 1)
            ])

            let subtitle = "Progress — your judgment" as NSString
            subtitle.draw(at: CGPoint(x: 24, y: 52), withAttributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor(red: 0.45, green: 0.48, blue: 0.45, alpha: 1)
            ])

            let beforeRect = CGRect(x: 24, y: headerH + 8, width: panelW, height: panelH)
            let afterRect = CGRect(x: 24 + panelW + gap, y: headerH + 8, width: panelW, height: panelH)
            drawFitted(before, in: beforeRect, corner: 16, context: cg)
            drawFitted(after, in: afterRect, corner: 16, context: cg)

            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.white
            ]
            drawCaption("Before", in: CGRect(x: beforeRect.minX + 12, y: beforeRect.maxY - 36, width: 100, height: 24), attrs: labelAttrs)
            drawCaption("After", in: CGRect(x: afterRect.minX + 12, y: afterRect.maxY - 36, width: 100, height: 24), attrs: labelAttrs)

            drawWatermark(in: CGRect(x: 24, y: canvasH - footerH - 8, width: canvasW - 48, height: footerH))
        }
    }

    private static func composeSingle(_ image: UIImage, plantName: String) -> UIImage {
        let canvasW: CGFloat = 1080
        let canvasH: CGFloat = 1350
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: canvasW, height: canvasH), format: format)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            UIColor(red: 0.96, green: 0.95, blue: 0.92, alpha: 1).setFill()
            cg.fill(CGRect(x: 0, y: 0, width: canvasW, height: canvasH))

            let photoRect = CGRect(x: 40, y: 80, width: canvasW - 80, height: canvasH - 200)
            drawFitted(image, in: photoRect, corner: 20, context: cg)

            let title = plantName as NSString
            title.draw(at: CGPoint(x: 48, y: 28), withAttributes: [
                .font: UIFont.systemFont(ofSize: 26, weight: .semibold),
                .foregroundColor: UIColor(red: 0.18, green: 0.20, blue: 0.18, alpha: 1)
            ])

            drawWatermark(in: CGRect(x: 40, y: canvasH - 100, width: canvasW - 80, height: 72))
        }
    }

    private static func drawFitted(_ image: UIImage, in rect: CGRect, corner: CGFloat, context: CGContext) {
        context.saveGState()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: corner)
        path.addClip()
        let scale = max(rect.width / max(image.size.width, 1), rect.height / max(image.size.height, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let origin = CGPoint(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2
        )
        image.draw(in: CGRect(origin: origin, size: size))
        context.restoreGState()
    }

    private static func drawCaption(_ text: String, in rect: CGRect, attrs: [NSAttributedString.Key: Any]) {
        let bg = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        UIColor.black.withAlphaComponent(0.45).setFill()
        bg.fill()
        (text as NSString).draw(in: rect.insetBy(dx: 8, dy: 4), withAttributes: attrs)
    }

    /// Soft watermark bottom-leading. Uses HonestLeaf asset if present; otherwise text.
    static func drawWatermark(in rect: CGRect) {
        let honestLeaf = UIImage(named: "HonestLeaf") ?? UIImage(named: "Honest Leaf")
        if let leaf = honestLeaf {
            let size: CGFloat = 28
            let imgRect = CGRect(x: rect.minX, y: rect.midY - size / 2, width: size, height: size)
            leaf.draw(in: imgRect, blendMode: .normal, alpha: 0.55)
            drawWatermarkText(at: CGPoint(x: imgRect.maxX + 10, y: rect.midY - 18))
        } else {
            drawWatermarkText(at: CGPoint(x: rect.minX, y: rect.midY - 18))
        }
    }

    private static func drawWatermarkText(at point: CGPoint) {
        ("Watertruth" as NSString).draw(at: point, withAttributes: [
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: UIColor(red: 0.35, green: 0.55, blue: 0.40, alpha: 0.65)
        ])
        (tagline as NSString).draw(at: CGPoint(x: point.x, y: point.y + 20), withAttributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor(red: 0.45, green: 0.48, blue: 0.45, alpha: 0.55)
        ])
    }

    /// JPEG-compress for SwiftData storage (cover / care photos).
    static func compressedJPEG(from data: Data, maxDimension: CGFloat = 1600, quality: CGFloat = 0.72) -> Data? {
        guard let image = UIImage(data: data) else { return data }
        return compressedJPEG(from: image, maxDimension: maxDimension, quality: quality)
    }

    static func compressedJPEG(from image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.72) -> Data? {
        let size = image.size
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
