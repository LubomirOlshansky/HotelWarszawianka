#!/usr/bin/env python3
"""Puts a recorded or generated sound (ElevenLabs, a field recording) into game/audio/sfx.

Usage:
  python3 -I tools/add_sfx.py SOURCE NAME [--loop] [--fade=0.5] [--trim=0.06]
      [--peak=-3] [--rms=DB | --match] [--rate=22050] [--mono]
      [--from="ElevenLabs Sound Effects v2"] [--prompt="..."] [--dry]

  SOURCE   any file ffmpeg reads (mp3, wav, ogg)
  NAME     the sound's name in sfx.gd (LOOPS or SHOTS); writes game/audio/sfx/NAME.wav

  --loop    makes a seamless loop: the last --fade seconds are cross-faded into the start, so the
            file wraps on itself whatever the source's own ends were (an mp3 has padding)
  --trim    seconds cut from both ends first (mp3 encoder padding), default 0.06
  --peak    the highest peak allowed, dBFS (the game's files peak at -3 for QOA headroom)
  --match   keeps the loudness (RMS) of the file being replaced, so its level in sfx.gd stays right
  --rms     or a loudness to reach, dBFS; the peak limit wins and the shortfall is printed
  --rate    sample rate, default 22050 like every other effect
  --dry     measures and prints, writes nothing

It also sets the loop end in NAME.wav.import (the game loops by that number) and records where the
sound came from in game/audio/sfx/sources.json; tools/make_sfx.py never overwrites a recorded name.
Needs ffmpeg on the path. Run `godot --headless --path game --import` afterwards, then
`tools/verify.sh --only=sfx` (it checks every loop's seam).
"""
import array
import datetime
import json
import math
import os
import re
import subprocess
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, "game", "audio", "sfx")
SOURCES = os.path.join(SFX_DIR, "sources.json")


def decode(path, rate, channels):
    """The source as interleaved 16-bit samples."""
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "s16le", "-ac", str(channels), "-ar", str(rate), "-"],
        check=True, capture_output=True).stdout
    a = array.array("h")
    a.frombytes(raw[:len(raw) // 2 * 2])
    if sys.byteorder == "big":
        a.byteswap()
    return a


def levels(a):
    """(peak dBFS, RMS dBFS) of interleaved 16-bit samples."""
    if not a:
        return -120.0, -120.0
    peak = max(max(a), -min(a)) / 32768.0
    rms = math.sqrt(sum(v * v for v in a) / len(a)) / 32768.0
    return 20 * math.log10(max(peak, 1e-6)), 20 * math.log10(max(rms, 1e-6))


def read_wav(path):
    with wave.open(path, "rb") as w:
        a = array.array("h")
        a.frombytes(w.readframes(w.getnframes()))
        if sys.byteorder == "big":
            a.byteswap()
        return a


def make_loop(a, channels, fade_frames):
    """Cross-fades the tail into the head (equal power), so the end runs into the start."""
    frames = len(a) // channels
    fade_frames = min(fade_frames, frames // 3)
    out = array.array("h", a[fade_frames * channels:])
    n = len(out) // channels
    for i in range(fade_frames):
        t = (i + 0.5) / fade_frames
        g_old = math.cos(t * math.pi / 2)
        g_new = math.sin(t * math.pi / 2)
        for c in range(channels):
            old = out[(n - fade_frames + i) * channels + c]
            new = a[i * channels + c]
            out[(n - fade_frames + i) * channels + c] = max(-32768, min(32767, round(old * g_old + new * g_new)))
    return out


def arg(name, default=None):
    for x in sys.argv[1:]:
        if x == "--" + name:
            return True
        if x.startswith("--" + name + "="):
            return x.split("=", 1)[1]
    return default


def main():
    pos = [x for x in sys.argv[1:] if not x.startswith("--")]
    if len(pos) != 2:
        print(__doc__)
        return 2
    src, name = pos
    rate = int(arg("rate", 22050))
    channels = 1 if arg("mono") else 2
    peak_max = float(arg("peak", -3.0))
    out_path = os.path.join(SFX_DIR, name + ".wav")

    a = decode(src, rate, channels)
    cut = int(float(arg("trim", 0.06)) * rate) * channels
    if cut and len(a) > cut * 4:
        a = a[cut:len(a) - cut]
    if arg("loop"):
        a = make_loop(a, channels, int(float(arg("fade", 0.5)) * rate))

    peak, rms = levels(a)
    want = None
    if arg("match") and os.path.exists(out_path):
        want = levels(read_wav(out_path))[1]
    elif arg("rms") not in (None, True):
        want = float(arg("rms"))
    gain = peak_max - peak
    note = ""
    if want is not None:
        need = want - rms
        if need > gain:
            note = "  (%.1f dB under the wanted loudness: the peak limit won; raise its level in sfx.gd)" % (need - gain)
        else:
            gain = need
    k = 10 ** (gain / 20)
    a = array.array("h", (max(-32768, min(32767, round(v * k))) for v in a))
    peak2, rms2 = levels(a)
    frames = len(a) // channels
    print("%s: %.2f s, %d Hz, %d ch, gain %+.1f dB, peak %.1f dBFS, RMS %.1f dBFS%s" % (
        name, frames / rate, rate, channels, gain, peak2, rms2, note))
    if arg("dry"):
        return 0

    with wave.open(out_path, "wb") as w:
        w.setnchannels(channels)
        w.setsampwidth(2)
        w.setframerate(rate)
        b = array.array("h", a)
        if sys.byteorder == "big":
            b.byteswap()
        w.writeframes(b.tobytes())

    imp = out_path + ".import"
    if os.path.exists(imp):
        s = open(imp, encoding="utf-8").read()
        if arg("loop"):
            s = re.sub(r"edit/loop_mode=\d+", "edit/loop_mode=2", s)
            s = re.sub(r"edit/loop_begin=\d+", "edit/loop_begin=0", s)
            s = re.sub(r"edit/loop_end=-?\d+", "edit/loop_end=%d" % frames, s)
        open(imp, "w", encoding="utf-8").write(s)
    else:
        print("  no %s.wav.import yet: import the project once, then set its loop and QOA like its neighbours" % name)

    sources = {}
    if os.path.exists(SOURCES):
        sources = json.load(open(SOURCES, encoding="utf-8"))
    row = {"from": arg("from", "recorded"), "added": datetime.date.today().isoformat()}
    if arg("prompt") not in (None, True):
        row["prompt"] = arg("prompt")
    sources[name] = row
    with open(SOURCES, "w", encoding="utf-8") as f:
        json.dump(sources, f, ensure_ascii=False, indent="\t", sort_keys=True)
        f.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
