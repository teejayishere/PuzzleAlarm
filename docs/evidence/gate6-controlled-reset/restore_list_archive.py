"""Restore the original Actions ZIP from lossless Git-preserved parts (no network)."""
import argparse
import hashlib
import json
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output", type=Path, help="New ZIP path; an existing file is never overwritten")
args = parser.parse_args()
root = Path(__file__).resolve().parent
manifest = json.loads((root / "list-archive-parts.json").read_text())
for part in manifest["parts"]:
    data = (root / part["file"]).read_bytes()
    if len(data) != part["bytes"] or hashlib.sha256(data).hexdigest() != part["sha256"]:
        raise ValueError("Part integrity failure: " + part["file"])
args.output.parent.mkdir(parents=True, exist_ok=True)
digest = hashlib.sha256()
size = 0
with args.output.open("xb") as output:
    for part in manifest["parts"]:
        data = (root / part["file"]).read_bytes()
        output.write(data)
        digest.update(data)
        size += len(data)
if size != manifest["original_bytes"] or digest.hexdigest() != manifest["original_sha256"]:
    raise ValueError("Restored ZIP integrity failure")
print(str(args.output.resolve()) + " SHA-256 " + digest.hexdigest())
