"""Street objects audit (F, 2026-11-07: "rework the objects on the roads ... look for the artifacts,
unslop the objects, remove or change the objects that are not in place or mean something else").

    python3 -I tools/object_audit.py [MAP.json] [--street=NAME] [--box=X0,Z0,X1,Z1] [--json=OUT] [--list=N]
        prints the artifact counts per rule (and per street with --street / --box), --list N
        prints the first N findings of each rule with their position; --json writes them all.
    python3 -I tools/object_audit.py [MAP.json] --by-street[=N]
        the N streets (default 30) with the most findings, each finding given to the named road
        within STREET_REACH m of it (the street-by-street worklist).

Every small object the bake places from OpenStreetMap (lamps, signal poles, benches, bins, bike
racks, advertising columns, shelters, parked cars, the street-detail props in
game/data/street_details.json) and every barrier line (fences, walls, hedges) is tested against
the finished map: buildings and landmark footprints, road ribbons, traffic islands and medians,
zebras, tram tracks, water, steps and decks. A rule is an artifact the player can see:

    P1 inside  the object stands inside a building at least 1.5 m high (it pokes out of the wall)
    P2 lane    a pavement object or signal pole inside a road's carriageway (not on an island or median)
    P3 zebra   a pavement object on the middle of a zebra
    P4 track   on a tram track's rails
    P5 water   in the river or a pond
    P6 deck    under a bridge or viaduct deck: OSM put it on the deck, the game draws it on the
               ground below (props stand on terrain_height), so it hangs in the shade under the slab
    P7 double  the same kind of object again within DOUBLE m (two bake sources for one thing)
    P8 steps   a bench, bin, rack, column or shelter on a flight of steps
    P9 alone   a signal pole more than SIGNAL_REACH m from any junction or crossing (means nothing)
    P10 shelter a bus/tram shelter more than SHELTER_REACH m from any road a bus or tram uses
               (OSM's amenity=shelter in a park or a yard: a picnic roof drawn as a bus stop)
    P11 car    a parked car on a zebra, a lane, another parked car or in a building
    L1 inside  a barrier run mostly inside a building
    L2 stub    a barrier fragment shorter than STUB m that touches no other barrier
    L3 double  a barrier that runs on top of another one (two OSM ways for one fence)
    L4 path    a barrier across a footway or a zebra (the path walks into a wall; really a gate)
    L5 stairs  a wall or fence that frames a flight of steps (an underpass or metro stair): drawn as
               the 1.6-1.9 m grey slab, really a 1 m balustrade (street_pass B5, now city-wide); a line
               with OSM's height, material or fence type (tools/barrier_tags.py) keeps its mapped look

tools/object_fixes.py applies the confident verdicts to the map; this file only measures, so
it is also the before/after scorecard of every street. Deterministic, standard library only.
"""
import json
import math
import os
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
CELL = 16.0
DOUBLE = {"lamp": 1.2, "signal": 0.6, "bench": 0.5, "bin": 0.5, "bike": 0.5, "column": 1.5, "shelter": 2.0}
SIGNAL_REACH = 30.0
STREET_REACH = 30.0
SHELTER_REACH = 9.0
STUB = 1.5
# A pole closer than this to a track's centreline stands on the rails (centre poles between two
# tracks stand about 1.8 m from each, and are real).
TRACK = 1.2
# L5: a stair's side wall stands within STAIR m of the flight's line, and is at most STAIR_RUN m long.
STAIR = 2.2
STAIR_RUN = 40.0
PAVEMENT = ("lamp", "bench", "bin", "bike", "column", "shelter", "sd")
STRIDE = {"lamps": 2, "signals": 3, "benches": 3, "bins": 3, "bikes": 3, "columns": 3, "shelters": 3, "parked": 4}
KIND = {"lamps": "lamp", "signals": "signal", "benches": "bench", "bins": "bin", "bikes": "bike",
        "columns": "column", "shelters": "shelter", "parked": "car"}
RULES = {
    "P1": "inside a building or landmark", "P2": "in a carriageway", "P3": "on a zebra",
    "P4": "on tram rails", "P5": "in water", "P6": "under a deck (drawn on the ground below)",
    "P7": "double", "P8": "on steps", "P9": "signal far from any crossing",
    "P10": "shelter far from any bus/tram road", "P11": "parked car in the wrong place",
    "L1": "barrier inside a building", "L2": "barrier stub", "L3": "barrier on top of another",
    "L4": "barrier across a path or zebra", "L5": "stair wall drawn as a slab",
}
NO_ROOM = ("roof", "steps", "construction", "ruins", "bridge", "carport", "transformer_tower")


