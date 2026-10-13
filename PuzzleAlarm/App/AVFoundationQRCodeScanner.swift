import AVFoundation
import Foundation

@MainActor final class AVFoundationQRCodeScanner: QRCodeScanning {
    private let worker = QRCaptureWorker()
    private var attempt: UUID?
    var session: AVCaptureSession { worker.session }
    deinit { worker.stop() }
    func start(_ receive: @escaping @MainActor @Sendable (QRScannerEvent) -> Void) {
        stop()
        let id = UUID(); attempt = id
        Task { [weak self] in
            guard self?.attempt == id else { return }
            let permission = AVCaptureDevice.authorizationStatus(for: .video)
            if permission == .notDetermined {
                receive(.status(.notDetermined))
                _ = await AVCaptureDevice.requestAccess(for: .video)
            }
            guard let self, self.attempt == id else { return }
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.worker.start { [weak self] event in
                    guard self?.attempt == id else { return }; receive(event)
                }
            case .denied: receive(.status(.denied))
            case .restricted: receive(.status(.restricted))
            case .notDetermined: receive(.status(.notDetermined))
            @unknown default: receive(.status(.unavailable))
            }
        }
    }
    func stop() { attempt = nil; worker.stop() }
}

/// Every mutable capture operation and delegate callback uses this serial queue.
/// The session is exposed only for the main-thread preview layer attachment.
private final class QRCaptureWorker: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "PuzzleAlarm.QR.capture")
    private var receive: (@MainActor @Sendable (QRScannerEvent) -> Void)?
    private var observers: [NSObjectProtocol] = []
    private var generation: UUID?
    func start(_ callback: @escaping @MainActor @Sendable (QRScannerEvent) -> Void) {
        queue.async { [self] in
            receive = callback
            let id = UUID(); generation = id
            for name in [AVCaptureSession.wasInterruptedNotification, AVCaptureSession.runtimeErrorNotification] {
                observers.append(NotificationCenter.default.addObserver(forName: name, object: session, queue: nil) {
                    [weak self] _ in
                    guard let self else { return }
                    self.queue.async {
                        guard self.generation == id else { return }
                        self.send(.status(.interrupted))
                    }
                })
            }
            do {
                if session.inputs.isEmpty {
                    guard let device = AVCaptureDevice.default(for: .video) else {
                        send(.status(.unavailable)); return
                    }
                    let input = try AVCaptureDeviceInput(device: device)
                    let output = AVCaptureMetadataOutput()
                    session.beginConfiguration()
                    guard session.canAddInput(input) else {
                        session.commitConfiguration(); send(.status(.unavailable)); return
                    }
                    session.addInput(input)
                    guard session.canAddOutput(output) else {
                        session.removeInput(input); session.commitConfiguration()
                        send(.status(.unavailable)); return
                    }
                    session.addOutput(output)
                    guard output.availableMetadataObjectTypes.contains(.qr) else {
                        session.removeOutput(output); session.removeInput(input); session.commitConfiguration()
                        send(.status(.unavailable)); return
                    }
                    output.setMetadataObjectsDelegate(self, queue: queue)
                    output.metadataObjectTypes = [.qr]
                    session.commitConfiguration()
                }
                session.startRunning()
                send(.status(session.isRunning ? .authorized : .unavailable))
            } catch { send(.status(.unavailable)) }
        }
    }
    func stop() {
        queue.async { [self] in
            receive = nil; generation = nil
            observers.forEach { NotificationCenter.default.removeObserver($0) }; observers.removeAll()
            if session.isRunning { session.stopRunning() }
        }
    }
    private func send(_ event: QRScannerEvent) {
        guard let callback = receive else { return }
        Task { @MainActor in callback(event) }
    }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        for case let object as AVMetadataMachineReadableCodeObject in objects where object.type == .qr {
            if let value = object.stringValue { send(.payload(value)) }
        }
    }
}
