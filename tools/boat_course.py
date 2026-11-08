"""Boat race "Wiślana Szprotka" (docs/design/boat-race.md): the course down the Vistula.

Follows the river from the mouth of Port Czerniakowski downstream (north-west) to below Most
Śląsko-Dąbrowski on game/map/water.bin's shore-distance channel (R: metres to the shore x 4):
every STEP metres the cross-section's two shores are found, the centre point taken, the
centreline smoothed (the side harbours, Port Praski above all, would pull it sideways), and the
half width clamped. Then the rings go along it every RING_GAP metres in a slalom from bank side
to bank side, a few small gold rings on the fast line, a quiet stretch where the sand barge
comes up the right-bank lane (rings keep to the left there), and the finish arch.

Writes game/data/boat_race.json:
    line   [[x, z, half_width], ...] every STEP m from the start, downstream
    rings  [{"i": line index, "x", "z", "yaw" (radians, the ring faces down the line), "w"
             (opening width, m), "gold": bool, "finish": bool}, ...]
    grid   four start slots [[x, z], ...] behind the start line, side by side
    barge  {"from": line index where it starts, "to": index it heads for, "side": lateral offset
            as a share of the half width (+ is the right bank, Praga)}
    flow   unit vector of the current, downstream at the start (the game samples the line)
boat_race.gd loads it; check_boat_race.gd checks the rings stand in open water clear of the
bridge piers and runs the rivals down it.

Bridge piers: the bake's piers standing in the water (centrum.json decks.piers) and Most
Poniatowskiego's own river piers (map_builder.gd PN_*, longer, with cutwaters) are circles the
course keeps clear of: a ring's opening PIER_RING m from any, the straight run between two rings
(and from the grid to the first) PIER_RUN m; a ring that fails moves across the river to the
nearest offset that clears both runs. The barge's lane does the same, line point by line point.

Usage:
    python3 -I tools/boat_course.py [--water=game/map/water.bin] [--out=game/data/boat_race.json]
        [--png=build/boat_course.png] [--map=game/map/centrum.json]
Run it again after a water.bin re-bake (check_boat_race.gd fails when a ring is on dry land).
"""
import json
import math
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
START = (1545.0, 705.0)     # in the river off the mouth of Port Czerniakowski, by the start pontoon
HEAD = (-0.45, -0.89)       # downstream at the start
STEP = 10.0
END_Z = -1880.0             # just past Most Śląsko-Dąbrowski
MAX_SCAN = 260.0            # a side harbour wider than this does not count as the river
SMOOTH = 9                  # moving-average half window (points)
HW_MAX = 120.0
FIRST = 14                  # the first ring this many points after the start line
RING_GAP = 12               # points between rings (120 m)
SWING = 0.42                # the slalom's lateral swing, a share of the half width
EDGE = 22.0                 # a ring's centre keeps this far from the shore
RING_W = 16.0
GOLD_W = 9.0
BARGE_FROM = 175
BARGE_TO = 20
BARGE_SIDE = 0.55
BARGE_CLEAR = (95, 185)     # rings in this index range keep to the left (west) half
PN_PIERS = [(1036.0, -171.0), (1106.0, -195.0), (1178.0, -219.0)]   # Poniatowski's river piers
PN_R = 16.0                 # half their length with the cutwaters
PN_HALF = 4.9               # half their thickness along the bridge (+0.4 m)
PIER_RING = 6.0             # clearance from a ring's opening (each end) to a pier's circle
PIER_RUN = 7.0              # clearance from the straight run between rings
BARGE_CLEAR_M = 10.0        # clearance from the barge's sides


def load(path):
    b = open(path, "rb").read()
    w, h = struct.unpack("<II", b[:8])
    x0, z0, px = struct.unpack("<fff", b[8:20])
    red = b[20::4][: w * h]

    def sd(x, z):
        i = int((x - x0) / px)
        j = int((z - z0) / px)
        if i < 0 or j < 0 or i >= w or j >= h:
            return 0.0
        return red[j * w + i] * 0.25
    return sd


