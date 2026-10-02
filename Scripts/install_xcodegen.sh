#!/bin/bash
set -euo pipefail

# Official release digest pinned with the version; no Homebrew/Mint dependency.
version="2.44.1"
digest="a2e905fb68446e9bb4008cdfe2e13e3f176d0cbcca828b71770f8e53fca91b73"
tool_dir="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/puzzlealarm-xcodegen.XXXXXX")"
archive="$tool_dir/xcodegen.zip"
curl --fail --location --silent --show-error \
  "https://github.com/yonaskolb/XcodeGen/releases/download/$version/xcodegen.zip" \
  --output "$archive"
echo "$digest  $archive" | shasum -a 256 --check
unzip -q "$archive" -d "$tool_dir"
generator="$(python3 - "$tool_dir" <<'PY'
from pathlib import Path
import sys

candidates = [p for p in Path(sys.argv[1]).rglob("xcodegen") if p.is_file()]
if len(candidates) != 1:
    raise SystemExit(f"Expected one XcodeGen executable, found {len(candidates)}")
print(candidates[0])
PY
)"
"$generator" --version
if [[ -n "${GITHUB_PATH:-}" ]]; then
  dirname "$generator" >> "$GITHUB_PATH"
else
  echo "Run this executable: $generator"
fi
