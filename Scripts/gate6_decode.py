"""Decode quiescent mapped files; fail closed on loss, corruption or absent attachment."""
import argparse
import json
import re
import struct
from pathlib import Path


def decode(data):
    if len(data) < 128:
        raise ValueError('short header')
    magic, version, capacity, stride, pid, attempted, committed, overflow, truncation, initialized = struct.unpack_from('<10Q', data)
    if (magic, version, stride, initialized) != (0x3146554236434744, 1, 1024, 1):
        raise ValueError('invalid header')
    if capacity < 1 or len(data) != 128 + capacity * stride or committed > capacity:
        raise ValueError('invalid size/count')
    errors = []
    records = []
    truncated = 0
    for index in range(committed):
        offset = 128 + index * stride
        seq, mono, wall, length, flags, checksum, reserved = struct.unpack_from('<QQQIIII', data, offset)
        if seq != index + 1 or length > stride - 40 or flags > 1 or reserved:
            errors.append(f'invalid record {index}')
            continue
        payload = data[offset + 40:offset + 40 + length]
        actual = 2166136261
        for byte in payload + struct.pack('<Q', seq) + data[offset + 8:offset + 32]:
            actual = ((actual ^ byte) * 16777619) & 0xffffffff
        if actual != checksum:
            errors.append(f'checksum {index}')
        truncated += flags
        records.append(dict(pid=pid, sequence=seq, monotonic_ns=mono, wall_ns=wall,
                            truncated=bool(flags), message=payload.decode('utf-8', errors='replace')))
    if attempted != committed + overflow or truncated != truncation:
        errors.append('counter mismatch or interrupted record')
    if any(b['monotonic_ns'] < a['monotonic_ns'] for a, b in zip(records, records[1:])):
        errors.append('time reversal')
    attachment = any('probe attached window=' in r['message'] for r in records)
    if not attachment:
        errors.append('missing attachment')
    if any('capture limited' in r['message'] for r in records):
        errors.append('bounded path/gesture capture incomplete')
    # New probes announce each snapshot, including empty lists. Validate cardinality
    # and order independently of byte/sequence integrity. Legacy omission markers
    # above remain fatal; old archives are never upgraded into complete captures.
    pending = None
    counted_gestures = any(r['message'].startswith('gesture list ') for r in records)
    for record in records:
        message = record['message']
        entry = re.fullmatch(r'gesture depth=(\d+) index=(\d+) object=.+', message)
        if counted_gestures and message.startswith('gesture depth=') and not entry:
            errors.append('invalid counted gesture')
        if pending is not None and entry:
            depth, count, seen = pending
            if (int(entry[1]), int(entry[2])) != (depth, seen) or seen >= count:
                errors.append('gesture list index/count mismatch')
            pending = (depth, count, seen + 1)
            continue
        if pending is not None and pending[1] != pending[2]:
            errors.append('gesture list incomplete')
        pending = None
        if message.startswith('gesture list '):
            listing = re.fullmatch(r'gesture list depth=(\d+) count=(\d+)', message)
            if listing:
                pending = (int(listing[1]), int(listing[2]), 0)
            else:
                errors.append('invalid gesture list')
        elif entry:
            errors.append('gesture missing list')
    if pending is not None and pending[1] != pending[2]:
        errors.append('gesture list incomplete')
    if overflow or truncation:
        errors.append('lost/truncated records')
    if not records or not records[0]['message'].startswith('process start uuid='):
        errors.append('missing process identity')
    return dict(pid=pid, attempted=attempted, committed=committed, overflow=overflow,
                truncation=truncation, attachment=attachment, errors=errors, records=records)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('directory', type=Path)
    args = parser.parse_args()
    reports = []
    for path in sorted(args.directory.glob('*.bin')):
        try:
            report = decode(path.read_bytes())
        except Exception as exc:
            report = dict(errors=[str(exc)], records=[])
        report['file'] = path.name
        reports.append(report)
    (args.directory / 'timelines.json').write_text(json.dumps(reports, indent=2))
    counters = [{k: v for k, v in r.items() if k != 'records'} for r in reports]
    (args.directory / 'integrity.json').write_text(json.dumps(counters, indent=2))
    return 0 if reports and all(not r['errors'] for r in reports) else 1


if __name__ == '__main__':
    raise SystemExit(main())
