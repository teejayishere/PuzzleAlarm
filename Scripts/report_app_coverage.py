"""Summarize behavioral app coverage separately from core and SwiftUI rendering."""
import json
from pathlib import Path
import sys

document = json.loads(Path(sys.argv[1]).read_text())
behavior = {"AlarmStore.swift", "AlarmStorePresentation.swift", "AlarmEditorDraft.swift", "AlarmFormatting.swift", "AppEnvironment.swift"}
found = []
for target in document.get("targets", []):
    if target.get("name") != "PuzzleAlarm.app":
        continue
    for item in target.get("files", []):
        name = Path(item.get("path", "")).name
        if name not in behavior:
            continue
        found.append(name)
        print(f"{name}: {item.get('coveredLines')}/{item.get('executableLines')} lines")
        for function in item.get("functions", []):
            if function.get("executionCount", 0) == 0:
                print(f"  uncalled {function.get('lineNumber')}: {function.get('name')}")
            elif function.get("coveredLines", 0) < function.get("executableLines", 0):
                print(f"  partial {function.get('lineNumber')}: {function.get('name')} "
                      f"{function.get('coveredLines')}/{function.get('executableLines')} lines")
if not found:
    raise SystemExit("No production application behavior coverage found")
print("SwiftUI rendering and physical AlarmKit behavior are not inferred from line coverage.")
