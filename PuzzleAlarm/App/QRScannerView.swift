import AVFoundation
import SwiftUI
import UIKit

struct QRScannerView: UIViewControllerRepresentable {
    var onPayload: @MainActor (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        QRScannerController(onPayload: onPayload)
    }

    func updateUIViewController(_ controller: QRScannerController, context: Context) {
        controller.onPayload = onPayload
    }

    static func dismantleUIViewController(_ controller: QRScannerController, coordinator: ()) {
        controller.shutdown()
    }
}

@MainActor
final class QRScannerController: UIViewController {
    var onPayload: @MainActor (String) -> Void
    private let capture = QRCapturePipeline()
    private var preview: AVCaptureVideoPreviewLayer?
    private let message = UILabel()
    private var observers: [any NSObjectProtocol] = []
    private var authorizationTask: Task<Void, Never>?
    private var visible = false

    init(onPayload: @escaping @MainActor (String) -> Void) {
        self.onPayload = onPayload
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let layer = AVCaptureVideoPreviewLayer(session: capture.session)
        layer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(layer)
        preview = layer
        message.numberOfLines = 0
        message.textColor = .white
        message.font = .preferredFont(forTextStyle: .body)
        message.textAlignment = .center
        message.text = "Preparing camera…"
        let retry = UIButton(configuration: .filled())
        retry.setTitle("Scan again", for: .normal)
        retry.addTarget(self, action: #selector(retryCamera), for: .touchUpInside)
        let controls = UIStackView(arrangedSubviews: [message, retry])
        controls.axis = .vertical
        controls.spacing = 12
        controls.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        controls.isLayoutMarginsRelativeArrangement = true
        controls.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        controls.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controls)
        NSLayoutConstraint.activate([
            controls.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            controls.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        observe(AVCaptureSession.wasInterruptedNotification) { controller in
            controller.message.text = "Camera interrupted. Try again when the camera is available."
        }
        observe(AVCaptureSession.interruptionEndedNotification) { controller in
            controller.message.text = "Camera available again. Tap Scan again to continue."
        }
        observe(AVCaptureSession.runtimeErrorNotification) { controller in
            controller.capture.stop(reset: true)
            controller.message.text = "The camera stopped unexpectedly. Tap Scan again to retry."
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visible = true
        retryCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        visible = false
        authorizationTask?.cancel()
        capture.stop()
    }

    func shutdown() {
        visible = false
        authorizationTask?.cancel()
        capture.stop()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    @objc private func retryCamera() {
        guard visible else { return }
        authorizationTask?.cancel()
        authorizationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                message.text = "Allow camera access to scan your alarm’s QR code."
                let allowed = await AVCaptureDevice.requestAccess(for: .video)
                guard !Task.isCancelled, visible else { return }
                if allowed { startCapture() }
                else { message.text = "Camera access denied. Enable it in Settings, then try again." }
            case .authorized: startCapture()
            case .denied:
                message.text = "Camera access denied. Enable it in Settings, then try again."
            case .restricted:
                message.text = "Camera access is restricted on this device."
            @unknown default:
                message.text = "Camera authorization is unavailable."
            }
        }
    }

    private func startCapture() {
        message.text = "Starting camera…"
        capture.start(onMessage: { [weak self] text in
            Task { @MainActor [weak self] in
                guard let self, visible else { return }
                message.text = text
            }
        }, onPayload: { [weak self] payload in
            Task { @MainActor [weak self] in
                guard let self, visible else { return }
                onPayload(payload)
            }
        })
    }

    private func observe(_ name: Notification.Name, action: @escaping @MainActor (QRScannerController) -> Void) {
        observers.append(NotificationCenter.default.addObserver(forName: name, object: capture.session, queue: .main) {
            [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, visible else { return }
                action(self)
            }
        })
    }
}

// All configuration, start/stop and metadata state stay on this one serial queue.
// Only the session reference is shared with the main-thread preview layer.
// All capture configuration/state is confined to queue. The main actor only
// attaches the stable session reference to its preview layer.
private final class QRCapturePipeline: @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "PuzzleAlarm.QRCapture")
    private var sink: QRMetadataSink?
    private var configured = false

    func start(onMessage: @escaping @Sendable (String) -> Void,
               onPayload: @escaping @Sendable (String) -> Void) {
        queue.async { [self] in
            do {
                if !configured { try configure(onMessage: onMessage, onPayload: onPayload) }
                sink?.delivered = false
                if !session.isRunning { session.startRunning() }
                onMessage(session.isRunning ? "Point the camera at your alarm’s QR code." :
                    "The camera is unavailable. Tap Scan again to retry.")
            } catch {
                onMessage("No usable QR camera is available on this device. Tap Scan again to retry.")
            }
        }
    }

    func stop(reset: Bool = false) {
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
            if reset { configured = false }
        }
    }

    private func configure(onMessage: @escaping @Sendable (String) -> Void,
                           onPayload: @escaping @Sendable (String) -> Void) throws {
        enum Unavailable: Error { case camera, input, output, qr }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        guard let device = AVCaptureDevice.default(for: .video) else { throw Unavailable.camera }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw Unavailable.input }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { throw Unavailable.output }
        session.addOutput(output)
        guard output.availableMetadataObjectTypes.contains(.qr) else { throw Unavailable.qr }
        let receiver = QRMetadataSink { [weak self] value in
            guard let self else { return }
            queue.async { [self] in
                if session.isRunning { session.stopRunning() }
                onMessage("Code read. If it was not accepted, tap Scan again.")
                onPayload(value)
            }
        }
        output.setMetadataObjectsDelegate(receiver, queue: queue)
        output.metadataObjectTypes = [.qr]
        sink = receiver
        configured = true
    }
}

private final class QRMetadataSink: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    // AVFoundation invokes this delegate only on the pipeline's serial queue.
    var delivered = false
    private let receive: @Sendable (String) -> Void

    init(receive: @escaping @Sendable (String) -> Void) { self.receive = receive }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !delivered,
              let value = objects.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue })
                .first(where: { !$0.isEmpty && $0.utf8.count <= 2_048 }) else { return }
        delivered = true
        receive(value)
    }
}
