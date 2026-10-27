"""Run one unchanged acceptance shell block within an absolute per-job budget."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

label = sys.argv[1]
output = Path("TestResults/acceptance-steps")
output.mkdir(parents=True, exist_ok=True)
script = output / (label + ".sh")
script.write_text(sys.stdin.read())
deadline = int(os.environ["ACCEPTANCE_START"]) + int(os.environ["ACCEPTANCE_MINUTES"]) * 60
record = dict(label=label, sha=os.environ["GITHUB_SHA"], run_id=os.environ["GITHUB_RUN_ID"],
              attempt=os.environ["GITHUB_RUN_ATTEMPT"], started=time.time(), deadline=deadline)
code = 124
try:
    remaining = deadline - time.time()
    if remaining <= 0:
        raise TimeoutError("Absolute acceptance deadline reached; no command started")
    with (output / (label + ".log")).open("w") as log:
        process = subprocess.Popen(["bash", "-e", "-o", "pipefail", str(script)],
                                   stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=remaining)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            simulator = os.environ.get("SIMULATOR_ID")
            if simulator:
                subprocess.run(["xcrun", "simctl", "shutdown", simulator], timeout=20, check=False)
            record["deadline_exceeded"] = True
except Exception as error:
    record["tooling_error"] = str(error)
finally:
    record.update(finished=time.time(), exit_code=code)
    (output / (label + ".json")).write_text(json.dumps(record, indent=2) + "\n")
    log_path = output / (label + ".log")
    if log_path.exists():
        print(log_path.read_text(errors="replace"))
    print(json.dumps(record))
sys.exit(code)
