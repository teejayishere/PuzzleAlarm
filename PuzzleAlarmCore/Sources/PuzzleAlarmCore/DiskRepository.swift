import Foundation

#if canImport(Darwin)
// Foundation-only Apple filesystem adapter; compiled for macOS tests and iOS.
// No UI, AlarmKit or daemon dependency.
public actor DiskRepository: PuzzleAlarmRepository {
    private let file: URL
    private let beforeCommit: @Sendable () throws -> Void

    public init(directory: URL) {
        file = directory.appendingPathComponent("state.json")
        beforeCommit = {}
    }

    // Fault seam after staging, before atomic replacement; used only by tests.
    init(directory: URL, beforeCommit: @escaping @Sendable () throws -> Void) {
        file = directory.appendingPathComponent("state.json")
        self.beforeCommit = beforeCommit
    }

    public static func applicationSupportDirectory() throws -> URL {
        guard let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw PersistenceError.io("Application Support unavailable")
        }
        return root.appendingPathComponent("PuzzleAlarm", isDirectory: true)
    }

    public func load() throws -> RepositoryRead {
        try coordinated { try Self.read($0) }
    }

    public func commit(_ state: RepositoryState, expecting: RepositoryVersion) throws -> RepositorySnapshot {
        let hook = beforeCommit
        return try coordinated { file in
            guard try Self.read(file).version == expecting else { throw PersistenceError.conflict }
            let snapshot = try RepositorySnapshot(state: state)
            let data = try RepositoryCodec.encode(snapshot)
            let pending = file.appendingPathExtension("pending")
            do {
                // Intent marker survives termination inside Foundation's atomic write.
                // Never promote it automatically: a prior good document is authoritative.
                try data.write(to: pending, options: .atomic)
                try hook()
                try data.write(to: file, options: .atomic)
            } catch { throw PersistenceError.io("write; reload before deciding whether to retry") }
            // Commit is already durable at the filesystem API boundary. Cleanup is
            // advisory: failure leaves interruptedWrite=true, never a false rollback.
            do { try FileManager.default.removeItem(at: pending) } catch { }
            return snapshot
        }
    }

    private static func read(_ file: URL) throws -> RepositoryRead {
        let pending = FileManager.default.fileExists(atPath: file.appendingPathExtension("pending").path)
        let bytes: Data
        do {
            bytes = try Data(contentsOf: file)
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError {
                if pending { throw PersistenceError.interruptedInitialWrite }
                return .missing
            }
            throw PersistenceError.io("read")
        }
        return .loaded(try RepositoryCodec.decode(bytes), interruptedWrite: pending)
    }

    private func coordinated<T>(_ operation: (URL) throws -> T) throws -> T {
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
        } catch { throw PersistenceError.io("create storage directory") }
        // Exclusive coordination covers read/check/write, including other repository
        // instances/processes using this path. There is no await inside the transaction.
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinationError: NSError?
        var result: Result<T, any Error>?
        coordinator.coordinate(writingItemAt: file, options: .forReplacing, error: &coordinationError) { url in
            result = Result { try operation(url) }
        }
        if coordinationError != nil { throw PersistenceError.io("coordinate storage") }
        guard let result else { throw PersistenceError.io("missing coordinated result") }
        return try result.get()
    }
}
#endif
