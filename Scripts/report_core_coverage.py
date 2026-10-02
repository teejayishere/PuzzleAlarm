"""Report only production Swift package coverage; test execution is a separate gate."""
import json
import os
from pathlib import Path
import sys

document = json.loads(Path(sys.argv[1]).read_text())
files = [
    item
    for entry in document["data"]
    for item in entry["files"]
    if "/PuzzleAlarmCore/Sources/PuzzleAlarmCore/" in item["filename"].replace("\\", "/")
]
if not files:
    raise SystemExit("No core files in Swift coverage output")
covered = sum(item["summary"]["lines"]["covered"] for item in files)
count = sum(item["summary"]["lines"]["count"] for item in files)
if not count:
    raise SystemExit("No executable core lines in coverage output")
lines = ["## Core line coverage", "", "| Source | Covered lines | Total lines | Percent |",
         "| --- | ---: | ---: | ---: |"]
for item in sorted(files, key=lambda item: item["filename"]):
    summary = item["summary"]["lines"]
    lines.append(f"| {Path(item['filename']).name} | {summary['covered']} | {summary['count']} | {summary['percent']:.2f}% |")
lines += ["", f"Total: {covered}/{count} lines ({100 * covered / count:.2f}%).",
          "Line coverage is not evidence of physical alarm behavior or exhaustive branch correctness."]
report = "\n".join(lines) + "\n"
print(report)
if summary_path := os.environ.get("GITHUB_STEP_SUMMARY"):
    with open(summary_path, "a", encoding="utf-8") as summary_file:
        summary_file.write(report)
