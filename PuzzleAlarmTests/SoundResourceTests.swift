import AVFoundation
import PuzzleAlarmCore
import XCTest
@testable import PuzzleAlarm

final class SoundResourceTests: XCTestCase {
    func testEveryBundledSoundIsPlayableAndMissingResourcesFallBack() throws {
        for sound in BundledSound.allCases {
            let url = try XCTUnwrap(Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"))
            let file = try AVAudioFile(forReading: url)
            XCTAssertEqual(file.processingFormat.channelCount, 1)
            XCTAssertEqual(file.processingFormat.sampleRate, 44_100)
            let seconds = Double(file.length) / file.processingFormat.sampleRate
            XCTAssertGreaterThanOrEqual(seconds, 3)
            XCTAssertLessThanOrEqual(seconds, 4)
            XCTAssertEqual(AlarmConfigurationFactory.selectedSound(.bundled(sound)), .named(sound.rawValue + ".wav"))
            XCTAssertEqual(AlarmConfigurationFactory.selectedSound(.bundled(sound), bundle: Bundle(for: Self.self)), .default)
        }
    }
}
