"""One sequential experiment. Absolute deadlines include setup; never retry a test."""
import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time

ROOT = Path('TestResults')
ROOT.mkdir(exist_ok=True)
RAW = ROOT / 'raw'
RAW.mkdir(exist_ok=True)
# Fixed for this authorized experiment, measured from the initial request handling.
START = datetime.datetime.fromisoformat('2026-10-17T23:29:33+00:00').timestamp()
TEST_END = START + 25 * 60 - 15  # reserve termination grace before minute 25
END = START + 30 * 60
manifest = dict(start_utc=START, test_deadline_utc=TEST_END, absolute_deadline_utc=END,
                sha=os.environ.get('GITHUB_SHA'), outcomes=[], outcome='INCOMPLETE',
                gates='6–12 HELD', overhead='Nonzero; formatting, clock reads, mapped stores and page residency effects remain.')


def save():
    (ROOT / 'outcome-manifest.json').write_text(json.dumps(manifest, indent=2))


def command(args, log, deadline=TEST_END):
    remaining = deadline - time.time()
    if remaining <= 0:
        raise TimeoutError('absolute budget exhausted')
    with (ROOT / log).open('w') as stream:
        process = subprocess.Popen(args, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            return process.wait(timeout=remaining)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGINT)
            try:
                process.wait(timeout=8)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            raise TimeoutError('test deadline reached; process group stopped')


def capture():
    # App processes are quiescent before the raw files are copied/decoded.
    subprocess.run(['xcrun', 'simctl', 'terminate', os.environ['SIMULATOR_ID'],
                    'com.teejayishere.PuzzleAlarm'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15)
    source = Path.home() / 'Library/Developer/CoreSimulator/Devices' / os.environ['SIMULATOR_ID'] / 'data/Containers/Data/Application'
    for path in source.glob('*/tmp/gate6-*.bin'):
        shutil.copyfile(path, RAW / path.name)
    return command(['python3', 'Scripts/gate6_decode.py', str(RAW)], 'decode.log', END)


try:
    save()
    methods = [('toggle', 'testEnableDisableAndFailureRetryAreHonest'),
               ('editor', 'testAudioPreviewStopsOnSelectionNavigationBackgroundAndRelaunch')]
    for name, method in methods:
        args = ['xcodebuild', '-project', 'PuzzleAlarm.xcodeproj', '-scheme', 'PuzzleAlarm',
                '-configuration', 'Debug', '-destination', f'platform=iOS Simulator,id={os.environ["SIMULATOR_ID"]},arch={os.uname().machine}',
                '-derivedDataPath', 'DerivedData', '-resultBundlePath', str(ROOT / f'{name}.xcresult'),
                f'-only-testing:PuzzleAlarmUITests/AlarmManagementUITests/{method}',
                '-test-iterations', '1', '-parallel-testing-enabled', 'NO',
                '-test-timeouts-enabled', 'YES', '-maximum-test-execution-time-allowance', '600',
                'CODE_SIGNING_ALLOWED=NO', 'test']
        manifest['outcomes'].append(dict(name=name, declaration=method, executions=1, status='started', command=args))
        save()
        code = command(args, name + '.log')
        manifest['outcomes'][-1].update(exit=code, status='PASS' if code == 0 else 'FAIL')
        integrity = capture()
        manifest['integrity_exit'] = integrity
        save()
        if code or integrity:
            manifest['outcome'] = 'RELEVANT_FAILURE' if code else 'INSTRUMENTATION_FAILURE'
            break
    else:
        manifest['outcome'] = 'INCONCLUSIVE'
except Exception as exc:
    manifest['outcome'] = 'STOPPED'
    manifest['reason'] = str(exc)
finally:
    try:
        manifest['integrity_exit'] = capture()
    except Exception as exc:
        manifest['capture_error'] = str(exc)
    manifest['negative_conclusion_allowed'] = False
    manifest['complete_capture'] = manifest.get('integrity_exit') == 0 and 'capture_error' not in manifest
    manifest['finished_utc'] = time.time()
    manifest['raw_sha256'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in RAW.glob('*.bin')}
    save()
raise SystemExit(0 if manifest['outcome'] == 'INCONCLUSIVE' else 1)
