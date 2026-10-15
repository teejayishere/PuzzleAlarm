import AVFoundation
import Foundation
import Observation
import PuzzleAlarmCore

@MainActor
protocol PreviewPlayback: AnyObject {
    func start(_ url: URL) throws
    func stop()
}

@MainActor
@Observable
final class SoundPreview {
    private let playback: any PreviewPlayback
    private let catalog: AlarmSoundCatalog
    private(set) var isPlaying = false
    private(set) var message: String?

    init(playback: any PreviewPlayback = AudioPreviewPlayback(), catalog: AlarmSoundCatalog = .init()) {
        self.playback = playback; self.catalog = catalog
    }
    func play(_ selection: SoundSelection) {
        stop()
        guard let url = catalog.resource(for: selection) else {
            message = selection == .systemDefault
                ? "The system default sound is available when the alarm fires."
                : "This sound is unavailable. The alarm will use the system default."
            return
        }
        do { try playback.start(url); isPlaying = true }
        catch { playback.stop(); message = "Preview is unavailable. You can still save this alarm." }
    }
    func stop() {
        playback.stop(); isPlaying = false; message = nil
    }
}

@MainActor
final class AudioPreviewPlayback: PreviewPlayback {
    private var player: AVAudioPlayer?
    private var ownsSession = false
    func start(_ url: URL) throws {
        stop()
        let session = AVAudioSession.sharedInstance()
        // A foreground, explicitly requested preview; no background audio mode.
        try session.setCategory(.ambient, mode: .default)
        try session.setActive(true)
        ownsSession = true
        do {
            let value = try AVAudioPlayer(contentsOf: url)
            value.volume = 0.35
            value.numberOfLoops = -1
            guard value.prepareToPlay(), value.play() else { throw PreviewError.unavailable }
            player = value
        } catch { stop(); throw error }
    }
    func stop() {
        player?.stop(); player = nil
        if ownsSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            ownsSession = false
        }
    }
    private enum PreviewError: Error { case unavailable }
}
