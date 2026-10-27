xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm \
  -configuration Debug -destination "platform=iOS Simulator,id=$SIMULATOR_ID,arch=$(uname -m)" \
  -derivedDataPath DerivedData -resultBundlePath TestResults/TenList.xcresult \
  -only-testing:PuzzleAlarmUITests/AlarmManagementUITests/testEnableDisableAndFailureRetryAreHonest \
  -run-tests-until-failure -test-iterations 10 -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test-without-building
