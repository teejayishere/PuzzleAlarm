from pathlib import Path
from gate6_decode import decode
import sys

root = Path(sys.argv[1])
normal = decode((root / 'normal.bin').read_bytes())
assert not normal['errors'], normal
assert normal['records'][-1]['message'] == 'unicode π ✓'
gestures = decode((root / 'gestures.bin').read_bytes())
assert not gestures['errors'], gestures
assert sum(r['message'].startswith('gesture depth=') for r in gestures['records']) == 80
overflow = decode((root / 'overflow.bin').read_bytes())
assert overflow['overflow'] == 1 and overflow['errors']
truncated = decode((root / 'truncated.bin').read_bytes())
assert truncated['truncation'] == 1 and truncated['errors']
print('Actual Swift mmap writer/decoder roundtrip, overflow and truncation PASS')
