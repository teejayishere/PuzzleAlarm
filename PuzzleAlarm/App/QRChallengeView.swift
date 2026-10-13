import SwiftUI
import AVFoundation
import PuzzleAlarmCore

struct QRChallengeView: View {
    @Bindable var store: AlarmStore
    let sessionID: UUID
    @State private var controller: QRScanController
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    init(store: AlarmStore, sessionID: UUID) {
        self.store = store; self.sessionID = sessionID
        let scanner: any QRCodeScanning
        #if DEBUG
        if ProcessInfo.processInfo.environment["PUZZLE_UI_TEST"] == "1" {
            let fake = FakeQRCodeScanner()
            if let status = ProcessInfo.processInfo.environment["PUZZLE_CAMERA_STATUS"],
               let value = QRScannerStatus(rawValue: status) { fake.permission = value }
            scanner = fake
        } else { scanner = AVFoundationQRCodeScanner() }
        #else
        scanner = AVFoundationQRCodeScanner()
        #endif
        _controller = State(initialValue: QRScanController(store: store, scanner: scanner))
    }
    private var identity: ChallengeIdentity? {
        guard let record = store.session(sessionID),
              record.session.phase == .active, record.session.currentChallenge?.kind == .qr else { return nil }
        return ChallengeIdentity(sessionID: sessionID, index: record.session.currentChallengeIndex, kind: .qr)
    }
    var body: some View {
        Form {
            if let identity {
                Text("Scan the code saved for this alarm.")
                Text(controller.status.rawValue.capitalized).accessibilityIdentifier("qr.status")
                if controller.status == .authorized, let scanner = controller.scanner as? AVFoundationQRCodeScanner {
                    QRPreview(session: scanner.session).frame(height: 280)
                        .accessibilityLabel("Camera preview")
                }
                if [.denied, .restricted].contains(controller.status) {
                    Text("Camera access is required. You can allow it in Settings; the challenge stays incomplete.")
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                } else if [.unavailable, .interrupted].contains(controller.status) {
                    Text("Camera unavailable or interrupted. Retry when the camera is available.")
                }
                Button("Scan / Retry") { controller.start(identity) }
                    .disabled(store.isBusy || controller.isSubmitting || scenePhase != .active)
                    .accessibilityIdentifier("qr.start")
                #if DEBUG
                if let fake = controller.scanner as? FakeQRCodeScanner {
                    Button("Simulate wrong QR") { fake.emit(.payload("unrelated")) }
                        .accessibilityIdentifier("qr.fake.wrong")
                    Button("Simulate matching QR") {
                        if let record = store.session(sessionID), case let .qr(value) = record.session.currentChallenge {
                            fake.emit(.payload(value.expectedPayload))
                        }
                    }.accessibilityIdentifier("qr.fake.correct")
                    Button("Simulate interruption") { fake.emit(.status(.interrupted)) }
                        .accessibilityIdentifier("qr.fake.interrupt")
                }
                #endif
            } else if let record = store.session(sessionID) {
                let qrIndex = record.session.definitionSnapshot.challengeSequence.items.firstIndex { $0.kind == .qr }
                if let qrIndex, record.session.currentChallengeIndex > qrIndex {
                    Text(record.session.phase == .completed ? "Wake-up complete" : "QR complete")
                        .accessibilityIdentifier("qr.completed")
                    if record.session.phase == .active { Text("Continue with the next challenge.") }
                    else if record.session.phase != .completed { Text("Alarm cleanup is pending.") }
                } else { Text("This challenge is not active.") }
            } else { Text("Session unavailable.") }
            if !controller.feedback.isEmpty { Text(controller.feedback).accessibilityIdentifier("qr.feedback") }
            if let error = store.errorMessage { Text(error).accessibilityIdentifier("qr.error") }
        }
        .navigationTitle("QR Challenge")
        .onDisappear { controller.stop() }
        .onChange(of: scenePhase) { _, _ in controller.stop() }
        .onChange(of: identity) { _, _ in controller.stop() }
    }
}

private struct QRPreview: UIViewRepresentable {
    let session: AVCaptureSession
    final class Preview: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
    func makeUIView(context: Context) -> Preview {
        let view = Preview(); view.previewLayer.session = session; view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }
    func updateUIView(_ view: Preview, context: Context) { view.previewLayer.session = session }
    static func dismantleUIView(_ view: Preview, coordinator: ()) { view.previewLayer.session = nil }
}
