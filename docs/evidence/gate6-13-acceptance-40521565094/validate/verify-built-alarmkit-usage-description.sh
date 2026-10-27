python3 - <<'PY'
import pathlib, plistlib
path = pathlib.Path("DerivedData/Build/Products/Debug-iphonesimulator/PuzzleAlarm.app/Info.plist")
value = plistlib.loads(path.read_bytes()).get("NSAlarmKitUsageDescription")
if not isinstance(value, str) or not value.strip():
    raise SystemExit("Built app is missing NSAlarmKitUsageDescription")
print(f"Built app usage description: {value}")
camera = plistlib.loads(path.read_bytes()).get("NSCameraUsageDescription")
if not isinstance(camera, str) or not camera.strip():
    raise SystemExit("Built app is missing NSCameraUsageDescription")
print(f"Built camera usage description: {camera}")
photos = plistlib.loads(path.read_bytes()).get("NSPhotoLibraryAddUsageDescription")
if not isinstance(photos, str) or not photos.strip():
    raise SystemExit("Built app is missing NSPhotoLibraryAddUsageDescription")
print(f"Built QR image save usage description: {photos}")
PY
