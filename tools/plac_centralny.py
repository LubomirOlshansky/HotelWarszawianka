"""Plac Centralny's planting (F's photos, 2026-11-05).

    python3 -I tools/plac_centralny.py [MAP.json] [--dry]     (rewrites the map in place, idempotent)

The new square in front of the Palace of Culture (Marszałkowska side, laid 2024-25: paved plazas,
lawns, a pool, the old parade tribune, a striped field of slabs and grass, 109 young trees of locust, ash, ginkgo and
magnolia) is in OpenStreetMap as lawns, plazas, paths and the pool, but the 2023 laser scan
predates the trees, so the lawns are bare. This module adds, on the finished map data and after
plaza_gardens (bake_osm.py calls `apply(out)` there):

  * young trees in loose groves on the lawns and in two rows along the central axis's edges, in
    the photos' mix (a narrow ginkgo, a light locust, an ash, a small magnolia), into `trees3d`
    (+ `trees3d_crown`);
  * perennial beds (`surfaces` kind flowerbed) under the groves and by the pool;
  * larch benches along the axis, seats towards the Palace.

The tribune, the striped field, the WARSZAWA letters and the lamps are the landmark sites
`trybuna` and `plac_centralny` (game/scripts/landmarks.gd); trees keep out of its footprint (KEEP_OUT).
Everything is deterministic (hashes of the position, never Python's hash) and `plac_centralny` in
the data marks the place as planted, so a second run adds nothing. Standard library only.
Spec: docs/landmarks/specs/plac_centralny.md.
"""
import json
import math
import os
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
sys.path.insert(0, TOOLS)
import bake_street_pois as P  # noqa: E402

MAP = os.path.join(ROOT, "game", "map", "centrum.json")

# Marszałkowska's frame (game/scripts/first_scene.gd FRAME_*): s metres north along the street,
# t metres east of it. The square is s -45..92, t -245..-23; the Palace's terrace is at t -245.
FRAME_O = (-937.0, 210.1)
FRAME_S = (-0.34917, -0.93706)
FRAME_T = (0.93706, -0.34917)

POI_GAP = 1.6
TREE_GAP = 4.0      # a new trunk keeps this far from every other trunk (scanned or ours)
CLEAR = 1.0         # the trunk's disc that must be clear of the solids
BED_CLEAR = 0.4
PATH_GAP = 1.3      # and from the middle of a mapped footway

# 2025 plantings, a year on: [top, crown radius, crown base, kind] (kind 1 = conifer).
SPECIES = {
    "ginkgo": [8.4, 1.5, 2.4, 0],     # miłorząb: narrow, light yellow-green
    "locust": [8.8, 2.1, 2.6, 0],     # glediczja / robinia: the light open crown of the photos' tall trees
    "ash": [9.4, 2.4, 2.8, 0],        # jesion
    "magnolia": [4.8, 1.8, 1.2, 0],   # magnolia: the small tree by the lawns' edge
}

# The tribune and the striped field with the sign (landmarks.gd trybuna, plac_centralny): no trunk here
# (s0, s1, t0, t1). 2026-11-08: moved with them onto the tribune's real spot (OSM's walls) and east of
# it; the rows along the axis (s 47.5 and 84) stay outside, so the planting is unchanged.
KEEP_OUT = [(49.0, 82.5, -136.0, -80.0)]

# The lamps of landmarks.gd PCZ_LAMPS [s, t]: no trunk within LAMP_GAP of one.
LAMPS = [(64.0, -205.0), (64.0, -190.0), (64.0, -76.0), (64.0, -64.0), (42.0, -200.0), (86.0, -200.0),
         (42.0, -120.0), (86.0, -120.0), (42.0, -160.0), (86.0, -160.0)]
LAMP_GAP = 1.6

# [s0, s1, t0, t1, spacing, mix]: the groves (the lawns and the Palace's forecourt strips).
GROVES = [
    (14.0, 46.0, -183.0, -145.0, 6.0, ["locust", "ginkgo", "ash", "ginkgo", "magnolia"]),     # south-west lawn
    (14.0, 45.0, -136.0, -76.0, 6.4, ["ginkgo", "locust", "ash", "locust", "magnolia"]),      # south-east lawn
    (84.0, 114.0, -181.0, -144.0, 6.0, ["ash", "locust", "ginkgo", "locust", "magnolia"]),    # north-west lawn
    (84.0, 112.0, -134.0, -76.0, 6.4, ["locust", "ginkgo", "ash", "ginkgo", "magnolia"]),     # north-east lawn, the pool's
    (14.0, 44.0, -238.0, -190.0, 6.6, ["ash", "locust", "ginkgo"]),                           # the Palace's south forecourt
    (82.0, 106.0, -238.0, -190.0, 6.6, ["locust", "ash", "ginkgo"]),                          # the Palace's north forecourt
]
# Two rows along the central axis's edges (s, t0, t1, step): the paved axis between the lawns.
ROWS = [(47.5, -176.0, -80.0, 8.0), (84.0, -176.0, -80.0, 8.0)]

