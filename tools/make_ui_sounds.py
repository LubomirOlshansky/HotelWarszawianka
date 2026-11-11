"""Generate the little synth UI sounds (original, synthesised from scratch).

Usage: python3 -I tools/make_ui_sounds.py game/audio/ui [name ...]   (default: all)

Writes 22 kHz mono 16-bit WAVs:
  blip.wav   a soft two-note square blip for buttons (TIME, VHS, CAM...)
  tune.wav   a radio tuning burst: filtered static sweeping past a whistle
  start.wav  the title's "tap to drive": a rising arpeggio on a detuned saw
  ring.wav   a friend's call (hud.gd show_call, F 2026-11-10): a cheeky old-phone ringtone,
             eight bouncy square-and-sine notes, then the phone buzzing twice on the table
"""
import math
import os
import random
import struct
import sys
import wave

RATE = 22050


def write(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.7 / peak
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * gain)) * 32767)) for s in samples))


def env(i, n, attack, release):
    t = i / RATE
    end = n / RATE
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (end - t) / release) if release > 0 else 1.0
    return max(0.0, a * r)


def blip():
    out = []
    for f, length in ((880.0, 0.045), (1318.5, 0.07)):
        n = int(RATE * length)
        ph = 0.0
        for i in range(n):
            ph += f / RATE
            sq = 1.0 if (ph % 1.0) < 0.5 else -1.0
            sine = math.sin(math.tau * ph)
            out.append((0.35 * sq + 0.65 * sine) * env(i, n, 0.003, 0.03))
    # a soft low-pass so the square isn't harsh
    y, smooth = 0.0, 0.35
    for i, s in enumerate(out):
        y += (s - y) * smooth
        out[i] = y
    return out


def tune():
    rnd = random.Random(87)
    n = int(RATE * 0.38)
    out = []
    lp = bp = 0.0
    ph = 0.0
    for i in range(n):
        t = i / n
        noise = rnd.uniform(-1.0, 1.0)
        # a sweeping band-pass over white noise: the dial passing stations
        cut = 0.08 + 0.5 * (0.5 + 0.5 * math.sin(t * math.tau * 1.6))
        lp += (noise - lp) * cut
        bp += (lp - bp) * 0.06
        hiss = (lp - bp)
        # a heterodyne whistle gliding down
        ph += (2400.0 - 1900.0 * t) / RATE
        whistle = 0.18 * math.sin(math.tau * ph) * math.sin(math.pi * t)
        out.append((hiss * 0.9 + whistle) * env(i, n, 0.01, 0.12))
    return out


def start():
    out = []
    notes = [261.63, 329.63, 392.0, 493.88, 523.25]  # C E G B C: a Cmaj7 rising
    for k, f in enumerate(notes):
        length = 0.09 if k < len(notes) - 1 else 0.5
        n = int(RATE * length)
        ph = [0.0, 0.0]
        for i in range(n):
            s = 0.0
            for v, det in enumerate((1.0, 1.006)):
                ph[v] += f * det / RATE
                s += 2.0 * (ph[v] % 1.0) - 1.0
            out.append(s * 0.5 * env(i, n, 0.004, 0.06 if k < len(notes) - 1 else 0.4))
    y = 0.0
    for i, s in enumerate(out):
        y += (s - y) * 0.22
        out[i] = y
    # a little echo
    d = int(RATE * 0.11)
    tail = out + [0.0] * (d * 3)
    for i in range(d, len(tail)):
        tail[i] += 0.35 * tail[i - d]
    return tail


def ring():
    out = []
    # E5 G5 B5 G5 · A5 E5 D5 G5: bouncy, a little off-kilter, ends up in the air.
    tune_notes = [659.25, 783.99, 987.77, 783.99, 880.0, 659.25, 587.33, 783.99]
    for k, f in enumerate(tune_notes):
        length = 0.12 if k % 4 != 3 else 0.2
        n = int(RATE * length)
        ph = 0.0
        for i in range(n):
            # a little pitch blip at each note's start: the cheap phone speaker's "boing"
            bend = 1.0 + 0.04 * max(0.0, 1.0 - i / (RATE * 0.025))
            ph += f * bend / RATE
            sq = 1.0 if (ph % 1.0) < 0.5 else -1.0
            sine = math.sin(math.tau * ph)
            out.append((0.4 * sq + 0.6 * sine) * env(i, n, 0.004, 0.05))
        out.extend([0.0] * int(RATE * (0.02 if k % 4 != 3 else 0.08)))
    y = 0.0
    for i, s in enumerate(out):
        y += (s - y) * 0.4
        out[i] = y
    # bzz bzz: the phone buzzing on the table (a low rattling square, two bursts)
    for burst in range(2):
        n = int(RATE * 0.16)
        ph = 0.0
        for i in range(n):
            ph += 155.0 / RATE
            rattle = (1.0 if (ph % 1.0) < 0.5 else -1.0) * (0.75 + 0.25 * math.sin(math.tau * 31.0 * i / RATE))
            out.append(0.45 * rattle * env(i, n, 0.01, 0.03))
        out.extend([0.0] * int(RATE * 0.08))
    y = 0.0
    for i in range(len(out) - int(RATE * 0.48), len(out)):
        y += (out[i] - y) * 0.3
        out[i] = y
    return out


SOUNDS = (("blip", blip), ("tune", tune), ("start", start), ("ring", ring))


def main(out_dir, only=()):
    os.makedirs(out_dir, exist_ok=True)
    for name, fn in SOUNDS:
        if only and name not in only:
            continue
        path = os.path.join(out_dir, name + ".wav")
        write(path, fn())
        print(path, os.path.getsize(path), "bytes")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
