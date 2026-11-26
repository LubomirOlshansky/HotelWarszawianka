#!/usr/bin/env python3
"""Cuts a generated techno take into a deck track for "Za deckami" (docs/design/smola-decks.md).

Usage:
  python3 -I tools/make_deck_tracks.py SOURCE ID NAME [--phrase=N] [--dry]
      [--from="ElevenLabs Music v2.5"] [--prompt="..."]

  SOURCE   any file ffmpeg reads (the take, 2 to 4 minutes of four-on-the-floor techno)
  ID       the track's id: writes game/audio/club/decks_ID.ogg and its row in
           game/data/decks_tracks.json
  NAME     the name on the deck ("BETON")
  --phrase which 16-beat phrase after the first kick the cut starts on (default: the best one)
  --dry    measures and prints, writes nothing

The game stands on a beat grid: every deck track is BEATS beats at exactly BPM, a kick on every
beat, the first kick LEAD seconds into the file, and it loops on itself. A generated take
holds its tempo, but its kicks start anywhere, it has breakdowns, and it does not loop. So:

  1. two bands give a rise curve each: the clicks (over 3 kHz, 1 ms steps) and the kick band
     (under 140 Hz, 2.5 ms steps);
  2. the take's tempo is the comb that fits the clicks best (126 to 138 BPM);
  3. both curves folded on the beat show where in the beat the kick starts: the click that has
     the low band's swell right after it (single beats are no good for that: a bass note is
     often louder than its kick). A window of BEATS beats is chosen that starts a whole number
     of 16-beat phrases after the first kick, where no kick is missing (no breakdown) and each
     quarter's fold matches the whole's without a shift;
  4. the window is cut LEAD before its kick, BEATS beats to the sample (ElevenLabs Music keeps
     the tempo it is asked for to a hundredth of a BPM; a take off BPM is refused, not
     stretched);
  5. the samples just before the cut are cross-faded into the last SEAM seconds, so the end runs
     into the start;
  6. the level is set (RMS_DB, peak under PEAK_DB), the file is written as mono Ogg Vorbis, read back
     and measured: its length to the sample and every kick against the grid.

It refuses a take whose kicks drift more than half of MAX_DEV in the window or whose window
misses a kick. The row in decks_tracks.json keeps the lanes' picture (8 values a beat: the loudness and
the kick band) and where the take came from. Standard library and ffmpeg. Run
`godot --headless --path game --import` afterwards, then `tools/verify.sh --only=decks`.
"""
import array
import cmath
import datetime
import json
import math
import os
import subprocess
import sys
import tempfile
import wave

BPM = 132.0
BEATS = 64
QUALITY = "2"  # Ogg Vorbis quality, mono: about 0.25 MB a track (F, 2026-11-26: small files)
RATE = 44100
LEAD = 0.004
SEAM = 0.006
RMS_DB = -17.0
PEAK_DB = -1.5
MAX_DEV = 0.012
LOW_RATE = 2000
LOW_HOP = 5
HI_RATE = 8000
HI_HOP = 8
STEPS = 8  # picture values a beat
TEMPO_OFF = 0.03  # a take this near BPM is on it (2 ms over the track at most)
FULL = 0.8  # a window's weakest kick, as a share of the median kick
BINS = 182  # the beat folded into this many bins (2.5 ms)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "game", "audio", "club")
DATA = os.path.join(ROOT, "game", "data", "decks_tracks.json")