def pts(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def seg_d(p, a, b):
    ax, az = a
    dx, dz = b[0] - ax, b[1] - az
    L = dx * dx + dz * dz
    t = 0.0 if L < 1e-9 else max(0.0, min(1.0, ((p[0] - ax) * dx + (p[1] - az) * dz) / L))
    return math.hypot(p[0] - ax - t * dx, p[1] - az - t * dz), t


def inside(p, poly):
    x, z = p
    c = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, zi = poly[i]
        xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi + 1e-12) + xi:
            c = not c
        j = i
    return c


def crosses(a, b, c, d):
    def o(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return o(a, b, c) * o(a, b, d) < 0 and o(c, d, a) * o(c, d, b) < 0


class Grid:
    """Items (polygons or polylines with a payload) bucketed by the cells their bounding box covers."""

    def __init__(self, pad=0.0):
        self.cells = defaultdict(list)
        self.pad = pad

    def add(self, poly, item):
        xs = [p[0] for p in poly]
        zs = [p[1] for p in poly]
        for cx in range(int(math.floor((min(xs) - self.pad) / CELL)), int(math.floor((max(xs) + self.pad) / CELL)) + 1):
            for cz in range(int(math.floor((min(zs) - self.pad) / CELL)), int(math.floor((max(zs) + self.pad) / CELL)) + 1):
                self.cells[(cx, cz)].append((poly, item))

    def near(self, p):
        return self.cells.get((int(math.floor(p[0] / CELL)), int(math.floor(p[1] / CELL))), ())

    def near_seg(self, a, b):
        """The items in every cell the segment a-b passes, each once."""
        n = max(1, int(math.hypot(b[0] - a[0], b[1] - a[1]) / (CELL * 0.5)))
        seen = set()
        out = []
        for k in range(n + 1):
            t = k / n
            for it in self.near((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)):
                if id(it) not in seen:
                    seen.add(id(it))
                    out.append(it)
        return out


class World:
    """The finished map, indexed for point and line tests."""

    def __init__(self, d):
        self.d = d
        import check_streets
        self.asphalt = check_streets.pole_tests(d)
        self.blds = Grid()
        for b in d.get("buildings", []):
            if b.get("kind") in NO_ROOM or float(b.get("mh", 0.0)) > 1.5:
                continue
            poly = pts(b["p"])
            if len(poly) >= 3:
                self.blds.add(poly, (b.get("kind", ""), float(b.get("h", 0.0))))
        # Landmark outlines are left out: many are a site's outer ring round a courtyard or a
        # plaza (Muzeum's yard of parked cars), not a wall.
        self.water = Grid()
        for a in d.get("areas", []):
            if a.get("k") == "water":
                self.water.add(pts(a["p"]), "water")
        self.isl = Grid()
        for key in ("islands",):
            for a in d.get(key, []):
                poly = pts(a["p"])
                if len(poly) >= 3:
                    self.isl.add(poly, key)
        for m in d.get("medians", []):
            poly = pts(m.get("s", []))
            if len(poly) >= 3:
                self.isl.add(poly, "median")
        self.roads = Grid(pad=12.0)
        self.bus_roads = Grid(pad=SHELTER_REACH + 10.0)
        for r in d.get("roads", []):
            if r.get("bridge") or r.get("tunnel"):
                continue
            line = pts(r["p"])
            w = float(r.get("w", 6.0))
            self.roads.add(line, (r, w))
            if r.get("k") not in ("service", "living_street"):
                self.bus_roads.add(line, (r, w))
        self.trams = Grid(pad=SHELTER_REACH + 4.0)
        for t in d.get("trams", []):
            if int(t.get("dk", 0)) == 0:
                self.trams.add(pts(t["p"]), t)
        self.zebras = Grid(pad=3.0)
        self.foot = Grid(pad=3.0)
        for p in d.get("paths", []):
            line = pts(p["p"])
            if len(line) < 2:
                continue
            if p.get("k") == "zebra":
                self.zebras.add(line, float(p.get("w", 3.0)))
            elif p.get("k") in ("foot", "cycle"):
                self.foot.add(line, float(p.get("w", 2.0)))
        self.steps = Grid(pad=2.0)
        for s in d.get("steps", []):
            line = pts(s["p"])
            if len(line) >= 2:
                self.steps.add(line, s)
        self.decks = Grid(pad=12.0)
        for pc in d.get("decks", {}).get("pieces", []):
            line = pts(pc["p"])
            if len(line) >= 2 and pc.get("k") in ("road", "foot", "tram", "rail", None):
                self.decks.add(line, (float(pc.get("l", 4.0)), float(pc.get("r", 4.0))))
        self.junctions = Grid(pad=SIGNAL_REACH)
        ends = Counter()
        for r in d.get("roads", []):
            line = pts(r["p"])
            for q in (line[0], line[-1]):
                ends[(round(q[0], 1), round(q[1], 1))] += 1
        for q, n in ends.items():
            if n >= 3:
                self.junctions.add([q], "jn")
        for p in d.get("paths", []):
            if p.get("k") in ("zebra", "cyclecross"):
                line = pts(p["p"])
                if line:
                    self.junctions.add(line, "x")

    # -- point tests --------------------------------------------------------------------------
    def in_building(self, p, tall=0.0):
        """The kind of the building whose outline holds p (at least `tall` m high), or None."""
        for poly, (kind, h) in self.blds.near(p):
            if h >= tall and inside(p, poly):
                return kind
        return None

    def in_water(self, p):
        return any(inside(p, poly) for poly, _ in self.water.near(p))

    def on_island(self, p):
        return any(inside(p, poly) for poly, _ in self.isl.near(p))

    def lane_gap(self, p):
        """Distance past the nearest carriageway edge (negative: inside it), and that road."""
        best, road = 99.0, None
        for line, (r, w) in self.roads.near(p):
            for a, b in zip(line, line[1:]):
                dd, _ = seg_d(p, a, b)
                g = dd - w * 0.5
                if g < best:
                    best, road = g, r
        return best, road

    def on_line(self, grid, p, pad=0.0, mid=False):
        for line, w in grid.near(p):
            if not isinstance(w, float):
                continue
            for k, (a, b) in enumerate(zip(line, line[1:])):
                dd, t = seg_d(p, a, b)
                if dd < w * 0.5 - pad:
                    if not mid:
                        return True
                    # The zebra's middle: not its first and last 1.2 m (the kerb, where poles stand).
                    seg = math.hypot(b[0] - a[0], b[1] - a[1])
                    if len(line) == 2 and 1.2 < t * seg < seg - 1.2:
                        return True
                    if len(line) > 2 and 0 < k < len(line) - 2:
                        return True
        return False

    def on_track(self, p):
        for line, _ in self.trams.near(p):
            for a, b in zip(line, line[1:]):
                if seg_d(p, a, b)[0] < TRACK:
                    return True
        return False

    def on_steps(self, p):
        for line, _ in self.steps.near(p):
            for a, b in zip(line, line[1:]):
                if seg_d(p, a, b)[0] < 1.2:
                    return True
        return False

    def under_deck(self, p):
        for line, (l, r) in self.decks.near(p):
            for a, b in zip(line, line[1:]):
                dd, t = seg_d(p, a, b)
                if 0.0 < t < 1.0 and dd < min(l, r) - 0.3:
                    return True
        return False

    def near_any(self, grid, p, reach):
        for line, _ in grid.near(p):
            for a in line:
                if abs(a[0] - p[0]) < reach and abs(a[1] - p[1]) < reach and math.hypot(a[0] - p[0], a[1] - p[1]) < reach:
                    return True
            for a, b in zip(line, line[1:]):
                if seg_d(p, a, b)[0] < reach:
                    return True
        return False

    def bus_road_near(self, p):
        for line, (r, w) in self.bus_roads.near(p):
            for a, b in zip(line, line[1:]):
                if seg_d(p, a, b)[0] - w * 0.5 < SHELTER_REACH:
                    return True
        return self.near_any(self.trams, p, SHELTER_REACH + 3.0)


def objects(d, sd_items):
    """(key, index, kind, x, z) for every point object; index is the record's number in its list."""
    out = []
    for key, st in STRIDE.items():
        lst = d.get(key, [])
        for i in range(0, len(lst) - st + 1, st):
            out.append((key, i // st, KIND[key], float(lst[i]), float(lst[i + 1])))
    for i, it in enumerate(sd_items):
        out.append(("street_details", i, "sd:" + str(it[0]), float(it[1]), float(it[2])))
    return out


def audit(d, sd_items, keep=None):
    """Findings [(rule, key, index, kind, x, z, note)] for the objects `keep(x, z)` accepts."""
    w = World(d)
    keep = keep or (lambda x, z: True)
    out = []
    seen = defaultdict(list)
    for key, idx, kind, x, z in objects(d, sd_items):
        if not keep(x, z):
            continue
        p = (x, z)
        base = "sd" if kind.startswith("sd:") else kind
        hit = []
        b = w.in_building(p, 1.5)
        if b:
            hit.append(("P1", b))
        if w.in_water(p):
            hit.append(("P5", ""))
        if w.under_deck(p):
            hit.append(("P6", ""))
        if base in PAVEMENT or base in ("car", "signal"):
            g, road = w.lane_gap(p)
            limit = {"car": -0.9, "signal": -0.5}.get(base, -0.25)
            if base in ("lamp", "signal"):
                # Poles: on the asphalt as drawn (tapered bands, carriage areas), check_streets S1's test.
                drawn = w.asphalt[0](x, z) and not w.asphalt[1](x, z)
                g = min(g, limit - 0.01) if drawn else max(g, 0.0)
            if g < limit and road is not None and road.get("k") not in ("service",) and not w.on_island(p):
                hit.append(("P11" if base == "car" else "P2", f"{-g:.1f} m into {road.get('name') or road.get('k')}"))
        if base != "signal" and w.on_line(w.zebras, p, pad=0.2, mid=True):
            hit.append(("P11" if base == "car" else "P3", "zebra"))
        if base in PAVEMENT and w.on_track(p):
            hit.append(("P4", ""))
        if base in ("bench", "bin", "bike", "column", "shelter") and w.on_steps(p):
            hit.append(("P8", ""))
        if base == "signal" and not w.near_any(w.junctions, p, SIGNAL_REACH):
            hit.append(("P9", ""))
        if base == "shelter" and not w.bus_road_near(p):
            hit.append(("P10", ""))
        # P7: the same kind again within DOUBLE m (P11 for two parked cars on one spot).
        r = DOUBLE.get(base, 0.6 if base == "sd" else 2.2)
        cell = (int(x // 4), int(z // 4))
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for (ox, oz, ok) in seen[(cell[0] + dx, cell[1] + dz)]:
                    if ok == kind and math.hypot(ox - x, oz - z) < r:
                        hit.append(("P11" if base == "car" else "P7", f"{math.hypot(ox - x, oz - z):.1f} m"))
                        break
        seen[cell].append((x, z, kind))
        for rule, note in hit:
            out.append((rule, key, idx, kind, round(x, 1), round(z, 1), note))
    out += audit_lines(d, w, keep)
    return out


def line_len(line):
    return sum(math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(line, line[1:]))


def samples(line, step=1.0):
    out = []
    for a, b in zip(line, line[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        n = max(1, int(L / step))
        for k in range(n):
            t = k / n
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    out.append(line[-1])
    return out


def audit_lines(d, w, keep):
    out = []
    bars = Grid(pad=0.6)
    lines = d.get("lines", [])
    for i, l in enumerate(lines):
        if l.get("k") in ("fence", "wall", "hedge"):
            line = pts(l["p"])
            if len(line) >= 2:
                bars.add(line, i)
    for i, l in enumerate(lines):
        k = l.get("k")
        if k not in ("fence", "wall", "hedge"):
            continue
        line = pts(l["p"])
        if len(line) < 2:
            continue
        mid = line[len(line) // 2]
        if not keep(mid[0], mid[1]):
            continue
        L = line_len(line)
        ss = samples(line)
        inn = sum(1 for s in ss if w.in_building(s, 2.5))
        if inn > 0.6 * len(ss):
            out.append(("L1", "lines", i, k, round(mid[0], 1), round(mid[1], 1), f"{L:.1f} m"))
            continue
        if L < STUB:
            touch = False
            for e in (line[0], line[-1]):
                for oline, j in bars.near(e):
                    if j != i and any(seg_d(e, a, b)[0] < 0.6 for a, b in zip(oline, oline[1:])):
                        touch = True
                        break
                if touch:
                    break
            if not touch and not w.in_building(line[0]) and not w.in_building(line[-1]):
                out.append(("L2", "lines", i, k, round(mid[0], 1), round(mid[1], 1), f"{L:.1f} m"))
                continue
        # L3: 80 % of its samples lie within 0.4 m of another barrier of the same kind (the longer one stays).
        if L >= STUB:
            on = 0
            other = None
            for s in ss:
                for oline, j in bars.near(s):
                    if j == i or lines[j].get("k") != k:
                        continue
                    oL = line_len(oline)
                    if oL < L or (oL == L and j > i):
                        continue
                    if any(seg_d(s, a, b)[0] < 0.4 for a, b in zip(oline, oline[1:])):
                        on += 1
                        other = j
                        break
            if on >= 0.8 * len(ss):
                out.append(("L3", "lines", i, k, round(mid[0], 1), round(mid[1], 1), f"{L:.1f} m on #{other}"))
                continue
        # L5: most of a wall or fence lies within STAIR m of a flight of steps (and the line is styled
        # nothing yet): the stair's balustrade.
        if k in ("wall", "fence") and L <= STAIR_RUN and not l.get("st") and not any(t in l for t in ("h", "m", "ft")):
            by = sum(1 for s in ss if w.near_any(w.steps, s, STAIR))
            if by >= 0.6 * len(ss):
                out.append(("L5", "lines", i, k, round(mid[0], 1), round(mid[1], 1), f"{L:.1f} m"))
                continue
        # L4: a segment crossing a footway's or a zebra's centreline.
        for grid, what in ((w.zebras, "zebra"), (w.foot, "footway")):
            hitp = None
            for a, b in zip(line, line[1:]):
                for pl, pw in grid.near_seg(a, b):
                    for c, e in zip(pl, pl[1:]):
                        if crosses(a, b, c, e):
                            hitp = (c, e)
                            break
                    if hitp:
                        break
                if hitp:
                    break
            if hitp:
                out.append(("L4", "lines", i, k, round(mid[0], 1), round(mid[1], 1), what))
                break
    return out


def street_box(d, name, pad=25.0):
    xs, zs = [], []
    for r in d.get("roads", []):
        if r.get("name") == name:
            for x, z in pts(r["p"]):
                xs.append(x)
                zs.append(z)
    if not xs:
        raise SystemExit(f"object_audit: no road named {name!r}")
    segs = [pts(r["p"]) for r in d["roads"] if r.get("name") == name]

    def keep(x, z):
        for line in segs:
            for a, b in zip(line, line[1:]):
                if seg_d((x, z), a, b)[0] < pad:
                    return True
        return False
    return keep


def by_street(d, found):
    """{street name: Counter(rule)} for the findings, by the nearest named road within STREET_REACH."""
    g = Grid(pad=STREET_REACH)
    for r in d.get("roads", []):
        if r.get("name"):
            g.add(pts(r["p"]), r["name"])
    out = defaultdict(Counter)
    for f in found:
        p = (f[4], f[5])
        best, name = STREET_REACH, "(no street)"
        for line, nm in g.near(p):
            for a, b in zip(line, line[1:]):
                dd = seg_d(p, a, b)[0]
                if dd < best:
                    best, name = dd, nm
        out[name][f[0]] += 1
    return out


def load(path):
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    sdp = os.path.join(ROOT, "game", "data", "street_details.json")
    sd = []
    if os.path.exists(sdp):
        with open(sdp, encoding="utf-8") as f:
            sd = json.load(f).get("items", [])
    return d, sd


def main(argv):
    path = os.path.join(ROOT, "game", "map", "centrum.json")
    street = box = jout = None
    nlist = 0
    streets = 0
    for a in argv:
        if a.startswith("--street="):
            street = a.split("=", 1)[1]
        elif a.startswith("--box="):
            box = [float(v) for v in a.split("=", 1)[1].split(",")]
        elif a.startswith("--json="):
            jout = a.split("=", 1)[1]
        elif a.startswith("--by-street"):
            streets = int(a.split("=", 1)[1]) if "=" in a else 30
        elif a.startswith("--list="):
            nlist = int(a.split("=", 1)[1])
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        elif not a.startswith("--"):
            path = a
    d, sd = load(path)
    keep = None
    if street:
        keep = street_box(d, street)
    elif box:
        x0, z0, x1, z1 = box
        keep = lambda x, z: min(x0, x1) <= x <= max(x0, x1) and min(z0, z1) <= z <= max(z0, z1)
    f = audit(d, sd, keep)
    c = Counter(r[0] for r in f)
    by = defaultdict(Counter)
    for r in f:
        by[r[0]][r[3]] += 1
    print(f"object_audit: {len(f)} findings" + (f" along {street}" if street else ""))
    for rule in RULES:
        if c[rule]:
            kinds = ", ".join(f"{k} {n}" for k, n in by[rule].most_common(6))
            print(f"  {rule:4} {c[rule]:6}  {RULES[rule]:42} {kinds}")
            for r in [r for r in f if r[0] == rule][:nlist]:
                print(f"         {r[3]:12} ({r[4]}, {r[5]}) {r[6]}")
    if streets:
        rows = sorted(by_street(d, f).items(), key=lambda kv: -sum(kv[1].values()))[:streets]
        for name, cnt in rows:
            print(f"  {sum(cnt.values()):5}  {name:36} " + ", ".join(f"{r} {n}" for r, n in sorted(cnt.items())))
    if jout:
        with open(jout, "w", encoding="utf-8") as fo:
            json.dump([dict(zip(("rule", "key", "i", "kind", "x", "z", "note"), r)) for r in f], fo, ensure_ascii=False, indent=0)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
