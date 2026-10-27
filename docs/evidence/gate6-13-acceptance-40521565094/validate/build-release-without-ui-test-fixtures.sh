set -o pipefail
xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Release -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath ReleaseDerivedData CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee "$RUNNER_TEMP/ios-release.log"
