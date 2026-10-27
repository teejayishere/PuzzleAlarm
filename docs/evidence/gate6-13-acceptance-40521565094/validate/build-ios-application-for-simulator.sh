set -o pipefail
xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build \
  2>&1 | tee "$RUNNER_TEMP/ios-build.log"
