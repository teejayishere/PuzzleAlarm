set -o pipefail
xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath DerivedData -resultBundlePath TestResults/Application.xcresult \
  -only-testing:PuzzleAlarmTests/AlarmStoreTests -only-testing:PuzzleAlarmTests/AlarmEditorDraftTests \
  -only-testing:PuzzleAlarmTests/AlarmEnabledInputTests \
  -only-testing:PuzzleAlarmTests/PersistenceIntegrationTests \
  -parallel-testing-enabled NO -enableCodeCoverage YES CODE_SIGNING_ALLOWED=NO test \
  2>&1 | tee "$RUNNER_TEMP/application-tests.log"
