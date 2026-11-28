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

The Tajny klient set (plan doc "First 10 minutes: Tajny klient", the sound phase), all original:
  mlask.wav      the MLASK sting (2 s): a hummed "m", a wet cartoon smack falling in pitch, a bass
                 hit, a sticker's slap and a three-bell sparkle with a short echo; never anyone's
                 real chewing
  drumroll.wav   Zbyszek's drumroll: a snare roll growing for 1.4 s, then the crash
  sting.wav      the mission-start sting (1.2 s): a noise-and-saw riser, an impact, a bright stab
  voice_kebabulo.wav, voice_kemal.wav, voice_zbyszek.wav, voice_fan.wav
                 each character's line blip: four syllables of a little square-and-formant voice,
                 low and lazy for Kebabulo, warm for Kemal, quick and high for Zbyszek
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


def _noise(n, seed):
    rnd = random.Random(seed)
    return [rnd.uniform(-1.0, 1.0) for _ in range(n)]


def mlask():
    out = []
    # the hummed "m": a short nasal 140 Hz
    n = int(RATE * 0.09)
    for i in range(n):
        t = i / RATE
        out.append(0.35 * (math.sin(math.tau * 140.0 * t) + 0.3 * math.sin(math.tau * 280.0 * t)) * env(i, n, 0.01, 0.03))
    # the wet smack: a pitch drop 1100 -> 140 Hz over 70 ms with a squelch of filtered noise
    n = int(RATE * 0.16)
    noise = _noise(n, 87)
    ph = 0.0
    lp = 0.0
    smack = []
    for i in range(n):
        t = i / RATE
        f = 140.0 + 960.0 * math.exp(-t / 0.022)
        ph += f / RATE
        lp += (noise[i] - lp) * 0.25
        smack.append((0.9 * math.sin(math.tau * ph) + 0.7 * lp) * math.exp(-t / 0.045))
    # the bass hit under it
    n = int(RATE * 0.5)
    bass = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += (48.0 + 40.0 * math.exp(-t / 0.03)) / RATE
        bass.append(1.1 * math.sin(math.tau * ph) * math.exp(-t / 0.16))
    # the sticker's slap: a bright click 0.12 s later
    n = int(RATE * 0.05)
    slap = [0.0] * int(RATE * 0.12) + [s * math.exp(-i / (RATE * 0.008)) for i, s in enumerate(_noise(n, 11))]
    hit = layer(smack, bass, slap)
    # the sparkle: C6 E6 G6 bells, then a held C7 with an echo
    bells = gap(0.3)
    for f in (1046.5, 1318.5, 1568.0):
        bells += tone(f, 0.07, 0.1, 0.002, 0.05, bell=0.4)
    bells += tone(2093.0, 0.6, 0.08, 0.002, 0.5, bell=0.5)
    bells = add_echo([0.45 * s for s in bells], 0.13, 0.3)
    tail = layer(hit, bells)
    return lowpass(out + tail + gap(0.05), 0.6)


def drumroll():
    out = []
    noise = _noise(int(RATE * 2.2), 5)
    k = 0
    t = 0.0
    hits = []
    while t < 1.4:
        hits.append(t)
        t += 0.042 - 0.012 * (t / 1.4)
    n = int(RATE * 2.1)
    out = [0.0] * n
    for h in hits:
        a = 0.25 + 0.75 * (h / 1.4) ** 1.6
        i0 = int(h * RATE)
        for i in range(int(RATE * 0.05)):
            if i0 + i >= n:
                break
            tt = i / RATE
            body = math.sin(math.tau * 190.0 * tt) * math.exp(-tt / 0.01)
            out[i0 + i] += a * (0.55 * noise[(i0 + i) % len(noise)] + 0.45 * body) * math.exp(-tt / 0.018)
        k += 1
    # the crash at 1.4 s: a long bright noise, high-passed, and a low hit
    i0 = int(RATE * 1.4)
    hp_prev = 0.0
    lp = 0.0
    for i in range(n - i0):
        tt = i / RATE
        x = noise[(i * 7) % len(noise)]
        lp += (x - lp) * 0.3
        hp = x - lp
        out[i0 + i] += (0.9 * hp * math.exp(-tt / 0.35) + 0.8 * math.sin(math.tau * 70.0 * tt) * math.exp(-tt / 0.12))
    return out


def sting():
    n = int(RATE * 0.5)
    noise = _noise(n, 3)
    riser = []
    ph = 0.0
    lp = 0.0
    for i in range(n):
        t = i / n
        ph += (180.0 + 900.0 * t * t) / RATE
        lp += (noise[i] - lp) * (0.05 + 0.5 * t)
        riser.append((0.35 * (2.0 * (ph % 1.0) - 1.0) + 0.5 * lp) * t * t)
    # the impact: a bass thump and a noise burst
    n = int(RATE * 0.7)
    noise = _noise(n, 9)
    impact = []
    ph = 0.0
    for i in range(n):
        t = i / RATE
        ph += (55.0 + 60.0 * math.exp(-t / 0.04)) / RATE
        impact.append(1.0 * math.sin(math.tau * ph) * math.exp(-t / 0.2) + 0.6 * noise[i] * math.exp(-t / 0.03))
    # the bright stab: A minor add9 on detuned saws, with an echo
    stab = []
    chord = (440.0, 523.25, 659.25, 987.77)
    n = int(RATE * 0.45)
    phs = [0.0] * 8
    for i in range(n):
        s = 0.0
        for k, f in enumerate(chord):
            for v, det in enumerate((1.0, 1.007)):
                phs[k * 2 + v] += f * det / RATE
                s += 2.0 * (phs[k * 2 + v] % 1.0) - 1.0
        stab.append(0.18 * s * env(i, n, 0.004, 0.35))
    stab = add_echo(lowpass(stab, 0.35), 0.11, 0.3)
    return riser + layer(impact, stab)


def _voice(base, spread, syll, seed, length=0.06):
    rnd = random.Random(seed)
    out = []
    for k in range(syll):
        f = base * (1.0 + rnd.uniform(-spread, spread))
        n = int(RATE * length * rnd.uniform(0.8, 1.2))
        ph = 0.0
        form = rnd.choice((700.0, 1100.0, 1600.0))
        ph2 = 0.0
        for i in range(n):
            ph += f / RATE
            ph2 += form / RATE
            sq = 1.0 if (ph % 1.0) < 0.5 else -1.0
            s = 0.55 * sq + 0.3 * math.sin(math.tau * ph) + 0.25 * math.sin(math.tau * ph2) * (0.5 + 0.5 * sq)
            out.append(s * env(i, n, 0.004, 0.025))
        out += gap(0.022)
    return lowpass(out, 0.3)


def voice_kebabulo():
    return _voice(150.0, 0.12, 4, 21, 0.075)


def voice_kemal():
    return _voice(210.0, 0.18, 4, 33, 0.065)


def voice_zbyszek():
    return _voice(320.0, 0.2, 4, 45, 0.05)


def voice_fan():
    return _voice(420.0, 0.24, 3, 57, 0.045)


SOUNDS = (("blip", blip), ("tune", tune), ("start", start), ("ring", ring),
          ("count", count), ("go", go), ("checkpoint", checkpoint), ("win", win), ("fail", fail),
          ("tick", tick), ("step", step), ("offer", offer), ("ping", ping),
          ("mlask", mlask), ("drumroll", drumroll), ("sting", sting),
          ("voice_kebabulo", voice_kebabulo), ("voice_kemal", voice_kemal), ("voice_zbyszek", voice_zbyszek), ("voice_fan", voice_fan))


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
