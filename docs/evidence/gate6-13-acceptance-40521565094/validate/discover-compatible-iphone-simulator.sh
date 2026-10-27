xcrun simctl list devices available
xcrun simctl list devices available --json > "$RUNNER_TEMP/devices.json"
xcrun simctl list runtimes --json > "$RUNNER_TEMP/runtimes.json"
xcodebuild -project PuzzleAlarm.xcodeproj -scheme PuzzleAlarm -showdestinations
simulator_id="$(python3 Scripts/select_simulator.py "$RUNNER_TEMP/devices.json" "$RUNNER_TEMP/runtimes.json" 26.0)"
echo "id=$simulator_id" >> "$GITHUB_OUTPUT"
