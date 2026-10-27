python3 - <<'PY'
from pathlib import Path
binary = Path("ReleaseDerivedData/Build/Products/Release-iphonesimulator/PuzzleAlarm.app/PuzzleAlarm").read_bytes()
for marker in [b"toggle-input-diagnostic.log", b"PUZZLE_UI_TEST", b"simulated-system.json", b"TestAlarmScheduler", b"FakeQRCodeScanner", b"Simulate matching QR"]:
    if marker in binary:
        raise SystemExit("DEBUG fixture leaked into Release: " + marker.decode())
print("Release contains no UI-test switches, fake scheduler or simulated-system storage.")
PY
