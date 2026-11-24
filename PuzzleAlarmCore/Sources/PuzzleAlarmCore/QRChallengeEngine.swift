import Foundation

public enum QRChallengeEngine {
    // Camera adapters and deterministic previews use the same exact matcher.
    public static func accepts(_ payload: String, configuration: QRConfiguration) -> Bool {
        payload == configuration.expectedPayload
    }
}
