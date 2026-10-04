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
print(f"Uncovered production core lines: {total}")
