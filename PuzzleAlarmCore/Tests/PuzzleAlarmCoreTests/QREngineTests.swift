import Foundation
import Testing
@testable import PuzzleAlarmCore

private let qrOrders: [[Int]] = [[2], [2, 0], [0, 2], [2, 1], [1, 2],
    [0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]]

@Test(arguments: qrOrders)
func QREngineExactSnapshotAndOrderedRestoration(_ order: [Int]) throws {
    let configs = try configurations()
    let session = try activeSession(sequence: order.map { configs[$0] })
    var coordinator = try ChallengeCoordinator(restoring: PersistedSession(session: session,
        updatedAt: session.scheduledWakeUpDate))
    let qrIndex = try #require(order.firstIndex(of: 2))
    let qrIdentity = ChallengeIdentity(sessionID: session.id, index: qrIndex, kind: .qr)
    guard case let .qr(configuration) = configs[2] else { throw FixtureError.invalidDate }
    if qrIndex > 0 {
        var engine = try QREngine(restoring: coordinator.record)
        #expect(throws: DomainError.outOfOrder) {
            try engine.submit(configuration.expectedPayload, for: qrIdentity, at: coordinator.record.updatedAt)
        }
        #expect(engine.record == coordinator.record)
    }
    while coordinator.currentIdentity != qrIdentity {
        try coordinator.recordSuccess(for: #require(coordinator.currentIdentity), at: coordinator.record.updatedAt)
    }
    var engine = try QREngine(restoring: roundTrip(coordinator.record))
    let before = engine
    let payload = configuration.expectedPayload
    for bad in ["", " ", "unrelated", QRConfiguration(token: uuid(230)).expectedPayload,
                payload.uppercased(), payload + "\n", " " + payload, payload + "?x=1",
                payload.replacingOccurrences(of: ":", with: "%3A"), "puzzlealarm://challenge/not-a-uuid"] {
        #expect(try engine.submit(bad, for: qrIdentity, at: engine.record.updatedAt) == .wrong)
        #expect(engine == before)
    }
    #expect(try engine.submit(payload, for: qrIdentity, at: engine.record.updatedAt) == .completed)
    #expect(engine.record.session.currentChallengeIndex == qrIndex + 1)
    #expect(engine.record.session.completedAt == nil)
    #expect(engine.record.session.remainingCancellationIDs.count == 5)
    engine = try QREngine(restoring: roundTrip(engine.record))
    let after = engine
    #expect(try engine.submit(payload, for: qrIdentity, at: engine.record.updatedAt) == .stale)
    #expect(engine == after)
    #expect(engine.record.session.phase == (qrIndex == order.count - 1 ? .completing : .active))
}

@Test func QREngineRejectsForeignIdentityAndRegressingClockAtomically() throws {
    let session = try activeSession(sequence: [.qr(QRConfiguration(token: uuid(99)))])
    var engine = try QREngine(restoring: PersistedSession(session: session, updatedAt: session.scheduledWakeUpDate))
    let identity = try #require(engine.coordinator.currentIdentity)
    let before = engine
    for invalid in [ChallengeIdentity(sessionID: uuid(240), index: 0, kind: .qr),
                    ChallengeIdentity(sessionID: session.id, index: -1, kind: .qr),
                    ChallengeIdentity(sessionID: session.id, index: 1, kind: .qr),
                    ChallengeIdentity(sessionID: session.id, index: 0, kind: .math)] {
        #expect(throws: DomainError.outOfOrder) {
            try engine.submit(QRConfiguration(token: uuid(99)).expectedPayload, for: invalid, at: engine.record.updatedAt)
        }
        #expect(engine == before)
    }
    #expect(throws: DomainError.self) {
        try engine.submit(QRConfiguration(token: uuid(99)).expectedPayload, for: identity,
                          at: engine.record.updatedAt.addingTimeInterval(-1))
    }
    #expect(engine == before)
}
