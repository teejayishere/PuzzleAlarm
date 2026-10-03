import Foundation

public enum RepositoryVersion: Equatable, Sendable {
    case missing
    case revision(UUID)
}

public struct RepositorySnapshot: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let revision: UUID
    public let state: RepositoryState

    init(state: RepositoryState, revision: UUID = UUID()) throws {
        try state.validate()
        schemaVersion = 1
        self.revision = revision
        self.state = state
    }

    private enum CodingKeys: String, CodingKey { case schemaVersion, revision, state }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let version = try c.decode(Int.self, forKey: .schemaVersion)
        guard version == 1 else { throw PersistenceError.unsupportedSchema(version) }
        schemaVersion = version
        revision = try c.decode(UUID.self, forKey: .revision)
        state = try c.decode(RepositoryState.self, forKey: .state)
    }

    public var version: RepositoryVersion { .revision(revision) }
}

public enum RepositoryRead: Equatable, Sendable {
    // Missing local state says nothing about existing AlarmKit alarms.
    case missing
    case loaded(RepositorySnapshot, interruptedWrite: Bool)

    public var version: RepositoryVersion {
        switch self {
        case .missing: .missing
        case let .loaded(snapshot, _): snapshot.version
        }
    }
}

public protocol PuzzleAlarmRepository: Sendable {
    func load() async throws -> RepositoryRead
    // Compare-and-swap rejects stale writers rather than losing one update.
    func commit(_ state: RepositoryState, expecting: RepositoryVersion) async throws -> RepositorySnapshot
}

enum RepositoryCodec {
    private struct Header: Decodable { let schemaVersion: Int }

    static func decode(_ data: Data) throws -> RepositorySnapshot {
        do {
            let decoder = JSONDecoder()
            let header = try decoder.decode(Header.self, from: data)
            guard header.schemaVersion == 1 else { throw PersistenceError.unsupportedSchema(header.schemaVersion) }
            let snapshot = try decoder.decode(RepositorySnapshot.self, from: data)
            try snapshot.state.validate()
            return snapshot
        } catch let error as PersistenceError { throw error }
        catch { throw PersistenceError.corrupt }
    }

    static func encode(_ snapshot: RepositorySnapshot) throws -> Data {
        try snapshot.state.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(snapshot)
    }
}

public actor InMemoryRepository: PuzzleAlarmRepository {
    public enum Failure: Sendable { case read, write }
    private var bytes: Data?
    private var nextFailure: Failure?

    public init(storedRepresentation: Data? = nil) { bytes = storedRepresentation }

    public func failNext(_ failure: Failure) { nextFailure = failure }
    public func storedRepresentation() -> Data? { bytes }

    public func load() throws -> RepositoryRead {
        if nextFailure == .read {
            nextFailure = nil
            throw PersistenceError.io("injected read")
        }
        guard let bytes else { return .missing }
        return .loaded(try RepositoryCodec.decode(bytes), interruptedWrite: false)
    }

    public func commit(_ state: RepositoryState, expecting: RepositoryVersion) throws -> RepositorySnapshot {
        guard try load().version == expecting else { throw PersistenceError.conflict }
        let snapshot = try RepositorySnapshot(state: state)
        let encoded = try RepositoryCodec.encode(snapshot)
        if nextFailure == .write {
            nextFailure = nil
            throw PersistenceError.io("injected write")
        }
        bytes = encoded
        return snapshot
    }
}
