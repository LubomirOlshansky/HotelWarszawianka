"""The reference-versus-model sheet: Google 3D Tiles renders of a building above the game's turntable
tiles of its site from the nearest matching side, plus the two top views, on one PNG.

    python3 -I tools/refs_compare.py KEY [--slug=SLUG] [--out=FILE.png] [--tile=640x480]
Writes refs/SLUG/KEY_vs_refs.png (gitignored, local: it holds Google imagery; never attach or publish it).

KEY is the landmark site key; run `tools/turntable.sh KEY` first (its lit tiles are read from
shots/turntable_KEY/). SLUG (default KEY) names the refs folder: refs/SLUG/3dtiles/ in the working copy (Google renders
never go to the shared folder: render them here), made by tools/tiles3d/render.mjs with its
SOURCES.md lines (heading, pitch). Each render is paired with the turntable tile seen from the same
side: a render looking along heading H matches turntable yaw (360 - H) % 360 (yaw 0 = the view from
the south, looking north = heading 0; yaw 90 = from the east). Renders at pitch about -28 pair with
the low ring (pitch -25), at -40 or steeper with the high ring (-50); a render more than 25 degrees
from any yaw is left out. Top pairs with top. Row 1: references; row 2: the model.
Render the references to match exactly with `--angles=8 --pitch=-25` (the low ring's yaws).

The reviewer reads this ONE sheet instead of a dozen images (Ufficio Primo pilot, 2026-11-26): the
first build's flat dark dome and sparse roof lights showed at once beside the render.
References stay local (refs/ and shots/ are gitignored); never commit, publish or trace them.
Standard library only; the pasting is game/tools/shot_sheet.gd (needs Godot: $GODOT or `godot`).
"""
import os
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
YAWS = [0, 45, 90, 135, 180, 225, 270, 315]
LINE = re.compile(r"^- \S* ?(\S+\.png): .*heading (-?[\d.]+), pitch (-?[\d.]+)")


def refs_dir(slug):
    d = os.path.join(ROOT, "refs", slug, "3dtiles")
    return d if os.path.isfile(os.path.join(d, "SOURCES.md")) else None


def renders(d):
    """[(file, heading, pitch)] from the folder's SOURCES.md, last line per file wins."""
    seen = {}
    for line in open(os.path.join(d, "SOURCES.md"), encoding="utf-8"):
        m = LINE.match(line.strip())
        if m and os.path.isfile(os.path.join(d, m.group(1))):
            seen[m.group(1)] = (os.path.join(d, m.group(1)), float(m.group(2)), float(m.group(3)))
    return list(seen.values())


def pairs(key, refs, shots):
    out = []
    for path, heading, pitch in sorted(refs, key=lambda r: (r[2] < -80, r[1])):
        if pitch < -80:
            model = os.path.join(shots, f"{key}_lit_top.png")
            out.append((path, model, "top"))
            continue
        want = (360.0 - heading) % 360.0
        yaw = min(YAWS, key=lambda y: min(abs(y - want), 360 - abs(y - want)))
        off = min(abs(yaw - want), 360 - abs(yaw - want))
        if off > 25.0:
            print(f"refs_compare: {os.path.basename(path)} (heading {heading:g}) is {off:.0f} deg from any yaw, left out")
            continue
        ring = "hi" if pitch <= -40.0 else "lo"
        out.append((path, os.path.join(shots, f"{key}_lit_{ring}_{yaw:03d}.png"), f"yaw {yaw} {ring}"))
    return out


def main():
    args = sys.argv[1:]
    if not args or args[0].startswith("-"):
        sys.exit(__doc__)
    key = args[0]
    opts = dict(a[2:].split("=", 1) for a in args[1:] if a.startswith("--") and "=" in a)
    slug = opts.get("slug", key)
    shots = os.path.join(ROOT, "shots", f"turntable_{key}")
    if not os.path.isfile(os.path.join(shots, f"{key}_lit_top.png")):
        sys.exit(f"refs_compare: no turntable for {key}: run tools/turntable.sh {key} first")
    d = refs_dir(slug)
    if d is None:
        sys.exit(f"refs_compare: no 3D Tiles renders for {slug} (refs/{slug}/3dtiles/SOURCES.md): "
                 f"node tools/tiles3d/render.mjs --building=NAME --slug={slug} --angles=8 --pitch=-25")
    ps = pairs(key, renders(d), shots)
    if not ps:
        sys.exit("refs_compare: no render matches a turntable side")
    # Beside the references, not beside the turntable sheet that is shown to F and put on pages: the
    # sheet holds Google imagery, which stays local (Fable's review, 2026-11-26).
    out = opts.get("out", os.path.join(ROOT, "refs", slug, f"{key}_vs_refs.png"))
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    # The two rows: every reference, then every model tile, in the same order (shot_sheet pastes
    # row-major and scales each tile to the first one's size).
    files = [p[0] for p in ps] + [p[1] for p in ps]
    godot = os.environ.get("GODOT", "godot")
    cmd = [godot, "--headless", "--path", os.path.join(ROOT, "game"), "--script", "res://tools/shot_sheet.gd",
           "--", f"--out={os.path.abspath(out)}", f"--cols={len(ps)}", f"--tile={opts.get('tile', '640x480')}", *files]
    r = subprocess.run(cmd, capture_output=True, text=True)
    lines = [l for l in r.stdout.splitlines() if l.startswith("shot_sheet")]
    print("\n".join(lines))
    print("refs_compare: columns " + " | ".join(p[2] for p in ps) + "; row 1 references, row 2 the model")
    print(out)
    sys.exit(r.returncode)


if __name__ == "__main__":
    main()
