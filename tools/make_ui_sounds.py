"""Generate the little synth UI sounds (original, synthesised from scratch).

Usage: python3 -I tools/make_ui_sounds.py game/audio/ui [name ...]   (default: all)

Writes 22 kHz mono 16-bit WAVs:
  blip.wav   a soft two-note square blip for buttons (TIME, VHS, CAM...)
  tune.wav   a radio tuning burst: filtered static sweeping past a whistle
  start.wav  the title's "tap to drive": a rising arpeggio on a detuned saw
  ring.wav   a friend's call (hud.gd show_call, F 2026-11-10): a cheeky old-phone ringtone,
             eight bouncy square-and-sine notes, then the phone buzzing twice on the table

The gameplay feedback set (sound engine plan, step 1, 2026-11-19): what the game tells you, in
one arcade voice (the blip's square-and-sine, in C), short and dry so it reads over the engine:
  count.wav      a countdown's number (the drag race's and the boat race's 3-2-1): one A4 beep
  go.wav         START!/GO: A5 with a fifth, a quick upward bend, a short echo
  checkpoint.wav a ring or gate passed: two quick notes, E6 then A6
  win.wav        a race won, a job done: C5 E5 G5 rising into a held C6 and G5, a little echo
  fail.wav       a race lost, a run timed out: G4, E4, then C4 bending down, on a dull square
  tick.wav       each of a clock's last ten seconds: a dry woodblock click
  step.wav       a quest's next step: G5 then D6, soft bell partials
  offer.wav      a job or quest offered on a card: D6 F#6 A6, quick and light
  ping.wav       the game pointing something out (an alert note): one soft E6 ding
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


def tone(f, length, sq_mix=0.35, attack=0.003, release=0.05, bend=0.0, bend_t=0.02, bell=0.0):
    """One note in the HUD's voice: square and sine (`sq_mix` of square), an optional pitch blip
    at its start (`bend` up, over `bend_t` s) and inharmonic bell partials (`bell`)."""
    n = int(RATE * length)
    out = []
    ph = 0.0
    ph2 = ph3 = 0.0
    for i in range(n):
        b = 1.0 + bend * max(0.0, 1.0 - i / (RATE * bend_t)) if bend else 1.0
        ph += f * b / RATE
        sq = 1.0 if (ph % 1.0) < 0.5 else -1.0
        s = sq_mix * sq + (1.0 - sq_mix) * math.sin(math.tau * ph)
        if bell:
            ph2 += f * 2.76 / RATE
            ph3 += f * 5.4 / RATE
            decay = math.exp(-i / (RATE * 0.12))
            s += bell * decay * (0.6 * math.sin(math.tau * ph2) + 0.3 * math.sin(math.tau * ph3))
        out.append(s * env(i, n, attack, release))
    return out


def lowpass(out, smooth):
    y = 0.0
    for i, s in enumerate(out):
        y += (s - y) * smooth
        out[i] = y
    return out


def add_echo(out, delay, gain, repeats=3):
    d = int(RATE * delay)
    tail = out + [0.0] * (d * repeats)
    for i in range(d, len(tail)):
        tail[i] += gain * tail[i - d]
    return tail


def layer(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def gap(seconds):
    return [0.0] * int(RATE * seconds)


def count():
    return lowpass(tone(440.0, 0.14, 0.45, 0.002, 0.05), 0.4)


def go():
    a = tone(880.0, 0.42, 0.4, 0.002, 0.3, bend=-0.08, bend_t=0.04)
    e = tone(1318.5, 0.42, 0.25, 0.002, 0.3, bend=-0.08, bend_t=0.04)
    return add_echo(lowpass(layer(a, [0.6 * s for s in e]), 0.45), 0.09, 0.3)


def checkpoint():
    return lowpass(tone(1318.5, 0.055, 0.3, 0.002, 0.02) + tone(1760.0, 0.16, 0.3, 0.002, 0.12, bell=0.25), 0.5)


def win():
    out = []
    for f in (523.25, 659.25, 783.99):
        out += tone(f, 0.085, 0.4, 0.003, 0.03)
    held = layer(tone(1046.5, 0.75, 0.35, 0.004, 0.55, bell=0.2), [0.55 * s for s in tone(783.99, 0.75, 0.2, 0.004, 0.55)])
    return add_echo(lowpass(out + held, 0.35), 0.12, 0.28)


def fail():
    out = tone(392.0, 0.16, 0.6, 0.003, 0.04) + gap(0.03) + tone(329.63, 0.16, 0.6, 0.003, 0.04) + gap(0.03)
    # the last note sags a semitone and more as it dies: the arcade's "wah"
    n = int(RATE * 0.55)
    ph = 0.0
    for i in range(n):
        t = i / n
        ph += 261.63 * (1.0 - 0.12 * t * t) / RATE
        sq = 1.0 if (ph % 1.0) < 0.5 else -1.0
        vib = 1.0 + 0.15 * math.sin(math.tau * 6.0 * i / RATE)
        out.append((0.6 * sq + 0.4 * math.sin(math.tau * ph)) * vib * env(i, n, 0.003, 0.35))
    return lowpass(out, 0.18)


def tick():
    # a woodblock: a fast-decaying 1.2 kHz sine with a 3.1 kHz partial and a click of noise
    rnd = random.Random(10)
    n = int(RATE * 0.06)
    out = []
    for i in range(n):
        t = i / RATE
        d = math.exp(-t / 0.012)
        s = 0.8 * math.sin(math.tau * 1200.0 * t) + 0.3 * math.sin(math.tau * 3100.0 * t) * math.exp(-t / 0.005)
        s += 0.25 * rnd.uniform(-1.0, 1.0) * math.exp(-t / 0.002)
        out.append(s * d * min(1.0, i / (RATE * 0.0008)))
    return out


def step():
    return add_echo(lowpass(tone(783.99, 0.11, 0.15, 0.003, 0.05, bell=0.3) + tone(1174.66, 0.38, 0.15, 0.003, 0.3, bell=0.3), 0.45), 0.1, 0.22)


def offer():
    out = []
    for k, f in enumerate((1174.66, 1479.98, 1760.0)):
        out += tone(f, 0.06 if k < 2 else 0.2, 0.25, 0.002, 0.03 if k < 2 else 0.15)
    return lowpass(out, 0.45)


def ping():
    return lowpass(tone(1318.5, 0.26, 0.1, 0.002, 0.22, bell=0.35), 0.5)


SOUNDS = (("blip", blip), ("tune", tune), ("start", start), ("ring", ring),
          ("count", count), ("go", go), ("checkpoint", checkpoint), ("win", win), ("fail", fail),
          ("tick", tick), ("step", step), ("offer", offer), ("ping", ping))


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
