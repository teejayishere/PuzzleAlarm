set -euo pipefail
xcodegen generate --spec project.yml
xcrun simctl list devices available --json > "$RUNNER_TEMP/devices.json"
xcrun simctl list runtimes --json > "$RUNNER_TEMP/runtimes.json"
simulator_id="$(python3 Scripts/select_simulator.py "$RUNNER_TEMP/devices.json" "$RUNNER_TEMP/runtimes.json" 26.0)"
echo "SIMULATOR_ID=$simulator_id" >> "$GITHUB_ENV"
xcrun simctl bootstatus "$simulator_id" -b