def centreline(sd):
    p = START
    d = HEAD
    pts = []
    for _ in range(1000):
        if sd(*p) <= 0.0:
            break
        n = (-d[1], d[0])
        a = 0.0
        while a < MAX_SCAN and sd(p[0] + n[0] * a, p[1] + n[1] * a) > 0.0:
            a += 1.0
        c = 0.0
        while c < MAX_SCAN and sd(p[0] - n[0] * c, p[1] - n[1] * c) > 0.0:
            c += 1.0
        off = (a - c) * 0.5 if a < MAX_SCAN and c < MAX_SCAN else 0.0
        m = (p[0] + n[0] * off, p[1] + n[1] * off)
        pts.append([m[0], m[1], min(a, c) + abs(off) if off else min(a, c)])
        if len(pts) > 3:
            q = pts[-4]
            dd = (m[0] - q[0], m[1] - q[1])
            ln = math.hypot(*dd) or 1.0
            d = (0.7 * d[0] + 0.3 * dd[0] / ln, 0.7 * d[1] + 0.3 * dd[1] / ln)
            ln = math.hypot(*d)
            d = (d[0] / ln, d[1] / ln)
        p = (m[0] + d[0] * STEP, m[1] + d[1] * STEP)
        if p[1] < END_Z:
            break
    return pts


def smooth(pts, sd):
    out = []
    for i in range(len(pts)):
        lo = max(0, i - SMOOTH)
        hi = min(len(pts), i + SMOOTH + 1)
        x = sum(p[0] for p in pts[lo:hi]) / (hi - lo)
        z = sum(p[1] for p in pts[lo:hi]) / (hi - lo)
        out.append([x, z])
    # resample at STEP along the smoothed curve
    res = [out[0]]
    acc = 0.0
    for i in range(1, len(out)):
        a, b = out[i - 1], out[i]
        seg = math.hypot(b[0] - a[0], b[1] - a[1])
        t = 0.0
        while acc + seg - t >= STEP:
            t += STEP - acc
            acc = 0.0
            f = t / seg
            res.append([a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f])
        acc += seg - t
    # half width: the nearer shore across the smoothed line
    line = []
    for i, p in enumerate(res):
        j = min(i + 1, len(res) - 1)
        k = max(i - 1, 0)
        d = (res[j][0] - res[k][0], res[j][1] - res[k][1])
        ln = math.hypot(*d) or 1.0
        n = (-d[1] / ln, d[0] / ln)
        a = 0.0
        while a < HW_MAX and sd(p[0] + n[0] * a, p[1] + n[1] * a) > 0.0:
            a += 1.0
        c = 0.0
        while c < HW_MAX and sd(p[0] - n[0] * c, p[1] - n[1] * c) > 0.0:
            c += 1.0
        line.append([round(p[0], 1), round(p[1], 1), round(min(a, c), 1), n])
    return line


def _capsule(cx, cz, ax, az, half, r):
    """A pier's footprint (a capsule along (ax, az)) as circles every r m: [(x, z, r)]."""
    n = max(1, int(math.ceil(2.0 * max(0.0, half - r) / max(r, 0.5))))
    out = []
    for k in range(n + 1):
        t = -max(0.0, half - r) + 2.0 * max(0.0, half - r) * k / n
        out.append((cx + ax * t, cz + az * t, r))
    return out


def load_piers(path, sd):
    """Pier footprints in the water as circles: [(x, z, r)]. A bake pier is thin along its
    bridge (s[1]) and long across it (s[0], one carriageway's deck); Poniatowski's own piers
    replace the bake's on its river part."""
    out = []
    try:
        d = json.load(open(path))
    except OSError:
        return out
    bdir = (0.949, -0.316)
    for p in d.get("decks", {}).get("piers", []):
        c = p["c"]
        if sd(c[0], c[1]) <= 0.0:
            continue
        # Most Poniatowskiego's river part: its own stone piers stand there instead.
        rel = (c[0] - PN_PIERS[0][0], c[1] - PN_PIERS[0][1])
        along = rel[0] * bdir[0] + rel[1] * bdir[1]
        across = -rel[0] * bdir[1] + rel[1] * bdir[0]
        if -60.0 < along < 360.0 and abs(across) < 30.0:
            continue
        dx, dz = p["d"]
        out.extend(_capsule(c[0], c[1], -dz, dx, float(p["s"][0]), float(p["s"][1]) + 0.4))
    for c in PN_PIERS:
        out.extend(_capsule(c[0], c[1], -bdir[1], bdir[0], PN_R, PN_HALF))
    return out


def seg_clear(a, b, piers, margin):
    """The smallest gap from segment a-b to a pier circle (negative: it hits one)."""
    best = 1e9
    ax, az = a
    dx, dz = b[0] - ax, b[1] - az
    l2 = dx * dx + dz * dz or 1.0
    for (px, pz, r) in piers:
        t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / l2))
        g = math.hypot(ax + dx * t - px, az + dz * t - pz) - r - margin
        best = min(best, g)
    return best


