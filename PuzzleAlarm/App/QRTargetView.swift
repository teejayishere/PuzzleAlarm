import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRTargetView: View {
    let payload: String

    var body: some View {
        VStack(spacing: 12) {
            if let rendered = renderedImage {
                let image = Image(uiImage: rendered)
                image.resizable().interpolation(.none).scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .accessibilityLabel("QR code for this alarm")
                ShareLink(item: image, preview: SharePreview("PuzzleAlarm QR", image: image)) {
                    Label("Share QR code", systemImage: "square.and.arrow.up")
                }
            } else {
                Text("The QR code could not be generated.")
            }
            Text("Save or print this code and put it where you must get up to scan it.")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var renderedImage: UIImage? {
        guard !payload.isEmpty, payload.utf8.count <= 2_048 else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let code = filter.outputImage else { return nil }
        // Include a four-module white quiet zone in the shared image itself.
        let background = CIImage(color: .white).cropped(to: code.extent.insetBy(dx: -4, dy: -4))
        let bordered = code.composited(over: background)
            .transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let image = CIContext().createCGImage(bordered, from: bordered.extent) else { return nil }
        return UIImage(cgImage: image)
    }
}
