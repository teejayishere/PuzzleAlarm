"""A green XCTest summary alone does not prove negative postconditions ran."""
from collections import Counter
from pathlib import Path
import re
import sys

CASES = {
    "testPrimaryIssueIsForwardedBeforeNormalCapture",
    "testSecondaryCollectorIssueCannotReenterAndGuardResets",
    "testTransitionIssueWithEditorPresentSkipsQueriesAndRelaunches",
    "testUnavailableApplicationRetainsIssueWithoutQueries",
}
ISSUES = Counter({"primary": 2, "secondary": 1, "transition": 1, "unavailable": 1})


def verify(text):
    completed = Counter(re.findall(r"Capture regression completed: (\w+)", text))
    issues = Counter(re.findall(r"Forwarding original XCTest issue: capture-regression-(\w+) source=", text))
    if completed != Counter({name: 1 for name in CASES}):
        raise ValueError(f"Negative regression postconditions did not complete exactly once: {dict(completed)}")
    if issues != ISSUES:
        raise ValueError(f"Intentional primary/secondary issue evidence mismatch: {dict(issues)}")
    print("All four negative regressions reached their postconditions; all five intentional issues were forwarded.")


if __name__ == "__main__":
    try:
        verify(Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace"))
    except ValueError as error:
        sys.exit(str(error))
