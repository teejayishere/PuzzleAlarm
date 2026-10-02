"""Fail on new Xcode warnings; explicitly report the shell's SDK metadata advisory."""
from pathlib import Path
import re
import sys

advisory = "warning: Metadata extraction skipped. No AppIntents.framework dependency found."
unexpected = []
known_count = 0
for filename in sys.argv[1:]:
    for line in Path(filename).read_text(errors="replace").splitlines():
        if re.search(r"warning:", line, re.IGNORECASE):
            if "appintentsmetadataprocessor[" in line and line.endswith(advisory):
                known_count += 1
            else:
                unexpected.append(f"{filename}: {line}")
if unexpected:
    raise SystemExit("Unexpected Xcode warnings:\n" + "\n".join(unexpected))
print(f"No compiler/destination warnings. SDK metadata advisories observed: {known_count}.")
if known_count:
    print("Xcode skipped App Intents metadata because this Stage 2 shell has no AppIntents dependency.")
