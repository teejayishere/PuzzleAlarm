"""Offline checks of the replacement attempt's fail-closed time/preservation wrapper."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest.mock import MagicMock, patch

SCRIPT = Path(__file__).with_name("run_gate6_reset.py")


class ResetBudgetTests(unittest.TestCase):
    def invoke(self, now=1001, status=0, timeout=False):
        with tempfile.TemporaryDirectory() as directory:
            previous = Path.cwd()
            os.chdir(directory)
            child = MagicMock(pid=42)
            child.wait.side_effect = [subprocess.TimeoutExpired("xcodebuild", 1), 0] if timeout else None
            child.wait.return_value = status
            try:
                with patch.dict(os.environ, {"GATE6_RESET_START": "1000", "GITHUB_SHA": "frozen",
                        "GITHUB_RUN_ID": "1", "GITHUB_RUN_ATTEMPT": "1", "SIMULATOR_ID": "selected"}), \
                        patch("sys.argv", [str(SCRIPT), "case", "xcodebuild", "test"]), \
                        patch("time.time", return_value=now), \
                        patch("subprocess.Popen", return_value=child) as start, \
                        patch("subprocess.run") as shutdown, \
                        patch("os.killpg", create=True) as kill, \
                        patch("builtins.print"), self.assertRaises(SystemExit) as result:
                    runpy.run_path(str(SCRIPT), run_name="__main__")
                record = json.loads(Path("TestResults/case.json").read_text())
                return result.exception.code, record, start, shutdown, kill, child
            finally:
                os.chdir(previous)

    def testSuccessPreservesExactIdentityAndAbsoluteBudget(self):
        code, record, start, shutdown, kill, child = self.invoke()
        self.assertEqual(code, 0)
        self.assertEqual(record["sha"], "frozen")
        self.assertEqual(record["deadline"], 3040)
        child.wait.assert_called_once_with(timeout=2039)
        self.assertTrue(start.call_args.kwargs["start_new_session"])
        shutdown.assert_not_called()
        kill.assert_not_called()

    def testOriginalFailureIsNotRetriedOrConvertedToSuccess(self):
        code, record, start, _, _, child = self.invoke(status=65)
        self.assertEqual(code, 65)
        self.assertEqual(record["exit_code"], 65)
        start.assert_called_once()
        child.wait.assert_called_once()

    def testExpiredBudgetDoesNotStartTests(self):
        code, record, start, _, _, _ = self.invoke(now=3041)
        self.assertEqual(code, 124)
        self.assertIn("tooling_error", record)
        start.assert_not_called()

    def testDeadlineTerminatesGroupAndStopsSelectedSimulator(self):
        code, record, start, shutdown, kill, _ = self.invoke(timeout=True)
        self.assertEqual(code, 124)
        self.assertTrue(record["deadline_exceeded"])
        start.assert_called_once()
        kill.assert_called_once()
        shutdown.assert_called_once_with(["xcrun", "simctl", "shutdown", "selected"], timeout=20, check=False)


if __name__ == "__main__":
    unittest.main()
