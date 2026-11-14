"""The barrier types of tools/object_types.py as pictures: the type plot of the whole map (the
review picture of walls doc 5 "Keeping it honest") and the 20-sample check's contact sheets.

    python3 tools/overlay_object_types.py plot ROWS.json OUT.png [--map=DIR] [--px=2400]
        every wall, fence and hedge coloured by its type (hard lines thicker, `tc: default` grey),
        the roads faint, a legend with the metres per type
    python3 tools/overlay_object_types.py sheet ROWS.json NAME OUT.jpg --rules=a,b [--n=20]
        [--seed=5] [--max-tries=60] [--r=30] [--photos=1] [--map=DIR] [--kind=fence] [--min-len=10]
        the 20-sample check of one rule (or several that give one type): lines of those rules
        at least min-len m long (a shorter one can't be told on a photo) drawn with a fixed seed, the nearest street-level photos
        of each line's middle (tools/street_photos.py, into the gitignored refs/step5-NAME-NN/),
        lines with no photo replaced by the next draw, one cell per line: the photo, a small
        plan (the line red, other barriers grey, buildings, roads, the camera blue with its view)
        and the line's kind, type, rule, length and height. A reviewer marks each cell right,
        wrong or no photo; a rule ships at 16 of 20 right.

ROWS.json is `tools/object_types.py apply ... --rows=FILE`. Photos are reference only: never
committed or shipped. Needs Pillow; runs without -I so it finds it.
"""
import json
import math
import os
import random
import re
import subprocess
import sys

from PIL import Image, ImageDraw, ImageFont

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import object_types as O  # noqa: E402

# One colour per type, grouped by look: dark steel, iron and piers, mesh, wire, wood and sheet,
# green, masonry, concrete, rails and parapets, low things.
COLOURS = {
    "fence_plain": (150, 150, 150), "bars_black": (40, 40, 60), "bars_pier": (120, 40, 140),
    "rail_street": (230, 160, 0), "rail_tram": (0, 150, 70), "mesh_panel": (0, 170, 200),
    "chain_link": (90, 120, 200), "ball_net": (150, 200, 255), "low_lawn": (170, 220, 90),
    "wood": (150, 90, 30), "hoarding": (255, 120, 0), "green_fence": (60, 140, 40),
    "hedge_low": (110, 200, 60), "hedge_tall": (20, 100, 20), "chain_posts": (200, 200, 120),
    "low_wall": (220, 190, 140), "basin_rim": (210, 210, 170), "island_edge": (200, 200, 200),
    "wall_brick": (190, 50, 30), "wall_plaster": (230, 210, 150), "wall_precast": (110, 110, 110),
    "wall_stone": (170, 150, 120), "noise_screen": (150, 70, 40), "gabion": (130, 120, 100),
    "glass_screen": (160, 220, 230), "guard_rail": (255, 230, 0), "parapet_concrete": (255, 0, 120),
    "deck_railing": (255, 60, 60), "rail_waterfront": (0, 90, 255), "balustrade": (240, 140, 200),
    "balustrade_rail": (200, 100, 200), "balustrade_white": (255, 255, 255), "site": (0, 0, 0), "removed": (255, 0, 0),
}


def font(size):
    try:
        return ImageFont.load_default(size=size)
    except TypeError:
        return ImageFont.load_default()


def load_map(map_dir):
    return json.load(open(os.path.join(map_dir, "centrum.json"), encoding="utf-8"))


