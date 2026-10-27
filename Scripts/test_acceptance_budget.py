"""Offline fail-stop checks; no Xcode, Simulator, network or test retries."""
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import tempfile
import unittest
from unittest.mock import MagicMock, patch

SCRIPT = Path(__file__).with_name("run_acceptance_step.py").resolve()


class AcceptanceBudgetTests(unittest.TestCase):
    def invoke(self, minutes=34, now=1001, status=0, timeout=False):
        with tempfile.TemporaryDirectory() as directory:
            previous = Path.cwd()
            os.chdir(directory)
            child = MagicMock(pid=42)
            if timeout:
                child.wait.side_effect = [subprocess.TimeoutExpired("bash", 1), 0]
            else:
                child.wait.return_value = status
            try:
                with patch.dict(os.environ, {"ACCEPTANCE_START": "1000", "ACCEPTANCE_MINUTES": str(minutes),
                        "GITHUB_SHA": "frozen", "GITHUB_RUN_ID": "1", "GITHUB_RUN_ATTEMPT": "1",
                        "SIMULATOR_ID": "selected"}), patch("sys.argv", [str(SCRIPT), "case"]), \
                        patch("sys.stdin", io.StringIO("exit 65\n")), patch("time.time", return_value=now), \
                        patch("subprocess.Popen", return_value=child) as start, patch("subprocess.run") as shutdown, \
                        patch("os.killpg", create=True) as kill, patch("builtins.print"), \
                        self.assertRaises(SystemExit) as result:
                    runpy.run_path(str(SCRIPT), run_name="__main__")
                record = json.loads(Path("TestResults/acceptance-steps/case.json").read_text())
                self.assertEqual(Path("TestResults/acceptance-steps/case.sh").read_text(), "exit 65\n")
                return result.exception.code, record, start, shutdown, kill, child
            finally:
                os.chdir(previous)

    def testEachLaneUsesAbsoluteBudgetAndFrozenIdentity(self):
        for minutes in (34, 19, 79):
            with self.subTest(minutes=minutes):
                code, record, start, shutdown, kill, child = self.invoke(minutes=minutes)
                self.assertEqual(code, 0)
                self.assertEqual(record["sha"], "frozen")
                self.assertEqual(record["deadline"], 1000 + minutes * 60)
                child.wait.assert_called_once_with(timeout=minutes * 60 - 1)
                self.assertTrue(start.call_args.kwargs["start_new_session"])
                self.assertEqual(start.call_args.args[0][:4], ["bash", "-e", "-o", "pipefail"])
                shutdown.assert_not_called()
                kill.assert_not_called()

    def testOriginalFailureIsNotRetriedOrConvertedToSuccess(self):
        code, record, start, _, _, child = self.invoke(status=65)
        self.assertEqual(code, 65)
        self.assertEqual(record["exit_code"], 65)
        start.assert_called_once()
        child.wait.assert_called_once()

    def testExpiredBudgetStartsNothing(self):
        code, record, start, _, _, _ = self.invoke(minutes=19, now=2141)
        self.assertEqual(code, 124)
        self.assertIn("tooling_error", record)
        start.assert_not_called()

    def testDeadlineTerminatesGroupAndSelectedSimulatorWithoutRetry(self):
        code, record, start, shutdown, kill, child = self.invoke(timeout=True)
        self.assertEqual(code, 124)
        self.assertTrue(record["deadline_exceeded"])
        start.assert_called_once()
        kill.assert_called_once()
        shutdown.assert_called_once_with(["xcrun", "simctl", "shutdown", "selected"], timeout=20, check=False)


if __name__ == "__main__":
    unittest.main()