def ring_ends(r):
    across = (math.cos(r["yaw"]), -math.sin(r["yaw"]))
    h = r["w"] * 0.5
    return (r["x"] - across[0] * h, r["z"] - across[1] * h), (r["x"] + across[0] * h, r["z"] + across[1] * h)


def clear_rings(rs, line, grid, piers, sd):
    """Moves rings across the river until each opening and each run between rings clears the
    piers: ring by ring down the course, a ring and (when the run between them crosses a bridge)
    the next one together, the nearest offsets first."""
    start = ((grid[1][0] + grid[2][0]) / 2, (grid[1][1] + grid[2][1]) / 2)

    def cands(r):
        x, z, hw, n = line[r["i"]]
        base = (r["x"] - x) * n[0] + (r["z"] - z) * n[1]
        out = [r]
        for step in range(1, 45):
            for sgn in (1.0, -1.0):
                off = base + sgn * step * 2.5
                if abs(off) <= hw - EDGE * 0.6:
                    out.append(dict(r, x=round(x + n[0] * off, 1), z=round(z + n[1] * off, 1)))
        return out

    def opening_ok(c):
        if c["finish"]:
            return True
        e0, e1 = ring_ends(c)
        return (seg_clear(e0, e1, piers, PIER_RING) >= 0.0 and sd(e0[0], e0[1]) >= 4.0
                and sd(e1[0], e1[1]) >= 4.0 and sd(c["x"], c["z"]) >= EDGE * 0.6)

    def run_ok(a, c):
        return seg_clear(a, (c["x"], c["z"]), piers, PIER_RUN) >= 0.0

    moved = 0
    for k in range(len(rs)):
        a = start if k == 0 else (rs[k - 1]["x"], rs[k - 1]["z"])
        nxt = rs[k + 1] if k + 1 < len(rs) else None
        if opening_ok(rs[k]) and run_ok(a, rs[k]) and (nxt is None or run_ok((rs[k]["x"], rs[k]["z"]), nxt)):
            continue
        done = False
        for c in (cands(rs[k]) if not rs[k]["finish"] else [rs[k]]):
            if not (opening_ok(c) and run_ok(a, c)):
                continue
            if nxt is None or run_ok((c["x"], c["z"]), nxt):
                rs[k] = c
                done = True
                break
            # the next ring moves too
            for c2 in (cands(nxt) if not nxt["finish"] else [nxt]):
                if opening_ok(c2) and run_ok((c["x"], c["z"]), c2):
                    rs[k] = c
                    rs[k + 1] = c2
                    done = True
                    break
            if done:
                break
        if done:
            moved += 1
        else:
            print("boat_course: ring %d at line %d: no offset clears the piers" % (k, rs[k]["i"]), file=sys.stderr)
    return moved


def barge_lane(line, piers, side):
    """Per line point (barge range) the barge's offset in metres (+ towards +n), clear of the piers."""
    lane = []
    want_prev = None
    for i, (x, z, hw, n) in enumerate(line):
        want = side * hw
        if want_prev is not None:
            want = want_prev  # keep to the lane it is in unless it has to move
        best = None
        for step in range(0, 60):
            for sgn in (1.0, -1.0):
                off = want + sgn * step * 2.0
                if abs(off) > hw - 12.0:
                    continue
                c = (x + n[0] * off, z + n[1] * off)
                if seg_clear(c, c, piers, BARGE_CLEAR_M) >= 0.0:
                    best = off
                    break
            if best is not None:
                break
        best = side * hw if best is None else best
        # drift back towards its side
        best += (side * hw - best) * 0.08
        lane.append(round(best, 1))
        want_prev = best
    return lane


def rings(line, sd):
    out = []
    k = 0
    i = FIRST
    while i < len(line) - 4:
        x, z, hw, n = line[i]
        # +n is which bank? +x is the right bank (Praga) on this stretch
        east = 1.0 if n[0] > 0 else -1.0
        side = 1.0 if k % 2 == 0 else -1.0
        amt = SWING * (0.6 if k % 4 == 1 else 1.0)
        off = side * amt * hw
        if BARGE_CLEAR[0] <= i <= BARGE_CLEAR[1]:
            off = -east * abs(off) if k % 2 == 0 else -east * 0.1 * hw
        off = max(-(hw - EDGE), min(hw - EDGE, off))
        rx, rz = x + n[0] * off, z + n[1] * off
        j = min(i + 1, len(line) - 1)
        yaw = math.atan2(line[j][0] - line[i - 1][0], line[j][1] - line[i - 1][1])
        gold = k % 5 == 3
        out.append({"i": i, "x": round(rx, 1), "z": round(rz, 1), "yaw": round(yaw, 4),
                    "w": GOLD_W if gold else RING_W, "gold": gold, "finish": False})
        k += 1
        i += RING_GAP
    # the finish arch on the centreline at the end, wide
    x, z, hw, n = line[-3]
    yaw = math.atan2(line[-1][0] - line[-5][0], line[-1][1] - line[-5][1])
    out.append({"i": len(line) - 3, "x": x, "z": z, "yaw": round(yaw, 4), "w": min(2.0 * hw - 2 * EDGE, 60.0),
                "gold": False, "finish": True})
    for r in out:
        if sd(r["x"], r["z"]) < EDGE * 0.5:
            print("boat_course: ring at line %d is near the shore (%.1f m)" % (r["i"], sd(r["x"], r["z"])), file=sys.stderr)
    return out


