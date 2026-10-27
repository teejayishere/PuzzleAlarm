set -o pipefail
xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath DerivedData -resultBundlePath TestResults/Routing.xcresult \
  -only-testing:PuzzleAlarmTests/WakeUpRoutingTests \
  -only-testing:PuzzleAlarmUITests/WakeUpRoutingUITests \
  -parallel-testing-enabled NO -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO test-without-building \
  2>&1 | tee "$RUNNER_TEMP/routing-tests.log"
