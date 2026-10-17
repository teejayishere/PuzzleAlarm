import Foundation
import Darwin

// CI-only. Main-actor serialization; no file operations, flushing or locks in record().
// Formatting, clock reads and mapped stores still have overhead. No zero-overhead claim.
@MainActor
final class Gate6Recorder {
    static let shared = Gate6Recorder()
    static let capacity = 16384
    static let stride = 1024
    static let header = 128
    let memory: UnsafeMutableRawPointer
    let bytes: Int
    let failStop: Bool
    init(path: String? = nil, capacity: Int = Gate6Recorder.capacity, failStop: Bool = true) {
        self.failStop = failStop
        bytes = Self.header + capacity * Self.stride
        let destination = path ?? FileManager.default.temporaryDirectory
            .appendingPathComponent("gate6-\(getpid())-\(UUID().uuidString).bin").path
        let fd = open(destination, O_RDWR | O_CREAT | O_EXCL, S_IRUSR | S_IWUSR)
        precondition(fd >= 0, "recorder open failed")
        precondition(ftruncate(fd, off_t(bytes)) == 0, "recorder allocation failed")
        let mapped = mmap(nil, bytes, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
        precondition(mapped != MAP_FAILED && mapped != nil, "recorder mmap failed")
        memory = mapped!
        precondition(close(fd) == 0)
        // Initialize and prefault every byte before any instrumented interaction.
        memset(memory, 0, bytes)
        put(0, 0x3146554236434744); put(8, 1); put(16, UInt64(capacity))
        put(24, UInt64(Self.stride)); put(32, UInt64(getpid()))
        put(72, 1); put(80, DispatchTime.now().uptimeNanoseconds)
        put(88, UInt64(Date().timeIntervalSince1970 * 1e9))
        record("process start uuid=\(UUID().uuidString) pid=\(getpid())")
    }
    func get(_ offset: Int) -> UInt64 { memory.load(fromByteOffset: offset, as: UInt64.self) }
    func put(_ offset: Int, _ value: UInt64) { memory.storeBytes(of: value.littleEndian, toByteOffset: offset, as: UInt64.self) }
    func record(_ message: String) {
        let sequence = get(40) + 1
        put(40, sequence)
        let index = get(48)
        guard index < get(16) else {
            put(56, get(56) + 1)
            precondition(!failStop, "recorder overflow; stop experiment")
            return
        }
        let slot = Self.header + Int(index) * Self.stride
        put(slot + 8, DispatchTime.now().uptimeNanoseconds)
        put(slot + 16, UInt64(Date().timeIntervalSince1970 * 1e9))
        var count = 0
        var hash: UInt32 = 2166136261
        var truncated = false
        for byte in message.utf8 {
            if count == Self.stride - 40 { truncated = true; break }
            memory.storeBytes(of: byte, toByteOffset: slot + 40 + count, as: UInt8.self)
            hash = (hash ^ UInt32(byte)) &* 16777619
            count += 1
        }
        memory.storeBytes(of: UInt32(count).littleEndian, toByteOffset: slot + 24, as: UInt32.self)
        memory.storeBytes(of: UInt32(truncated ? 1 : 0).littleEndian, toByteOffset: slot + 28, as: UInt32.self)
        for shift in 0..<8 {
            hash = (hash ^ UInt32((sequence >> (shift * 8)) & 255)) &* 16777619
        }
        for index in 8..<32 {
            hash = (hash ^ UInt32(memory.load(fromByteOffset: slot + index, as: UInt8.self))) &* 16777619
        }
        memory.storeBytes(of: hash.littleEndian, toByteOffset: slot + 32, as: UInt32.self)
        if truncated { put(64, get(64) + 1) }
        // Commit marker last; decoder rejects incomplete slots and sequence gaps.
        put(slot, sequence)
        put(48, index + 1)
        precondition(!truncated || !failStop, "recorder truncation; stop experiment")
    }
}
