import AVFoundation
import Combine
import PuzzleAlarmCore
import SwiftUI

@MainActor
struct SoundPreviewView: View {
    let selection: SoundSelection
    @StateObject private var playback = SoundPreviewPlayback.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if selection == .systemDefault {
                Text("iOS chooses the system alarm sound. Its audio file is not available for preview here.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Button(playback.isPlaying ? "Stop Preview" : "Preview sound",
                       systemImage: playback.isPlaying ? "stop.fill" : "play.fill") {
                    if playback.isPlaying { playback.stop() }
                    else { playback.play(selection) }
                }
                .accessibilityIdentifier("sound.preview")
            }
            if let error = playback.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.red)
                    .accessibilityIdentifier("sound.preview.error")
            }
        }
        .onChange(of: selection) { _, _ in playback.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { playback.stop() } }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in
            playback.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.mediaServicesWereResetNotification)) { _ in
            playback.stop()
        }
        .onDisappear { playback.stop() }
    }
}

// All preview views share one owner; previews never loop or compete for playback.
@MainActor
private final class SoundPreviewPlayback: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = SoundPreviewPlayback()
    @Published private(set) var isPlaying = false
    @Published private(set) var errorMessage: String?
    private var player: AVAudioPlayer?
    private var sessionActive = false

    func play(_ selection: SoundSelection) {
        stop()
        errorMessage = nil
        guard case let .bundled(sound) = selection else {
            errorMessage = "The system alarm sound is not available for preview."
            return
        }
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") ??
                Bundle.main.url(forResource: sound.rawValue, withExtension: "wav", subdirectory: "Sounds") else {
            errorMessage = "This sound file is unavailable. The alarm will use the system default."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            sessionActive = true
            let next = try AVAudioPlayer(contentsOf: url)
            next.numberOfLoops = 0
            next.volume = 0.6
            next.delegate = self
            player = next
            guard next.prepareToPlay(), next.play() else {
                stop()
                errorMessage = "The sound preview could not start."
                return
            }
            isPlaying = true
        } catch {
            stop()
            errorMessage = "The sound preview is unavailable. Try again."
        }
    }

    func stop() {
        errorMessage = nil
        let previous = player
        player = nil
        previous?.delegate = nil
        previous?.stop()
        isPlaying = false
        if sessionActive {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
                sessionActive = false
            } catch {
                errorMessage = "Preview stopped, but iOS could not release the audio session."
            }
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let identity = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player, ObjectIdentifier(current) == identity else { return }
            stop()
            if !flag { errorMessage = "The sound preview did not finish successfully." }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        let identity = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player, ObjectIdentifier(current) == identity else { return }
            stop()
            errorMessage = "This sound file could not be played."
        }
    }
}