def plot(rows, out, map_dir, px):
    d = load_map(map_dir)
    x0, z0, x1, z1 = d["bounds"]
    s = px / (x1 - x0)
    legend_w = 520
    W, H = int((x1 - x0) * s), int((z1 - z0) * s)
    img = Image.new("RGB", (W + legend_w, H), (250, 248, 242))
    dr = ImageDraw.Draw(img)

    def P(x, z):
        return ((x - x0) * s, (z - z0) * s)
    for a in d.get("areas", []):
        if a["k"] in ("water", "park"):
            pts = [P(*q) for q in O.pairs(a["p"])]
            if len(pts) >= 3:
                dr.polygon(pts, fill=(205, 225, 245) if a["k"] == "water" else (232, 242, 225))
    for r in d.get("roads", []):
        dr.line([P(*q) for q in O.pairs(r["p"])], fill=(215, 215, 215), width=max(1, int(r.get("w", 6) * s)))
    for b in d.get("buildings", []):
        pts = [P(*q) for q in O.pairs(b["p"])]
        if len(pts) >= 3:
            dr.polygon(pts, fill=(228, 226, 222))
    lines = d["lines"]
    metres = {}
    order = sorted(rows, key=lambda r: (r["tc"] != "default", r["sc"] == "H"))
    for r in order:
        l = lines[r["i"]]
        col = COLOURS.get(r["ty"], (255, 0, 255))
        if r["tc"] == "default":
            col = (175, 175, 175)
        w = 3 if r["sc"] == "H" else 2
        dr.line([P(*q) for q in O.pairs(l["p"])], fill=col, width=w)
        metres[(r["k"], r["ty"])] = metres.get((r["k"], r["ty"]), 0.0) + r["L"]
    f, fb = font(16), font(20)
    y = 16
    dr.text((W + 16, y), "Barrier types (tools/object_types.py)", fill=(0, 0, 0), font=fb)
    y += 30
    dr.text((W + 16, y), "thick: class H; grey: tc default", fill=(60, 60, 60), font=f)
    y += 28
    for kind in O.KINDS:
        tot = sum(v for (k, _), v in metres.items() if k == kind)
        dr.text((W + 16, y), "%s  %.1f km" % (kind, tot / 1000), fill=(0, 0, 0), font=fb)
        y += 26
        for (k, ty), v in sorted(metres.items(), key=lambda kv: -kv[1]):
            if k != kind or v < 50:
                continue
            dr.rectangle([W + 20, y + 3, W + 44, y + 15], fill=COLOURS.get(ty, (255, 0, 255)))
            dr.text((W + 54, y), "%-18s %6.1f km  %4.1f %%" % (ty, v / 1000, 100 * v / tot), fill=(0, 0, 0), font=f)
            y += 20
        y += 10
    dflt = sum(r["L"] for r in rows if r["k"] == "fence" and r["tc"] == "default")
    fen = sum(r["L"] for r in rows if r["k"] == "fence")
    dr.text((W + 16, y + 6), "fence tc default: %.1f %%" % (100 * dflt / max(fen, 1)), fill=(0, 0, 0), font=fb)
    img.save(out)
    print("overlay_object_types plot: %s (%d x %d)" % (out, img.width, img.height))


def photos_of(slug):
    """[(path, camera x, z, heading, date, dist)] that street_photos.py saved under refs/slug."""
    out_dir = os.path.join(ROOT, "refs", slug, "street")
    src = os.path.join(out_dir, "SOURCES.md")
    out = []
    if not os.path.exists(src):
        return out
    for line in open(src, encoding="utf-8"):
        m = re.match(r"- `street/([^`]+)`: .*, ([0-9-]{10}); camera at \(([-\d.]+), ([-\d.]+)\), heading ([-\d.None]+), ([\d.]+) m", line)
        if m and os.path.exists(os.path.join(out_dir, m.group(1))):
            hd = None if m.group(5) == "None" else float(m.group(5))
            out.append((os.path.join(out_dir, m.group(1)), float(m.group(3)), float(m.group(4)), hd, m.group(2), float(m.group(6))))
    return out


def plan(d, segs, r, cam, size=240, half=35.0):
    """A small plan round a line: buildings, roads, other barriers grey, the line red, the camera."""
    img = Image.new("RGB", (size, size), (250, 248, 242))
    dr = ImageDraw.Draw(img)
    cx, cz = r["x"], r["z"]
    s = size / (2 * half)

    def P(x, z):
        return ((x - cx + half) * s, (z - cz + half) * s)
    box = (cx - half - 60, cz - half - 60, cx + half + 60, cz + half + 60)

    def near(flat):
        xs, zs = flat[0::2], flat[1::2]
        return max(xs) >= box[0] and min(xs) <= box[2] and max(zs) >= box[1] and min(zs) <= box[3]
    for a in d.get("areas", []):
        if a["k"] in ("water", "park", "pitch") and near(a["p"]):
            pts = [P(*q) for q in O.pairs(a["p"])]
            if len(pts) >= 3:
                dr.polygon(pts, fill={"water": (200, 220, 245), "park": (225, 240, 215), "pitch": (200, 235, 200)}[a["k"]])
    for rd in d.get("roads", []):
        if near(rd["p"]):
            dr.line([P(*q) for q in O.pairs(rd["p"])], fill=(205, 205, 205), width=max(1, int(rd.get("w", 6) * s)))
    for t in d.get("trams", []):
        if near(t["p"]):
            dr.line([P(*q) for q in O.pairs(t["p"])], fill=(120, 170, 120), width=2)
    for b in d.get("buildings", []):
        if near(b["p"]):
            pts = [P(*q) for q in O.pairs(b["p"])]
            if len(pts) >= 3:
                dr.polygon(pts, fill=(222, 218, 210), outline=(170, 165, 160))
    for j, (k, flat) in segs:
        if j != r["i"] and near(flat):
            dr.line([P(*q) for q in O.pairs(flat)], fill=(120, 120, 120), width=1)
    me = d["lines"][r["i"]]["p"]
    dr.line([P(*q) for q in O.pairs(me)], fill=(230, 0, 0), width=3)
    if cam:
        x, z, hd = cam
        p = P(x, z)
        dr.ellipse([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], fill=(0, 80, 255))
        if hd is not None:
            a = math.radians(hd)
            dr.line([p, (p[0] + math.sin(a) * 30, p[1] - math.cos(a) * 30)], fill=(0, 80, 255), width=2)
    dr.text((4, size - 14), "%d m" % int(2 * half), fill=(80, 80, 80), font=font(11))
    return img