# Benches along the axis: [s, t], seats towards the Palace (west).
BENCHES = [(51.0, -170.0), (51.0, -140.0), (51.0, -114.0), (77.0, -170.0), (77.0, -140.0), (77.0, -114.0)]


def world(s, t):
    return (FRAME_O[0] + s * FRAME_S[0] + t * FRAME_T[0], FRAME_O[1] + s * FRAME_S[1] + t * FRAME_T[1])


def frame(x, z):
    rx, rz = x - FRAME_O[0], z - FRAME_O[1]
    return rx * FRAME_S[0] + rz * FRAME_S[1], rx * FRAME_T[0] + rz * FRAME_T[1]


def _hash01(x, z, salt):
    """A stable 0..1 from a position (never Python's hash)."""
    return (math.sin(x * 12.9898 + z * 78.233 + salt * 37.719) * 43758.5453) % 1.0


def _keep_out(s, t):
    return any(a <= s <= b and c <= t <= d for a, b, c, d in KEEP_OUT)


def _path_near(paths, x, z, gap):
    for (ax, az), (bx, bz) in paths:
        dx, dz = bx - ax, bz - az
        n = dx * dx + dz * dz
        u = 0.0 if n == 0 else max(0.0, min(1.0, ((x - ax) * dx + (z - az) * dz) / n))
        if math.hypot(x - (ax + u * dx), z - (az + u * dz)) < gap:
            return True
    return False


