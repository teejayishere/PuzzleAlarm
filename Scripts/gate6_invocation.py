"""Construct the bounded invocation; help inspection is not an execution preflight."""
import re

METHODS = [('editor', 'testAudioPreviewStopsOnSelectionNavigationBackgroundAndRelaunch')]


def test_command(simulator_id, architecture, result_path, method):
    return ['xcodebuild', '-project', 'PuzzleAlarm.xcodeproj', '-scheme', 'PuzzleAlarm',
            '-configuration', 'Debug', '-destination',
            f'platform=iOS Simulator,id={simulator_id},arch={architecture}',
            '-derivedDataPath', 'DerivedData', '-resultBundlePath', str(result_path),
            f'-only-testing:PuzzleAlarmUITests/AlarmManagementUITests/{method}',
            '-parallel-testing-enabled', 'NO', '-test-timeouts-enabled', 'YES',
            '-maximum-test-execution-time-allowance', '600', 'CODE_SIGNING_ALLOWED=NO', 'test']


def check_advertised_options(help_text):
    # Check every option emitted by the shared command constructor. This only
    # detects missing option names, not valid values, destinations or execution.
    advertised = set(re.findall(r'^\s+(-[\w-]+)(?=\s|:)', help_text, re.MULTILINE))
    options = {arg.split(':', 1)[0] for arg in test_command('ID', 'arm64', 'result', METHODS[0][1])
               if arg.startswith('-')}
    missing = options - advertised
    if missing:
        raise ValueError('Selected Xcode does not advertise: ' + ', '.join(sorted(missing)))


if __name__ == '__main__':
    import sys
    from pathlib import Path
    check_advertised_options(Path(sys.argv[1]).read_text())
    print('Option names advertised; exact invocation and Simulator execution remain unvalidated.')
