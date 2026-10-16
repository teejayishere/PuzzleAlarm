"""Export named XCTest screenshots into a Windows-friendly, offline gallery."""
import hashlib
import html
import json
import os
from pathlib import Path
import shutil
import struct
import subprocess

SCREENS = [
    ("01-alarm-list", "Alarm list", "Saved 8:30 AM weekday alarm with Siren selected."),
    ("02-create-alarm", "Create alarm", "The existing Add Alarm form and native time wheel."),
    ("03-edit-alarm", "Edit alarm", "The existing Edit Alarm form for a saved alarm."),
    ("04-repeat", "Repeat configuration", "Weekdays selected through the ordinary Repeat screen."),
    ("05-math-configuration", "Math configuration", "Hard difficulty and six required correct answers."),
    ("06-memory-configuration", "Memory configuration", "Hard difficulty, nine digits, four seconds and two rounds."),
    ("07-sound-selection", "Sound selection", "The native sound picker showing the current bundled choices."),
    ("08-math-challenge", "Math challenge", "The deterministic 2 + 3 fixture, before answer entry."),
    ("09-memory-challenge", "Memory challenge", "Recall phase after the sequence has hidden; before answer entry."),
    ("10-qr-challenge", "QR challenge", "DEBUG fake scanner authorized. Simulator controls are visible; no real camera verification."),
    ("11-qr-code-display", "QR-code display", "The configured fixture QR code and native sharing entry point."),
]


def objects(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from objects(child)


def main():
    output = Path("TestResults/PuzzleAlarm-Visual-Demo")
    output.mkdir(parents=True, exist_ok=True)
    records = []
    found = {}
    for bundle in ("Management", "Math", "Memory", "QR"):
        destination = Path("TestResults/DemoAttachments") / bundle
        subprocess.run(["xcrun", "xcresulttool", "export", "attachments", "--path",
                        f"TestResults/{bundle}.xcresult", "--output-path", str(destination)], check=True)
        manifest = json.loads((destination / "manifest.json").read_text())
        for item in objects(manifest):
            name = item.get("suggestedHumanReadableName", "")
            for key, _, _ in SCREENS:
                if name.startswith("PuzzleAlarm-demo-" + key):
                    source = destination / item["exportedFileName"]
                    if key in found:
                        raise SystemExit(f"Duplicate demo screenshot: {key}")
                    data = source.read_bytes()
                    if data[:8] != b"\x89PNG\r\n\x1a\n":
                        raise SystemExit(f"Not a PNG: {source}")
                    width, height = struct.unpack(">II", data[16:24])
                    if width < 300 or height <= width:
                        raise SystemExit(f"Unexpected iPhone portrait dimensions: {width}x{height}")
                    shutil.copyfile(source, output / (key + ".png"))
                    found[key] = {"file": key + ".png", "width": width, "height": height,
                                  "sha256": hashlib.sha256(data).hexdigest(), "bundle": bundle,
                                  "attachment": item}
    missing = {key for key, _, _ in SCREENS} - found.keys()
    if missing:
        raise SystemExit(f"Missing required Simulator screenshots: {sorted(missing)}")
    for key, title, caption in SCREENS:
        records.append({"title": title, "caption": caption, **found[key]})
    evidence = {
        "capture_commit": os.environ["GITHUB_SHA"],
        "application_source_commit": "10be76a4b071c7c32b7f8e1938a0883f78d9e66e",
        "baseline_ci": "https://github.com/teejayishere/PuzzleAlarm/actions/runs/38923363999",
        "capture_run": f"{os.environ['GITHUB_SERVER_URL']}/{os.environ['GITHUB_REPOSITORY']}/actions/runs/{os.environ['GITHUB_RUN_ID']}",
        "toolchain": subprocess.check_output(["xcodebuild", "-version"], text=True).strip(),
        "simulator_id": os.environ["SIMULATOR_ID"],
        "simulators": json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "--json"], text=True)),
        "screens": records,
    }
    (output / "evidence.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    escape = html.escape
    cards = "\n".join(
        f'<article id="{key}"><h2>{escape(title)}</h2><p>{escape(caption)}</p>'
        f'<a href="{key}.png"><img src="{key}.png" alt="{escape(title)}" loading="lazy"></a>'
        f'<p><a href="{key}.png" download>Download PNG</a></p></article>'
        for key, title, caption in SCREENS)
    page = f'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>PuzzleAlarm — actual iPhone Simulator visual demo</title>
<style>body{{font:17px system-ui,sans-serif;line-height:1.5;background:#f3f4f6;color:#172033;margin:0}}
header,main,footer{{max-width:1150px;margin:auto;padding:24px}}a{{color:#164eb0}}
main{{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:24px}}
article{{background:white;border-radius:12px;padding:20px}}h1{{line-height:1.2}}
h2{{font-size:21px}}img{{display:block;width:100%;height:auto}}code{{overflow-wrap:anywhere}}</style>
<header><h1>PuzzleAlarm visual demo</h1><p>Actual iOS Simulator screenshots from the current app.
Documentation/evidence only. Stage 12 has not started.</p>
<p>These screens use existing deterministic DEBUG-only UI-test fixtures. Alarm scheduling effects and the QR
camera are simulated. No physical iPhone, real camera scan, audible alarm delivery or lock-screen behavior is verified.</p>
<p>Windows: extract the entire ZIP, then double-click <strong>index.html</strong>. Click any image for full size.
The PNG files also open directly in Photos. Everything in this gallery works offline; no Xcode or Mac is needed.</p>
<p>Application source: <code>{evidence['application_source_commit']}</code> ·
<a href="{evidence['baseline_ci']}">Successful main CI</a><br>
Capture revision: <code>{escape(evidence['capture_commit'])}</code> ·
<a href="{evidence['capture_run']}">Capture CI run</a> · <a href="evidence.json">Evidence metadata</a></p>
<p>Follow the numbered screens below for a still-image walkthrough. No video was recorded.</p></header>
<main>{cards}</main><footer>PNG screenshots are unmodified XCTest captures. The metadata records original
attachment provenance, dimensions, hashes and toolchain. CI success must be checked on the linked run.</footer></html>'''
    (output / "index.html").write_text(page, encoding="utf-8")
    (output / "README.txt").write_text(
        "PuzzleAlarm actual iPhone Simulator visual demo\n\n"
        "Windows: right-click the downloaded ZIP > Extract All. Open index.html in the extracted folder.\n"
        "Or open any numbered PNG directly in Photos. No Xcode, Mac or xcresult viewer is required.\n"
        "The gallery is an offline still-image walkthrough; no video was recorded.\n"
        "DEBUG fixtures simulate scheduler/camera effects. Physical device verification: NOT RUN.\n"
        f"Capture commit: {evidence['capture_commit']}\nCI: {evidence['capture_run']}\n", encoding="utf-8")
    print(f"Exported {len(records)} actual Simulator screenshots and offline gallery to {output}")


if __name__ == "__main__":
    main()
