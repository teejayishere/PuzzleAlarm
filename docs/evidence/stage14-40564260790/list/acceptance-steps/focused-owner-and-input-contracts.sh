xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath DerivedData -resultBundlePath TestResults/Contracts.xcresult \
  -only-testing:PuzzleAlarmTests/AlarmStoreTests \
  -only-testing:PuzzleAlarmTests/AlarmEnabledInputTests \
  -only-testing:PuzzleAlarmTests/AlarmEditorDraftTests \
  -only-testing:PuzzleAlarmTests/PersistenceIntegrationTests \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