def sheet(rows, name, out, rules, n, seed, max_tries, radius, n_photos, map_dir, kind, min_len=10.0):
    d = load_map(map_dir)
    # the rule "hz" draws the lines a hazard made hard, whatever their type rule
    pool = [r for r in rows if (r["rule"] in rules or ("hz" in rules and r["hz"])) and (not kind or r["k"] == kind)
            and r["L"] >= min_len]
    rnd = random.Random("%s:%d" % (name, seed))
    rnd.shuffle(pool)
    segs = [(i, (l["k"], l["p"])) for i, l in enumerate(d["lines"]) if l.get("k") in O.KINDS]
    picked, tried, no_photo = [], 0, []
    for r in pool:
        if len(picked) >= n or tried >= max_tries:
            break
        tried += 1
        slug = "step5-%s-%d" % (name, r["i"])
        if not photos_of(slug):
            subprocess.run([sys.executable, "-I", os.path.join(TOOLS, "street_photos.py"), str(r["x"]), str(r["z"]),
                            "--r=%d" % radius, "--max=%d" % n_photos, "--slug=" + slug],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        ph = photos_of(slug)
        if ph:
            picked.append((r, ph, slug))
        else:
            no_photo.append(r["i"])
    cw, chh, ph_w, ph_h, pl = 760, 300, 500, 300, 240
    cols = 2
    rows_n = (len(picked) + cols - 1) // cols
    img = Image.new("RGB", (cols * cw, 50 + rows_n * (chh + 10)), (255, 255, 255))
    dr = ImageDraw.Draw(img)
    f, fb = font(14), font(18)
    dr.text((10, 10), "step 5, 20-sample check: %s (rules %s), seed %d: %d lines with a photo of %d tried; no photo: %s"
            % (name, ",".join(rules), seed, len(picked), tried, " ".join(map(str, no_photo[:20]))), fill=(0, 0, 0), font=fb)
    for c, (r, ph, slug) in enumerate(picked):
        x0, y0 = (c % cols) * cw, 50 + (c // cols) * (chh + 10)
        path, camx, camz, hd, date, dist = ph[0]
        try:
            im = Image.open(path).convert("RGB")
            im.thumbnail((ph_w, ph_h))
            img.paste(im, (x0, y0))
        except OSError:
            pass
        img.paste(plan(d, segs, r, (camx, camz, hd), pl), (x0 + ph_w + 10, y0))
        dr.rectangle([x0, y0, x0 + 36, y0 + 22], fill=(0, 0, 0))
        dr.text((x0 + 4, y0 + 3), "#%d" % (c + 1), fill=(255, 255, 0), font=fb)
        dr.text((x0 + ph_w + 10, y0 + pl + 2), "%s %s  %s  %s/%s%s" % (r["k"], r["ty"], r["rule"], r["tc"], r["sc"],
                                                                        (" hz " + r["hz"]) if r["hz"] else ""), fill=(0, 0, 0), font=f)
        dr.text((x0 + ph_w + 10, y0 + pl + 20), "line %d  %.0f m  h %s  (%.0f, %.0f)" % (r["i"], r["L"], r["h"], r["x"], r["z"]),
                fill=(60, 60, 60), font=f)
        dr.text((x0 + ph_w + 10, y0 + pl + 38), "%s  %.0f m away" % (date, dist), fill=(60, 60, 60), font=f)
    img.save(out, quality=85)
    manifest = {"name": name, "rules": rules, "seed": seed, "tried": tried, "no_photo": no_photo,
                "cells": [{"n": c + 1, "i": r["i"], "k": r["k"], "ty": r["ty"], "rule": r["rule"], "x": r["x"], "z": r["z"],
                           "photos": [os.path.relpath(p[0], ROOT) for p in ph]} for c, (r, ph, slug) in enumerate(picked)]}
    with open(os.path.splitext(out)[0] + ".json", "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1, ensure_ascii=False)
    print("overlay_object_types sheet: %s: %d with a photo of %d tried -> %s" % (name, len(picked), tried, out))


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = {a.split("=")[0]: (a.split("=", 1)[1] if "=" in a else True) for a in argv if a.startswith("--")}
    map_dir = opt.get("--map", O.MAP_DIR)
    if len(args) >= 3 and args[0] == "plot":
        plot(json.load(open(args[1], encoding="utf-8")), args[2], map_dir, int(opt.get("--px", 2400)))
        return 0
    if len(args) >= 4 and args[0] == "sheet":
        rules = str(opt.get("--rules", args[2])).split(",")
        sheet(json.load(open(args[1], encoding="utf-8")), args[2], args[3], rules, int(opt.get("--n", 20)),
              int(opt.get("--seed", 5)), int(opt.get("--max-tries", 60)), int(opt.get("--r", 30)),
              int(opt.get("--photos", 1)), map_dir, opt.get("--kind", ""), float(opt.get("--min-len", 10)))
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
