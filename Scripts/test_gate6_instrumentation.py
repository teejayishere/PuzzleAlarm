"""Apply the real generator in a disposable copy; never touch product sources."""
import contextlib
import io
import os
from pathlib import Path
import re
import runpy
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
FILES = ['PuzzleAlarm/App/' + name + '.swift' for name in
         ['UITestEnvironment', 'NativeAlarmSwitch', 'ContentView', 'PuzzleAlarmApp',
          'AlarmEditorView', 'SoundPreview']]
TEST = 'PuzzleAlarmUITests/AlarmManagementUITests.swift'


class InstrumentationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        parent = ROOT / 'TestResults'
        parent.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=parent) as directory:
            workspace = Path(directory)
            for name in FILES + [TEST, 'Scripts/Gate6Recorder.swift']:
                target = workspace / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text((ROOT / name).read_text())
            previous = Path.cwd()
            try:
                os.chdir(workspace)
                with contextlib.redirect_stdout(io.StringIO()):
                    runpy.run_path(str(ROOT / 'Scripts/diagnose_gate6.py'))
                cls.generated = {name: (workspace / name).read_text() for name in
                                 FILES + [TEST, 'PuzzleAlarm/App/Gate6InputProbe.swift',
                                          'PuzzleAlarm/App/Gate6Recorder.swift']}
            finally:
                os.chdir(previous)

    def test_entire_original_ui_declaration_and_regressions_preserved(self):
        modified = self.generated[TEST]
        modified = re.sub(r'^\s*print\("GATE6 boundary .*$', '', modified, flags=re.MULTILINE)
        modified = modified.replace(', "PUZZLE_INPUT_TRACE": "1"', '')
        modified = modified.replace('XCTAssertTrue(app.buttons["editor.save"].waitForExistence(timeout: 10), app.debugDescription)', '')

        def normalize(text):
            return re.sub(r'[\s;]+', '', re.sub(r'//[^\n]*', '', text))

        self.assertEqual(normalize(modified), normalize((ROOT / TEST).read_text()))
        for boundary in ['home begin', 'home returned', 'activate begin', 'activate returned']:
            self.assertEqual(self.generated[TEST].count('GATE6 boundary ' + boundary), 1)

    def test_all_gestures_enumerated_with_fixed_recorder_bound(self):
        probe = self.generated['PuzzleAlarm/App/Gate6InputProbe.swift']
        self.assertIn('gestures.enumerated()', probe)
        self.assertNotIn('.prefix(', probe)
        self.assertIn('gesture list depth=\\(depth) count=\\(gestures.count)', probe)
        self.assertIn('index=\\(index)', probe)
        self.assertIn('depth < 24', probe)
        self.assertIn('capture limited ancestors', probe)
        recorder = self.generated['PuzzleAlarm/App/Gate6Recorder.swift']
        self.assertEqual(recorder, (ROOT / 'Scripts/Gate6Recorder.swift').read_text())
        self.assertIn('static let capacity = 16384', recorder)
        self.assertIn('put(56, get(56) + 1)', recorder)
        self.assertIn('precondition(!failStop', recorder)

    def test_passive_probe_and_lifecycle_observation(self):
        probe = self.generated['PuzzleAlarm/App/Gate6InputProbe.swift']
        for option in ['cancelsTouchesInView', 'delaysTouchesBegan', 'delaysTouchesEnded']:
            self.assertIn('probe.' + option + ' = false', probe)
        self.assertIn('canPrevent(_ other: UIGestureRecognizer) -> Bool { false }', probe)
        self.assertIn('canBePrevented(by other: UIGestureRecognizer) -> Bool { false }', probe)
        for notification in ['willResignActive', 'didEnterBackground', 'willEnterForeground', 'didBecomeActive']:
            self.assertIn('UIApplication.' + notification + 'Notification', probe)
        self.assertIn('private var observingLifecycle = false', probe)

    def test_audio_stop_operations_unchanged_after_removing_records(self):
        audio = self.generated['PuzzleAlarm/App/SoundPreview.swift']
        audio = re.sub(r'^\s*UITestEnvironment.traceToggle\(.*\)\n', '\n', audio, flags=re.MULTILINE)
        self.assertEqual(re.sub(r'\s+', '', audio),
                         re.sub(r'\s+', '', (ROOT / 'PuzzleAlarm/App/SoundPreview.swift').read_text()))

    def test_no_callback_file_io_in_generated_fixture(self):
        fixture = self.generated['PuzzleAlarm/App/UITestEnvironment.swift']
        callback = fixture.split('static func traceToggle')[1].split('static let now')[0]
        self.assertIn('Gate6Recorder.shared.record(message)', callback)
        for forbidden in ['FileHandle', 'write(', 'synchronize', 'NSLock']:
            self.assertNotIn(forbidden, callback)


if __name__ == '__main__':
    unittest.main()
