"""Footways whose walkers stand on the carriageway: a pavement mapped hugging the kerb (or a stub
running onto a junction's asphalt) puts the people walking it (pedestrians.gd: anywhere in the
middle 60 % of the footway's width, about 0.3 m of body round them) over the kerb onto the road.

Usage: python3 -I tools/check_foot_on_road.py [MAP_DIR] [--box=X0,Z0,X1,Z1] [--list] [--max=M]

The class, over the whole map (Marszałkowska at Widok, 2026-11-26, "pedestrians walk on it"): a
footway sample (every metre, not on a deck) that runs along a kerb within KERB_NEAR m (within
ALONG of parallel) and whose walking band reaches past that kerb onto a carriage polygon or a
drawn road ribbon, more than CROSSING_CLEAR m from any zebra or cycle crossing. Footways across a
road (crossings, OSM's footway=crossing) are not along a kerb and are not counted. Prints the
metres and the footways, per the whole map and inside --box; --list prints every footway with its
`--at=`. Exits 1 when the whole map has more than MAX metres (the count after the Widok junction,
recorded on purpose: a change that adds walkers on the road fails; one that removes some lowers
MAX in the same change). Standard library only, ~3 s.
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
KERB_NEAR = 2.5        # m: a kerb this near the footway's middle is the one it runs along
ALONG = 0.9            # cos: the footway runs within ~25 degrees of the kerb
BODY = 0.25            # m round a walker
SPREAD = 0.3           # pedestrians.gd: a walker's side offset, up to this share of the width
CROSSING_CLEAR = 3.0   # m: near a zebra or cycle crossing people step off the kerb on purpose
MAX = 9820             # m on the whole map after the Widok junction (2026-11-26; main had 9849, 398 footways)
CELL = 10.0


def pts(f):
    return [(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]


def inside(x, z, poly):
    hit = False
    j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi + 1e-12) + xi:
            hit = not hit
        j = i
    return hit


def seg_near(p, a, b):
    """(distance, unit direction of ab) from p to the segment ab."""
    dx, dz = b[0] - a[0], b[1] - a[1]
    L2 = dx * dx + dz * dz
    if L2 < 1e-12:
        return math.dist(p, a), (0.0, 0.0)
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / L2))
    L = math.sqrt(L2)
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dz), (dx / L, dz / L)


class Grid:
    def __init__(self):
        self.cells = {}

    def add_box(self, box, item):
        for i in range(int(box[0] // CELL), int(box[2] // CELL) + 1):
            for j in range(int(box[1] // CELL), int(box[3] // CELL) + 1):
                self.cells.setdefault((i, j), []).append(item)

    def at(self, x, z):
        return self.cells.get((int(x // CELL), int(z // CELL)), [])


def ribbon_quads(r):
    """The drawn (not hidden) pieces of a road ribbon as quads (map_builder's road strips)."""
    p = pts(r["p"])
    cum = [0.0]
    for a, b in zip(p, p[1:]):
        cum.append(cum[-1] + math.dist(a, b))
    hide, wv, cv = r.get("hide", []), r.get("wv"), r.get("cv")
    out = []
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
        out.append([(ax + nx * (ca - wa / 2), az + nz * (ca - wa / 2)), (bx + nx * (cb - wb / 2), bz + nz * (cb - wb / 2)),
                    (bx + nx * (cb + wb / 2), bz + nz * (cb + wb / 2)), (ax + nx * (ca + wa / 2), az + nz * (ca + wa / 2))])
    return out


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
    map_dir = args[0] if args else os.path.join(HERE, "..", "game", "map")
    with open(os.path.join(map_dir, "centrum.json"), encoding="utf-8") as f:
        d = json.load(f)
    box = [float(v) for v in opt["box"].split(",")] if "box" in opt else None
    limit = float(opt.get("max", MAX))
    asphalt = Grid()
    for c in d.get("carriage", []):
        if c.get("dk") is not None:
            continue
        q = pts(c["p"])
        if len(q) >= 3:
            asphalt.add_box((min(x for x, _ in q), min(z for _, z in q), max(x for x, _ in q), max(z for _, z in q)), q)
    for r in d.get("roads", []):
        if r.get("bridge") or r.get("dk") is not None or r.get("tn") is not None:
            continue
        for q in ribbon_quads(r):
            asphalt.add_box((min(x for x, _ in q), min(z for _, z in q), max(x for x, _ in q), max(z for _, z in q)), q)
    kerbs = Grid()
    for k in d.get("kerbs", []):
        q = pts(k["p"])
        for a, b in zip(q, q[1:]):
            kerbs.add_box((min(a[0], b[0]) - KERB_NEAR, min(a[1], b[1]) - KERB_NEAR,
                           max(a[0], b[0]) + KERB_NEAR, max(a[1], b[1]) + KERB_NEAR), (a, b))
    xings = Grid()
    for f in d.get("paths", []):
        if f["k"] in ("zebra", "cyclecross"):
            q = pts(f["p"])
            for a, b in zip(q, q[1:]):
                xings.add_box((min(a[0], b[0]) - CROSSING_CLEAR, min(a[1], b[1]) - CROSSING_CLEAR,
                               max(a[0], b[0]) + CROSSING_CLEAR, max(a[1], b[1]) + CROSSING_CLEAR), (a, b))

    def on_asphalt(x, z):
        return any(inside(x, z, q) for q in asphalt.at(x, z))

    total, total_paths, in_box, box_paths, rows = 0, 0, 0, 0, []
    for fi, f in enumerate(d.get("paths", [])):
        if f["k"] != "foot" or f.get("dk") is not None:
            continue
        line = pts(f["p"])
        reach = SPREAD * float(f.get("w", 2.0)) + BODY
        hits = []
        for a, b in zip(line, line[1:]):
            L = math.dist(a, b)
            if L < 0.05:
                continue
            u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
            n = max(1, int(L))
            for k in range(n):
                p = (a[0] + u[0] * (k + 0.5) * L / n, a[1] + u[1] * (k + 0.5) * L / n)
                best = None
                for ka, kb in kerbs.at(*p):
                    dist, kd = seg_near(p, ka, kb)
                    if dist <= KERB_NEAR and abs(u[0] * kd[0] + u[1] * kd[1]) >= ALONG and (best is None or dist < best[0]):
                        best = (dist, ka, kb)
                if best is None:
                    continue
                # the band's two edges; the one towards the kerb is the one that may be on the road
                nx, nz = -u[1], u[0]
                if not any(on_asphalt(p[0] + s * nx * reach, p[1] + s * nz * reach) for s in (-1.0, 1.0)):
                    continue
                if any(seg_near(p, xa, xb)[0] <= CROSSING_CLEAR for xa, xb in xings.at(*p)):
                    continue
                hits.append(p)
        if not hits:
            continue
        total += len(hits)
        total_paths += 1
        here = [h for h in hits if box and box[0] <= h[0] <= box[2] and box[1] <= h[1] <= box[3]]
        if here:
            in_box += len(here)
            box_paths += 1
        rows.append((len(hits), fi, hits[len(hits) // 2], len(here)))
    if "list" in opt:
        for n, fi, at, nb in sorted(rows, reverse=True):
            if box is None or nb:
                print("  footway %d: %d m, --at=%.0f,%.0f" % (fi, n, at[0], at[1]))
    msg = "%d m of footway with walkers on the road, %d footways" % (total, total_paths)
    if box:
        msg += "; in the box %d m, %d footways" % (in_box, box_paths)
    ok = total <= limit
    print("check_foot_on_road: %s (%s; at most %d)" % ("OK" if ok else "FAIL", msg, limit))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
