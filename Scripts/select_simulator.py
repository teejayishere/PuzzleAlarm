"""Select an available iPhone with a compatible iOS runtime, without a model name."""
import json
from pathlib import Path
import re
import sys

devices = json.loads(Path(sys.argv[1]).read_text())["devices"]
runtimes = json.loads(Path(sys.argv[2]).read_text())["runtimes"]
minimum = tuple(int(part) for part in sys.argv[3].split("."))
candidates = []
for runtime in runtimes:
    if not runtime.get("isAvailable", False):
        continue
    identifier = runtime["identifier"]
    if not identifier.startswith("com.apple.CoreSimulator.SimRuntime.iOS-"):
        continue
    version = tuple(int(part) for part in runtime["version"].split("."))
    if version < minimum:
        continue
    for device in devices.get(identifier, []):
        if device.get("isAvailable", False) and device["name"].startswith("iPhone"):
            udid = device["udid"]
            if re.fullmatch(r"[0-9A-Fa-f-]{36}", udid) is None:
                raise SystemExit("Unexpected Simulator UDID")
            candidates.append((version, device["name"], udid))

if not candidates:
    raise SystemExit(f"No available iPhone Simulator supports iOS {sys.argv[3]}+")
# Highest compatible runtime; stable name/UDID ordering within that runtime.
latest = max(item[0] for item in candidates)
selected = min(item for item in candidates if item[0] == latest)
print(selected[2])
print(f"Selected {selected[1]} / iOS {'.'.join(map(str, latest))}", file=sys.stderr)
