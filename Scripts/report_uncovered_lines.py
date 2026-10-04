"""Print LLVM's actual uncovered line records, rather than infer them from regions."""
from pathlib import Path
import subprocess

bin_path = Path(subprocess.check_output(["swift", "build", "--show-bin-path"], text=True).strip())
binary = bin_path / "PuzzleAlarmPackageTests.xctest/Contents/MacOS/PuzzleAlarmPackageTests"
profile = bin_path / "codecov/default.profdata"
report = subprocess.check_output([
    "xcrun", "llvm-cov", "export", str(binary),
    f"-instr-profile={profile}", "-format=lcov"
], text=True)
source = None
total = 0
for line in report.splitlines():
    if line.startswith("SF:"):
        path = Path(line[3:])
        source = path if "/PuzzleAlarmCore/Sources/PuzzleAlarmCore/" in path.as_posix() else None
    elif source is not None and line.startswith("DA:"):
        number, count, *_ = line[3:].split(",")
        if int(count) == 0:
            text = source.read_text().splitlines()[int(number) - 1]
            print(f"{source.name}:{number}: {text.strip()}")
            total += 1
print(f"LCOV merged uncovered source lines: {total} (see SwiftPM closure counts below)")

# SwiftPM's JSON summary can differ from LCOV's merged line view (for example,
# separate closure instantiations). Preserve the original evidence for auditing.
import json
json_path = subprocess.check_output(["swift", "test", "--show-codecov-path"], text=True).strip()
document = json.loads(Path(json_path).read_text())
for unit in document["data"]:
    for item in unit["files"]:
        if "/PuzzleAlarmCore/Sources/PuzzleAlarmCore/" not in item["filename"]:
            continue
        if item["summary"]["lines"]["covered"] == item["summary"]["lines"]["count"]:
            continue
        source_lines = Path(item["filename"]).read_text().splitlines()
        print(f"SwiftPM JSON {Path(item['filename']).name}: {item['summary']['lines']}")
        for segment in item["segments"]:
            if segment[2] == 0 and segment[3]:
                number = segment[0]
                print(f"  zero-count segment {segment}: {source_lines[number - 1].strip()}")
    for function in unit["functions"]:
        if function["count"] == 0 and any("/PuzzleAlarmCore/Sources/PuzzleAlarmCore/" in f for f in function["filenames"]):
            print(f"Uncalled function: {function['name']}; files={function['filenames']}; regions={function['regions']}")
