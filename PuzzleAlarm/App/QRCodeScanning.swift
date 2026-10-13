import Foundation
import Observation
import PuzzleAlarmCore

enum QRScannerStatus: String, Sendable {
    case idle, notDetermined, authorized, denied, restricted, unavailable, interrupted
}
enum QRScannerEvent: Sendable { case status(QRScannerStatus), payload(String) }

@MainActor protocol QRCodeScanning: AnyObject {
    func start(_ receive: @escaping @MainActor @Sendable (QRScannerEvent) -> Void)
    func stop()
}

@MainActor @Observable final class QRScanController {
    private(set) var status = QRScannerStatus.idle
    private(set) var feedback = ""
    private(set) var isSubmitting = false
    private var attempt: UUID?
    let scanner: any QRCodeScanning
    private let store: AlarmStore
    init(store: AlarmStore, scanner: any QRCodeScanning) { self.store = store; self.scanner = scanner }
    func start(_ identity: ChallengeIdentity) {
        stop()
        let id = UUID(); attempt = id
        scanner.start { [weak self] event in
            guard let self, self.attempt == id else { return }
            switch event {
            case let .status(value):
                self.status = value
                if [.denied, .restricted, .unavailable, .interrupted].contains(value) {
                    self.attempt = nil; self.scanner.stop()
                }
            case let .payload(value):
                guard self.status == .authorized, !self.isSubmitting else { return }
                self.isSubmitting = true
                Task { [weak self] in
                    guard let self else { return }
                    defer { self.isSubmitting = false }
                    guard self.attempt == id else { return }
                    let result = await self.store.submitQR(value, identity: identity)
                    guard self.attempt == id else { return }
                    switch result {
                    case .wrong: self.feedback = "This is not the configured QR code."
                    case .stale: self.stop(); self.feedback = "This challenge has already changed."
                    case .completed: self.stop(); self.feedback = "QR complete."
                    case nil: self.feedback = "Scan was not saved. Try again."
                    }
                }
            }
        }
    }
    func stop() { attempt = nil; scanner.stop(); status = .idle }
}

#if DEBUG
@MainActor final class FakeQRCodeScanner: QRCodeScanning {
    var permission: QRScannerStatus = .authorized
    private(set) var starts = 0
    private(set) var stops = 0
    private(set) var receive: (@MainActor @Sendable (QRScannerEvent) -> Void)?
    func start(_ receive: @escaping @MainActor @Sendable (QRScannerEvent) -> Void) {
        starts += 1; self.receive = receive; receive(.status(permission))
    }
    func stop() { stops += 1; receive = nil }
    func emit(_ event: QRScannerEvent) { receive?(event) }
}
#endif
