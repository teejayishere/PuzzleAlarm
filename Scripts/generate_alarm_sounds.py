"""Original deterministic mono 16-bit LPCM CAF assets; Python standard library only."""
import argparse
import math
from pathlib import Path
import struct

RATE = 22050
DURATION = 4
NAMES = ("harsh_buzzer", "rapid_beeps", "siren", "escalating")


def asset(name):
    samples = bytearray()
    for i in range(RATE * DURATION):
        t = i / RATE
        if name == "harsh_buzzer":
            value = math.sin(2 * math.pi * 180 * t) + .35 * math.sin(2 * math.pi * 540 * t)
        elif name == "rapid_beeps":
            value = math.sin(2 * math.pi * 1100 * t) if t % .2 < .1 else 0
        elif name == "siren":
            value = math.sin(2 * math.pi * 700 * t - 300 * math.cos(2 * math.pi * t))
        else:
            value = (0.25 + .75 * t / DURATION) * math.sin(2 * math.pi * (450 * t + 90 * t * t))
        # Short fades and headroom; preview also uses a reduced player volume.
        envelope = min(1, t / .01, (DURATION - t) / .01)
        samples.extend(struct.pack("<h", round(14000 * envelope * value)))
    desc = struct.pack(">d4sIIIII", RATE, b"lpcm", 12, 2, 1, 1, 16)
    return (b"caff\x00\x01\x00\x00" + b"desc" + struct.pack(">q", len(desc)) + desc
            + b"data" + struct.pack(">q", len(samples) + 4) + b"\x00" * 4 + samples)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--directory", type=Path, default=Path("PuzzleAlarm/Resources/Sounds"))
    args = parser.parse_args()
    for name in NAMES:
        path = args.directory / (name + ".caf")
        expected = asset(name)
        if args.check:
            if path.read_bytes() != expected:
                raise SystemExit(f"Nonreproducible sound: {path}")
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(expected)
        print(f"{path}: {len(expected)} bytes, {DURATION}s, {RATE}Hz mono LPCM")


if __name__ == "__main__":
    main()
