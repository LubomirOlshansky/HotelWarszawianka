"""Generate the game's sound effects and ambience (original, synthesised from scratch).

Usage: python3 -I tools/make_sfx.py game/audio/sfx [game/audio/radio] [--only=name,...]

No samples, no downloads: every sound is built here from oscillators, noise and
filters, in the same pure-Python way as make_music.py and make_ui_sounds.py.

Loops are made seamless the way the radio loops are: the excitation is periodic by
construction (pulses at whole-sample periods, noise generated once per loop length)
and every filter runs over the loop three times, keeping the last pass, so its state
at the end matches the start. Writes 16-bit 22.05 kHz WAVs: mono, except the city and
rain beds (stereo: they are wide and nothing sits in the middle). In Godot, import the
loops with loop mode Forward, loop end = the full length, QOA (tools/check_sfx.gd).

After writing, it prints a table per file: peak and RMS (dBFS), for loops the step
and the slope across the loop point against the 99.9th percentile elsewhere, the
share of energy below 2 kHz and the 85% roll-off frequency; and the radio loops'
levels (if their folder is given) to balance the buses against.

  engine_idle / engine_mid / engine_high   a tired 1.2 l four-cylinder hatchback at
      ~850, ~2400 and ~4500 rpm: firing pulses (one weak cylinder, a little timing
      jitter) through an exhaust and a small muffler, intake roar with load
  tyre_roll    the tyres on dry asphalt (low rumble), by speed
  tyre_wet     the hiss of tyres on a wet road
  tyre_squeal  a squeal for slides and hard braking
  rotor        a light helicopter: four-blade slap at ~18 Hz, turbine whine, tail rotor
  city_day / city_night   distant traffic beds (stereo)
  rain         a rain bed with droplets (stereo)
  thump_soft / thump_hard / crash / clang   collisions (clang: a guard rail)
  jar_clink / jar_break   the słoiki run's jars
  tram_bell    the tram's two-tone bell
  horn / horn_double      a small car's horn
  horn_player  the night-buses loop: the player's little hatch's own horn, one short bright
      "meep" (494 / 622 Hz, 0.3 s, a nasal square through a 1.3 kHz band): the B key and
      the HUD's horn button (buses.gd)
  nitro_whoosh G13b (car.gd nitro_started): the Kebab Boost lighting, 0.9 s: a low thump, then
      band-passed noise sweeping 500 -> 3,200 Hz and back, a hiss of gas on top
  pigeons      a flock flushing
  tram_creak   the vintage-tram loop (old_tram.gd): the old set's low creak, 1.1 s: a stick-slip
      pulse train wandering 70-110 Hz through two body resonances (380 / 820 Hz), swelling in
      and out
  old_tram_bell  the old set's own two-tone gong, 1.6 s: two strikes, 784 then 622 Hz, with
      the gong's inharmonic partials (lower and plainer than the modern tram_bell)
  coin           v1.0: the money pop's two-note ting (0.7 s)
  amb_river / amb_park / amb_square / amb_yard   v1.0: the districts' beds (sfx.gd DISTRICT_BEDS, 10 s loops)
  birds_a / birds_b       sparrow chirps, a whistled phrase (day)
  siren_far / dog_far     the night's rare distant events
  police_siren   loop 3g-2 (docs/design/police.md 10): the patrol car's two-tone siren,
      590 / 790 Hz for 0.5 s each, a soft square through a 3 kHz low-pass (a 1 s loop)
  police_whoop   a 0.35 s sweep 400 -> 1,100 Hz (a unit warns or joins)
  megaphone      the megaphone's chirp before a line: a 0.12 s band-passed noise burst, a
      1 kHz click
  whistle        the city guard's / the officer's whistle: two 0.15 s blasts at 2.9 kHz
      with a 20 Hz trill
  scribble       0.8 s of pencil strokes (filtered noise): the clamp's countdown
  stamp          a 120 Hz thud and a paper slap, 0.25 s: the end of a caution
  clank          partials at 600 / 1,700 Hz, 0.3 s: the clamp on and off
  club_leak      loop MW-5 (city_sounds.gd): a club's four-on-the-floor through a door,
      124 BPM, low-passed (a 7.7 s loop)
  metro_chime    our own three-note chime for a train below a metro entrance
  train_rumble / train_bridge   the railway audit (trains.gd): a train's wheels going by, 2.4 s:
      a swelling low rumble and two "tu-dum" bogie pairs over rail joints; on a bridge the
      girders' drone and ringing clacks
  train_horn     our own two-tone horn, 622 then 523 Hz, 1.5 s (a train out of a tunnel mouth)
  station_gong   our own four-tone platform gong (G4 C5 E5 C5), 2.6 s (a train pulling in)
  church_bell    one toll of a church bell (the hour is struck by repeating it)
  busker         an original street-guitar loop for the Patelnia at 19:00 (9.6 s)
  crowd_murmur   loop MW-3 (crowds.gd): a crowd talking, fourteen formant-noise voices in
      syllables and phrases, two soft laughs (an 8 s loop)
  steps_guitar   the guitarist on the river steps: the same three chords, G, C and D, at
      92 BPM, nylon-soft (a 15.7 s loop)
  bark_small / bark_mid / bark_big   loop MW-4 (city_life.gd): a dog's bark at a horn, three
      sizes (a long low dog, a squat flat-faced one, a big fluffy one): a glottal pulse train
      through formants, higher and shorter for the small dog, two yaps or one woof
  bike_bell      a bicycle's thumb bell: two strikes of a small bell, 0.6 s
  watch_beep     a running watch's double beep at 2.4 kHz as Kolka passes
  queue_chatter  a trend queue's chatter: six voices, closer and brighter than the murmur (a 6 s
      loop)
  phone_shutter  a phone's camera shutter: a click and a short noise slide, 0.15 s
  cafe_bell      a café door's bell: three little tings, 0.9 s
  frog_chime     loop MW-2: the Frogs shop's door, a two-note croak "kum-kum" and a ting, 0.8 s
  scooter_clatter loop MW-2: a Leżak knocked over: a clank, a thud, a rattle, 0.7 s
  fan_chant      the fans by Stadion Leguminy (fans.gd): a belly drum and a wordless crowd tune
      in unison at 120 BPM, a cheer at the phrase's end (an 8 s loop)
  gong_bowls     the sound-healing rings (wellness.gd): a gong every 6 s and a singing bowl between (a 12 s loop)
  techno_thump   the techno-yoga speaker (wellness.gd): a muffled four-on-the-floor at 128 BPM (a 7.5 s loop)
  jazz_trio      the jazz evenings under the Powiśle saucer (city_sounds.gd `jazz`): an original swung
      tune in F at 132 BPM, walking bass, ride and brushes, piano comping, vibraphone (a 14.5 s loop)

  --only=club_leak,busker  makes just those (the city's sounds: club_leak, metro_chime,
  church_bell, busker, crowd_murmur, steps_guitar; loop MW-4's bark_small, bark_mid, bark_big,
  bike_bell, watch_beep, queue_chatter, phone_shutter, cafe_bell; loop MW-2's frog_chime,
  scooter_clatter; the night-buses loop's horn_player; the vintage-tram loop's tram_creak,
  old_tram_bell; the railway audit's train_rumble, train_bridge, train_horn, station_gong) and leaves the other files as
  they are.
"""
import array
import cmath
import math
import os
import random
import struct
import sys
import wave

RATE = 22050
TAU = math.tau


# --- filters --------------------------------------------------------------------

def biquad(x, kind, f, q=0.707, loop=False):
    """RBJ biquad: 'lp', 'hp' or 'bp' (constant 0 dB peak). loop=True runs it over the
    signal three times and keeps the last pass (the periodic steady state)."""
    f = min(f, RATE * 0.45)
    w = TAU * f / RATE
    cw = math.cos(w)
    alpha = math.sin(w) / (2.0 * q)
    if kind == "lp":
        b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
    elif kind == "hp":
        b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
    else:
        b0, b1, b2 = alpha, 0.0, -alpha
    a0 = 1 + alpha
    a1 = -2 * cw / a0
    a2 = (1 - alpha) / a0
    b0 /= a0
    b1 /= a0
    b2 /= a0
    n = len(x)
    y = array.array("d", bytes(8 * n))
    x1 = x2 = y1 = y2 = 0.0
    for _ in range(3 if loop else 1):
        for i in range(n):
            xi = x[i]
            yi = b0 * xi + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2 = x1
            x1 = xi
            y2 = y1
            y1 = yi
            y[i] = yi
    return y


def onepole(x, f, loop=False):
    k = 1.0 - math.exp(-TAU * f / RATE)
    n = len(x)
    y = array.array("d", bytes(8 * n))
    s = 0.0
    for _ in range(3 if loop else 1):
        for i in range(n):
            s += (x[i] - s) * k
            y[i] = s
    return y


def mix(*parts):
    """Sum of (weight, signal) pairs, all the same length."""
    n = len(parts[0][1])
    out = array.array("d", bytes(8 * n))
    for w, sig in parts:
        for i in range(n):
            out[i] += w * sig[i]
    return out


def zeros(n):
    return array.array("d", bytes(8 * n))


def noise(n, rnd):
    return array.array("d", (rnd.uniform(-1.0, 1.0) for _ in range(n)))


def saturate(x, drive):
    k = math.tanh(drive)
    return array.array("d", (math.tanh(drive * v) / k for v in x))


def echo(x, taps, extra):
    """Sparse echoes (delay s, gain) for one-shots: a far, open-street feel."""
    out = array.array("d", list(x) + [0.0] * int(extra * RATE))
    for d, g in taps:
        k = int(d * RATE)
        for i in range(len(x)):
            if i + k < len(out):
                out[i + k] += g * x[i]
    return out


def fade(x, attack, release):
    n = len(x)
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    for i in range(min(a, n)):
        x[i] *= i / a
    for i in range(min(r, n)):
        x[n - 1 - i] *= i / r
    return x


def place(out, sig, at, gain=1.0):
    """Adds `sig` into `out` from sample `at`, wrapping round (loops) or clipped."""
    n = len(out)
    for i, v in enumerate(sig):
        out[(at + i) % n] += gain * v


def bell(n, partials, strike_noise=0.0, rnd=None):
    """Sum of decaying sines: (freq, amp, decay seconds)."""
    out = zeros(n)
    for f, amp, dec in partials:
        k = math.exp(-1.0 / (dec * RATE))
        e = amp
        w = TAU * f / RATE
        for i in range(n):
            out[i] += e * math.sin(w * i)
            e *= k
    if strike_noise and rnd:
        m = int(0.004 * RATE)
        for i in range(m):
            out[i] += strike_noise * rnd.uniform(-1, 1) * (1 - i / m)
    return out


# --- engine ---------------------------------------------------------------------

