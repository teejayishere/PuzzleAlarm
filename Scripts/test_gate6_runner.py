"""Exercise stop/accounting paths with fake processes; no Apple tools are run."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from gate6_invocation import METHODS

RUNNER = Path(__file__).with_name('run_gate6_buffered.py').resolve()


class RunnerTests(unittest.TestCase):
    def simulate(self, assertion=False, export_error=False, activation=False):
        invocations = []

        def popen(args, stdout, **kwargs):
            if args[0] == 'xcodebuild':
                invocations.append(args)
                method = Path(args[args.index('-resultBundlePath') + 1]).stem
                declaration = dict(METHODS)[method]
                stdout.write(f"Test Case '-[AlarmManagementUITests {declaration}]' started.\n")
                if assertion:
                    stdout.write('XCTAssertEqual failed\n')
                if activation:
                    stdout.write('Failed to launch com.teejayishere.PuzzleAlarm: Timed out attempting to launch app.\n')
                code = 65 if assertion or activation else 0
            elif args[:2] == ['xcrun', 'xcresulttool']:
                if export_error:
                    raise RuntimeError('simulated export failure')
                declaration = dict(METHODS)[Path(args[-1]).stem]
                json.dump({'testNodes': [{'nodeType': 'Test Case', 'name': declaration,
                                         'result': 'Failed' if assertion or activation else 'Passed'}]}, stdout)
                code = 0
            else:
                # Decoder success is deliberately insufficient for complete capture.
                code = 0
            return SimpleNamespace(wait=lambda timeout=None: code)

        workspace_temp = RUNNER.parents[1] / 'TestResults'
        workspace_temp.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=workspace_temp) as directory:
            previous = Path.cwd()
            try:
                os.chdir(directory)
                with patch.dict(os.environ, GATE6_START=str(time.time()), SIMULATOR_ID='fake'), \
                     patch('os.uname', return_value=SimpleNamespace(machine='arm64'), create=True), \
                     patch('subprocess.Popen', side_effect=popen), patch('subprocess.run'):
                    with self.assertRaises(SystemExit):
                        runpy.run_path(str(RUNNER), run_name='__main__')
                manifest = json.loads(Path('TestResults/outcome-manifest.json').read_text())
            finally:
                os.chdir(previous)
        return manifest, invocations

    def test_assertion_stops_after_one_without_product_blame(self):
        manifest, calls = self.simulate(assertion=True)
        self.assertEqual(len(calls), 1)
        self.assertNotIn('-dry-run', calls[0])
        self.assertEqual(manifest['actual_test_executions'], 1)
        self.assertEqual(manifest['outcome'], 'ASSERTION_FAILURE_CAUSE_UNKNOWN')
        self.assertFalse(manifest['complete_capture'])
        self.assertFalse(manifest['negative_conclusion_allowed'])

    def test_export_failure_keeps_observed_start_and_stops(self):
        manifest, calls = self.simulate(export_error=True)
        self.assertEqual(len(calls), 1)
        self.assertEqual(manifest['actual_test_executions'], 1)
        self.assertEqual(manifest['outcome'], 'TOOLING_FAILURE')
        self.assertFalse(manifest['complete_capture'])

    def test_activation_timeout_stops_without_cause_or_completeness_claim(self):
        manifest, calls = self.simulate(activation=True)
        self.assertEqual(len(calls), 1)
        self.assertEqual(manifest['actual_test_executions'], 1)
        self.assertEqual(manifest['outcome'], 'TOOLING_FAILURE')
        self.assertFalse(manifest['complete_capture'])
        self.assertFalse(manifest['negative_conclusion_allowed'])

    def test_one_success_remains_inconclusive_and_integrity_is_not_completeness(self):
        manifest, calls = self.simulate()
        self.assertEqual(len(calls), 1)
        self.assertEqual(manifest['actual_test_executions'], 1)
        self.assertEqual(manifest['outcome'], 'SUCCESSFUL_SAMPLES_INCONCLUSIVE')
        self.assertTrue(all(item['raw_integrity_valid'] for item in manifest['outcomes']))
        self.assertFalse(manifest['complete_capture'])


if __name__ == '__main__':
    unittest.main()
