xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath DerivedData -resultBundlePath TestResults/Editor.xcresult \
  -only-testing:PuzzleAlarmUITests/AlarmManagementUITests/testEditorEnabledTogglePersistsAfterRepeatedNativeInput \
  -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test
