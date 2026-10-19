"""Offline command-policy checks, never Xcode or Simulator validation."""
from pathlib import Path
import unittest
from gate6_invocation import METHODS, check_advertised_options, test_command


class InvocationTests(unittest.TestCase):
    def test_archived_selected_xcode_advertises_all_emitted_options(self):
        help_path = Path(__file__).resolve().parents[1] / 'docs/evidence/gate6-buffered-39080779760/xcodebuild-help.txt'
        check_advertised_options(help_path.read_text())

    def test_missing_option_fails_closed(self):
        with self.assertRaises(ValueError):
            check_advertised_options('Usage: xcodebuild -project')

    def test_one_original_declaration_no_dry_run_or_repetitions(self):
        self.assertEqual(METHODS, [('editor', 'testAudioPreviewStopsOnSelectionNavigationBackgroundAndRelaunch')])
        for name, method in METHODS:
            args = test_command('ID', 'arm64', f'{name}.xcresult', method)
            self.assertEqual(args[-1], 'test')
            self.assertEqual([a for a in args if a.startswith('-only-testing:')],
                             [f'-only-testing:PuzzleAlarmUITests/AlarmManagementUITests/{method}'])
            for forbidden in ('-dry-run', '-test-iterations', '-retry-tests-on-failure',
                              '-run-tests-until-failure', '-test-repetition-relaunch-enabled'):
                self.assertNotIn(forbidden, args)
            self.assertEqual(args[args.index('-parallel-testing-enabled') + 1], 'NO')
            self.assertEqual(args[args.index('-maximum-test-execution-time-allowance') + 1], '600')


if __name__ == '__main__':
    unittest.main()