def _footways(data):
    out = []
    for p in data.get("paths", []):
        if p["k"] != "foot":
            continue
        q = p["p"]
        pts = [(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]
        if not any(-60 <= frame(*pt)[0] <= 130 and -250 <= frame(*pt)[1] <= -15 for pt in pts):
            continue
        out.extend(zip(pts, pts[1:]))
    return out


def _lawns(data):
    """The mapped lawns and park beds near the square, as (s, t) polygons: a tree belongs on grass."""
    out = []
    for a in data.get("areas", []):
        if a["k"] not in ("grass", "park"):
            continue
        q = a["p"]
        pts = [frame(q[i], q[i + 1]) for i in range(0, len(q) - 1, 2)]
        if any(-60 <= s <= 130 and -250 <= t <= -15 for s, t in pts):
            out.append(pts)
    return out


def _inside(s, t, poly):
    hit = False
    for i in range(len(poly)):
        (as_, at), (bs, bt) = poly[i], poly[i - 1]
        if (at > t) != (bt > t) and s < as_ + (t - at) * (bs - as_) / (bt - at):
            hit = not hit
    return hit


def _bed(x, z, rx, rz, seed):
    """A bed's outline: an uneven 10-gon, flat [x, z, ...] as the map's surfaces."""
    out = []
    for i in range(10):
        a = i / 10 * math.tau
        k = 0.8 + _hash01(x + i, z - i, seed) * 0.4
        out += [round(x + math.cos(a) * rx * k, 1), round(z + math.sin(a) * rz * k, 1)]
    return out


def _tree(x, z, kind):
    top, radius, base, conifer = SPECIES[kind]
    k = 0.9 + _hash01(x, z, 2) * 0.22
    return [round(x, 1), round(z, 1), round(top * k, 1), round(radius * k, 1), round(base * k, 1), conifer]


def plan(data, solids):
    """The additions: (trees [x, z, top, radius, base, kind], beds [flat polygons], benches [x, z, yaw])."""
    t3 = data.get("trees3d", [])
    taken = [(t3[i], t3[i + 1]) for i in range(0, len(t3) - 5, 6)
             if -50 <= frame(t3[i], t3[i + 1])[0] <= 125 and -250 <= frame(t3[i], t3[i + 1])[1] <= -15]
    pois = [(p["x"], p["z"]) for p in data.get("pois", []) if p.get("k") != "address" and "x" in p]
    paths = _footways(data)
    lawns = _lawns(data)
    mine = []
    trees = []

    def try_tree(s, t, kind, need_lawn):
        if _keep_out(s, t):
            return
        if any(math.hypot(s - ls, t - lt) < LAMP_GAP for ls, lt in LAMPS):
            return
        if need_lawn and not any(_inside(s, t, poly) for poly in lawns):
            return
        x, z = world(s, t)
        if solids.blocked(x, z, CLEAR, skip=("tree",)):
            return
        if _path_near(paths, x, z, PATH_GAP):
            return
        if any(math.hypot(x - px, z - pz) < POI_GAP for px, pz in pois):
            return
        if any(math.hypot(x - tx, z - tz) < TREE_GAP for tx, tz in taken + mine):
            return
        trees.append(_tree(x, z, kind))
        mine.append((x, z))

    # The rows first (they set the axis), then the groves (loose, staggered, on the lawns only).
    for s0, t0, t1, step in ROWS:
        t = t0
        n = 0
        while t <= t1:
            try_tree(s0 + (_hash01(s0, t, 3) - 0.5) * 0.8, t, ["ginkgo", "locust"][n % 2], False)
            t += step
            n += 1
    for s0, s1, t0, t1, step, mix in GROVES:
        s = s0
        row = 0
        while s <= s1:
            t = t0 + (step * 0.5 if row % 2 else 0.0)
            while t <= t1:
                js = s + (_hash01(s, t, 3) - 0.5) * step * 0.6
                jt = t + (_hash01(s, t, 4) - 0.5) * step * 0.6
                kind = mix[int(_hash01(js, jt, 1) * len(mix)) % len(mix)]
                try_tree(js, jt, kind, True)
                t += step
            s += step * 0.87
            row += 1
    # Perennial beds beside some trunks (the photos' gravel-mulched beds of grasses and sage).
    beds = []
    for t in trees:
        if t[3] > 2.2 or _hash01(t[0], t[1], 5) > 0.5:
            continue
        a = _hash01(t[0], t[1], 6) * math.tau
        bx, bz = t[0] + math.cos(a) * 2.2, t[1] + math.sin(a) * 2.2
        s, tt = frame(bx, bz)
        rx, rz = 1.3 + _hash01(bx, bz, 7) * 1.0, 1.0 + _hash01(bx, bz, 8) * 0.9
        ring = _bed(bx, bz, rx, rz, 9)
        pts = list(zip(ring[0::2], ring[1::2]))
        if _keep_out(s, tt):
            continue
        if not all(any(_inside(*frame(*pt), poly) for poly in lawns) for pt in pts):
            continue
        if any(solids.blocked(px, pz, BED_CLEAR, skip=("tree",)) for px, pz in pts):
            continue
        if any(math.hypot(px - mx, pz - mz) < 0.7 for px, pz in pts for mx, mz in mine):
            continue
        if any(math.hypot(bx - ox, bz - oz) < 3.6 for ox, oz in [(sum(b[0::2]) / 10, sum(b[1::2]) / 10) for b in beds]):
            continue
        beds.append(ring)
    benches = []
    for s, t in BENCHES:
        x, z = world(s, t)
        if solids.blocked(x, z, 0.9, skip=("tree", "bench")):
            continue
        # the seat faces yaw's -z (plaza_gardens): towards the Palace, west = -t
        dx, dz = -FRAME_T[0], -FRAME_T[1]
        benches.append([round(x, 1), round(z, 1), round(math.atan2(-dx, -dz), 2)])
    return trees, beds, benches


def apply(data, verbose=True):
    """Plants the square into the finished map data; returns the number of trees added."""
    import bake_osm
    if data.get("plac_centralny"):
        if verbose:
            print("plac centralny: already planted")
        return 0
    solids = P.Solids(data)
    trees, beds, benches = plan(data, solids)
    data["plac_centralny"] = True
    flat = [v for t in trees for v in t]
    data.setdefault("trees3d_crown", []).extend(bake_osm.crown_scales(flat, data.get("roads", [])))
    data.setdefault("trees3d", []).extend(flat)
    data.setdefault("surfaces", []).extend({"k": "flowerbed", "p": b} for b in beds)
    data.setdefault("benches", []).extend(v for b in benches for v in b)
    if verbose:
        print(f"plac centralny: {len(trees)} trees, {len(beds)} beds, {len(benches)} benches")
    return len(trees)


def main(argv):
    path = MAP
    dry = False
    for arg in argv:
        if arg == "--dry":
            dry = True
        elif arg.startswith("--"):
            print(__doc__)
            return 2
        else:
            path = arg
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    n = apply(data)
    if n and not dry:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
