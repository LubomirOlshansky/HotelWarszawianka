"""Pictures for the road design system (docs/design/road-design-system.md): measure a street on the
orthophoto and check a design against it, flat from above, without running the game.

Usage:
  python3 -I tools/road_design_plot.py mosaic TILES_DIR RES OUT.png
      Stitch the GUGiK ortho tiles (TILES_DIR/tiles.json: {"name.png": [x0, z0, x1, z1]} in map
      metres; the Mac fetches them into refs/road_design/) into one image at RES m/px, with
      OUT.png.json holding {x0, z0, res, w, h}.
  python3 -I tools/road_design_plot.py unroll ORTHO.png OUT.png AX,AZ BX,BZ S0 S1 HALF [--along PX] [--across PX] [--map MAP.json]
      The ortho straightened along the axis A->B: rows are s (top = S0), columns the offset to
      the right of the axis (-HALF..HALF), with a 1 m ruler (yellow, red = axis) and s every 10 m.
      Read a street's cross-section straight off it. --map draws a map's kerbs (cyan) and
      markings (magenta) on top, to check a design lines up.
  python3 -I tools/road_design_plot.py flat MAP.json OUT.png X0 Z0 X1 Z1 [--scale PX] [--ortho ORTHO.png] [--graph]
      A flat render of a map's road layers (ribbons with their hide ranges, carriage areas,
      medians, islands, kerbs, markings, zebras, cycle crossings, arrows) over plain ground or
      over the ortho, for before/after pictures. --graph draws the traffic lanes on top (cyan,
      a dot at each lane's start).

Needs Pillow (as tools/overlay_*.py do).
"""
import json
import math
import sys

from PIL import Image, ImageDraw

Image.MAX_IMAGE_PIXELS = None


def opt(args, name, default):
    if name in args:
        i = args.index(name)
        v = args[i + 1]
        del args[i:i + 2]
        return v
    return default


def mosaic(args):
    tiles_dir, res, out = args[0], float(args[1]), args[2]
    tiles = json.load(open(tiles_dir.rstrip("/") + "/tiles.json"))
    x0 = min(v[0] for v in tiles.values())
    z0 = min(v[1] for v in tiles.values())
    x1 = max(v[2] for v in tiles.values())
    z1 = max(v[3] for v in tiles.values())
    w, h = int(round((x1 - x0) / res)), int(round((z1 - z0) / res))
    img = Image.new("RGB", (w, h))
    for name, (a, b, c, d) in tiles.items():
        im = Image.open(tiles_dir.rstrip("/") + "/" + name).convert("RGB")
        im = im.resize((int(round((c - a) / res)), int(round((d - b) / res))), Image.LANCZOS)
        img.paste(im, (int(round((a - x0) / res)), int(round((b - z0) / res))))
    img.save(out)
    json.dump({"x0": x0, "z0": z0, "res": res, "w": w, "h": h}, open(out + ".json", "w"))
    print("mosaic: %s %dx%d px, x %.0f..%.0f z %.0f..%.0f" % (out, w, h, x0, x1, z0, z1))


def unroll(args):
    along = float(opt(args, "--along", "4"))
    across = float(opt(args, "--across", "10"))
    mp = opt(args, "--map", None)
    ortho, out = args[0], args[1]
    A = tuple(map(float, args[2].split(",")))
    B = tuple(map(float, args[3].split(",")))
    s0, s1, half = float(args[4]), float(args[5]), float(args[6])
    meta = json.load(open(ortho + ".json"))
    src = Image.open(ortho)
    px = src.load()
    L = math.dist(A, B)
    d = ((B[0] - A[0]) / L, (B[1] - A[1]) / L)
    n = (-d[1], d[0])
    W, H = int(2 * half * across), int((s1 - s0) * along)
    img = Image.new("RGB", (W, H))
    q = img.load()
    r = meta["res"]
    for j in range(H):
        s = s0 + j / along
        for i in range(W):
            off = -half + i / across
            u = (A[0] + d[0] * s + n[0] * off - meta["x0"]) / r
            v = (A[1] + d[1] * s + n[1] * off - meta["z0"]) / r
            if 0 <= u < meta["w"] - 1 and 0 <= v < meta["h"] - 1:
                q[i, j] = px[int(u), int(v)]
    g = ImageDraw.Draw(img, "RGBA")
    for k in range(int(-half), int(half) + 1):
        x = (k + half) * across
        g.line([(x, 0), (x, H)], fill=((255, 255, 0, 90 if k % 5 else 200) if k else (255, 0, 0, 200)), width=1)
        if k % 5 == 0:
            g.text((x + 2, 2), str(k), fill=(255, 255, 0, 255))
    for s in range(int(math.ceil(s0 / 10)) * 10, int(s1) + 1, 10):
        y = (s - s0) * along
        g.line([(0, y), (W, y)], fill=(0, 255, 255, 120))
        g.text((2, y + 1), str(s), fill=(0, 255, 255, 255))
    if mp:
        data = json.load(open(mp))

        def T(x, z):
            rx, rz = x - A[0], z - A[1]
            return ((rx * n[0] + rz * n[1] + half) * across, (rx * d[0] + rz * d[1] - s0) * along)
        for k in data["kerbs"]:
            p = k["p"]
            g.line([T(p[i], p[i + 1]) for i in range(0, len(p), 2)], fill=(0, 255, 255, 255), width=2)
        for m in data["markings"]:
            p = m["p"]
            g.line([T(p[i], p[i + 1]) for i in range(0, len(p), 2)], fill=(255, 0, 255, 255), width=1)
    img.save(out)
    print("unroll: %s %dx%d px" % (out, W, H))