def engine(rpm, load, seconds, seed):
    """A small, slightly tired four-cylinder: two firings per revolution."""
    rnd = random.Random(seed)
    period = round(RATE / (rpm / 30.0))
    rpm = RATE / period * 30.0
    cycle = 4 * period
    n = cycle * max(1, round(seconds * RATE / cycle))
    cyl = [1.0, 0.93, 1.0, 0.8]           # cylinder four is a little weak
    pulse = zeros(n)
    rasp = zeros(n)
    tick = zeros(n)
    # narrow pulses: harmonics up into the phone speaker's range (it has no bass)
    width = max(3, min(period // 6, 34))
    hiss = noise(n, rnd)
    firings = n // period
    for k in range(firings):
        a = cyl[k % 4] * (1.0 + rnd.uniform(-0.07, 0.07))
        at = k * period + rnd.randint(-1, 1)
        for i in range(width):
            pulse[(at + i) % n] += a * math.sin(math.pi * i / width) ** 2
        # exhaust rasp: a burst of noise after every firing, louder under load
        burst = period // 2
        for i in range(burst):
            rasp[(at + i) % n] += hiss[(at + i) % n] * a * (1 - i / burst) ** 2
        # valve train: a tiny tick between firings
        tick[(at + period // 2) % n] += 0.6 + 0.3 * rnd.random()
    f_fire = rpm / 30.0
    body = mix(
        (0.6, biquad(pulse, "lp", max(8.0 * f_fire, 500.0), 0.8, True)),
        (0.7, biquad(pulse, "bp", 170.0, 2.5, True)),      # exhaust pipe
        (1.1, biquad(pulse, "bp", 430.0, 2.0, True)),      # small muffler
        (0.7, biquad(pulse, "bp", 680.0, 2.5, True)),      # a tinny back box
        (0.3, biquad(pulse, "bp", 1050.0, 3.0, True)),     # body panels
    )
    roar = biquad(biquad(rasp, "bp", 420.0 + 0.08 * rpm, 0.9, True), "lp", 1600.0, 0.7, True)
    clatter = biquad(tick, "bp", 1650.0, 6.0, True)
    # the cambelt, alternator and fan never stop: a soft continuous whirr between firings
    whirr = biquad(hiss, "bp", 880.0 + 0.1 * rpm, 1.4, True)
    out = mix((1.0, body), (0.5 + 1.0 * load, roar), (0.08, clatter), (0.05, whirr))
    out = saturate(out, 1.6)
    out = biquad(biquad(out, "lp", 2100.0, 0.7, True), "hp", 32.0, 0.7, True)
    return out, rpm


# --- tyres, rotor ---------------------------------------------------------------

def tyre_roll(seconds, seed):
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    w = noise(n, rnd)
    low = biquad(biquad(w, "lp", 260.0, 0.6, True), "lp", 340.0, 0.6, True)
    body = biquad(w, "bp", 110.0, 1.2, True)
    grain = biquad(w, "bp", 900.0, 0.8, True)
    hum = biquad(w, "bp", 520.0, 1.0, True)        # the tread on the asphalt
    out = mix((1.0, low), (0.5, body), (0.45, hum), (0.08, grain))
    # a slow surface texture: the road isn't perfectly even (whole cycles per loop)
    for i in range(n):
        t = i / n
        out[i] *= 1.0 + 0.12 * math.sin(TAU * 3 * t + 0.4) + 0.07 * math.sin(TAU * 7 * t + 1.9)
    return biquad(out, "hp", 30.0, 0.7, True)


def tyre_wet(seconds, seed):
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    w = noise(n, rnd)
    hiss = biquad(biquad(w, "hp", 1300.0, 0.7, True), "lp", 6500.0, 0.7, True)
    spray = biquad(w, "bp", 2600.0, 0.9, True)
    out = mix((1.0, hiss), (0.6, spray))
    for i in range(n):
        t = i / n
        out[i] *= 1.0 + 0.18 * math.sin(TAU * 5 * t) + 0.1 * math.sin(TAU * 11 * t + 2.0)
    return out


def tyre_squeal(seconds, seed):
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    # whole cycles of the base tone per loop, so the phase closes
    cycles = round(1180.0 * n / RATE)
    f0 = cycles * RATE / n
    ph = 0.0
    out = zeros(n)
    wob = [(2, 0.035, rnd.random()), (5, 0.02, rnd.random()), (13, 0.012, rnd.random())]
    for i in range(n):
        t = i / n
        dev = sum(a * math.sin(TAU * (c * t + p)) for c, a, p in wob)
        ph += f0 * (1.0 + dev) / RATE
        s = math.sin(TAU * ph) + 0.35 * math.sin(TAU * 2 * ph + 0.3) + 0.12 * math.sin(TAU * 3 * ph + 1.1)
        out[i] = s * (0.8 + 0.2 * math.sin(TAU * (9 * t + 0.2)))
    # FM is a sum of whole-cycle sines, so its integral over the loop is zero: the
    # phase ends where it began. Add a little rubber noise.
    grit = biquad(noise(n, rnd), "bp", 1500.0, 1.5, True)
    out = mix((1.0, out), (0.25, grit))
    return biquad(out, "lp", 4200.0, 0.7, True)


def rotor(seconds, seed):
    rnd = random.Random(seed)
    blade = 1225                      # 18 Hz: four blades at 4.5 rev/s
    n = blade * round(seconds * RATE / blade)
    slap = zeros(n)
    thump = zeros(n)
    w = noise(n, rnd)
    for k in range(n // blade):
        at = k * blade
        a = 1.0 if k % 4 else 1.12     # one blade a touch out of track
        m = blade // 3
        for i in range(m):
            env = (i / 40.0 if i < 40 else 1.0) * (1 - i / m) ** 3
            slap[(at + i) % n] += a * w[(at + i) % n] * env
        for i in range(60):
            thump[(at + i) % n] += a * math.sin(math.pi * i / 60)
    tail = zeros(n)
    tp = 450                          # 49 Hz tail rotor
    for k in range(n // tp):
        for i in range(20):
            tail[(k * tp + i) % n] += math.sin(math.pi * i / 20)
    whine = zeros(n)
    for i in range(n):
        t = i / n
        c = round(1520.0 * n / RATE)
        whine[i] = math.sin(TAU * c * t) + 0.3 * math.sin(TAU * 2 * c * t)
    out = mix(
        (1.0, biquad(slap, "bp", 480.0, 0.8, True)),
        (0.9, biquad(thump, "bp", 72.0, 1.4, True)),
        (0.25, biquad(tail, "bp", 300.0, 1.0, True)),
        (0.25, biquad(w, "bp", 140.0, 1.0, True)),
        (0.03, whine),
    )
    return biquad(saturate(out, 1.2), "lp", 3500.0, 0.7, True)


# --- beds -------------------------------------------------------------------------

def swells(n, rnd, count, width, shared=None):
    """A periodic envelope: soft bumps at random places (wrapped), 0..1."""
    env = zeros(n)
    times = shared if shared is not None else [rnd.random() for _ in range(count)]
    for c in times:
        for i in range(n):
            d = (i / n - c + 0.5) % 1.0 - 0.5
            env[i] += math.exp(-(d / width) ** 2)
    return env, times


def city(seconds, seed, night):
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    shared = None
    chans = []
    for ch in range(2):
        w = noise(n, rnd)
        rumble = biquad(biquad(w, "lp", 150.0 if night else 220.0, 0.6, True), "lp", 260.0, 0.6, True)
        mid = biquad(w, "bp", 520.0, 0.6, True)
        air = biquad(w, "hp", 3200.0, 0.7, True)
        env, shared = swells(n, rnd, 5 if night else 9, 0.035, shared)
        # the other channel hears the same passing cars, a little later
        if ch == 1:
            env = array.array("d", (env[(i - int(0.05 * RATE)) % n] for i in range(n)))
        out = zeros(n)
        for i in range(n):
            t = i / n
            slow = 0.75 + 0.15 * math.sin(TAU * (t + 0.1 * ch)) + 0.1 * math.sin(TAU * (3 * t + 0.4))
            out[i] = rumble[i] * slow * (0.8 if night else 1.0) + mid[i] * (0.07 + 0.24 * env[i]) * (0.7 if night else 1.0) \
                + air[i] * (0.004 if night else 0.008)
        chans.append(biquad(out, "hp", 28.0, 0.7, True))
    return chans


def rain(seconds, seed):
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    chans = []
    for ch in range(2):
        w = noise(n, rnd)
        wash = biquad(biquad(w, "hp", 500.0, 0.6, True), "lp", 7000.0, 0.6, True)
        patter = biquad(w, "bp", 1100.0, 0.5, True)
        drops = zeros(n)
        for _ in range(int(140 * seconds)):
            at = rnd.randrange(n)
            f = rnd.uniform(1800.0, 5200.0)
            a = rnd.uniform(0.2, 1.0) ** 2
            length = int(RATE * rnd.uniform(0.002, 0.006))
            for i in range(length):
                drops[(at + i) % n] += a * math.sin(TAU * f * i / RATE) * (1 - i / length) ** 2
        heavy = zeros(n)
        for _ in range(int(9 * seconds)):  # a few fat drops on metal and puddles
            at = rnd.randrange(n)
            sig = bell(int(0.05 * RATE), [(rnd.uniform(700, 1300), 1.0, 0.012), (rnd.uniform(2000, 3000), 0.5, 0.008)])
            place(heavy, sig, at, rnd.uniform(0.2, 0.5))
        out = mix((0.55, wash), (0.35, patter), (0.5, drops), (0.35, heavy))
        for i in range(n):
            t = i / n
            out[i] *= 1.0 + 0.08 * math.sin(TAU * (2 * t + 0.3 * ch))
        chans.append(biquad(out, "hp", 120.0, 0.7, True))
    return chans


# --- one-shots ------------------------------------------------------------------------

def thump(seconds, seed, hard):
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    exc = zeros(n)
    for i in range(int(0.006 * RATE)):
        exc[i] = rnd.uniform(-1, 1) + (1.0 if i < 30 else 0.0)
    body = mix((0.45, biquad(exc, "bp", 82.0, 3.0)), (0.6, biquad(exc, "bp", 165.0, 3.0)),
               (0.9, biquad(exc, "bp", 330.0, 3.0)), (0.8, biquad(exc, "bp", 520.0, 4.0)),
               (0.5, biquad(exc, "bp", 790.0, 5.0)))         # door and wing panels
    out = biquad(body, "lp", 1600.0, 0.7)
    if hard:
        crunch = zeros(n)
        w = noise(n, rnd)
        m = int(0.07 * RATE)
        for i in range(m):
            crunch[i] = w[i] * (1 - i / m) ** 1.5
        for _ in range(6):  # bits of trim rattling
            at = rnd.randrange(int(0.03 * RATE), int(0.25 * RATE))
            sig = bell(int(0.06 * RATE), [(rnd.uniform(900, 2400), 1.0, 0.02)])
            place(crunch, sig, at, rnd.uniform(0.1, 0.3))
        metal = mix((1.0, biquad(crunch, "bp", 950.0, 4.0)), (0.7, biquad(crunch, "bp", 1630.0, 5.0)),
                    (0.4, biquad(crunch, "bp", 2650.0, 6.0)), (0.3, crunch))
        out = mix((1.0, out), (0.45, metal))
    return fade(saturate(out, 1.4), 0.0, 0.05)


def crash(seed):
    rnd = random.Random(seed)
    a = thump(1.1, seed, True)
    b = thump(1.1, seed + 1, True)
    out = zeros(len(a))
    place(out, a, 0, 1.0)
    place(out, b[: len(a) - int(0.07 * RATE)], int(0.07 * RATE), 0.7)
    debris = zeros(len(a))
    for _ in range(14):
        at = rnd.randrange(int(0.1 * RATE), int(0.85 * RATE))
        sig = bell(int(0.08 * RATE), [(rnd.uniform(1200, 3600), 1.0, 0.015), (rnd.uniform(3000, 5000), 0.4, 0.01)])
        place(debris, sig, at, rnd.uniform(0.05, 0.2))
    out = mix((1.0, out), (1.0, debris))
    return fade(out, 0.0, 0.08)


def clang(seed):
    rnd = random.Random(seed)
    n = int(1.3 * RATE)
    ring = bell(n, [(282.0, 1.0, 0.45), (761.0, 0.7, 0.32), (1392.0, 0.45, 0.22), (2207.0, 0.25, 0.15),
                    (3290.0, 0.12, 0.09)], 0.6, rnd)
    hit = thump(1.3, seed, False)
    out = mix((0.75, ring), (0.8, hit))
    return fade(out, 0.0, 0.1)


def jar_clink(seed):
    rnd = random.Random(seed)
    n = int(0.45 * RATE)
    out = zeros(n)
    for k, at in enumerate((0.0, 0.085, 0.19)):
        f = rnd.uniform(2200, 2700)
        sig = bell(int(0.2 * RATE), [(f, 1.0, 0.06), (f * 1.53, 0.5, 0.04), (f * 2.31, 0.25, 0.025)], 0.3, rnd)
        place(out, sig[: n - int(at * RATE)], int(at * RATE), 1.0 / (k + 1))
    return fade(out, 0.0, 0.04)


def jar_break(seed):
    rnd = random.Random(seed)
    n = int(0.9 * RATE)
    out = zeros(n)
    w = noise(n, rnd)
    m = int(0.05 * RATE)
    for i in range(m):
        out[i] += 0.7 * w[i] * (1 - i / m) ** 2
    out = biquad(out, "hp", 1500.0, 0.7)
    for _ in range(30):
        at = rnd.randrange(0, int(0.6 * RATE))
        f = rnd.uniform(2000, 6500)
        sig = bell(int(0.1 * RATE), [(f, 1.0, 0.02), (f * 1.47, 0.5, 0.012)])
        place(out, sig[: n - at], at, rnd.uniform(0.08, 0.35) * (1 - at / n))
    thud = thump(0.9, seed, False)
    return fade(mix((1.0, out), (0.35, thud)), 0.0, 0.06)


def tram_bell(seed):
    rnd = random.Random(seed)
    n = int(1.4 * RATE)
    out = zeros(n)
    for at, f, g in ((0.0, 1175.0, 1.0), (0.17, 932.0, 0.9)):
        sig = bell(n - int(at * RATE), [(f, 1.0, 0.5), (f * 2.32, 0.35, 0.25), (f * 3.86, 0.15, 0.12),
                                        (f * 0.5, 0.2, 0.6)], 0.3, rnd)
        place(out, sig, int(at * RATE), g)
    return fade(out, 0.0, 0.1)


def horn(double):
    n = int((0.62 if double else 0.5) * RATE)
    out = zeros(n)
    toots = [(0.0, 0.16), (0.24, 0.36)] if double else [(0.0, 0.46)]
    for start, end in toots:
        for f in (415.0, 523.0):
            ph = 0.0
            for i in range(int(start * RATE), int(end * RATE)):
                ph += f / RATE
                sq = 1.0 if ph % 1.0 < 0.42 else -1.0
                t = (i - start * RATE) / RATE
                env = min(1.0, t / 0.012) * min(1.0, ((end - start) - t) / 0.03)
                out[i] += 0.5 * sq * env
    out = mix((0.5, biquad(out, "lp", 1800.0, 0.7)), (0.8, biquad(out, "bp", 1150.0, 2.0)))
    return saturate(out, 1.3)


def horn_player():
    """The night-buses loop: the hero hatch's horn, one short bright meep."""
    n = int(0.36 * RATE)
    out = zeros(n)
    start, end = 0.0, 0.3
    for f, amp in ((494.0, 0.5), (622.0, 0.42)):
        ph = 0.0
        for i in range(int(start * RATE), int(end * RATE)):
            ph += f / RATE
            sq = 1.0 if ph % 1.0 < 0.35 else -1.0
            t = (i - start * RATE) / RATE
            env = min(1.0, t / 0.008) * min(1.0, ((end - start) - t) / 0.04)
            out[i] += amp * sq * env
    out = mix((0.45, biquad(out, "lp", 2400.0, 0.7)), (0.9, biquad(out, "bp", 1300.0, 2.2)))
    return saturate(out, 1.5)


def nitro_whoosh(seed):
    """G13b: the nitro lights: a thump, then a rising and falling rush of air."""
    rnd = random.Random(seed)
    n = int(0.9 * RATE)
    w = noise(n, rnd)
    out = zeros(n)
    chunk = 441
    for a in range(0, n, chunk):
        t = a / n
        f = 500.0 + 2700.0 * math.sin(math.pi * min(1.0, t * 1.15)) ** 1.5
        seg = biquad(w[a:a + chunk * 2] if a + chunk * 2 <= n else w[a:], "bp", f, 1.6)
        env = min(1.0, t / 0.08) * (1.0 - t) ** 1.2
        for i in range(min(chunk, n - a)):
            out[a + i] = seg[i] * env
    thump_exc = zeros(n)
    for i in range(int(0.12 * RATE)):
        thump_exc[i] = math.sin(2 * math.pi * 70.0 * i / RATE) * math.exp(-i / (0.035 * RATE))
    hiss = biquad(w, "hp", 4500.0, 0.7)
    for i in range(n):
        hiss[i] *= 0.25 * (1.0 - i / n) ** 2
    return fade(saturate(mix((1.0, out), (0.8, thump_exc), (0.5, hiss)), 1.3), 0.004, 0.08)


def tram_creak(seed):
    """The vintage-tram loop: a low wooden-and-steel creak, stick-slip pulses through resonances."""
    rnd = random.Random(seed)
    n = int(1.1 * RATE)
    out = zeros(n)
    i = 0.0
    while i < n:
        t = i / n
        f = 70.0 + 40.0 * (0.5 - 0.5 * math.cos(TAU * t * 1.3)) + rnd.uniform(-6.0, 6.0)
        k = int(i)
        amp = math.sin(math.pi * t) ** 1.5 * rnd.uniform(0.6, 1.0)
        for m in range(min(18, n - k)):
            out[k + m] += amp * (1.0 - m / 18.0) * (1.0 if m < 3 else -0.4)
        i += RATE / f
    body = mix((0.9, biquad(out, "bp", 380.0, 4.0)), (0.55, biquad(out, "bp", 820.0, 5.0)),
               (0.25, biquad(out, "lp", 240.0, 0.7)))
    return fade(saturate(body, 1.4), 0.03, 0.12)


def old_tram_bell(seed):
    """The vintage-tram loop: the old set's two-tone gong, struck twice."""
    rnd = random.Random(seed)
    n = int(1.6 * RATE)
    out = zeros(n)
    for at, f, g in ((0.0, 784.0, 1.0), (0.24, 622.0, 0.85)):
        sig = bell(n - int(at * RATE), [(f, 1.0, 0.7), (f * 2.76, 0.3, 0.3), (f * 5.4, 0.12, 0.12),
                                        (f * 0.5, 0.25, 0.8)], 0.4, rnd)
        place(out, sig, int(at * RATE), g)
    return fade(out, 0.0, 0.15)


def pigeons(seed):
    rnd = random.Random(seed)
    n = int(1.7 * RATE)
    out = zeros(n)
    w = noise(n, rnd)
    for bird in range(6):
        t = rnd.uniform(0.0, 0.18)
        rate = rnd.uniform(10.0, 13.0)
        amp = rnd.uniform(0.5, 1.0)
        while t < 1.5:
            at = int(t * RATE)
            m = int(0.022 * RATE)
            for i in range(m):
                if at + i < n:
                    out[at + i] += amp * w[(at + i * 7 + bird * 991) % n] * math.sin(math.pi * i / m)
            t += 1.0 / rate
            rate = max(5.0, rate * 0.965)
            amp *= 0.955
    out = mix((1.0, biquad(out, "bp", 1300.0, 0.8)), (0.5, biquad(out, "bp", 3200.0, 1.0)))
    return fade(out, 0.005, 0.2)


def chirp(f0, f1, length, harm=0.15):
    n = int(length * RATE)
    out = zeros(n)
    ph = 0.0
    for i in range(n):
        t = i / n
        f = f0 + (f1 - f0) * t
        ph += f / RATE
        env = math.sin(math.pi * t) ** 1.5
        out[i] = env * (math.sin(TAU * ph) + harm * math.sin(TAU * 2 * ph))
    return out


def birds(seed, kind):
    rnd = random.Random(seed)
    n = int(2.4 * RATE)
    out = zeros(n)
    t = 0.05
    if kind == "a":       # sparrows: short downward chirps in clumps
        while t < 2.1:
            for _ in range(rnd.randint(2, 4)):
                sig = chirp(rnd.uniform(4300, 5200), rnd.uniform(3000, 3600), rnd.uniform(0.04, 0.07))
                place(out, sig[: n - int(t * RATE)], int(t * RATE), rnd.uniform(0.4, 1.0))
                t += rnd.uniform(0.08, 0.13)
            t += rnd.uniform(0.25, 0.5)
    else:                 # a whistled phrase, a pause, an answer
        for _ in range(2):
            for f0, f1, length in ((2300, 2900, 0.12), (2900, 2500, 0.09), (2200, 3300, 0.16), (3300, 2600, 0.2)):
                f0 *= rnd.uniform(0.95, 1.05)
                f1 *= rnd.uniform(0.95, 1.05)
                sig = chirp(f0, f1, length, 0.05)
                place(out, sig[: max(0, n - int(t * RATE))], int(t * RATE), 0.8)
                t += length + 0.03
            t += 0.45
    out = biquad(out, "lp", 6000.0, 0.7)
    return echo(out, [(0.09, 0.2), (0.23, 0.08)], 0.3)


def siren_far(seed):
    n = int(7.0 * RATE)
    out = zeros(n)
    ph = 0.0
    for i in range(n):
        t = i / RATE
        f = 950.0 + 320.0 * math.sin(TAU * t / 3.2 - 1.2)
        ph += f / RATE
        s = math.sin(TAU * ph) + 0.33 * math.sin(TAU * 3 * ph) + 0.2 * math.sin(TAU * 5 * ph)
        out[i] = s * min(1.0, t / 2.2) * min(1.0, (7.0 - t) / 2.6)
    out = biquad(biquad(out, "lp", 1300.0, 0.7), "lp", 1600.0, 0.7)
    return echo(out, [(0.12, 0.35), (0.26, 0.2), (0.41, 0.12)], 0.5)


# --- loop 3g-2: the police and the city guards (docs/design/police.md section 10) -----

def soft_square(ph, k=2.6):
    """A square wave with its corners rounded (tanh of a sine): `ph` in cycles."""
    return math.tanh(k * math.sin(TAU * ph)) / math.tanh(k)


def police_siren(seed):
    """Two tones, 0.5 s each, a whole number of cycles in each half (295 and 395), so every
    switch and the loop point fall on a zero crossing."""
    half = RATE // 2
    out = zeros(2 * half)
    for part, f in enumerate((590.0, 790.0)):
        for i in range(half):
            out[part * half + i] = soft_square(f * i / RATE)
    out = biquad(biquad(out, "lp", 3000.0, 0.7, loop=True), "lp", 3000.0, 0.7, loop=True)
    # A little air of the horn's bell: a second, quieter band round 1.4 kHz.
    body = biquad(out, "bp", 1400.0, 1.2, loop=True)
    return mix((1.0, out), (0.35, body))


def police_whoop(seed):
    n = int(0.35 * RATE)
    out = zeros(n)
    ph = 0.0
    for i in range(n):
        t = i / n
        f = 400.0 + 700.0 * (t ** 0.7)
        ph += f / RATE
        out[i] = soft_square(ph) * min(1.0, t * 12.0) * (1.0 - t) ** 0.6
    return fade(biquad(out, "lp", 3200.0, 0.7), 0.004, 0.03)


def megaphone(seed):
    rnd = random.Random(seed)
    n = int(0.16 * RATE)
    burst = noise(n, rnd)
    m = int(0.12 * RATE)
    for i in range(n):
        burst[i] *= (1.0 - i / m) ** 1.5 if i < m else 0.0
    burst = biquad(biquad(burst, "bp", 1500.0, 2.5), "bp", 1800.0, 1.5)
    click = bell(n, [(1000.0, 1.0, 0.012), (3000.0, 0.3, 0.006)])
    out = mix((1.0, burst), (0.6, click))
    return fade(saturate(out, 2.0), 0.0, 0.02)


def whistle(seed):
    rnd = random.Random(seed)
    blast = int(0.15 * RATE)
    gap = int(0.09 * RATE)
    n = 2 * blast + gap + int(0.05 * RATE)
    out = zeros(n)
    air = biquad(noise(n, rnd), "bp", 2900.0, 3.0)
    for b in range(2):
        at = b * (blast + gap)
        ph = 0.0
        for i in range(blast):
            t = i / RATE
            trill = math.sin(TAU * 20.0 * t)
            ph += (2900.0 + 90.0 * trill) / RATE
            env = min(1.0, i / (0.01 * RATE)) * min(1.0, (blast - i) / (0.02 * RATE))
            out[at + i] += (math.sin(TAU * ph) * (0.8 + 0.2 * trill) + 0.35 * air[at + i]) * env
    return out


def scribble(seed):
    rnd = random.Random(seed)
    n = int(0.8 * RATE)
    out = zeros(n)
    w = noise(n, rnd)
    at = 0
    while at < n - int(0.05 * RATE):
        stroke = int(rnd.uniform(0.04, 0.11) * RATE)
        g = rnd.uniform(0.5, 1.0)
        for i in range(min(stroke, n - at)):
            env = math.sin(math.pi * i / stroke) ** 2
            out[at + i] += w[at + i] * env * g
        at += stroke + int(rnd.uniform(0.0, 0.04) * RATE)
    out = mix((1.0, biquad(out, "bp", 3800.0, 1.4)), (0.4, biquad(out, "bp", 6500.0, 2.0)))
    return fade(out, 0.01, 0.05)


def stamp(seed):
    rnd = random.Random(seed)
    n = int(0.25 * RATE)
    thud = bell(n, [(120.0, 1.0, 0.05), (240.0, 0.35, 0.03)])
    slap = noise(n, rnd)
    m = int(0.03 * RATE)
    for i in range(n):
        slap[i] *= (1.0 - i / m) ** 2 if i < m else 0.0
    slap = biquad(slap, "bp", 2200.0, 1.0)
    return fade(mix((1.0, thud), (0.55, slap)), 0.0, 0.03)


def clank(seed):
    rnd = random.Random(seed)
    n = int(0.3 * RATE)
    out = bell(n, [(600.0, 1.0, 0.08), (1700.0, 0.6, 0.05), (2650.0, 0.25, 0.03)], 0.5, rnd)
    return fade(out, 0.0, 0.03)


def dog_far(seed):
    rnd = random.Random(seed)
    n = int(2.4 * RATE)
    out = zeros(n)
    for at in (0.0, 0.33, 1.25):
        m = int(rnd.uniform(0.11, 0.15) * RATE)
        bark = zeros(m)
        ph = 0.0
        for i in range(m):
            t = i / m
            f = 430.0 - 140.0 * t
            ph += f / RATE
            glottal = (ph % 1.0) ** 3
            bark[i] = (glottal - 0.25 + 0.3 * rnd.uniform(-1, 1)) * math.sin(math.pi * t) ** 0.6
        voiced = mix((1.0, biquad(bark, "bp", 560.0, 4.0)), (0.7, biquad(bark, "bp", 1250.0, 5.0)),
                     (0.3, biquad(bark, "bp", 2300.0, 6.0)))
        place(out, voiced[: n - int(at * RATE)], int(at * RATE), rnd.uniform(0.8, 1.0))
    out = biquad(out, "lp", 1700.0, 0.7)
    return echo(out, [(0.14, 0.3), (0.31, 0.15)], 0.4)


# --- loop MW-5: the city's sounds at the notebook's places (docs/design/vision.md 3.1, 3.5,
# 3.10) ----------------------------------------------------------------------------------

def club_leak(seed):
    """A club's bass through a closed door: a four-on-the-floor kick at 124 BPM, a muffled
    offbeat hat and a low saw riff, all behind a wall (low-passed at ~600 Hz). Four bars,
    a whole number of samples a beat, so it loops."""
    rnd = random.Random(seed)
    beat = round(RATE * 60.0 / 124.0)
    n = beat * 16
    out = zeros(n)
    kick = zeros(int(0.3 * RATE))
    ph = 0.0
    for i in range(len(kick)):
        t = i / RATE
        ph += (50.0 + 90.0 * math.exp(-t * 35.0)) / RATE
        kick[i] = math.tanh(2.0 * math.sin(TAU * ph)) * math.exp(-t * 9.0)
    hat = zeros(int(0.08 * RATE))
    w = noise(len(hat), rnd)
    for i in range(len(hat)):
        hat[i] = w[i] * math.exp(-i / RATE * 40.0)
    riff = [0, 0, 7, 0, 10, 0, 7, 5]  # semitones over A1, an eighth each, two bars
    for b in range(16):
        place(out, kick, b * beat, 1.0)
        place(out, hat, b * beat + beat // 2, 0.25)
    for k in range(32):
        f = 55.0 * 2 ** (riff[k % 8] / 12.0)
        m = beat // 2
        note = zeros(m)
        phs = 0.0
        for i in range(m):
            phs += f / RATE
            note[i] = (2.0 * (phs % 1.0) - 1.0) * math.exp(-i / RATE * 6.0) * min(1.0, i / 60.0) * min(1.0, (m - i) / 60.0)
        place(out, note, k * m, 0.6)
    # ~600 Hz: muffled, but the kick's knock and the riff's harmonics still reach a phone's speaker
    wall = biquad(biquad(out, "lp", 560.0, 0.8, True), "lp", 700.0, 0.6, True)
    return biquad(wall, "hp", 35.0, 0.7, True)


def metro_chime(seed):
    """Our own three-note chime (not the real one) for a train below: soft bell tones G5, B5,
    D6 a third of a second apart, in a tiled hall's echo."""
    rnd = random.Random(seed)
    n = int(2.2 * RATE)
    out = zeros(n)
    for k, f in enumerate((784.0, 988.0, 1175.0)):
        sig = bell(n - int(k * 0.32 * RATE), [(f, 1.0, 0.7), (f * 2.0, 0.25, 0.3), (f * 3.0, 0.08, 0.12)], 0.05, rnd)
        place(out, sig, int(k * 0.32 * RATE), 0.9)
    out = biquad(out, "lp", 3200.0, 0.7)
    return fade(echo(out, [(0.09, 0.3), (0.21, 0.18), (0.37, 0.1)], 0.5), 0.0, 0.3)


def church_bell(seed):
    """One toll of a church bell: the hum, prime, minor-third tierce, quint and nominal partials,
    the low ones ringing longest; the hour is struck by repeating it."""
    rnd = random.Random(seed)
    n = int(4.5 * RATE)
    f = 233.0
    parts = [(f * 0.5, 0.5, 3.2), (f, 0.9, 2.4), (f * 1.19, 0.6, 1.6), (f * 1.5, 0.35, 1.2), (f * 2.0, 0.55, 1.0),
             (f * 2.52, 0.25, 0.6), (f * 3.0, 0.15, 0.45), (f * 4.07, 0.08, 0.3)]
    out = bell(n, parts, 0.3, rnd)
    return fade(echo(biquad(out, "lp", 2800.0, 0.7), [(0.18, 0.25), (0.42, 0.12)], 0.0), 0.002, 0.4)


def busker(seed):
    """An original street-guitar loop for the Patelnia at 19:00: steel strings (Karplus-Strong)
    strumming Dm, G, C and A7 at 100 BPM, a bar each, down-down-up-up-down; four bars that
    loop (the last strum rings into the first)."""
    rnd = random.Random(seed)
    beat = round(RATE * 0.6)
    n = beat * 16
    out = zeros(n)
    chords = [[50, 57, 62, 65, 69], [43, 50, 55, 59, 62, 67], [48, 52, 55, 60, 64], [45, 52, 55, 61, 64]]
    strums = [(0.0, 1, 1.0), (1.0, 1, 0.7), (1.5, -1, 0.5), (2.5, -1, 0.5), (3.0, 1, 0.8)]

    def string(midi, length):
        period = RATE / (440.0 * 2 ** ((midi - 69) / 12.0))
        d = int(period)
        m = int(length * RATE)
        buf = [rnd.uniform(-1, 1) for _ in range(d + 1)]
        sig = zeros(m)
        p = 0
        for i in range(m):
            a = buf[p]
            b = buf[(p + 1) % (d + 1)]
            sig[i] = a
            buf[p] = 0.4985 * (a + b)
            p = (p + 1) % (d + 1)
        return sig

    cache = {}
    for bar in range(4):
        notes = chords[bar]
        for at, way, vel in strums:
            order = notes if way > 0 else list(reversed(notes))
            for j, m in enumerate(order):
                if m not in cache:
                    cache[m] = string(m, 1.4)
                t = int((bar * 4 + at) * beat + j * 0.012 * RATE + rnd.uniform(0, 0.004) * RATE)
                place(out, cache[m], t, vel * 0.3)
    body = mix((1.0, biquad(out, "lp", 3600.0, 0.7, True)), (0.4, biquad(out, "bp", 210.0, 1.2, True)))
    return biquad(body, "hp", 70.0, 0.7, True)


# --- loop MW-3: the crowds' sounds (docs/design/vision.md 3.1, 3.3) ------------------

def crowd_murmur(seed):
    """A crowd talking (a club's queue, the river steps): fourteen voices, each a band of
    noise at a voice's formants switched on and off in syllables (3-6 a second, in phrases
    with pauses), and two soft laughs; periodic by construction, 8 s, so it loops."""
    rnd = random.Random(seed)
    n = int(8.0 * RATE)
    out = zeros(n)
    w = noise(n, rnd)
    for v in range(14):
        f1 = rnd.uniform(380.0, 820.0)
        band = mix((1.0, biquad(w, "bp", f1, 2.2, True)), (0.45, biquad(w, "bp", f1 * rnd.uniform(2.2, 3.0), 2.5, True)))
        env = zeros(n)
        i = rnd.randrange(n)
        left = n
        while left > 0:
            phrase = int(rnd.uniform(0.8, 2.4) * RATE)
            rate = rnd.uniform(3.0, 6.0)
            for k in range(phrase):
                ph = k / RATE * rate
                env[(i + k) % n] += max(0.0, math.sin(TAU * ph)) ** 2 * min(1.0, k / 600.0, (phrase - k) / 600.0)
            gap = int(rnd.uniform(0.4, 1.6) * RATE)
            i = (i + phrase + gap) % n
            left -= phrase + gap
        gain = rnd.uniform(0.4, 1.0)
        for k in range(n):
            out[k] += band[k] * env[k] * gain
    for _ in range(2):
        at = rnd.randrange(n)
        f = rnd.uniform(500.0, 700.0)
        laugh = biquad(noise(int(0.9 * RATE), rnd), "bp", f, 3.0)
        for k in range(len(laugh)):
            t = k / RATE
            laugh[k] *= max(0.0, math.sin(TAU * 5.5 * t)) * math.exp(-t * 2.5) * 1.6
        place(out, laugh, at, 1.0)
    # a little distance: the top rolled off, no rumble
    return biquad(biquad(out, "lp", 2600.0, 0.7, True), "hp", 120.0, 0.7, True)


# --- loop MW-4: everyday life (city_life.gd; docs/design/vision.md 3.4, 3.7) ------------------

def bark(seed, size):
    """A dog's bark: a glottal pulse train with a falling pitch through three formants. `size`
    0 small (two quick yaps, high), 1 mid (two barks), 2 big (one deep woof)."""
    rnd = random.Random(seed)
    f0, f1, length, formants, times = [
        (900.0, 640.0, 0.075, (1400.0, 2600.0, 3900.0), (0.0, 0.16)),
        (560.0, 380.0, 0.12, (900.0, 1700.0, 2800.0), (0.0, 0.24)),
        (300.0, 190.0, 0.22, (520.0, 1100.0, 2100.0), (0.0,)),
    ][size]
    n = int(0.62 * RATE)
    out = zeros(n)
    for at in times:
        m = int(length * rnd.uniform(0.9, 1.1) * RATE)
        sig = zeros(m)
        ph = 0.0
        for i in range(m):
            t = i / m
            f = f0 + (f1 - f0) * t
            ph += f / RATE
            glottal = (ph % 1.0) ** 3
            sig[i] = (glottal - 0.25 + 0.25 * rnd.uniform(-1, 1)) * math.sin(math.pi * t) ** 0.5
        voiced = mix((1.0, biquad(sig, "bp", formants[0], 3.5)), (0.7, biquad(sig, "bp", formants[1], 4.5)),
                     (0.3, biquad(sig, "bp", formants[2], 5.0)))
        place(out, voiced[: n - int(at * RATE)], int(at * RATE), rnd.uniform(0.85, 1.0))
    out = biquad(out, "lp", 4200.0 - 900.0 * size, 0.7)
    return fade(echo(out, [(0.09, 0.18)], 0.15), 0.0, 0.05)


def bike_bell(seed):
    """A thumb bell: two strikes, partials of a small dome (inharmonic), 0.6 s."""
    rnd = random.Random(seed)
    n = int(0.6 * RATE)
    out = zeros(n)
    for at in (0.0, 0.16):
        sig = bell(n - int(at * RATE), [(2480.0, 1.0, 0.22), (3910.0, 0.5, 0.12), (5620.0, 0.25, 0.08),
                                        (1240.0, 0.15, 0.3)], 0.4, rnd)
        place(out, sig, int(at * RATE), 1.0 if at == 0.0 else 0.85)
    return fade(out, 0.0, 0.06)


def watch_beep(seed):
    """A running watch's double beep: two 70 ms tones at 2.4 kHz, a soft square."""
    n = int(0.3 * RATE)
    out = zeros(n)
    for start in (0.0, 0.12):
        a = int(start * RATE)
        for i in range(int(0.07 * RATE)):
            t = i / RATE
            env = min(1.0, t / 0.004) * min(1.0, (0.07 - t) / 0.006)
            out[a + i] += soft_square(2400.0 * t, 2.0) * env * 0.6
    return biquad(out, "lp", 5000.0, 0.7)


def queue_chatter(seed):
    """A trend queue's chatter: six voices in syllables (4-7 a second), brighter and closer than
    the crowd's murmur, a laugh, over a low murmur bed; periodic by construction, 6 s, so it loops."""
    rnd = random.Random(seed)
    n = int(6.0 * RATE)
    out = zeros(n)
    w = noise(n, rnd)
    for v in range(6):
        f1 = rnd.uniform(480.0, 950.0)
        band = mix((1.0, biquad(w, "bp", f1, 2.6, True)), (0.5, biquad(w, "bp", f1 * rnd.uniform(2.3, 3.1), 3.0, True)))
        env = zeros(n)
        i = rnd.randrange(n)
        left = n
        while left > 0:
            phrase = int(rnd.uniform(0.6, 1.8) * RATE)
            rate = rnd.uniform(4.0, 7.0)
            for k in range(phrase):
                ph = k / RATE * rate
                env[(i + k) % n] += max(0.0, math.sin(TAU * ph)) ** 2 * min(1.0, k / 500.0, (phrase - k) / 500.0)
            gap = int(rnd.uniform(0.6, 2.0) * RATE)
            i = (i + phrase + gap) % n
            left -= phrase + gap
        gain = rnd.uniform(0.5, 1.0)
        for k in range(n):
            out[k] += band[k] * env[k] * gain
    at = rnd.randrange(n)
    laugh = biquad(noise(int(0.7 * RATE), rnd), "bp", rnd.uniform(600.0, 800.0), 3.0)
    for k in range(len(laugh)):
        t = k / RATE
        laugh[k] *= max(0.0, math.sin(TAU * 6.0 * t)) * math.exp(-t * 3.0) * 1.4
    place(out, laugh, at, 1.0)
    # a low, steady murmur bed under the voices (the queue never goes silent between phrases)
    bed = biquad(biquad(noise(n, random.Random(seed + 1000)), "bp", 520.0, 1.2, True), "lp", 1200.0, 0.7, True)
    for k in range(n):
        out[k] += bed[k] * 0.25
    return biquad(biquad(out, "lp", 3600.0, 0.7, True), "hp", 160.0, 0.7, True)


def phone_shutter(seed):
    """A phone's shutter: a sharp click, then a short slide of filtered noise, 0.15 s."""
    rnd = random.Random(seed)
    n = int(0.15 * RATE)
    out = zeros(n)
    w = noise(n, rnd)
    for i in range(n):
        t = i / RATE
        click = math.exp(-t * 900.0) if t < 0.01 else 0.0
        slide = math.exp(-((t - 0.05) / 0.025) ** 2) * 0.5
        out[i] = w[i] * (click + slide)
    return mix((1.0, biquad(out, "bp", 3200.0, 1.2)), (0.5, biquad(out, "hp", 6000.0, 0.7)))


def cafe_bell(seed):
    """A café door's bell: three little tings on a spring, 0.9 s."""
    rnd = random.Random(seed)
    n = int(0.9 * RATE)
    out = zeros(n)
    for at, g in ((0.0, 1.0), (0.09, 0.7), (0.21, 0.45)):
        f = rnd.uniform(3150.0, 3350.0)
        sig = bell(n - int(at * RATE), [(f, 1.0, 0.3), (f * 1.49, 0.4, 0.18), (f * 2.13, 0.2, 0.1)], 0.2, rnd)
        place(out, sig, int(at * RATE), g)
    return fade(out, 0.0, 0.08)


def frog_chime(seed):
    """Loop MW-2: the Frogs shop's door chime, a two-note croak ("kum-kum"): two low-mid tones
    pulsed at a frog's 28 Hz, the second a fourth under, a soft ting over the first, 0.8 s."""
    rnd = random.Random(seed)
    n = int(0.8 * RATE)
    out = zeros(n)
    for at, f, g in ((0.0, 392.0, 1.0), (0.26, 294.0, 0.85)):
        m = int(0.24 * RATE)
        sig = zeros(m)
        for i in range(m):
            t = i / RATE
            env = math.sin(math.pi * min(1.0, t / 0.24)) ** 0.7
            pulse = 0.5 + 0.5 * math.sin(2.0 * math.pi * 28.0 * t)
            ph = 2.0 * math.pi * f * t
            sig[i] = env * pulse * (math.sin(ph) + 0.45 * math.sin(2.0 * ph) + 0.2 * math.sin(3.0 * ph))
        place(out, biquad(sig, "lp", 1800.0), int(at * RATE), g)
    ting = bell(n, [(2640.0, 0.25, 0.25), (3960.0, 0.08, 0.12)], 0.05, rnd)
    place(out, ting, 0, 1.0)
    return fade(out, 0.002, 0.1)


def scooter_clatter(seed):
    """Loop MW-2: a Leżak knocked over: its stem's clank, the deck's thud and a plastic rattle
    as it settles, 0.7 s."""
    rnd = random.Random(seed)
    n = int(0.7 * RATE)
    out = zeros(n)
    for at, g in ((0.0, 1.0), (0.11, 0.55), (0.19, 0.3)):
        f = rnd.uniform(820.0, 980.0)
        sig = bell(n - int(at * RATE), [(f, 1.0, 0.09), (f * 2.76, 0.5, 0.05), (f * 5.4, 0.25, 0.03)], 0.6, rnd)
        place(out, sig, int(at * RATE), g)
    thud = zeros(int(0.15 * RATE))
    for i in range(len(thud)):
        t = i / RATE
        thud[i] = math.exp(-t * 30.0) * math.sin(2.0 * math.pi * (90.0 - 200.0 * t) * t)
    place(out, thud, int(0.1 * RATE), 1.4)
    w = noise(n, rnd)
    for i in range(n):
        t = i / RATE
        w[i] *= 0.25 * math.exp(-((t - 0.3) / 0.12) ** 2) * (0.5 + 0.5 * math.sin(2.0 * math.pi * 45.0 * t))
    return fade(mix((1.0, out), (1.0, biquad(w, "bp", 2400.0, 1.0))), 0.0, 0.08)


def steps_guitar(seed):
    """The guitarist on the river steps: the same three chords (G, C, D at 92 BPM), a bar
    each with a lazy strum, nylon-soft (Karplus-Strong with more damping than the busker's),
    two rounds that loop."""
    rnd = random.Random(seed)
    beat = round(RATE * 60.0 / 92.0)
    n = beat * 24
    out = zeros(n)
    chords = [[43, 47, 50, 55, 59, 67], [48, 52, 55, 60, 64], [50, 57, 62, 66]]
    strums = [(0.0, 1, 1.0), (1.5, 1, 0.6), (2.0, -1, 0.45), (3.0, 1, 0.7)]

    def string(midi, length):
        period = RATE / (440.0 * 2 ** ((midi - 69) / 12.0))
        d = int(period)
        m = int(length * RATE)
        buf = [rnd.uniform(-1, 1) for _ in range(d + 1)]
        sig = zeros(m)
        p = 0
        for i in range(m):
            a = buf[p]
            b = buf[(p + 1) % (d + 1)]
            sig[i] = a
            buf[p] = 0.496 * (a + b)
            p = (p + 1) % (d + 1)
        return sig

    cache = {}
    for bar in range(6):
        notes = chords[bar % 3]
        for at, way, vel in strums:
            order = notes if way > 0 else list(reversed(notes))
            for j, m in enumerate(order):
                if m not in cache:
                    cache[m] = string(m, 1.6)
                t = int((bar * 4 + at) * beat + j * 0.018 * RATE + rnd.uniform(0, 0.006) * RATE)
                place(out, cache[m], t, vel * 0.3)
    body = mix((1.0, biquad(out, "lp", 2400.0, 0.7, True)), (0.5, biquad(out, "bp", 180.0, 1.1, True)))
    return biquad(body, "hp", 70.0, 0.7, True)


# --- v1.0 juice: the money pop and the districts' ambiences (money_pop.gd, sfx.gd) -----------

def coin(seed):
    """A payment's "ka-ching": a bright two-note ting (a fifth apart, the second later and
    longer) over a short metal tick, 0.7 s."""
    rnd = random.Random(seed)
    n = int(0.7 * RATE)
    out = zeros(n)
    for at, f, g in ((0.0, 1976.0, 0.8), (0.085, 2960.0, 1.0)):
        sig = bell(n - int(at * RATE), [(f, 1.0, 0.22), (f * 2.76, 0.35, 0.1), (f * 5.4, 0.12, 0.04)], 0.25, rnd)
        place(out, sig, int(at * RATE), g)
    return fade(echo(biquad(out, "hp", 700.0, 0.7), [(0.07, 0.15)], 0.0)[:n], 0.0, 0.12)


def _bed(seconds, seed, body):
    """Two channels of a loop bed: `body(rnd, n, ch)` returns one channel, high-passed."""
    rnd = random.Random(seed)
    n = int(seconds * RATE)
    return [biquad(body(rnd, n, ch), "hp", 30.0, 0.7, True) for ch in range(2)]


def amb_river(seed):
    """Powiśle: the Vistula under the boulevard: low water noise lapping in slow swells, little
    bubbling blips on top, a far gull now and then (10 s loop)."""
    def body(rnd, n, ch):
        w = noise(n, rnd)
        flow = biquad(biquad(w, "bp", 420.0, 0.5, True), "lp", 900.0, 0.6, True)
        hush = biquad(w, "bp", 1500.0, 0.5, True)
        out = zeros(n)
        ph = rnd.random()
        for i in range(n):
            t = i / n
            lap = 0.55 + 0.3 * math.sin(TAU * (2 * t + ph)) + 0.15 * math.sin(TAU * (5 * t + 0.3 * ch))
            out[i] = flow[i] * lap * 0.9 + hush[i] * 0.05 * lap
        for _ in range(26):
            f0 = rnd.uniform(500.0, 1100.0)
            sig = chirp(f0, f0 * rnd.uniform(1.4, 2.0), rnd.uniform(0.03, 0.07), 0.0)
            place(out, sig, rnd.randrange(n), rnd.uniform(0.04, 0.12))
        return out
    return _bed(10.0, seed, body)


def amb_park(seed):
    """Ujazdów and Łazienki: wind in big trees (slow gusts of mid noise), leaf rustle (fast
    soft hiss), a far blackbird phrase twice in the loop (10 s loop)."""
    def body(rnd, n, ch):
        w = noise(n, rnd)
        gust = biquad(biquad(w, "bp", 380.0, 0.5, True), "lp", 700.0, 0.6, True)
        leaf = biquad(w, "bp", 3600.0, 0.6, True)
        out = zeros(n)
        for i in range(n):
            t = i / n
            g = 0.45 + 0.35 * math.sin(TAU * (t + 0.2 * ch)) + 0.2 * math.sin(TAU * (3 * t + 0.1))
            out[i] = gust[i] * g * 0.8 + leaf[i] * 0.05 * g * g
        for at in (0.18, 0.67):
            t = at
            for f0, f1, length in ((2400, 3100, 0.14), (3100, 2200, 0.18), (2300, 3000, 0.12), (2900, 2500, 0.2)):
                sig = chirp(f0 * rnd.uniform(0.96, 1.04), f1, length, 0.05)
                place(out, sig, int(t * n), 0.07)
                t += (length + 0.04) * RATE / n
        return out
    return _bed(10.0, seed, body)


def amb_square(seed):
    """The Old Town and the Royal Route: a square's soft talk (voices as band-limited noise in
    shifting bursts), cobble footsteps ticking, a far fountain hiss (10 s loop)."""
    def body(rnd, n, ch):
        w = noise(n, rnd)
        talk = biquad(biquad(w, "bp", 700.0, 0.8, True), "lp", 1600.0, 0.6, True)
        fount = biquad(w, "bp", 2800.0, 0.5, True)
        env, _ = swells(n, rnd, 14, 0.02)
        out = zeros(n)
        for i in range(n):
            out[i] = talk[i] * (0.18 + 0.5 * env[i]) + fount[i] * 0.03
        for _ in range(22):
            m = int(0.018 * RATE)
            sig = zeros(m)
            f = rnd.uniform(700.0, 1300.0)
            for i in range(m):
                sig[i] = math.sin(TAU * f * i / RATE) * (1 - i / m) ** 3
            place(out, sig, rnd.randrange(n), rnd.uniform(0.05, 0.14))
        return out
    return _bed(10.0, seed, body)


def amb_yard(seed):
    """Praga and Muranów: wind through courtyards (a thin low whistle that wanders), a heavy
    tram or train rumbling far off twice in the loop, a far tap of metal (10 s loop)."""
    def body(rnd, n, ch):
        w = noise(n, rnd)
        whistle = biquad(w, "bp", 330.0, 6.0, True)
        wind = biquad(biquad(w, "bp", 260.0, 0.6, True), "lp", 520.0, 0.6, True)
        rumble = biquad(biquad(w, "lp", 90.0, 0.7, True), "lp", 120.0, 0.7, True)
        out = zeros(n)
        for i in range(n):
            t = i / n
            g = 0.5 + 0.3 * math.sin(TAU * (t + 0.3 * ch)) + 0.2 * math.sin(TAU * (2 * t))
            pass_by = math.exp(-((t - 0.3) / 0.07) ** 2) + 0.7 * math.exp(-((t - 0.78) / 0.06) ** 2)
            out[i] = wind[i] * g * 0.6 + whistle[i] * 0.55 * g * g + rumble[i] * (0.15 + 1.1 * pass_by)
        for _ in range(3):
            sig = bell(int(0.5 * RATE), [(rnd.uniform(900, 1500), 1.0, 0.09), (rnd.uniform(2300, 3100), 0.4, 0.05)], 0.2, rnd)
            place(out, sig, rnd.randrange(n), rnd.uniform(0.03, 0.07))
        return out
    return _bed(10.0, seed, body)


# --- output and checks ------------------------------------------------------------

def jazz_trio(seed):
    """The jazz evenings under the Powiśle saucer (crowds.gd's `jazz` site, city_sounds.gd's
    `jazz`): an original quartet tune at 132 BPM, swung, eight bars in F that loop (Gm7 C7 Fmaj7
    D7b9 Gm7 C7 | Am7 D7 | Gm7 C7). A walking upright bass (Karplus-Strong, damped, with a finger
    thump), a ride cymbal's ding-ding-a-ding (inharmonic partials over noise) and the hi-hat's
    chick on 2 and 4, brushes swishing on the snare, piano comping on rootless voicings, and a
    vibraphone's melody with its tremolo. Heard across the square from the stage: low-passed, a
    little room. Every note lands on the grid and tails wrap, so it loops (14.5 s)."""
    rnd = random.Random(seed)
    beat = round(RATE * 60.0 / 132.0)
    n = beat * 32
    sw = 2.0 / 3.0  # a swung eighth's "and"
    bass_out, ride_out, drum_out, piano_out, vib_out = zeros(n), zeros(n), zeros(n), zeros(n), zeros(n)

    def hz(m):
        return 440.0 * 2 ** ((m - 69) / 12.0)

    def at(bar, pos):
        return int((bar * 4 + pos) * beat + rnd.uniform(-0.004, 0.004) * RATE)

    # The bass: four walking notes a bar, the last a step into the next bar's root.
    walk = [[43, 45, 46, 47], [48, 46, 43, 42], [41, 45, 48, 51], [50, 48, 45, 44],
            [43, 46, 50, 49], [48, 52, 55, 46], [45, 48, 50, 44], [43, 50, 48, 44]]

    def pluck(m, length):
        period = RATE / hz(m)
        d = int(period)
        k = int(length * RATE)
        buf = [rnd.uniform(-1, 1) for _ in range(d + 1)]
        # A softer excitation (a finger, not a pick): smooth the burst first.
        for _ in range(3):
            buf = [(buf[i - 1] + buf[i] + buf[(i + 1) % (d + 1)]) / 3.0 for i in range(d + 1)]
        sig = zeros(k)
        p = 0
        for i in range(k):
            a = buf[p]
            b = buf[(p + 1) % (d + 1)]
            sig[i] = a * min(1.0, (k - i) / (0.03 * RATE))
            buf[p] = 0.4975 * (a + b)
            p = (p + 1) % (d + 1)
        # The finger's thump on the string.
        f0 = hz(m)
        for i in range(min(k, int(0.05 * RATE))):
            sig[i] += 0.5 * math.sin(TAU * f0 * i / RATE) * math.exp(-i / (0.012 * RATE))
        return sig

    for bar, notes in enumerate(walk):
        for b, m in enumerate(notes):
            place(bass_out, pluck(m, 0.95 * beat / RATE), at(bar, b), 1.0 if b % 2 == 0 else 0.85)

    # The ride: partials a little out of tune with each other over a hiss, a long shimmer.
    def ride():
        k = int(0.9 * RATE)
        parts = [(3170.0, 1.0, 0.5), (4410.0, 0.7, 0.4), (5230.0, 0.6, 0.35), (6870.0, 0.4, 0.3), (8120.0, 0.3, 0.25)]
        sig = bell(k, parts)
        hiss = biquad(noise(k, rnd), "hp", 5000.0, 0.7)
        for i in range(k):
            sig[i] = 0.25 * sig[i] + 0.5 * hiss[i] * math.exp(-i / (0.35 * RATE))
        return sig

    def chick():
        k = int(0.05 * RATE)
        w = biquad(noise(k, rnd), "bp", 7000.0, 1.0)
        return [w[i] * math.exp(-i / (0.01 * RATE)) for i in range(k)]

    def brush():
        k = int(0.2 * RATE)
        w = biquad(noise(k, rnd), "bp", 3200.0, 0.6)
        return [w[i] * min(1.0, i / (0.015 * RATE)) * math.exp(-i / (0.06 * RATE)) for i in range(k)]

    rd, ch, br = ride(), chick(), brush()
    for bar in range(8):
        for pos, g in ((0.0, 0.9), (1.0, 1.0), (1.0 + sw, 0.6), (2.0, 0.9), (3.0, 1.0), (3.0 + sw, 0.6)):
            place(ride_out, rd, at(bar, pos), g * rnd.uniform(0.85, 1.0))
        for pos in (1.0, 3.0):
            place(drum_out, ch, at(bar, pos), 0.7)
            place(drum_out, br, at(bar, pos), 0.8)
        if bar % 4 == 3:
            # A little fill into the next four bars: two brush taps.
            place(drum_out, br, at(bar, 3.0 + sw), 0.5)
            place(drum_out, br, at(bar, 2.0 + sw), 0.4)

    # The piano: rootless voicings, comped (Charleston, anticipations), a soft felt tone.
    G7, C7, F7, D7, A7 = [58, 62, 65, 69], [58, 62, 64, 69], [57, 60, 64, 67], [54, 57, 60, 63], [55, 60, 64, 67]
    comp = [[(0.0, G7, 0.35), (1.0 + sw, G7, 0.5)], [(sw, C7, 0.3), (2.0, C7, 0.6)],
            [(0.0, F7, 0.5), (2.0 + sw, F7, 0.4)], [(1.0 + sw, D7, 0.5), (3.0 + sw, G7, 0.4)],
            [(1.0, G7, 0.35), (2.0 + sw, G7, 0.4)], [(0.0, C7, 0.35), (1.0 + sw, C7, 0.6)],
            [(0.0, A7, 0.5), (2.0, D7, 0.5)], [(0.0, G7, 0.5), (2.0, C7, 0.4), (3.0 + sw, G7, 0.3)]]
    tones = {}

    def piano(m, length):
        key = (m, round(length, 2))
        if key in tones:
            return tones[key]
        k = int((length + 0.12) * RATE)
        f0 = hz(m)
        sig = zeros(k)
        for h in range(1, 9):
            f = f0 * h * (1.0 + 0.0004 * h * h)
            if f > RATE * 0.45:
                break
            amp = 1.0 / h ** 1.4
            dec = 1.2 / (1.0 + 0.6 * h)
            w = TAU * f / RATE
            for i in range(k):
                sig[i] += amp * math.sin(w * i) * math.exp(-i / (dec * RATE))
        r = int(0.12 * RATE)
        for i in range(r):
            sig[k - 1 - i] *= i / r
        for i in range(int(0.004 * RATE)):
            sig[i] *= i / (0.004 * RATE)
        tones[key] = sig
        return sig

    for bar, hits in enumerate(comp):
        for pos, chord, length in hits:
            for j, m in enumerate(chord):
                place(piano_out, piano(m, length * 60.0 / 132.0 * 2.0), at(bar, pos) + int(j * 0.006 * RATE), 0.22)

    # The vibraphone: a sine with its 4x partial, the motor's tremolo, damped at the note's end.
    tune = [[(1.0, 70, 0.6), (1.0 + sw, 72, 0.3), (2.0, 74, 0.9), (3.0, 77, 0.6), (3.0 + sw, 76, 0.3)],
            [(0.0, 74, 0.6), (sw, 72, 0.3), (1.0, 70, 0.6), (1.0 + sw, 69, 0.3), (2.0, 67, 1.4), (3.0 + sw, 68, 0.3)],
            [(0.0, 69, 1.8), (2.0, 72, 0.6), (2.0 + sw, 76, 0.3), (3.0, 79, 1.0)],
            [(0.0, 78, 0.6), (sw, 75, 0.3), (1.0, 74, 0.6), (1.0 + sw, 72, 0.3), (2.0, 69, 0.6), (2.0 + sw, 66, 0.3), (3.0, 69, 1.0)],
            [(0.0, 70, 1.5), (1.0 + sw, 74, 0.3), (2.0, 77, 0.6), (2.0 + sw, 81, 0.3), (3.0, 79, 1.0)],
            [(0.0, 76, 0.6), (sw, 79, 0.3), (1.0, 82, 1.0), (2.0, 81, 0.6), (2.0 + sw, 79, 0.3), (3.0, 76, 1.0)],
            [(0.0, 72, 1.0), (1.0, 76, 0.6), (1.0 + sw, 72, 0.3), (2.0, 78, 0.6), (2.0 + sw, 74, 0.3), (3.0, 72, 0.6), (3.0 + sw, 69, 0.3)],
            [(0.0, 70, 1.0), (1.0, 67, 0.6), (1.0 + sw, 70, 0.3), (2.0, 69, 0.6), (2.0 + sw, 67, 0.3), (3.0, 64, 1.0)]]

    def vibe(m, beats):
        length = beats * 60.0 / 132.0
        k = int((length + 0.08) * RATE)
        f0 = hz(m)
        sig = zeros(k)
        for i in range(k):
            t = i / RATE
            trem = 1.0 - 0.28 * (0.5 + 0.5 * math.sin(TAU * 5.6 * t))
            v = math.sin(TAU * f0 * t) * math.exp(-t / 1.4) + 0.22 * math.sin(TAU * f0 * 3.98 * t) * math.exp(-t / 0.25)
            v += 0.1 * math.sin(TAU * f0 * 9.2 * t) * math.exp(-t / 0.04)
            sig[i] = v * trem
        r = int(0.08 * RATE)
        for i in range(r):
            sig[k - 1 - i] *= i / r
        return sig

    for bar, notes in enumerate(tune):
        for pos, m, beats in notes:
            place(vib_out, vibe(m, beats), at(bar, pos), 0.45 * rnd.uniform(0.85, 1.0))

    band = mix((0.8, biquad(bass_out, "lp", 900.0, 0.7, True)), (0.2, ride_out), (0.5, drum_out),
               (1.0, biquad(piano_out, "lp", 3000.0, 0.7, True)), (1.0, vib_out))
    # A small room (the saucer over the stage): a few wrapped reflections.
    room = zeros(n)
    for d, g in ((0.031, 0.32), (0.047, 0.24), (0.083, 0.18), (0.121, 0.12), (0.173, 0.08)):
        place(room, band, int(d * RATE), g)
    out = mix((1.0, band), (1.0, biquad(room, "lp", 2500.0, 0.7, True)))
    # The square's air and a far murmur under it, so it never drops to dead silence.
    air = biquad(noise(n, rnd), "lp", 600.0, 0.7, True)
    for i in range(n):
        out[i] += 0.015 * air[i]
    return biquad(biquad(out, "lp", 8000.0, 0.7, True), "hp", 45.0, 0.7, True)


def normalise(chans, peak_db):
    peak = max(max(abs(v) for v in c) for c in chans)
    g = 10 ** (peak_db / 20.0) / max(peak, 1e-9)
    return [array.array("d", (v * g for v in c)) for c in chans]


def write(path, chans):
    n = len(chans[0])
    frames = bytearray()
    for i in range(n):
        for c in chans:
            frames += struct.pack("<h", int(round(max(-1.0, min(1.0, c[i])) * 32767)))
    with wave.open(path, "wb") as w:
        w.setnchannels(len(chans))
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(bytes(frames))


def read(path):
    with wave.open(path, "rb") as w:
        ch = w.getnchannels()
        rate = w.getframerate()
        raw = w.readframes(w.getnframes())
    vals = array.array("h", raw)
    return [array.array("d", (v / 32768.0 for v in vals[c::ch])) for c in range(ch)], rate


def fft(a):
    n = len(a)
    a = list(a)
    j = 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit:
            j ^= bit
            bit >>= 1
        j |= bit
        if i < j:
            a[i], a[j] = a[j], a[i]
    size = 2
    while size <= n:
        w = cmath.exp(-2j * math.pi / size)
        for start in range(0, n, size):
            wk = 1.0
            for k in range(size // 2):
                u = a[start + k]
                v = a[start + k + size // 2] * wk
                a[start + k] = u + v
                a[start + k + size // 2] = u - v
                wk *= w
        size *= 2
    return a


def spectrum(x, rate):
    """Share of energy below 2 kHz and the 85% roll-off, from Hann-windowed 4096-point
    frames averaged over the file."""
    size = 4096
    power = [0.0] * (size // 2)
    frames = 0
    step = max(size, (len(x) - size) // 8)
    for start in range(0, max(1, len(x) - size + 1), step):
        seg = x[start:start + size]
        if len(seg) < size:
            seg = list(seg) + [0.0] * (size - len(seg))
        win = [seg[i] * (0.5 - 0.5 * math.cos(TAU * i / size)) for i in range(size)]
        f = fft(win)
        for k in range(size // 2):
            power[k] += abs(f[k]) ** 2
        frames += 1
    total = sum(power) or 1e-12
    below = sum(p for k, p in enumerate(power) if k * rate / size < 2000.0) / total
    acc = 0.0
    roll = 0.0
    for k, p in enumerate(power):
        acc += p
        if acc >= 0.85 * total:
            roll = k * rate / size
            break
    return below, roll


def db(v):
    return 20.0 * math.log10(max(v, 1e-9))


def check(path, loop):
    chans, rate = read(path)
    peak = max(max(abs(v) for v in c) for c in chans)
    rms = math.sqrt(sum(sum(v * v for v in c) for c in chans) / sum(len(c) for c in chans))
    line = {"file": os.path.basename(path), "ch": len(chans), "s": len(chans[0]) / rate,
            "kb": os.path.getsize(path) // 1024, "peak": db(peak), "rms": db(rms)}
    if loop:
        worst_step = worst_slope = 0.0
        ok = True
        for c in chans:
            steps = sorted(abs(c[i] - c[i - 1]) for i in range(1, len(c)))
            slopes = sorted(abs(c[i + 1] - 2 * c[i] + c[i - 1]) for i in range(1, len(c) - 1))
            p_step = steps[int(len(steps) * 0.999)]
            p_slope = slopes[int(len(slopes) * 0.999)]
            seam = abs(c[0] - c[-1])
            curve = abs(c[1] - 2 * c[0] + c[-1])
            worst_step = max(worst_step, seam / max(p_step, 1e-9))
            worst_slope = max(worst_slope, curve / max(p_slope, 1e-9))
            ok = ok and seam <= p_step and curve <= p_slope
        line["seam"] = "%.2f / %.2f %s" % (worst_step, worst_slope, "ok" if ok else "CLICK")
    else:
        line["seam"] = "one-shot"
    mono = chans[0] if len(chans) == 1 else array.array("d", ((a + b) * 0.5 for a, b in zip(chans[0], chans[1])))
    below, roll = spectrum(mono, rate)
    line["below2k"] = below
    line["rolloff"] = roll
    return line


# --- the fans by Stadion Leguminy (fans.gd) -------------------------------------------------

def fan_chant(seed):
    """Friendly fans outside a stadium, heard from the street: a bass drum carried on the belly
    ("boom, boom, boom-boom-boom" at 120 BPM) and a crowd singing a wordless, original two-bar
    tune in unison ("oo-oo-oo, eh-oh-eh-oh"): twenty-four voices, each a glottal pulse train at
    its own slightly-off pitch through a vowel's two formants, the syllables on the drum's grid,
    a cheer at the end of the phrase; the far-field roll-off of a crowd 40 m away. Periodic by
    construction (the drum's hits wrap round, the voices are silent across the seam), 8 s."""
    rnd = random.Random(seed)
    n = int(8.0 * RATE)
    beat = 0.5
    out = zeros(n)
    # The drum: a pitched thump (a falling sine) and a felt slap, a little off the grid.
    def hit():
        m = int(0.45 * RATE)
        sig = zeros(m)
        ph = 0.0
        for i in range(m):
            t = i / RATE
            f = 58.0 + 70.0 * math.exp(-t * 28.0)
            ph += TAU * f / RATE
            sig[i] = math.sin(ph) * math.exp(-t * 7.5) + (rnd.uniform(-1, 1) * math.exp(-t * 90.0) * 0.35)
        return sig
    grid = [0.0, 1.0, 2.0, 2.5, 3.0]          # boom, boom, boom-boom-boom (a 4-beat bar)
    for bar in range(4):
        for k, b in enumerate(grid):
            at = int(((bar * 4 + b) * beat + 0.12 + rnd.uniform(-0.008, 0.008)) * RATE)
            place(out, hit(), at % n, 0.9 if k < 2 else 0.75)
    drum = biquad(out, "lp", 900.0, 0.7, True)
    # The tune: (start beat, length in beats, MIDI note, vowel) over 16 beats; silent from 15.
    tune = [(0, 1, 62, "u"), (1, 1, 62, "u"), (2, 1.5, 62, "u"),
            (4, 0.5, 64, "e"), (4.5, 0.5, 66, "o"), (5, 0.5, 64, "e"), (5.5, 1.5, 62, "o"),
            (8, 1, 66, "u"), (9, 1, 66, "u"), (10, 1.5, 66, "u"),
            (12, 0.5, 67, "e"), (12.5, 0.5, 66, "o"), (13, 0.5, 64, "e"), (13.5, 1.2, 62, "o")]
    voices = zeros(n)
    for v in range(24):
        detune = rnd.uniform(-0.35, 0.35)            # semitones: a crowd, not a choir
        octave = 0 if v % 3 else -12                 # some sing an octave down
        late = rnd.uniform(0.0, 0.05)
        gain = rnd.uniform(0.5, 1.0)
        sig = zeros(n)
        for (b0, length, note, vowel) in tune:
            f0 = 440.0 * 2 ** ((note + octave + detune - 69) / 12.0)
            i0 = int((b0 * beat + 0.12 + late) * RATE)
            m = int(length * beat * 0.92 * RATE)
            ph = rnd.random()
            for i in range(m):
                ph += f0 * (1.0 + 0.004 * math.sin(TAU * 5.0 * i / RATE)) / RATE
                saw = 2.0 * (ph % 1.0) - 1.0
                env = min(1.0, i / 500.0, (m - i) / 900.0)
                sig[(i0 + i) % n] += saw * env * gain
        voices = mix((1.0, voices), (1.0, sig))
    # One "oh"-ish formant pair plus a brighter band for the whole crowd (from 40 m the vowels
    # blur anyway; the tune's (note, vowel) pairs only set the pitch).
    sung = mix((1.0, biquad(voices, "bp", 450.0, 1.6, True)), (0.7, biquad(voices, "bp", 850.0, 2.0, True)),
               (0.25, biquad(voices, "bp", 1900.0, 3.0, True)))
    # A cheer at the end of the phrase (beats 14.7-15.6): bright noise, rising and falling.
    w = noise(n, rnd)
    cheer = biquad(biquad(w, "bp", 1100.0, 0.8, True), "lp", 2400.0, 0.7, True)
    c0 = int((14.7 * beat + 0.12) * RATE)
    cm = int(0.9 * beat * RATE)
    shout = zeros(n)
    for i in range(cm):
        shout[(c0 + i) % n] = cheer[(c0 + i) % n] * math.sin(math.pi * i / cm) ** 1.5
    crowd = mix((0.3, sung), (0.5, shout))
    mixd = mix((1.0, drum), (1.0, crowd))
    return biquad(biquad(mixd, "lp", 3000.0, 0.7, True), "hp", 45.0, 0.7, True)


# --- the wellness circles (wellness.gd) --------------------------------------------------------

def gong_bowls(seed):
    """City-life satire #2 (wellness.gd, through city_sounds.gd's `gong`): a sound-healing ring heard
    from the path. A big gong struck every 6 s (inharmonic partials, a slow swell, a long wash) and
    a singing bowl between the strokes (a sine pair a few Hz apart that beats), 12 s, periodic by
    construction (the tails wrap round the seam), softened by the distance."""
    rnd = random.Random(seed)
    n = int(12.0 * RATE)
    out = zeros(n)
    # The gong: partials of a tam-tam (ratios not harmonic), each with its own decay.
    base = 98.0
    gong_parts = [(base * r, a, d) for (r, a, d) in
                  [(1.0, 1.0, 3.2), (1.52, 0.8, 2.6), (2.31, 0.7, 2.2), (2.97, 0.55, 1.8),
                   (3.83, 0.45, 1.5), (4.9, 0.3, 1.1), (6.2, 0.22, 0.9)]]
    m = int(6.0 * RATE)
    tail = bell(m, gong_parts, 0.35, rnd)
    # A slow swell after the stroke: a gong blooms before it fades.
    sw = int(0.6 * RATE)
    for i in range(sw):
        tail[i] *= 0.35 + 0.65 * (i / sw)
    wash = biquad(noise(m, rnd), "bp", 900.0, 0.9)
    for i in range(m):
        tail[i] += 0.05 * wash[i] * math.exp(-i / (1.6 * RATE))
    place(out, tail, int(0.1 * RATE), 1.0)
    place(out, tail, int(6.1 * RATE), 0.85)
    # The bowl: two sines 3.5 Hz apart beat slowly, rubbed in over 3 s and let go (on the seam of
    # the gong's decay), twice with a different pitch.
    for start, f, g in [(2.6, 432.0, 0.28), (8.3, 513.0, 0.24)]:
        k = int(3.4 * RATE)
        sig = zeros(k)
        for i in range(k):
            t = i / RATE
            env = math.sin(math.pi * min(1.0, t / 3.4)) ** 1.4
            sig[i] = env * (math.sin(TAU * f * t) + 0.9 * math.sin(TAU * (f + 3.5) * t)
                            + 0.25 * math.sin(TAU * f * 2.71 * t))
        place(out, sig, int(start * RATE), g)
    return biquad(biquad(out, "lp", 2800.0, 0.7, True), "hp", 50.0, 0.7, True)


def techno_thump(seed):
    """City-life satire #3 (wellness.gd, through city_sounds.gd's `thump`): the techno-yoga speaker
    from the pavement. 16 beats at 128 BPM (7.5 s): a four-on-the-floor kick (a falling sine), an
    off-beat open hat, a one-note rolling bass; low-passed hard, as a small speaker heard through
    air. Periodic (every hit lands on the grid, tails wrap)."""
    rnd = random.Random(seed)
    beat = 60.0 / 128.0
    n = int(16 * beat * RATE)
    out = zeros(n)
    def kick():
        k = int(0.32 * RATE)
        sig = zeros(k)
        ph = 0.0
        for i in range(k):
            t = i / RATE
            ph += TAU * (46.0 + 110.0 * math.exp(-t * 32.0)) / RATE
            sig[i] = math.sin(ph) * math.exp(-t * 11.0)
        return sig
    def hat():
        k = int(0.09 * RATE)
        w = biquad(noise(k, rnd), "hp", 6000.0, 0.7)
        return [w[i] * math.exp(-i / (0.025 * RATE)) for i in range(k)]
    def bass(f):
        k = int(0.2 * RATE)
        sig = zeros(k)
        for i in range(k):
            t = i / RATE
            saw = 2.0 * ((f * t) % 1.0) - 1.0
            sig[i] = saw * math.exp(-t * 9.0) * min(1.0, t * 400.0)
        return biquad(sig, "lp", 500.0, 1.2)
    kk, hh = kick(), hat()
    for b in range(16):
        place(out, kk, int(b * beat * RATE), 1.0)
        place(out, hh, int((b + 0.5) * beat * RATE), 0.22)
        place(out, bass(55.0 if (b // 4) % 2 == 0 else 61.7), int((b + 0.75) * beat * RATE), 0.3)
    # A park's air under the speaker, so the pauses between hits are never dead silence.
    air = biquad(noise(n, rnd), "lp", 700.0, 0.7, True)
    for i in range(n):
        out[i] += 0.05 * air[i]
    return biquad(biquad(out, "lp", 1600.0, 0.7, True), "hp", 35.0, 0.7, True)



# --- the railway audit (trains.gd, 2026-11-07) ------------------------------------

def _clack(n, at, rnd, ring=None):
    """One wheel over a rail joint: a low thud and a short bright tick (and, on a steel deck,
    a short ring)."""
    out = zeros(n)
    m = int(0.18 * RATE)
    for j in range(min(m, n - at)):
        t = j / RATE
        out[at + j] += 0.9 * math.sin(TAU * 62.0 * t) * math.exp(-t / 0.045)
    tick = biquad([rnd.uniform(-1, 1) * math.exp(-j / (0.008 * RATE)) for j in range(int(0.04 * RATE))], "bp", 1100.0, 1.2)
    for j, v in enumerate(tick):
        if at + j < n:
            out[at + j] += 1.4 * v
    if ring:
        sig = bell(min(int(0.5 * RATE), n - at), ring, 0.0)
        for j, v in enumerate(sig):
            out[at + j] += 0.35 * v
    return out


def train_pass(seed, bridge):
    """A train's wheels going by (trains.gd plays one every ~2 s while a train runs near):
    a rumble of low noise swelling and fading, and two "tu-dum" pairs as a car's bogies cross a
    rail joint. `bridge`: on a steel deck, a drone of the girders (110 / 233 / 347 Hz, beating)
    and every clack rings. 2.4 s, one-shot."""
    rnd = random.Random(seed)
    n = int(2.4 * RATE)
    bed = noise(n, rnd)
    low = mix((1.0, biquad(bed, "lp", 240.0, 0.7)), (0.7, biquad(bed, "bp", 95.0, 1.4)),
              (0.4, biquad(bed, "bp", 1700.0, 1.6)))
    out = zeros(n)
    for i in range(n):
        t = i / n
        out[i] = low[i] * (0.35 + 0.65 * math.sin(math.pi * t) ** 1.5)
    ring = [(410.0, 1.0, 0.25), (987.0, 0.5, 0.12), (1630.0, 0.25, 0.07)] if bridge else None
    for at in (0.35, 0.47, 1.45, 1.57):
        place(out, _clack(n, int(at * RATE), rnd, ring), 0, 0.8 if bridge else 0.6)
    if bridge:
        for i in range(n):
            t = i / RATE
            env = math.sin(math.pi * i / n) ** 1.2
            out[i] += env * 0.22 * (math.sin(TAU * 110.0 * t) + 0.6 * math.sin(TAU * 233.0 * t + 1.3)
                                    + 0.35 * math.sin(TAU * 347.0 * t + 0.4) + 0.3 * math.sin(TAU * 820.0 * t + 2.1)) * (0.75 + 0.25 * math.sin(TAU * 3.1 * t))
    out = biquad(out, "hp", 35.0, 0.7)
    return fade(out, 0.15, 0.4)


def train_horn(seed):
    """Our own two-tone train horn: a long high note falling to a lower one (622 then 523 Hz),
    reedy (a narrow pulse with a little vibrato) through two horn resonances, with an open
    echo as from a cutting. 1.5 s."""
    n = int(1.5 * RATE)
    out = zeros(n)
    for start, end, f in ((0.0, 0.55, 622.0), (0.6, 1.15, 523.0)):
        ph = 0.0
        for i in range(int(start * RATE), int(end * RATE)):
            t = (i - start * RATE) / RATE
            ph += f * (1.0 + 0.004 * math.sin(TAU * 5.5 * t)) / RATE
            sq = 1.0 if ph % 1.0 < 0.3 else -0.43
            env = min(1.0, t / 0.03) * min(1.0, ((end - start) - t) / 0.06)
            out[i] += sq * env
    out = mix((0.5, biquad(out, "lp", 2200.0, 0.7)), (0.9, biquad(out, "bp", 1250.0, 1.8)),
              (0.5, biquad(out, "bp", 640.0, 1.2)))
    out = saturate(out, 1.4)
    return fade(echo(out, [(0.18, 0.25), (0.41, 0.12)], 0.0), 0.0, 0.08)


def station_gong(seed):
    """Our own platform gong before an announcement (not the real one): four soft
    vibraphone tones, G4 C5 E5 C5, 0.3 s apart, ringing out over an open platform. 2.6 s."""
    rnd = random.Random(seed)
    n = int(2.6 * RATE)
    out = zeros(n)
    for k, f in enumerate((392.0, 523.3, 659.3, 523.3)):
        at = int(k * 0.3 * RATE)
        sig = bell(n - at, [(f, 1.0, 0.9), (f * 4.0, 0.18, 0.18), (f * 10.0, 0.05, 0.05)], 0.04, rnd)
        place(out, sig, at, 0.8)
    out = biquad(out, "lp", 3000.0, 0.7)
    return fade(echo(out, [(0.13, 0.22), (0.29, 0.12)], 0.4), 0.0, 0.4)

LOOPS = ["engine_idle", "engine_mid", "engine_high", "tyre_roll", "tyre_wet", "tyre_squeal", "rotor",
         "city_day", "city_night", "rain", "police_siren", "club_leak", "busker", "crowd_murmur", "steps_guitar",
         "queue_chatter", "amb_river", "amb_park", "amb_square", "amb_yard", "fan_chant", "gong_bowls", "techno_thump",
         "jazz_trio"]


def loud_rev(seed):
    """City-life satire #1 (loud_cars.gd): a loud car's rev as it passes, an invented big
    eight with a tuned pipe: two blips and a long pull up to the limiter, then the overrun
    crackle (short pops of filtered noise) as the driver lifts. 2.4 s, one-shot. The firing
    is uneven (a cross-plane burble: the gaps alternate), the pipe's resonances are low and
    wide, and the whole thing is saturated hard: the joke is that it is too much."""
    rnd = random.Random(seed)
    n = int(2.4 * RATE)
    # rpm over time: idle, blip, blip, the pull to the limiter (with a stutter), the lift.
    keys = [(0.0, 900), (0.12, 900), (0.22, 3600), (0.36, 1300), (0.48, 4200), (0.64, 1500),
            (0.72, 1500), (1.34, 6900), (1.40, 6400), (1.46, 6900), (1.52, 6500), (1.58, 6900),
            (1.72, 2600), (2.4, 1000)]

    def rpm_at(t):
        for (t0, r0), (t1, r1) in zip(keys, keys[1:]):
            if t <= t1:
                u = (t - t0) / max(t1 - t0, 1e-6)
                return r0 + (r1 - r0) * (u * u * (3 - 2 * u))
        return keys[-1][1]

    pulse = zeros(n)
    rasp = zeros(n)
    hiss = noise(n, rnd)
    load = zeros(n)
    ph = 0.0
    k = 0
    last = 900.0
    cur = 0.35
    for i in range(n):
        r = rpm_at(i / RATE)
        if i % 64 == 0:
            # under load while the revs climb, light while they fall
            cur = max(0.0, min(1.0, (r - last) * 0.02 + 0.35))
            last = r
        load[i] = cur
        # eight cylinders: four firings a revolution, the gaps alternating long and short
        ph += (r / 60.0 * 4.0) / RATE * (1.25 if k % 2 == 0 else 0.83)
        if ph >= 1.0:
            ph -= 1.0
            k += 1
            a = 1.0 + rnd.uniform(-0.15, 0.15)
            width = max(3, int(RATE / (r / 60.0 * 4.0) * 0.18))
            for j in range(min(width, n - i)):
                pulse[i + j] += a * math.sin(math.pi * j / width) ** 2
            burst = width * 3
            for j in range(min(burst, n - i)):
                rasp[i + j] += hiss[i + j] * a * (1 - j / burst) ** 2
    body = mix(
        (0.6, biquad(pulse, "lp", 900.0, 0.8)),
        (1.0, biquad(pulse, "bp", 230.0, 1.6)),     # the big pipe
        (1.2, biquad(pulse, "bp", 520.0, 1.4)),     # its resonator: the phone speaker's range
        (0.8, biquad(pulse, "bp", 1150.0, 2.0)),
        (0.4, biquad(pulse, "bp", 1900.0, 2.5)),    # the rasp of a straight-through box
    )
    roar = biquad(biquad(rasp, "bp", 950.0, 0.8), "lp", 3800.0, 0.7)
    for i in range(n):
        roar[i] *= 0.4 + 0.9 * load[i]
    # the overrun: pops of noise through a low resonance after the lift (1.6-2.3 s)
    pops = zeros(n)
    t = 1.62
    while t < 2.3:
        at = int(t * RATE)
        ln = int(rnd.uniform(0.008, 0.025) * RATE)
        g = rnd.uniform(0.6, 1.4) * (1.0 - (t - 1.6) / 0.9)
        for j in range(min(ln, n - at)):
            pops[at + j] += hiss[(at + j * 7) % n] * g * (1 - j / ln)
        t += rnd.uniform(0.03, 0.11)
    pops = biquad(pops, "bp", 700.0, 1.2)
    out = mix((1.0, body), (0.8, roar), (1.6, pops))
    out = saturate(out, 2.6)
    out = biquad(biquad(out, "lp", 4800.0, 0.7), "hp", 60.0, 0.7)
    return fade(out, 0.01, 0.25)


# Loop MW-5: the city's sounds (city_sounds.gd), made on their own with --only=.
CITY = {"club_leak": lambda: [club_leak(71)], "metro_chime": lambda: [metro_chime(72)],
        "church_bell": lambda: [church_bell(73)], "busker": lambda: [busker(74)],
        # Loop MW-3: the crowds' (city_sounds.gd add_crowd).
        "crowd_murmur": lambda: [crowd_murmur(75)], "steps_guitar": lambda: [steps_guitar(76)],
        # Loop MW-4: everyday life's (city_life.gd, the trend queues through city_sounds.gd).
        "bark_small": lambda: [bark(81, 0)], "bark_mid": lambda: [bark(82, 1)], "bark_big": lambda: [bark(83, 2)],
        "bike_bell": lambda: [bike_bell(84)], "watch_beep": lambda: [watch_beep(85)],
        "queue_chatter": lambda: [queue_chatter(86)], "phone_shutter": lambda: [phone_shutter(87)],
        "cafe_bell": lambda: [cafe_bell(88)],
        # Loop MW-2 (storefronts.gd): the Frogs door's croak chime, a Leżak knocked over.
        "frog_chime": lambda: [frog_chime(89)], "scooter_clatter": lambda: [scooter_clatter(90)],
        # The night-buses loop (buses.gd): the player's horn.
        "horn_player": lambda: [horn_player()],
        # G13b (car.gd): the nitro lighting.
        "nitro_whoosh": lambda: [nitro_whoosh(93)],
        # The vintage-tram loop (old_tram.gd): the old set's creak and its bell.
        "tram_creak": lambda: [tram_creak(91)], "old_tram_bell": lambda: [old_tram_bell(92)],
        # v1.0 juice: the money pop (money_pop.gd) and the districts' ambiences (sfx.gd).
        "coin": lambda: [coin(93)], "amb_river": lambda: amb_river(94), "amb_park": lambda: amb_park(95),
        "amb_square": lambda: amb_square(96), "amb_yard": lambda: amb_yard(97),
        # City-life satire #1 (loud_cars.gd): the loud cars' rev.
        "loud_rev": lambda: [loud_rev(98)],
        # The fans by Stadion Leguminy (fans.gd, through city_sounds.gd's `chant`).
        "fan_chant": lambda: [fan_chant(99)],
        # The wellness circles (wellness.gd, through city_sounds.gd's `gong` and `thump`).
        "gong_bowls": lambda: [gong_bowls(100)], "techno_thump": lambda: [techno_thump(101)],
        # The jazz evenings under the Powiśle saucer (crowds.gd's `jazz`, city_sounds.gd's `jazz`).
        "jazz_trio": lambda: [jazz_trio(102)],
        # The railway audit (trains.gd): the wheels, the wheels on a bridge, the horn, the platform gong.
        "train_rumble": lambda: [train_pass(103, False)], "train_bridge": lambda: [train_pass(104, True)],
        "train_horn": lambda: [train_horn(105)], "station_gong": lambda: [station_gong(106)]}


def main(out_dir, radio_dir=None, only=None):
    os.makedirs(out_dir, exist_ok=True)
    made = {}
    if only:
        for name in only:
            made[name] = CITY[name]()
        return _write_all(out_dir, made, radio_dir)
    idle, idle_rpm = engine(850.0, 0.1, 2.0, 11)
    mid, mid_rpm = engine(2400.0, 0.55, 1.6, 12)
    high, high_rpm = engine(4500.0, 0.9, 1.4, 13)
    print("engine loops recorded at %.0f, %.0f and %.0f rpm (scripts/sfx.gd ENGINE_RPM)" % (idle_rpm, mid_rpm, high_rpm))
    made["engine_idle"] = [idle]
    made["engine_mid"] = [mid]
    made["engine_high"] = [high]
    made["tyre_roll"] = [tyre_roll(2.0, 21)]
    made["tyre_wet"] = [tyre_wet(2.0, 22)]
    made["tyre_squeal"] = [tyre_squeal(1.0, 23)]
    made["rotor"] = [rotor(2.0, 24)]
    made["city_day"] = city(12.0, 31, False)
    made["city_night"] = city(12.0, 32, True)
    made["rain"] = rain(6.0, 33)
    made["thump_soft"] = [thump(0.4, 41, False)]
    made["thump_hard"] = [thump(0.7, 42, True)]
    made["crash"] = [crash(43)]
    made["clang"] = [clang(44)]
    made["jar_clink"] = [jar_clink(45)]
    made["jar_break"] = [jar_break(46)]
    made["tram_bell"] = [tram_bell(47)]
    made["horn"] = [horn(False)]
    made["horn_double"] = [horn(True)]
    made["pigeons"] = [pigeons(48)]
    made["birds_a"] = [birds(49, "a")]
    made["birds_b"] = [birds(50, "b")]
    made["siren_far"] = [siren_far(51)]
    made["dog_far"] = [dog_far(52)]
    made["police_siren"] = [police_siren(61)]
    made["police_whoop"] = [police_whoop(62)]
    made["megaphone"] = [megaphone(63)]
    made["whistle"] = [whistle(64)]
    made["scribble"] = [scribble(65)]
    made["stamp"] = [stamp(66)]
    made["clank"] = [clank(67)]
    for name, make in CITY.items():
        made[name] = make()
    return _write_all(out_dir, made, radio_dir)


def _write_all(out_dir, made, radio_dir):
    rows = []
    for name, chans in made.items():
        path = os.path.join(out_dir, name + ".wav")
        # Every file peaks at -3 dBFS: headroom for QOA, and the mix is set by the
        # players and buses in sfx.gd, not by the files.
        write(path, normalise(chans, -3.0))
        rows.append(check(path, name in LOOPS))
    print()
    print("| file | ch | s | KB | peak dBFS | RMS dBFS | loop seam step / slope (x p99.9) | energy < 2 kHz | 85% roll-off |")
    print("| --- | --- | --- | --- | --- | --- | --- | --- | --- |")
    for r in rows:
        print("| %s | %d | %.2f | %d | %.1f | %.1f | %s | %.0f%% | %.0f Hz |" % (
            r["file"], r["ch"], r["s"], r["kb"], r["peak"], r["rms"], r["seam"], r["below2k"] * 100, r["rolloff"]))
    if radio_dir:
        print()
        for f in sorted(os.listdir(radio_dir)):
            if f.endswith(".wav"):
                r = check(os.path.join(radio_dir, f), True)
                print("radio %s: peak %.1f dBFS, RMS %.1f dBFS, seam %s" % (f, r["peak"], r["rms"], r["seam"]))


if __name__ == "__main__":
    only = [a[len("--only="):] for a in sys.argv[1:] if a.startswith("--only=")]
    pos = [a for a in sys.argv[1:] if not a.startswith("--")]
    main(pos[0], pos[1] if len(pos) > 1 else None, only[0].split(",") if only else None)
