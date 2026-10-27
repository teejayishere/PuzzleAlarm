"""One ordinary focused invocation, bounded by the job's absolute test deadline."""
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

label, *command = sys.argv[1:]
output = Path("TestResults")
output.mkdir(exist_ok=True)
# Reserve six minutes for preservation and account conservatively for runner
# allocation before the first step. No new input instrumentation or test retry.
deadline = int(os.environ["GATE6_RESET_START"]) + 34 * 60
remaining = deadline - time.time()
record = {"label": label, "sha": os.environ["GITHUB_SHA"],
          "run_id": os.environ["GITHUB_RUN_ID"], "attempt": os.environ["GITHUB_RUN_ATTEMPT"],
          "started": time.time(), "deadline": deadline, "command": command}
code = 124
try:
    if remaining <= 0:
        raise TimeoutError("Absolute test deadline already reached")
    with (output / (label + ".log")).open("w") as log:
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=remaining)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            # Stop Simulator-hosted tests too; preserve the containers/xcresult.
            subprocess.run(["xcrun", "simctl", "shutdown", os.environ["SIMULATOR_ID"]], timeout=20, check=False)
            record["deadline_exceeded"] = True
except Exception as error:
    record["tooling_error"] = str(error)
finally:
    record.update(finished=time.time(), exit_code=code)
    (output / (label + ".json")).write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps(record))
sys.exit(code)
