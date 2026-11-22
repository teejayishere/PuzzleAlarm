"""Freeze finalized xcresult objects and logs before the artifact action reads them.

Staging is Xcode's live diagnostic workspace, not the finalized result objects.
Its omission and every read failure are explicit in the snapshot manifest.
"""
import argparse
import json
from pathlib import Path
import shutil
import zipfile


def preserve(result, logs, output):
    output.mkdir(parents=True, exist_ok=False)
    manifest = {"result": str(result), "excluded": [], "errors": [], "files": []}
    with zipfile.ZipFile(output / "xcresult.zip", "w", zipfile.ZIP_DEFLATED) as archive:
        if not result.is_dir():
            manifest["errors"].append(f"Missing result bundle: {result}")
        else:
            # Never traverse Staging: Simulator diagnostic collection can still
            # rename/delete trace files after xcodebuild exits or is cancelled.
            for child in sorted(result.iterdir()):
                if child.name == "Staging":
                    manifest["excluded"].append(f"{result.name}/Staging (live diagnostic workspace)")
                    continue
                files = sorted(child.rglob("*")) if child.is_dir() else [child]
                for source in files:
                    if not source.is_file():
                        continue
                    relative = f"{result.name}/{source.relative_to(result).as_posix()}"
                    try:
                        before = source.stat()
                        data = source.read_bytes()
                        after = source.stat()
                        if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                            raise OSError("File changed during snapshot")
                        archive.writestr(relative, data)
                        manifest["files"].append(relative)
                    except OSError as error:
                        manifest["errors"].append(f"{relative}: {error}")
    for source in logs:
        try:
            shutil.copyfile(source, output / source.name)
        except OSError as error:
            manifest["errors"].append(f"{source}: {error}")
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps({"snapshot_files": len(manifest["files"]),
                      "excluded": manifest["excluded"], "errors": manifest["errors"]}))
    return not manifest["errors"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("result", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("logs", nargs="+", type=Path)
    args = parser.parse_args()
    raise SystemExit(0 if preserve(args.result, args.logs, args.output) else 1)
