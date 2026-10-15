import AVFoundation
import Foundation
import PuzzleAlarmCore

// Validate before handing a name to AlarmKit. No persisted selection is rewritten.
struct AlarmSoundCatalog {
    var locate: (BundledSound) -> URL? = {
        Bundle.main.url(forResource: $0.rawValue, withExtension: "caf")
    }
    func resource(for selection: SoundSelection) -> URL? {
        guard case let .bundled(sound) = selection, let url = locate(sound),
              let file = try? AVAudioFile(forReading: url), file.length > 0,
              file.processingFormat.sampleRate > 0,
              Double(file.length) / file.processingFormat.sampleRate < 30 else { return nil }
        return url
    }
}