def main():
    args = dict(a.split("=", 1) for a in sys.argv[1:] if a.startswith("--") and "=" in a)
    water = args.get("--water", os.path.join(ROOT, "game/map/water.bin"))
    out = args.get("--out", os.path.join(ROOT, "game/data/boat_race.json"))
    sd = load(water)
    line = smooth(centreline(sd), sd)
    rs = rings(line, sd)
    piers = load_piers(args.get("--map", os.path.join(ROOT, "game/map/centrum.json")), sd)
    x, z, hw, n = line[2]
    d = (line[3][0] - line[1][0], line[3][1] - line[1][1])
    ln = math.hypot(*d)
    d = (d[0] / ln, d[1] / ln)
    grid = []
    for s in (-1.5, -0.5, 0.5, 1.5):
        grid.append([round(x + n[0] * s * 9.0 - d[0] * 6.0, 1), round(z + n[1] * s * 9.0 - d[1] * 6.0, 1)])
    east = 1.0 if line[BARGE_FROM][3][0] > 0 else -1.0
    moved = clear_rings(rs, line, grid, piers, sd)
    lane = barge_lane(line, piers, east * BARGE_SIDE)
    print("boat_course: %d pier circles in the water, %d rings moved clear of them" % (len(piers), moved))
    data = {
        "line": [[p[0], p[1], p[2]] for p in line],
        "rings": rs,
        "grid": grid,
        "barge": {"from": BARGE_FROM, "to": BARGE_TO, "side": round(east * BARGE_SIDE, 2), "lane": lane},
        "piers": [[round(p[0], 1), round(p[1], 1), p[2]] for p in piers],
        "flow": [round(d[0], 3), round(d[1], 3)],
    }
    with open(out, "w") as f:
        json.dump(data, f, separators=(",", ":"))
        f.write("\n")
    print("boat_course: %d line points (%.0f m), %d rings -> %s" % (len(line), len(line) * STEP, len(rs), out))
    png = args.get("--png")
    if png:
        try:
            from PIL import Image, ImageDraw
        except ImportError:
            return
        xs = [p[0] for p in line]
        zs = [p[1] for p in line]
        x0, z0 = min(xs) - 150, min(zs) - 150
        im = Image.new("RGB", (int((max(xs) - x0 + 150) / 2), int((max(zs) - z0 + 150) / 2)))
        for v in range(im.size[1]):
            for u in range(im.size[0]):
                if sd(x0 + u * 2, z0 + v * 2) > 0:
                    im.putpixel((u, v), (30, 60, 110))
        dr = ImageDraw.Draw(im)
        dr.line([((p[0] - x0) / 2, (p[1] - z0) / 2) for p in line], fill=(200, 200, 200))
        for (px, pz, pr) in piers:
            u, v = (px - x0) / 2, (pz - z0) / 2
            dr.ellipse((u - pr / 2, v - pr / 2, u + pr / 2, v + pr / 2), fill=(255, 60, 60))
        dr.line([((line[i][0] + line[i][3][0] * lane[i] - x0) / 2, (line[i][1] + line[i][3][1] * lane[i] - z0) / 2)
                 for i in range(BARGE_TO, BARGE_FROM)], fill=(120, 220, 120))
        for r in rs:
            u, v = (r["x"] - x0) / 2, (r["z"] - z0) / 2
            c = (255, 210, 0) if r["gold"] else ((255, 255, 255) if r["finish"] else (255, 110, 30))
            dx, dz = math.cos(r["yaw"]) * r["w"] / 4, -math.sin(r["yaw"]) * r["w"] / 4
            dr.line((u - dx, v - dz, u + dx, v + dz), fill=c, width=3)
        im.save(png)


if __name__ == "__main__":
    main()
