"""Print installed public SDK declarations before writing the capability spike."""
import pathlib
import subprocess

sdk = pathlib.Path(subprocess.check_output(
    ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], text=True).strip())
print(f"SDK: {sdk}", flush=True)
for module in ("AlarmKit", "AppIntents", "ActivityKit", "Foundation"):
    folder = sdk / "System/Library/Frameworks" / f"{module}.framework/Modules/{module}.swiftmodule"
    candidates = sorted(folder.glob("arm64-apple-ios-simulator.swiftinterface"))
    if len(candidates) != 1:
        raise SystemExit(f"Expected one public interface: {folder}")
    source = candidates[0].read_text()
    print(f"\nPUBLIC INTERFACE: {candidates[0]}", flush=True)
    if module == "AlarmKit":
        print(source, flush=True)
    else:
        needles = {
            "AppIntents": ("protocol LiveActivityIntent", "openAppWhenRun", "supportedModes",
                          "protocol AppIntent", "struct IntentParameter", "extension Swift.String"),
            "ActivityKit": ("struct AlertSound", "static func named"),
            "Foundation": ("enum Weekday",),
        }[module]
        lines = source.splitlines()
        selected = set()
        for i, line in enumerate(lines):
            if any(needle in line for needle in needles):
                selected.update(range(max(0, i - 3), min(len(lines), i + 20)))
        for i in sorted(selected):
            print(f"{i + 1}: {lines[i]}", flush=True)
