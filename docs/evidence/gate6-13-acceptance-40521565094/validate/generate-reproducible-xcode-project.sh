xcodegen --version
xcodegen generate --spec project.yml
cp PuzzleAlarm.xcodeproj/project.pbxproj "$RUNNER_TEMP/first-project.pbxproj"
cp PuzzleAlarm.xcodeproj/xcshareddata/xcschemes/PuzzleAlarm.xcscheme "$RUNNER_TEMP/first-scheme.xcscheme"
cp .generated/PuzzleAlarm-Info.plist "$RUNNER_TEMP/first-info.plist"
xcodegen generate --spec project.yml
cmp PuzzleAlarm.xcodeproj/project.pbxproj "$RUNNER_TEMP/first-project.pbxproj"
cmp PuzzleAlarm.xcodeproj/xcshareddata/xcschemes/PuzzleAlarm.xcscheme "$RUNNER_TEMP/first-scheme.xcscheme"
cmp .generated/PuzzleAlarm-Info.plist "$RUNNER_TEMP/first-info.plist"
test -z "$(git ls-files '*.xcodeproj/*' '.generated/*')"
