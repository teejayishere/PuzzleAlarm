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
from gate6_invocation import METHODS, test_command

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
    for name, method in METHODS:
        args = test_command(os.environ['SIMULATOR_ID'], os.uname().machine,
                            ROOT / f'{name}.xcresult', method)
        # No nonexecuting exact-command validation is claimed. The first real
        # invocation can still fail on setup/options; count it separately.
        item = dict(name=name, declaration=method, executions=0, completed_tests=0,
                    status='TOOLING_FAILURE', command=args,
                    invocation_started=False, complete_capture=False, raw_integrity_valid=False,
                    capture_completeness='UNVERIFIED_PROCESS_CORRELATION')
        manifest['outcomes'].append(item)
        save()
        item['invocation_started'] = True
        save()
        try:
            code = command(args, name + '.log')
            item['exit'] = code
        finally:
            # Preserve observed starts even if export/capture later times out.
            item.update(assess({}, (ROOT / f'{name}.log').read_text(), method, item.get('exit')))
            save()
            try:
                export = command(['xcrun', 'xcresulttool', 'get', 'test-results', 'tests', '--path',
                                  str(ROOT / f'{name}.xcresult')], name + '-tests.json', END)
                item['result_export_exit'] = export
                tree = json.loads((ROOT / f'{name}-tests.json').read_text()) if export == 0 else {}
                item.update(assess(tree, (ROOT / f'{name}.log').read_text(), method, item.get('exit')))
            finally:
                # Raw capture remains independent of fallible xcresult export.
                item['integrity_exit'] = capture(name)
                item['raw_integrity_valid'] = item['integrity_exit'] == 0
            # A valid set of copied files cannot prove that every test process
            # and interaction is represented. Correlation needs evidence review.
            save()
        if item['status'] == 'ASSERTION_FAILURE_CAUSE_UNKNOWN':
            manifest['outcome'] = 'ASSERTION_FAILURE_CAUSE_UNKNOWN'
            break
        if item['status'] == 'TOOLING_FAILURE':
            break
        if not item['raw_integrity_valid']:
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