ROAD = (78, 80, 84)
MINOR = (98, 98, 100)
WHITE = (255, 255, 255, 255)
RED = (196, 80, 70, 255)
MARK_W = {"edge": 0.2, "lane": 0.22, "centre": 0.2, "stop": 0.5, "bus": 0.3, "cycle": 0.18,
          "stripe": 0.45, "solid": 0.2}


def flat(args):
    S = float(opt(args, "--scale", "2"))
    ortho = opt(args, "--ortho", None)
    graph = "--graph" in args
    if graph:
        args.remove("--graph")
    mp, out = args[0], args[1]
    X0, Z0, X1, Z1 = map(float, args[2:6])
    data = json.load(open(mp))
    W, H = int((X1 - X0) * S), int((Z1 - Z0) * S)
    img = Image.new("RGB", (W, H), (221, 214, 200))
    if ortho:
        m = json.load(open(ortho + ".json"))
        crop = [(X0 - m["x0"]) / m["res"], (Z0 - m["z0"]) / m["res"], (X1 - m["x0"]) / m["res"], (Z1 - m["z0"]) / m["res"]]
        img = Image.open(ortho).crop(tuple(int(c) for c in crop)).resize((W, H))
    a = 150 if ortho else 255
    g = ImageDraw.Draw(img, "RGBA")

    def P(x, z):
        return ((x - X0) * S, (z - Z0) * S)

    def pts(f):
        return [P(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]

    def near(f, pad=60):
        xs, zs = f[0::2], f[1::2]
        return max(xs) > X0 - pad and min(xs) < X1 + pad and max(zs) > Z0 - pad and min(zs) < Z1 + pad

    def px(w):
        return max(1, round(w * S))

    for r in data["roads"]:
        if not near(r["p"]):
            continue
        p = [(r["p"][i], r["p"][i + 1]) for i in range(0, len(r["p"]), 2)]
        col = (MINOR if r["k"] in ("service", "living_street") else ROAD) + (a,)
        cum = [0.0]
        for i in range(1, len(p)):
            cum.append(cum[-1] + math.dist(p[i - 1], p[i]))
        hide, wv, cv = r.get("hide", []), r.get("wv"), r.get("cv")
        for i in range(len(p) - 1):
            sm = (cum[i] + cum[i + 1]) / 2
            if any(h0 <= sm <= h1 for h0, h1 in hide):
                continue
            wa = wv[i] if wv else r["w"]
            wb = wv[i + 1] if wv else r["w"]
            ca = cv[i] if cv else r.get("c", 0)
            cb = cv[i + 1] if cv else r.get("c", 0)
            (ax, az), (bx, bz) = p[i], p[i + 1]
            L = math.hypot(bx - ax, bz - az) or 1
            nx, nz = -(bz - az) / L, (bx - ax) / L
            quad = [(ax + nx * (ca - wa / 2), az + nz * (ca - wa / 2)), (bx + nx * (cb - wb / 2), bz + nz * (cb - wb / 2)),
                    (bx + nx * (cb + wb / 2), bz + nz * (cb + wb / 2)), (ax + nx * (ca + wa / 2), az + nz * (ca + wa / 2))]
            g.polygon([P(*v) for v in quad], fill=col)
    for c in data.get("carriage", []) + data.get("asphalt_fills", []):
        if near(c["p"]):
            g.polygon(pts(c["p"]), fill=(MINOR if c.get("k") in ("service", "living_street") else ROAD) + (a,))
    for m in data.get("medians", []):
        s = m["s"]
        if not near(s):
            continue
        col = (108, 152, 68, a) if m["k"] == "grass" else (143, 136, 125, a)
        for i in range(0, len(s) - 7, 4):
            g.polygon([P(s[i], s[i + 1]), P(s[i + 2], s[i + 3]), P(s[i + 6], s[i + 7]), P(s[i + 4], s[i + 5])], fill=col)
    edge = (0, 220, 255, 255) if ortho else (240, 240, 235, 255)
    for isl in data.get("islands", []):
        if near(isl["p"]):
            q = pts(isl["p"])
            g.polygon(q, fill=(211, 205, 193, a))
            g.line(q + q[:1], fill=edge, width=px(0.3))
    for t in data.get("trams", []):
        if near(t["p"]):
            g.line(pts(t["p"]), fill=(120, 100, 60, 255), width=px(1.5))
    for k in data.get("kerbs", []):
        if near(k["p"]):
            g.line(pts(k["p"]), fill=edge, width=px(0.3))

    def dashes(p, on, off, w):
        ph = 0.0
        for i in range(len(p) - 1):
            (ax, az), (bx, bz) = p[i], p[i + 1]
            L = math.hypot(bx - ax, bz - az)
            if L < 0.01:
                continue
            dx, dz = (bx - ax) / L, (bz - az) / L
            t = -ph
            while t < L:
                u0, u1 = max(t, 0.0), min(t + on, L)
                if u1 > u0:
                    g.line([P(ax + dx * u0, az + dz * u0), P(ax + dx * u1, az + dz * u1)], fill=WHITE, width=px(w))
                t += on + off
            ph = (ph + L) % (on + off)

    for m in data.get("markings", []):
        if not near(m["p"]):
            continue
        p = [(m["p"][i], m["p"][i + 1]) for i in range(0, len(m["p"]), 2)]
        if m["k"] == "cyclefill":
            g.line([P(*v) for v in p], fill=RED, width=px(m.get("w", 1.4)))
        elif m["k"] == "lane":
            dashes(p, 3.0, 5.0, 0.22)
        else:
            g.line([P(*v) for v in p], fill=WHITE, width=px(MARK_W.get(m["k"], 0.2)))
    for f in data["paths"]:
        if not near(f["p"]):
            continue
        q = [(f["p"][i], f["p"][i + 1]) for i in range(0, len(f["p"]), 2)]
        if f["k"] == "zebra":
            bar = max(2.0, float(f["w"]) - 0.4) / 2 if "w" in f else 1.8
            for i in range(len(q) - 1):
                (ax, az), (bx, bz) = q[i], q[i + 1]
                L = math.hypot(bx - ax, bz - az)
                if L < 1:
                    continue
                dx, dz = (bx - ax) / L, (bz - az) / L
                nx, nz = -dz, dx
                t = 0.6
                while t < L - 0.4:
                    cx, cz = ax + dx * t, az + dz * t
                    g.polygon([P(cx - dx * .25 - nx * bar, cz - dz * .25 - nz * bar), P(cx + dx * .25 - nx * bar, cz + dz * .25 - nz * bar),
                               P(cx + dx * .25 + nx * bar, cz + dz * .25 + nz * bar), P(cx - dx * .25 + nx * bar, cz - dz * .25 + nz * bar)], fill=WHITE)
                    t += 1.0
        elif f["k"] == "cycle" and not ortho:
            g.line([P(*v) for v in q], fill=(170, 70, 60, 255), width=px(2.0))
        elif f["k"] == "cyclecross":
            g.line([P(*v) for v in q], fill=RED, width=px(2.2))
    for s in data.get("symbols", []):
        if not (X0 < s["x"] < X1 and Z0 < s["z"] < Z1):
            continue
        x, z = P(s["x"], s["z"])
        dx, dz = s["d"]
        g.line([(x - dx * 1.2 * S, z - dz * 1.2 * S), (x + dx * 1.2 * S, z + dz * 1.2 * S)], fill=WHITE, width=px(0.3))
        if s["k"] == "arrow":
            for ch in s.get("t", "T"):
                if ch in "LR":
                    sg = 1 if ch == "R" else -1
                    nx, nz = -dz * sg, dx * sg
                    g.line([(x + dx * 0.6 * S, z + dz * 0.6 * S), (x + dx * 0.6 * S + nx * 0.9 * S, z + dz * 0.6 * S + nz * 0.9 * S)], fill=WHITE, width=px(0.3))
    if graph:
        for e in data.get("graph", {}).get("edges", []):
            if not near(e["p"]):
                continue
            q = [(e["p"][i], e["p"][i + 1]) for i in range(0, len(e["p"]), 2)]
            for k in range(int(e["n"])):
                off = float(e["o"]) + float(e["lw"]) * k
                line = []
                for i, (x, z) in enumerate(q):
                    a0, b0 = q[max(i - 1, 0)], q[min(i + 1, len(q) - 1)]
                    L = math.hypot(b0[0] - a0[0], b0[1] - a0[1]) or 1
                    line.append(P(x - (b0[1] - a0[1]) / L * off, z + (b0[0] - a0[0]) / L * off))
                g.line(line, fill=(0, 200, 230, 255), width=max(1, round(0.25 * S)))
                g.ellipse([line[0][0] - 3, line[0][1] - 3, line[0][0] + 3, line[0][1] + 3], fill=(0, 120, 200, 255))
    img.save(out)
    print("flat: %s %dx%d px" % (out, W, H))


def main():
    if len(sys.argv) < 3 or sys.argv[1] not in ("mosaic", "unroll", "flat"):
        print(__doc__)
        return 2
    {"mosaic": mosaic, "unroll": unroll, "flat": flat}[sys.argv[1]](sys.argv[2:])
    return 0


if __name__ == "__main__":
    sys.exit(main())
