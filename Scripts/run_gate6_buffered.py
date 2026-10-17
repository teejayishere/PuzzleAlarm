"""One sequential experiment. Absolute deadlines include setup; never retry a test."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time
from gate6_accounting import assess

ROOT = Path('TestResults')
ROOT.mkdir(exist_ok=True)
RAW = ROOT / 'raw'
RAW.mkdir(exist_ok=True)
START = float(os.environ['GATE6_START'])
TEST_END = START + 25 * 60 - 15
END = START + 30 * 60
manifest = dict(start_utc=START, test_deadline_utc=TEST_END, absolute_deadline_utc=END,
                sha=os.environ.get('GITHUB_SHA'), run_id=os.environ.get('GITHUB_RUN_ID'),
                run_attempt=os.environ.get('GITHUB_RUN_ATTEMPT'), outcomes=[],
                outcome='TOOLING_FAILURE', gates='6–12 HELD',
                overhead='Nonzero; formatting, clock reads, mapped stores and page residency effects remain.')


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


def capture(name):
    subprocess.run(['xcrun', 'simctl', 'terminate', os.environ['SIMULATOR_ID'],
                    'com.teejayishere.PuzzleAlarm'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=15)
    source = Path.home() / 'Library/Developer/CoreSimulator/Devices' / os.environ['SIMULATOR_ID'] / 'data/Containers/Data/Application'
    destination = RAW / name
    destination.mkdir(exist_ok=True)
    for path in source.glob('*/tmp/gate6-*.bin'):
        # Keep each invocation's files separate; old files cannot satisfy new capture.
        if path.name not in manifest.get('seen_raw', []):
            shutil.copyfile(path, destination / path.name)
    code = command(['python3', 'Scripts/gate6_decode.py', str(destination)], name + '-decode.log', END)
    manifest.setdefault('seen_raw', []).extend(p.name for p in destination.glob('*.bin'))
    return code


try:
    save()
    methods = [('toggle', 'testEnableDisableAndFailureRetryAreHonest'),
               ('editor', 'testAudioPreviewStopsOnSelectionNavigationBackgroundAndRelaunch')]
    for name, method in methods:
        args = ['xcodebuild', '-project', 'PuzzleAlarm.xcodeproj', '-scheme', 'PuzzleAlarm',
                '-configuration', 'Debug', '-destination', f'platform=iOS Simulator,id={os.environ["SIMULATOR_ID"]},arch={os.uname().machine}',
                '-derivedDataPath', 'DerivedData', '-resultBundlePath', str(ROOT / f'{name}.xcresult'),
                f'-only-testing:PuzzleAlarmUITests/AlarmManagementUITests/{method}',
                '-parallel-testing-enabled', 'NO',
                '-test-timeouts-enabled', 'YES', '-maximum-test-execution-time-allowance', '600',
                'CODE_SIGNING_ALLOWED=NO', 'test']
        # The selected Xcode parses this exact invocation without UI execution.
        preflight = [a for a in args]
        index = preflight.index('-resultBundlePath')
        del preflight[index:index + 2]
        preflight.insert(1, '-dry-run')
        preflight_code = command(preflight, name + '-invocation-preflight.log')
        item = dict(name=name, declaration=method, executions=0, completed_tests=0,
                    status='TOOLING_FAILURE', command=args, preflight_exit=preflight_code,
                    invocation_started=False, complete_capture=False)
        manifest['outcomes'].append(item)
        save()
        if preflight_code:
            manifest['reason'] = 'selected-toolchain invocation preflight failed; no UI execution'
            break
        item['invocation_started'] = True
        save()
        try:
            code = command(args, name + '.log')
            item['exit'] = code
        finally:
            export = command(['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path',
                              str(ROOT / f'{name}.xcresult')], name + '-tests.json', END)
            item['result_export_exit'] = export
            tree = json.loads((ROOT / f'{name}-tests.json').read_text()) if export == 0 else {}
            item.update(assess(tree, (ROOT / f'{name}.log').read_text(), method, item.get('exit')))
            item['integrity_exit'] = capture(name)
            item['complete_capture'] = item['integrity_exit'] == 0
            save()
        if item['status'] == 'PRODUCT_FAILURE':
            manifest['outcome'] = 'CAPTURED_PRODUCT_FAILURE' if item['complete_capture'] else 'PRODUCT_FAILURE_INCOMPLETE_CAPTURE'
            break
        if item['status'] == 'TOOLING_FAILURE':
            break
        if not item['complete_capture']:
            manifest['outcome'] = 'INCOMPLETE_CAPTURE'
            break
    else:
        manifest['outcome'] = 'SUCCESSFUL_SAMPLES_INCONCLUSIVE'
except Exception as exc:
    manifest['reason'] = str(exc)
finally:
    manifest['negative_conclusion_allowed'] = False
    manifest['complete_capture'] = bool(manifest['outcomes']) and all(i['complete_capture'] for i in manifest['outcomes'])
    manifest['actual_test_executions'] = sum(i['executions'] for i in manifest['outcomes'])
    manifest['xcodebuild_ui_invocations'] = sum(i['invocation_started'] for i in manifest['outcomes'])
    manifest['finished_utc'] = time.time()
    manifest['raw_sha256'] = {str(p.relative_to(RAW)): hashlib.sha256(p.read_bytes()).hexdigest() for p in RAW.rglob('*.bin')}
    save()
raise SystemExit(0 if manifest['outcome'] == 'SUCCESSFUL_SAMPLES_INCONCLUSIVE' else 1)
