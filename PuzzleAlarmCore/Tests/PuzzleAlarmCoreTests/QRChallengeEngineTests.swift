import Foundation
import Testing
@testable import PuzzleAlarmCore

@Test func qrMatchingRequiresTheExactConfiguredPayload() {
    let configuration = QRConfiguration(token: uuid(99))
    #expect(QRChallengeEngine.accepts(configuration.expectedPayload, configuration: configuration))
    let rejected = ["", " ", "unrelated", "puzzlealarm://challenge/not-a-uuid",
        QRConfiguration(token: uuid(98)).expectedPayload,
        configuration.expectedPayload + " ", " " + configuration.expectedPayload,
        configuration.expectedPayload + "?bypass=true", configuration.expectedPayload.uppercased()]
    for payload in rejected {
        #expect(!QRChallengeEngine.accepts(payload, configuration: configuration))
    }
}
