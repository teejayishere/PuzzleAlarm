import SwiftUI
import CoreImage.CIFilterBuiltins
import PuzzleAlarmCore

enum QRCodeImage {
    static func generate(_ configuration: QRConfiguration) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(configuration.expectedPayload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage,
              let code = CIContext().createCGImage(output, from: output.extent) else { return nil }
        // Four modules of quiet zone, integer scaling, opaque white export.
        let scale = 8, border = 32
        let size = CGSize(width: code.width * scale + border * 2, height: code.height * scale + border * 2)
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(origin: .zero, size: size))
            context.cgContext.interpolationQuality = .none
            UIImage(cgImage: code).draw(in: CGRect(x: border, y: border,
                width: code.width * scale, height: code.height * scale))
        }
    }
}

struct QRCodeView: View {
    let configuration: QRConfiguration
    @State private var sharing = false
    var body: some View {
        if let image = QRCodeImage.generate(configuration) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
                .frame(maxWidth: 300).accessibilityLabel("Configured alarm QR code")
                .accessibilityIdentifier("qr.image")
            Text("Save this alarm before printing or placing its code away from your bed.")
            Button("Share QR Code") { sharing = true }.accessibilityIdentifier("qr.share")
                .sheet(isPresented: $sharing) { QRShareSheet(image: image) }
        } else { Text("QR image unavailable. Reopen this configuration to retry.") }
    }
}

private struct QRShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
