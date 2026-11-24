#!/usr/bin/env python3
"""Create original, reproducible PCM alarm tones using only Python's standard library.

Run from any directory. Files are 44.1 kHz, 16-bit little-endian mono WAV;
peak amplitude is capped at 55% and all file/pulse boundaries have short ramps.
These are app resources, not evidence of AlarmKit playback on a physical device.
"""

import math
from pathlib import Path
import struct
import wave


SAMPLE_RATE = 44_100
DESTINATION = Path(__file__).resolve().parents[1] / "PuzzleAlarm" / "Resources" / "Sounds"


def edge(time, duration, ramp=0.012):
    return max(0.0, min(1.0, time / ramp, (duration - time) / ramp))


def tone(name, time, duration):
    if name == "harsh_buzzer":
        phase = 2 * math.pi * 180 * time
        return (math.sin(phase) + 0.4 * math.sin(3 * phase) + 0.2 * math.sin(5 * phase)) / 1.6
    if name == "rapid_beeps":
        pulse = time % 0.24
        return math.sin(2 * math.pi * 1_100 * time) * edge(pulse, 0.14)
    if name == "siren":
        # Integrated 600–1100 Hz frequency sweep; phase stays continuous.
        phase = 2 * math.pi * 850 * time - (250 / 0.8) * math.sin(2 * math.pi * 0.8 * time)
        return math.sin(phase)
    # Gradually increasing pitch and level, with no sudden final volume jump.
    phase = 2 * math.pi * (300 * time + 400 * time**3 / (3 * duration**2))
    return math.sin(phase) * (0.15 + 0.85 * time / duration)


def main():
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for name, duration in [("harsh_buzzer", 3), ("rapid_beeps", 3), ("siren", 4), ("escalating", 4)]:
        frames = bytearray()
        for index in range(SAMPLE_RATE * duration):
            time = index / SAMPLE_RATE
            amplitude = 0.55 * edge(time, duration) * tone(name, time, duration)
            frames.extend(struct.pack("<h", round(32_767 * max(-0.55, min(0.55, amplitude)))))
        path = DESTINATION / f"{name}.wav"
        with wave.open(str(path), "wb") as output:
            output.setnchannels(1)
            output.setsampwidth(2)
            output.setframerate(SAMPLE_RATE)
            output.writeframes(frames)
        print(f"Created {path.name}: {duration}s PCM mono")


if __name__ == "__main__":
    main()
