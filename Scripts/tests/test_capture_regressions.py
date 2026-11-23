import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("capture_check", Path(__file__).parents[1] / "check_capture_regressions.py")
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class CaptureCompletionTests(unittest.TestCase):
    def log(self):
        markers = ["Capture regression completed: " + name for name in sorted(checker.CASES)]
        issues = [f"Forwarding original XCTest issue: capture-regression-{kind} source=fixture.swift:10"
                  for kind, count in checker.ISSUES.items() for _ in range(count)]
        return "\n".join(markers + issues)

    def test_green_suite_without_postconditions_is_rejected(self):
        with self.assertRaises(ValueError):
            checker.verify("Executed 6 tests, with 0 failures\n** TEST SUCCEEDED **")

    def test_missing_secondary_and_duplicate_completion_are_rejected(self):
        missing = self.log().replace("capture-regression-secondary", "absent-secondary")
        with self.assertRaises(ValueError):
            checker.verify(missing)
        duplicated = self.log() + "\nCapture regression completed: " + sorted(checker.CASES)[0]
        with self.assertRaises(ValueError):
            checker.verify(duplicated)

    def test_complete_negative_evidence_is_accepted(self):
        checker.verify(self.log())


if __name__ == "__main__":
    unittest.main()
