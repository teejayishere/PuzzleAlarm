xcrun xccov view --report --json TestResults/Shell.xcresult > "$RUNNER_TEMP/app-coverage.json"
python3 Scripts/report_app_coverage.py "$RUNNER_TEMP/app-coverage.json"
