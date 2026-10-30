#!/usr/bin/env python3
"""Reject history outside the owner-approved restart (requires full git history)."""

import subprocess
import sys


ANCHOR = "862c2d872958c2e08971acbf605bbcf07ee4b3d5"
BASELINE = "159b777379ad587a615df56ef24fa273aa29ffe4"


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def main():
    revision = sys.argv[1] if len(sys.argv) == 2 else "HEAD"
    if len(sys.argv) > 2:
        raise ValueError("usage: check_restart_lineage.py [revision]")
    if git("rev-parse", "--is-shallow-repository") != "false":
        raise ValueError("full history required; fetch with depth 0")
    head = git("rev-parse", "--verify", f"{revision}^{{commit}}")
    if git("show", "-s", "--format=%P", ANCHOR) != BASELINE:
        raise ValueError("restart anchor must have the Gate 5 baseline as sole parent")
    subprocess.run(["git", "merge-base", "--is-ancestor", ANCHOR, head], check=True)
    merges = git("rev-list", "--min-parents=2", f"{ANCHOR}..{head}")
    if merges:
        raise ValueError(f"merge commits after restart anchor are forbidden:\n{merges}")
    print(f"Restart lineage PASS: {head}; fixed anchor {ANCHOR}; no later merges")


if __name__ == "__main__":
    try:
        main()
    except (subprocess.CalledProcessError, ValueError) as error:
        sys.exit(f"Restart lineage FAIL: {error}")
