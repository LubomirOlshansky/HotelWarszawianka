"""Generate the two short music loops inside Smoła (club.gd), synthesised from scratch.

Usage: python3 -I tools/make_club_loops.py game/audio/club

  smola_sala.wav   the room: 132 BPM techno, 8 bars (14.5 s). Four on the floor, an open hat
                   on the off-beat, a clap on 2 and 4, a rolling sixteenth bass in A minor
                   whose filter opens over the loop, a dark stab on the last bar.
  smola_patio.wav  the patio: 112 BPM deep house, 8 bars (17.1 s). A soft kick, shuffled hats,
                   minor-seventh chord stabs, a round sub bass.

No samples: every voice is written into a circular buffer, so the end runs into the start
without a click. The BPMs are club.gd's BPM and PATIO_BPM (TAŃCZ counts the beat from the
loop's playback position). 16-bit stereo WAV at 22050 Hz; Godot imports them looped (Forward)
with QOA compression.
"""
import math
import os
import random
import struct
import sys
import wave

RATE = 22050


def hz(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


class Loop:
    """A stereo circular buffer `bars` bars long at `bpm`."""

    def __init__(self, bpm, bars):
        self.beat = 60.0 / bpm
        self.n = int(round(bars * 4 * self.beat * RATE))
        self.l = [0.0] * self.n
        self.r = [0.0] * self.n

    def at(self, beat):
        return int(round(beat * self.beat * RATE))

    def put(self, sig, start, gain=1.0, pan=0.5):
        gl = gain * math.cos(pan * math.pi * 0.5) * 1.414
        gr = gain * math.sin(pan * math.pi * 0.5) * 1.414
        for i, s in enumerate(sig):
            j = (start + i) % self.n
            self.l[j] += s * gl
            self.r[j] += s * gr


def kick(rnd, punch=1.0, tone=50.0, decay=7.0, length=0.35):
    out = []
    ph = 0.0
    for i in range(int(length * RATE)):
        t = i / RATE
        f = tone + 140.0 * punch * math.exp(-t * 38.0)
        ph += f / RATE
        out.append(math.sin(ph * math.tau) * math.exp(-t * decay) + (rnd.random() - 0.5) * 0.3 * math.exp(-t * 400.0))
    return out


def noise_hit(rnd, length, decay, bright):
    """Noise through a one-pole high-pass (`bright` 0..1) with an exponential tail."""
    out = []
    prev_x = 0.0
    prev_y = 0.0
    a = 0.5 + 0.49 * bright
    for i in range(int(length * RATE)):
        x = rnd.random() * 2.0 - 1.0
        y = a * (prev_y + x - prev_x)
        prev_x, prev_y = x, y
        out.append(y * math.exp(-i / RATE * decay))
    return out


def clap(rnd):
    body = noise_hit(rnd, 0.22, 22.0, 0.55)
    out = [0.0] * len(body)
    for k, d in enumerate((0, 0.011, 0.022)):
        o = int(d * RATE)
        for i in range(len(body) - o):
            out[i + o] += body[i] * (0.6 if k < 2 else 1.0)
    return out


def saw_bass(f, length, cutoff, rnd, drive=1.6):
    """A saw through a resonant-ish two-pole low-pass, then soft-clipped."""
    out = []
    ph = rnd.random()
    y1 = y2 = 0.0
    n = int(length * RATE)
    for i in range(n):
        t = i / RATE
        ph = (ph + f / RATE) % 1.0
        x = 2.0 * ph - 1.0
        c = cutoff * (0.35 + 0.65 * math.exp(-t * 18.0))
        g = 1.0 - math.exp(-math.tau * c / RATE)
        y1 += g * (x - y1)
        y2 += g * (y1 - y2)
        env = min(1.0, t * 400.0) * min(1.0, (length - t) * 300.0)
        out.append(math.tanh(y2 * drive) * env)
    return out


def stab(freqs, length, cutoff, rnd, decay=6.0):
    out = [0.0] * int(length * RATE)
    for f in freqs:
        for det in (-0.006, 0.006):
            ph = rnd.random()
            y = 0.0
            g = 1.0 - math.exp(-math.tau * cutoff / RATE)
            for i in range(len(out)):
                ph = (ph + f * (1.0 + det) / RATE) % 1.0
                y += g * ((2.0 * ph - 1.0) - y)
                t = i / RATE
                out[i] += y * math.exp(-t * decay) * min(1.0, t * 300.0) / (len(freqs) * 2)
    return out


def sub(f, length):
    out = []
    for i in range(int(length * RATE)):
        t = i / RATE
        env = min(1.0, t * 200.0) * min(1.0, (length - t) * 200.0)
        out.append(math.sin(math.tau * f * t) * env)
    return out


def sala():
    rnd = random.Random(132)
    lp = Loop(132.0, 8)
    k = kick(rnd)
    hat = noise_hit(rnd, 0.16, 26.0, 0.97)
    tick = noise_hit(rnd, 0.04, 90.0, 0.99)
    cl = clap(rnd)
    for b in range(32):
        lp.put(k, lp.at(b), 0.95)
        lp.put(hat, lp.at(b + 0.5), 0.22, 0.6)
        for s in (0.25, 0.75):
            lp.put(tick, lp.at(b + s), 0.08 + 0.04 * rnd.random(), 0.35)
        if b % 2 == 1:
            lp.put(cl, lp.at(b), 0.35, 0.45)
    # The rolling bass: A minor sixteenths that skip the kick, the filter opening bar by bar.
    notes = [45, 45, 57, 45, 48, 45, 57, 52]
    for b in range(32):
        bar = b // 4
        cutoff = 260.0 + 140.0 * bar
        for s, step in enumerate((0.25, 0.5, 0.75)):
            m = notes[(b * 3 + s) % len(notes)]
            lp.put(saw_bass(hz(m), lp.beat * 0.22, cutoff, rnd), lp.at(b + step), 0.32)
    # The stab: a dark minor chord on the off-beats of the last bar, a call to the turn.
    chord = [hz(m) for m in (57, 60, 64, 69)]
    for b in (28.5, 29.5, 30.5, 31.0, 31.5):
        lp.put(stab(chord, lp.beat * 0.9, 1400.0, rnd), lp.at(b), 0.28, 0.55)
    return lp


def patio():
    rnd = random.Random(112)
    lp = Loop(112.0, 8)
    k = kick(rnd, punch=0.6, tone=55.0, decay=9.0, length=0.3)
    hat = noise_hit(rnd, 0.09, 45.0, 0.95)
    shaker = noise_hit(rnd, 0.05, 70.0, 0.9)
    cl = clap(rnd)
    for b in range(32):
        lp.put(k, lp.at(b), 0.8)
        lp.put(hat, lp.at(b + 0.5), 0.2, 0.62)
        # The shuffle: the second and fourth sixteenths late.
        for s in (0.27, 0.79):
            lp.put(shaker, lp.at(b + s), 0.07, 0.4)
        if b % 2 == 1:
            lp.put(cl, lp.at(b), 0.2, 0.5)
    # Am7 - Fmaj7 - Dm7 - Em7, two bars each: stabs on the "and" of 2 and 4, the sub on the roots.
    chords = [(45, (57, 60, 64, 67)), (41, (57, 60, 64, 65)), (38, (57, 60, 62, 65)), (40, (55, 59, 62, 64))]
    for c, (root, tones) in enumerate(chords):
        freqs = [hz(m) for m in tones]
        for bar in (0, 1):
            b0 = c * 8 + bar * 4
            for off in (1.5, 3.5):
                lp.put(stab(freqs, lp.beat * 0.7, 2200.0, rnd, decay=4.0), lp.at(b0 + off), 0.3, 0.45 if off < 2 else 0.58)
            for off, length in ((0.0, 1.4), (2.0, 0.6), (2.75, 1.0)):
                lp.put(sub(hz(root), lp.beat * length), lp.at(b0 + off), 0.42)
    return lp


def write(path, lp):
    peak = max(1e-6, max(max(abs(x) for x in lp.l), max(abs(x) for x in lp.r)))
    g = 0.89 / peak
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for a, b in zip(lp.l, lp.r):
            frames += struct.pack("<hh", int(max(-1.0, min(1.0, a * g)) * 32767), int(max(-1.0, min(1.0, b * g)) * 32767))
        w.writeframes(bytes(frames))
    print("%s: %.2f s" % (path, lp.n / RATE))


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    write(os.path.join(out, "smola_sala.wav"), sala())
    write(os.path.join(out, "smola_patio.wav"), patio())


if __name__ == "__main__":
    main()