def decode(path, rate, channels, extra=None, af=None):
    """The file as 16-bit samples (array 'h', interleaved)."""
    cmd = ["ffmpeg", "-v", "error"] + (extra or []) + ["-i", path]
    if af:
        cmd += ["-af", af]
    cmd += ["-ac", str(channels), "-ar", str(rate), "-f", "s16le", "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    out = array.array("h")
    out.frombytes(raw[: len(raw) // 2 * 2])
    return out


def rise(samples, hop):
    """A band's rise, one value every `hop` samples: the RMS of each step, where it grows."""
    n = len(samples) // hop
    env = [0.0] * n
    for i in range(n):
        acc = 0.0
        for v in samples[i * hop:(i + 1) * hop]:
            acc += v * v
        env[i] = math.sqrt(acc / hop)
    flux = [0.0] * n
    for i in range(1, n):
        d = env[i] - env[i - 1]
        if d > 0.0:
            flux[i] = d
    return flux, env


def comb(flux, frame_rate):
    """The tempo (BPM) whose comb fits a rise curve best, and how well (0 to 1)."""
    top = max(flux)
    pts = [(i / frame_rate, f) for i, f in enumerate(flux) if f > top * 0.08]
    total = sum(f for _, f in pts)

    def score(bpm):
        w = math.tau * bpm / 60.0
        z = 0j
        for t, f in pts:
            z += f * cmath.exp(1j * w * t)
        return abs(z) / total

    best = (0.0, 0.0)
    bpm = 126.0
    while bpm <= 138.0:
        best = max(best, (score(bpm), bpm))
        bpm += 0.05
    lo = best[1] - 0.06
    for k in range(61):
        best = max(best, (score(lo + k * 0.002), lo + k * 0.002))
    return best[1], best[0]


def fold(flux, frame_rate, period, t_from, t_to):
    """A rise curve folded on the beat between two times: BINS bins, lightly smoothed."""
    hist = [0.0] * BINS
    for i in range(max(1, int(t_from * frame_rate)), min(len(flux), int(t_to * frame_rate))):
        if flux[i] > 0.0:
            hist[int((i / frame_rate % period) / period * BINS) % BINS] += flux[i]
    return [hist[j - 2] * 0.1 + hist[j - 1] * 0.2 + hist[j] * 0.4 + hist[(j + 1) % BINS] * 0.2 + hist[(j + 2) % BINS] * 0.1
            for j in range(BINS)]


def lag(part, whole):
    """How many bins `part` sits after `whole` (two folds): the shift that matches them best."""
    best = (-1.0, 0)
    for shift in range(-12, 13):
        best = max(best, (sum(part[(j + shift) % BINS] * whole[j] for j in range(BINS)), shift))
    return best[1]


def kick_phase(hi_fold, low_fold):
    """Where in the beat the kick starts, in bins. The kick's click is a peak of the high band
    with the low band's swell right after it (a hat on the off-beat has the click, not the
    swell; a bass note has the swell, not the click)."""
    order = sorted(range(BINS), key=lambda j: -hi_fold[j])
    peaks = []
    for j in order:
        if hi_fold[j] < hi_fold[order[0]] * 0.4:
            break
        if all(min(abs(j - k), BINS - abs(j - k)) > 8 for k in peaks):
            peaks.append(j)
        if len(peaks) == 4:
            break
    after = int(0.09 / (60.0 / BPM) * BINS)
    return max(peaks, key=lambda j: max(low_fold[(j + d) % BINS] for d in range(1, after + 1)))


def analyse(path):
    """A file's grid: {bpm, comb, period, kick (s into the beat), hi, low (rise curves), body
    and tops (the low and the high band's level), hi_rate, low_rate (curve values a second), secs}."""
    hi, tops = rise(decode(path, HI_RATE, 1, af="highpass=f=3000"), HI_HOP)
    low, body = rise(decode(path, LOW_RATE, 1, af="lowpass=f=140"), LOW_HOP)
    hi_rate = HI_RATE / HI_HOP
    low_rate = LOW_RATE / LOW_HOP
    bpm, coherence = comb(hi, hi_rate)
    period = 60.0 / bpm
    secs = len(hi) / hi_rate
    k = kick_phase(fold(hi, hi_rate, period, 0.0, secs), fold(low, low_rate, period, 0.0, secs))
    return {"bpm": bpm, "comb": coherence, "period": period, "kick": (k + 0.5) * period / BINS,
            "hi": hi, "low": low, "body": body, "tops": tops, "hi_rate": hi_rate, "low_rate": low_rate, "secs": secs}


def drift(g, t_from, beats):
    """The largest shift (s) of a 16-beat stretch against the whole span, both bands."""
    worst = 0
    for flux, rate in ((g["hi"], g["hi_rate"]), (g["low"], g["low_rate"])):
        whole = fold(flux, rate, g["period"], t_from, t_from + beats * g["period"])
        for q in range(beats // 16):
            a = t_from + q * 16 * g["period"]
            worst = max(worst, abs(lag(fold(flux, rate, g["period"], a, a + 16 * g["period"]), whole)))
    return worst * g["period"] / BINS


def pick_window(g, phrase):
    """The first beat of the cut: a whole number of 16-beat phrases after the first kick. Among
    the windows with every kick in (no breakdown: the weakest kick's body at least FULL of the
    median) the one with the most going on up top (hats and percussion in: the track's full
    arrangement, not its intro). Returns (k0, the weakest kick as a share of the median); k0 -1
    for none."""
    period = g["period"]
    beat = []
    k = 0
    while g["kick"] + (k + 1) * period < g["secs"]:
        a = int((g["kick"] + k * period) * g["low_rate"])
        beat.append(max(g["body"][a:a + int(0.12 * g["low_rate"])]))
        k += 1
    median = sorted(beat)[len(beat) // 2]
    first = next(i for i, v in enumerate(beat) if v > median * 0.5)
    best = (-1, 0.0, -1.0)
    j = 1 if phrase < 0 else phrase
    while first + 16 * j + BEATS + 4 <= len(beat):
        k0 = first + 16 * j
        weakest = min(beat[k0:k0 + BEATS]) / median
        a = int((g["kick"] + k0 * period) * g["hi_rate"])
        tops = g["tops"][a:a + int(BEATS * period * g["hi_rate"])]
        busy = sum(tops) / len(tops)
        if phrase >= 0:
            return k0, weakest
        if weakest >= FULL and busy > best[2]:
            best = (k0, weakest, busy)
        j += 1
    return best[0], best[1]


def wrap(d, period):
    """A difference of two times in the beat, the short way round."""
    return (d + period * 0.5) % period - period * 0.5


def measure(path):
    """A written track against the grid: frames, where the kick starts in the beat (s; LEAD is
    right), the largest drift of a quarter of the track (s) and its tempo."""
    frames = len(decode(path, RATE, 1))
    g = analyse(path)
    return frames, g["kick"], drift(g, 0.0, BEATS), g["bpm"]


def picture(stereo, frames):
    """The lanes' picture: STEPS values a beat of the loudness and of the kick band, 0 to 99."""
    n = BEATS * STEPS
    loud = [0.0] * n
    kick = [0.0] * n
    count = [0] * n
    lp = 0.0
    a = math.exp(-math.tau * 120.0 / RATE)
    for i in range(frames):
        m = (stereo[2 * i] + stereo[2 * i + 1]) * 0.5
        lp = lp * a + m * (1.0 - a)
        j = min(n - 1, i * n // frames)
        loud[j] += m * m
        kick[j] += lp * lp
        count[j] += 1
    loud = [math.sqrt(v / max(1, c)) for v, c in zip(loud, count)]
    kick = [math.sqrt(v / max(1, c)) for v, c in zip(kick, count)]
    return ([min(99, int(99.0 * v / max(loud))) for v in loud],
            [min(99, int(99.0 * v / max(kick))) for v in kick])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    opts = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in sys.argv[1:] if a.startswith("--"))
    if len(args) != 3:
        print(__doc__)
        sys.exit(2)
    src, track_id, name = args
    dry = "dry" in opts

    g = analyse(src)
    period = g["period"]
    k0, weakest = pick_window(g, int(opts.get("phrase", "-1")))
    if k0 < 0:
        sys.exit("make_deck_tracks: %s: no window of %d beats; try --phrase" % (src, BEATS))
    start = g["kick"] + k0 * period
    moved = drift(g, start - 0.5 * period, BEATS)
    print("%s: take %.3f BPM (comb %.2f), the kick %.1f ms into the beat, window from %.2f s (beat %d), weakest kick %.2f of the median, drift %.1f ms"
            % (track_id, g["bpm"], g["comb"], g["kick"] * 1000.0, start, k0, weakest, moved * 1000.0))
    if abs(g["bpm"] - BPM) > TEMPO_OFF:
        sys.exit("make_deck_tracks: %s: the take is at %.2f BPM, not %.0f; generate it at %.0f" % (track_id, g["bpm"], BPM, BPM))
    if weakest < FULL:
        sys.exit("make_deck_tracks: %s: a kick is missing in the window (a breakdown); try --phrase" % track_id)
    if moved > MAX_DEV * 0.5:
        sys.exit("make_deck_tracks: %s: the kicks drift %.1f ms in the window" % (track_id, moved * 1000.0))
    if dry:
        return

    # The cut: PRE seconds of run-in (for the seam), then the window. The take is on BPM (checked
    # above), so the window is BEATS beats to the sample with no resampling.
    frames = int(round(BEATS * 60.0 / BPM * RATE))
    pre = 0.05
    stereo = decode(src, RATE, 2, extra=["-ss", "%.6f" % (start - LEAD - pre), "-t", "%.6f" % (BEATS * 60.0 / BPM + pre + 0.05)])
    head = int(round(pre * RATE))
    if len(stereo) // 2 < head + frames:
        sys.exit("make_deck_tracks: %s: the cut came out short" % track_id)
    run_in = stereo[:2 * head]
    body = array.array("h", stereo[2 * head:2 * (head + frames)])
    seam = int(SEAM * RATE)
    for i in range(seam):
        w = math.sin(0.5 * math.pi * (i + 1) / (seam + 1)) ** 2
        for c in range(2):
            j = 2 * (frames - seam + i) + c
            body[j] = int(round(body[j] * (1.0 - w) + run_in[2 * (head - seam + i) + c] * w))

    # The level: RMS_DB, the peak under PEAK_DB.
    rms = math.sqrt(sum(v * v for v in body) / len(body)) / 32768.0
    peak = max(abs(v) for v in body) / 32768.0
    gain = min(10.0 ** (RMS_DB / 20.0) / rms, 10.0 ** (PEAK_DB / 20.0) / peak)
    body = array.array("h", [max(-32768, min(32767, int(round(v * gain)))) for v in body])

    os.makedirs(OUT_DIR, exist_ok=True)
    out = os.path.join(OUT_DIR, "decks_%s.ogg" % track_id)
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "cut.wav")
        with wave.open(wav, "wb") as w:
            w.setnchannels(2)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(body.tobytes())
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ac", "1", "-c:a", "libvorbis", "-q:a", QUALITY,
                "-map_metadata", "-1", "-fflags", "+bitexact", "-flags:a", "+bitexact", out], check=True)
    got, lead, dev, out_bpm = measure(out)
    print("%s: wrote %s: %d frames (want %d), %.0f kB, level %.1f dB RMS, the kick %.1f ms into the beat, drift %.1f ms"
            % (track_id, os.path.relpath(out, ROOT), got, frames, os.path.getsize(out) / 1000.0,
            20.0 * math.log10(rms * gain), lead * 1000.0, dev * 1000.0))
    if got != frames or dev > MAX_DEV * 0.5 or abs(wrap(lead - LEAD, 60.0 / BPM)) > MAX_DEV * 0.5:
        os.remove(out)
        sys.exit("make_deck_tracks: %s: the written file is off the grid" % track_id)

    loud, kick = picture(body, frames)
    rows = []
    if os.path.exists(DATA):
        with open(DATA, encoding="utf-8") as f:
            rows = json.load(f)["tracks"]
    rows = [r for r in rows if r["id"] != track_id]
    rows.append({"id": track_id, "name": name, "file": "res://audio/club/decks_%s.ogg" % track_id,
            "bpm": BPM, "beats": BEATS, "frames": frames, "rate": RATE, "lead": LEAD,
            "loud": loud, "kick": kick,
            "from": opts.get("from", "ElevenLabs Music v2.5"), "prompt": opts.get("prompt", ""),
            "made": datetime.date.today().isoformat()})
    rows.sort(key=lambda r: r["id"])
    with open(DATA, "w", encoding="utf-8") as f:
        f.write("{\"tracks\": [\n")
        f.write(",\n".join(json.dumps(r, ensure_ascii=False) for r in rows))
        f.write("\n]}\n")


if __name__ == "__main__":
    main()
