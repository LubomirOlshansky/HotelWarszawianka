"""Gates and gaps (walls look W8, docs/design/walls-true-to-life.md 6.6 row 9 and 10): where a path or a
service drive meets a fence, wall or hedge, the line gets a real opening with gate posts. A pass on the
finished map data (main's centrum.json, docs/architecture/tech-debt.md TD-25).

    python3 -I tools/barrier_gates.py [MAP_DIR] [--dry] [--force] [--list] [--rows=FILE]
        writes the gates into MAP_DIR/centrum.json (default game/map), stamp-guarded: a map that
        carries the stamp at VERSION is left alone (--force plans it again from the lines alone and
        rewrites; the result is the same). --dry prints the counts and writes nothing; --list prints
        every gate; --rows writes one row per gate (tools/overlay_object_types.py `sheet` reads it
        for the photo check: rules gap_path, gap_service, open_path, open_service).
    python3 -I tools/barrier_gates.py --check [MAP_DIR]
        exit 1 unless the map carries the stamp and its gates are what the rules give today
    python3 -I tools/barrier_gates.py --selftest
        the rules on synthetic lines (a crossing, a shared gate node, an opening across a drive, a
        deck, a hazard line, a path that only ends on a fence, idempotence)

What it writes, on `lines` items of kind fence, wall or hedge whose class `sc` is S or H (not R, not
G) and that carry no hazard reason `hz` (a gap there would let the car fall):

    g    [[s, w, leaf], ...]: a gap from s metres along the line, w metres long. RULE GAP: a `paths`
         centre line (foot, cycle, zebra, cycle crossing) or a service road's centre line crosses
         the line, strictly or through a point both share (OpenStreetMap's gate node: the way's
         vertex on the line, the way going on to both sides). w = (the way's width + GAP_PAD) over
         the sine of the crossing angle (at least SIN_MIN), so the clear width straight across the
         way is its width + GAP_PAD; gaps that touch merge. `leaf` is 0 for a path; for a service
         road +1 or -1, the side of the line (+1: the left of the line's own direction, x, z ->
         (-dz, dx)) where its two open leaves lie, swung back against it.
    ge   [start, end]: what stands at the line's first and last point. RULE OPEN: the end faces an
         opening the bake already cut (bake_structures.clear_carriageways cuts every line out of a
         drivable carriageway or lane, object_fixes L4 out of a footway or zebra): it lies within
         the way's half width + OPEN_REACH m of a way's centre line, its last segment points at it,
         and the end of another S or H line of the same kind faces it from the other side, the two
         feet on the centre line within OPEN_PAIR m, neither more than EDGE_TOL m inside the way's
         width. 0 nothing, 1 a gate post (a path), +2 or -2 a
         gate post with an open leaf swung back against the line on its left (+) or right (-) side
         (a service road). The key is written only on a line with a gate at one end at least.

Not on a crossing at a bridge deck or in a tunnel (the way's `dk`, a bridge road: the way and the line
at different heights), not on a hazard line. A path that only ends on a line gets nothing (it does not
cross). The yard side of a service gate (where its leaves open) is the side the drive runs on for
longer (a gate stands near the street; the drive goes on into the yard).

The game (city_barriers.gd) honours `g` and `ge` only under `barrier_look` typed and panels: no
geometry, panel pieces, colliders or soft segments inside a gap, panel indices still metres / 2 along
the whole line; two gate posts GATE_RISE m taller than the line at a gap's edges and at an `ge` end,
inside the line (the opening's width for the car is the gap's, or the cut's, unchanged); the leaves
lie along the line on the yard side. Classic ignores both keys, so the classic city is main's.

The stamp `barrier_gates`: {"v": VERSION, "lines": lines with a gate, "gaps": gaps, "gap_m": metres,
"ends": gate ends, "leaves": ends and gaps with leaves, "by": {"gap_path", "gap_service", "open_path",
"open_service"}}. bake_osm.py runs `apply` last; tools/check_post_passes.py runs it on main's map.
After it: tools/bake_street_details.py and tools/bake_park_details.py (their stamps hash `lines`; the
placements do not read the gates), tools/bake_sectors.py, bake_city.gd. Standard library only.
"""
import json
import math
import os
import sys
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, ".."))

KEY = "barrier_gates"
VERSION = 1
KINDS = ("fence", "wall", "hedge")
CLASSES = ("S", "H")
GAP_PAD = 0.4       # m: a gap is the way's width and this much (the brief; object_fixes GATE_PAD)
SIN_MIN = 0.5       # a crossing flatter than 30 degrees opens as one at 30 (object_fixes gate_cuts)
TOUCH = 0.05        # m: a way's vertex this near the line shares its point (a gate node)
MERGE = 0.3         # m: gaps closer than this along a line are one
PIECE_MIN = 0.3     # m: a gap that would leave less of the line than this before or after it runs to the end
OPEN_REACH = 1.5    # m: a line's end within the way's half width and this of its centre line can face an opening
OPEN_PAIR = 3.0     # m: the two ends' feet on the centre line this near: one opening
EDGE_TOL = 0.15     # m: an end further inside the way's width than this gets no gate (a post there would
                    # stand in the way; the bake's cut leaves a fence end up to 0.09 m inside a drive's width)
CELL = 16.0
PATH_KINDS = ("foot", "cycle", "zebra", "cyclecross")


def pairs(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def side(p, a, b):
    """> 0 when p lies left of a->b (x, z: the normal (-dz, dx))."""
    return (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])


def seg_foot(p, a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    L2 = dx * dx + dz * dz
    t = 0.0 if L2 < 1e-12 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dz) / L2))
    q = (a[0] + dx * t, a[1] + dz * t)
    return math.hypot(p[0] - q[0], p[1] - q[1]), t, q


def runs(line):
    acc = [0.0]
    for a, b in zip(line, line[1:]):
        acc.append(acc[-1] + math.hypot(b[0] - a[0], b[1] - a[1]))
    return acc


def ways_of(d):
    """[(kind, width, points, on a deck)]: every `paths` way and every service road."""
    out = []
    for p in d.get("paths", []):
        if p.get("k") in PATH_KINDS:
            out.append(("path", float(p.get("w", 2.0)), pairs(p["p"]), "dk" in p))
    for r in d.get("roads", []):
        if r.get("k") == "service":
            out.append(("service", float(r.get("w", 3.0)), pairs(r["p"]), "dk" in r or bool(r.get("bridge"))))
    return out


class Grid:
    def __init__(self):
        self.cells = defaultdict(list)

    def add(self, item, x0, z0, x1, z1):
        for i in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
            for j in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
                self.cells[(i, j)].append(item)

    def near(self, x0, z0, x1, z1):
        seen = set()
        for i in range(int(math.floor(x0 / CELL)), int(math.floor(x1 / CELL)) + 1):
            for j in range(int(math.floor(z0 / CELL)), int(math.floor(z1 / CELL)) + 1):
                for it in self.cells.get((i, j), ()):
                    if it not in seen:
                        seen.add(it)
                        yield it


def eligible(l):
    """A line that can get a gate: fence, wall or hedge, class S or H, no hazard, not a closed ring's
    nothing (a ring can take gaps; it has no ends)."""
    return l.get("k") in KINDS and l.get("sc") in CLASSES and not l.get("hz") and len(l.get("p", ())) >= 4


def way_part_lengths(pts, k, t):
    """The way's length before and after the point t along its segment k."""
    acc = runs(pts)
    s = acc[k] + t * (acc[k + 1] - acc[k])
    return s, acc[-1] - s


def crossings(line, ways, wgrid):
    """(s along the line, way index, sin of the angle, yard side) for every way that crosses `line`:
    a way's segment through one of its segments, or ways meeting at a point on the line (a way's
    vertex within TOUCH m of it: OpenStreetMap's gate node, one way through it or two that end there)
    whose neighbouring points lie on both sides of the line."""
    acc = runs(line)
    hits = {}
    at_point = {}   # (k, rounded s) -> [s, k, sides, [(wi, vertex)]]
    x0 = min(p[0] for p in line) - 1.0
    z0 = min(p[1] for p in line) - 1.0
    x1 = max(p[0] for p in line) + 1.0
    z1 = max(p[1] for p in line) + 1.0
    seen_v = set()
    for wi, vi in wgrid.near(x0, z0, x1, z1):
        kind, ww, pts, deck = ways[wi]
        if deck:
            continue
        c, e = pts[vi], pts[vi + 1]
        for k, (a, b) in enumerate(zip(line, line[1:])):
            La = acc[k + 1] - acc[k]
            if La < 1e-6:
                continue
            s1, s2 = side(c, a, b), side(e, a, b)
            s3, s4 = side(a, c, e), side(b, c, e)
            if s1 * s2 < 0 and s3 * s4 < 0:
                den = (b[0] - a[0]) * (e[1] - c[1]) - (b[1] - a[1]) * (e[0] - c[0])
                t = ((c[0] - a[0]) * (e[1] - c[1]) - (c[1] - a[1]) * (e[0] - c[0])) / den
                u = ((c[0] - a[0]) * (b[1] - a[1]) - (c[1] - a[1]) * (b[0] - a[0])) / den
                s = acc[k] + t * La
                key = (wi, round(s, 1))
                if key not in hits:
                    sin = abs(den) / (La * math.hypot(e[0] - c[0], e[1] - c[1]))
                    hits[key] = (s, wi, sin, _yard(kind, pts, vi, u, a, b))
                continue
            for v in (vi, vi + 1):
                if (wi, v, k) in seen_v:
                    continue
                dd, t, _ = seg_foot(pts[v], a, b)
                if dd >= TOUCH:
                    continue
                seen_v.add((wi, v, k))
                s = acc[k] + t * La
                g = at_point.setdefault((k, round(s, 1)), [s, k, set(), []])
                for n in (v - 1, v + 1):
                    if 0 <= n < len(pts):
                        sn = side(pts[n], a, b)
                        if abs(sn) > 1e-6 * La:
                            g[2].add(1 if sn > 0 else -1)
                g[3].append((wi, v))
    for s, k, sides, members in at_point.values():
        if sides != {1, -1}:
            continue
        a, b = line[k], line[k + 1]
        # The widest way there decides the width; the chord between its neighbours on each side (or
        # the ways' points next to the gate) the angle.
        members.sort(key=lambda m: -ways[m[0]][1])
        wi, v = members[0]
        nb = {}
        for mwi, mv in members:
            mp = ways[mwi][2]
            for n in (mv - 1, mv + 1):
                if 0 <= n < len(mp):
                    sn = side(mp[n], a, b)
                    if abs(sn) > 1e-9:
                        nb.setdefault(1 if sn > 0 else -1, mp[n])
        La = acc[k + 1] - acc[k]
        dx, dz = nb[1][0] - nb[-1][0], nb[1][1] - nb[-1][1]
        n = math.hypot(dx, dz)
        sin = abs((b[0] - a[0]) * dz - (b[1] - a[1]) * dx) / (La * n) if n > 1e-9 else 1.0
        kind, _, pts, _ = ways[wi]
        key = (wi, round(s, 1))
        if key not in hits:
            hits[key] = (s, wi, sin, _yard(kind, pts, min(v, len(pts) - 2), 0.0 if v < len(pts) - 1 else 1.0, a, b))
    return sorted(hits.values())


def _yard(kind, pts, k, t, a, b):
    """For a service road crossing line segment a-b at t along its own segment k: the side of the line
    its leaves go (the yard: the side the drive runs on for longer); 0 for a path."""
    if kind != "service":
        return 0
    before, after = way_part_lengths(pts, k, t)
    far = pts[0] if before >= after else pts[-1]
    return 1 if side(far, a, b) > 0 else -1


def plan_gaps(line, cr, ways):
    """The line's gaps from its crossings: [[s, w, leaf], ...] merged, clamped to the line."""
    L = runs(line)[-1]
    spans = []
    for s, wi, sin, yard in cr:
        kind, ww, _, _ = ways[wi]
        w = (ww + GAP_PAD) / max(sin, SIN_MIN)
        spans.append([s - w * 0.5, s + w * 0.5, yard, kind])
    spans.sort()
    merged = []
    for sp in spans:
        if merged and sp[0] <= merged[-1][1] + MERGE:
            m = merged[-1]
            m[1] = max(m[1], sp[1])
            m[2] = m[2] or sp[2]
            m[3] = "service" if "service" in (m[3], sp[3]) else m[3]
        else:
            merged.append(list(sp))
    out = []
    for a, b, yard, kind in merged:
        if a < PIECE_MIN:
            a = 0.0
        if b > L - PIECE_MIN:
            b = L
        if b - a <= 0.0:
            continue
        out.append(([round(a, 2), round(b - a, 2), yard], kind))
    return out


def plan_opens(d, ways, wgrid):
    """{line index: [start, end]} for the line ends facing an opening across a way."""
    lines = d.get("lines", [])
    ends = Grid()
    info = {}
    for i, l in enumerate(lines):
        if not eligible(l):
            continue
        pts = pairs(l["p"])
        if math.hypot(pts[0][0] - pts[-1][0], pts[0][1] - pts[-1][1]) < 1e-6:
            continue   # a ring has no ends
        for e, (p, q) in enumerate(((pts[0], pts[1]), (pts[-1], pts[-2]))):
            info[(i, e)] = (p, q)
            ends.add((i, e), p[0], p[1], p[0], p[1])
    found = {}
    for wi, (kind, ww, pts, deck) in enumerate(ways):
        if deck:
            continue
        reach = ww * 0.5 + OPEN_REACH
        for k, (a, b) in enumerate(zip(pts, pts[1:])):
            if math.hypot(b[0] - a[0], b[1] - a[1]) < 1e-6:
                continue
            cand = []
            for (i, e) in ends.near(min(a[0], b[0]) - reach, min(a[1], b[1]) - reach,
                                    max(a[0], b[0]) + reach, max(a[1], b[1]) + reach):
                p, q = info[(i, e)]
                dd, t, f = seg_foot(p, a, b)
                if dd > reach or dd < ww * 0.5 - EDGE_TOL or not 0.0 < t < 1.0:
                    continue
                sp, sq = side(p, a, b), side(q, a, b)
                # The end's last segment points at the way: its previous point on the same side, further off.
                if sp * sq <= 0 or abs(sq) <= abs(sp):
                    continue
                cand.append((dd, i, e, sp, f))
            cand.sort()
            left = [c for c in cand if c[3] > 0]
            right = [c for c in cand if c[3] < 0]
            for c1 in left:
                for c2 in right:
                    if (c1[1], c1[2]) in found or (c2[1], c2[2]) in found:
                        continue
                    if lines[c1[1]]["k"] != lines[c2[1]]["k"]:
                        continue
                    if math.hypot(c1[4][0] - c2[4][0], c1[4][1] - c2[4][1]) > OPEN_PAIR:
                        continue
                    for c in (c1, c2):
                        found[(c[1], c[2])] = (kind, wi, k, a, b)
                    break
    out = {}
    for (i, e), (kind, wi, k, a, b) in found.items():
        v = 1
        if kind == "service":
            # Leaves on the yard side of the line, against it: which side of the line that is.
            wpts = ways[wi][2]
            p, _ = info[(i, e)]
            _, t, _ = seg_foot(p, a, b)
            before, after = way_part_lengths(wpts, k, t)
            far = wpts[0] if before >= after else wpts[-1]
            # The line's own direction at this end: its first segment, or its last.
            lp = pairs(lines[i]["p"])
            la, lb = (lp[0], lp[1]) if e == 0 else (lp[-2], lp[-1])
            v = 2 if side(far, la, lb) > 0 else -2
        out.setdefault(i, [0, 0])[e] = v
    return out


def plan(d):
    """{line index: {"g": [...], "ge": [...]}} and the counts, from the lines and ways alone (the
    gates already on the map are not read, so a plan of a gated map is the plan of the clean one)."""
    ways = ways_of(d)
    wgrid = Grid()
    for wi, (kind, ww, pts, deck) in enumerate(ways):
        for vi, (a, b) in enumerate(zip(pts, pts[1:])):
            wgrid.add((wi, vi), min(a[0], b[0]), min(a[1], b[1]), max(a[0], b[0]), max(a[1], b[1]))
    res = {}
    by = Counter()
    gap_m = 0.0
    gaps = 0
    leaves = 0
    for i, l in enumerate(d.get("lines", [])):
        if not eligible(l):
            continue
        line = pairs(l["p"])
        cr = crossings(line, ways, wgrid)
        if not cr:
            continue
        g = plan_gaps(line, cr, ways)
        if g:
            res.setdefault(i, {})["g"] = [x for x, _ in g]
            for x, kind in g:
                by["gap_" + kind] += 1
                gaps += 1
                gap_m += x[1]
                leaves += x[2] != 0
    opens = plan_opens(d, ways, wgrid)
    ends = 0
    for i, ge in opens.items():
        # An end a gap already reaches has no end left to stand a post on.
        g = res.get(i, {}).get("g", [])
        L = runs(pairs(d["lines"][i]["p"]))[-1]
        if any(x[0] <= 0.0 for x in g):
            ge[0] = 0
        if any(x[0] + x[1] >= L - 0.01 for x in g):
            ge[1] = 0
        if not any(ge):
            continue
        res.setdefault(i, {})["ge"] = ge
        for v in ge:
            if v:
                ends += 1
                by["open_service" if abs(v) == 2 else "open_path"] += 1
                leaves += abs(v) == 2
    counts = {"lines": len(res), "gaps": gaps, "gap_m": round(gap_m, 1), "ends": ends, "leaves": leaves,
              "by": dict(sorted(by.items()))}
    return res, counts


def summary(c):
    by = c["by"]
    return ("%d lines: %d gaps, %.0f m (%d by paths, %d by service roads); %d gate ends at openings (%d by paths, "
            "%d by service roads); %d with leaves") % (
        c["lines"], c["gaps"], c["gap_m"], by.get("gap_path", 0), by.get("gap_service", 0), c["ends"],
        by.get("open_path", 0), by.get("open_service", 0), c["leaves"])


def write(d, res, counts):
    for l in d.get("lines", []):
        l.pop("g", None)
        l.pop("ge", None)
    for i, v in res.items():
        d["lines"][i].update(v)
    d[KEY] = dict(counts, v=VERSION)


def apply(d, map_dir=None, force=False):
    """Writes the gates into the map data `d` in place (stamp-guarded); returns a one-line summary."""
    stamp = d.get(KEY) or {}
    if int(stamp.get("v", 0)) >= VERSION and not force:
        return "already gated (%s)" % summary(stamp)
    res, counts = plan(d)
    write(d, res, counts)
    return summary(counts)


def rows_of(d, res):
    """One row per gate for the photo sheet (overlay_object_types.py sheet): the line's fields and the
    gate's point."""
    out = []
    for i, v in sorted(res.items()):
        l = d["lines"][i]
        line = pairs(l["p"])
        acc = runs(line)
        L = acc[-1]

        def at(s):
            for k in range(len(line) - 1):
                if acc[k + 1] >= s:
                    t = 0.0 if acc[k + 1] - acc[k] < 1e-9 else (s - acc[k]) / (acc[k + 1] - acc[k])
                    return (line[k][0] + (line[k + 1][0] - line[k][0]) * t, line[k][1] + (line[k + 1][1] - line[k][1]) * t)
            return line[-1]
        base = {"i": i, "k": l["k"], "ty": l.get("ty", ""), "tc": l.get("tc", ""), "sc": l.get("sc", ""),
                "hz": l.get("hz", ""), "L": round(L, 1), "h": l.get("h", l.get("hs", ""))}
        for s, w, leaf in v.get("g", []):
            x, z = at(s + w * 0.5)
            out.append(dict(base, rule="gap_service" if leaf else "gap_path", x=round(x, 1), z=round(z, 1), w=w))
        for e, val in enumerate(v.get("ge", [])):
            if val:
                x, z = line[0] if e == 0 else line[-1]
                out.append(dict(base, rule="open_service" if abs(val) == 2 else "open_path", x=round(x, 1), z=round(z, 1), end=e))
    return out


def check(map_dir):
    with open(os.path.join(map_dir, "centrum.json"), encoding="utf-8") as f:
        d = json.load(f)
    stamp = d.get(KEY) or {}
    if int(stamp.get("v", 0)) < VERSION:
        print("barrier_gates: FAIL (the map has no %s stamp v%d)" % (KEY, VERSION))
        return 1
    res, counts = plan(d)
    have = {i: {k: l[k] for k in ("g", "ge") if k in l} for i, l in enumerate(d.get("lines", [])) if "g" in l or "ge" in l}
    bad = [i for i in set(have) | set(res) if have.get(i) != res.get(i)]
    print("barrier_gates: " + summary(counts))
    if bad or {k: stamp.get(k) for k in counts} != counts:
        print("barrier_gates: FAIL (%d lines differ from the rules' gates)" % len(bad))
        return 1
    print("barrier_gates: OK")
    return 0


def selftest():
    bad = []

    def ok(name, got, want):
        if got != want:
            bad.append("%s: got %r, want %r" % (name, got, want))

    def fence(p, **kw):
        return dict({"k": "fence", "ty": "fence_plain", "tc": "default", "sc": "S", "p": p}, **kw)
    d = {"paths": [{"k": "foot", "w": 2.0, "p": [5.0, -5.0, 5.0, 5.0]},          # through the fence
                   {"k": "foot", "w": 2.0, "p": [15.0, -5.0, 15.0, 0.0, 15.0, 5.0]},  # through its vertex (a gate node)
                   {"k": "foot", "w": 2.0, "p": [25.0, -5.0, 25.0, 0.0]},          # only ends on it
                   {"k": "foot", "w": 2.0, "dk": 3, "p": [35.0, -5.0, 35.0, 5.0]},  # on a deck
                   # two ways that end at one gate node on the line, from both sides
                   {"k": "foot", "w": 2.0, "p": [30.0, -5.0, 30.0, 0.0]}, {"k": "foot", "w": 2.0, "p": [30.0, 0.0, 30.0, 5.0]}],
         "roads": [{"k": "service", "w": 3.0, "p": [100.0, -2.0, 100.0, 40.0]}],
         "lines": [fence([0.0, 0.0, 15.0, 0.0, 40.0, 0.0]),
                   fence([0.0, 10.0, 40.0, 10.0], hz="drop"),
                   fence([0.0, 20.0, 40.0, 20.0], sc="R"),
                   # an opening the bake cut across the drive: two pieces ending 1.8 m off its centre line
                   fence([90.0, 0.0, 98.2, 0.0]), fence([110.0, 0.0, 101.8, 0.0]),
                   # the same across a footway at x = 60 (a path from z = -5 to 5)
                   fence([50.0, 0.0, 58.6, 0.0], k="wall", sc="H"), fence([61.4, 0.0, 70.0, 0.0], k="wall", sc="H")]}
    d["paths"].append({"k": "foot", "w": 2.0, "p": [60.0, -5.0, 60.0, 5.0]})
    msg = apply(d)
    l0 = d["lines"][0]
    ok("three gaps", [x[0] for x in l0.get("g", [])], [3.8, 13.8, 28.8])
    ok("gap width", [x[1] for x in l0.get("g", [])], [2.4, 2.4, 2.4])
    ok("no leaves on a path", [x[2] for x in l0.get("g", [])], [0, 0, 0])
    ok("hazard line", "g" in d["lines"][1], False)
    ok("R line", "g" in d["lines"][2], False)
    ok("drive opening", (d["lines"][3].get("ge"), d["lines"][4].get("ge")) in (([0, 2], [0, -2]), ([0, -2], [0, 2])), True)
    # The yard is south (+z: the drive runs 40 m that way, 2 m north): line 3 runs east, its left is
    # (-dz, dx) = (0, 1), +z: +2. Line 4 runs west, its left is -z: -2.
    ok("yard side", (d["lines"][3].get("ge"), d["lines"][4].get("ge")), ([0, 2], [0, -2]))
    ok("path opening", (d["lines"][5].get("ge"), d["lines"][6].get("ge")), ([0, 1], [1, 0]))
    ok("no ge without a gate", any("ge" in d["lines"][i] for i in (0, 1, 2)), False)
    st = d[KEY]
    ok("stamp", (st["v"], st["gaps"], st["ends"], st["leaves"], st["by"]),
       (VERSION, 3, 4, 2, {"gap_path": 3, "open_path": 2, "open_service": 2}))
    snap = json.dumps(d, sort_keys=True)
    ok("second run", apply(d).startswith("already gated"), True)
    ok("second run changes nothing", json.dumps(d, sort_keys=True), snap)
    apply(d, force=True)
    ok("forced run gives the same", json.dumps(d, sort_keys=True), snap)
    # A service road through a fence: a gap with leaves on the yard side.
    d2 = {"paths": [], "roads": [{"k": "service", "w": 3.0, "p": [5.0, -2.0, 5.0, 30.0]}],
          "lines": [fence([0.0, 0.0, 10.0, 0.0])]}
    apply(d2)
    ok("service gap", d2["lines"][0].get("g"), [[3.3, 3.4, 1]])
    for b in bad:
        print("  " + b)
    print("barrier_gates selftest: %s (%s)" % ("OK" if not bad else "FAIL", msg))
    return 1 if bad else 0


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opt = dict(a[2:].split("=", 1) if "=" in a else (a[2:], "1") for a in argv if a.startswith("--"))
    if "selftest" in opt:
        return selftest()
    map_dir = os.path.abspath(args[0] if args else os.path.join(ROOT, "game", "map"))
    if "check" in opt:
        return check(map_dir)
    path = os.path.join(map_dir, "centrum.json")
    with open(path, encoding="utf-8") as f:
        d = json.load(f)
    if "dry" in opt or "list" in opt or "rows" in opt:
        res, counts = plan(d)
        print("barrier_gates (dry): " + summary(counts))
        rows = rows_of(d, res)
        if "list" in opt:
            for r in rows:
                print("  %-12s line %5d %-6s %-14s %s  (%.1f, %.1f)" % (r["rule"], r["i"], r["k"], r["ty"], r["sc"], r["x"], r["z"]))
        if "rows" in opt:
            with open(opt["rows"], "w", encoding="utf-8") as f:
                json.dump(rows, f, indent=0)
        return 0
    msg = apply(d, map_dir, force="force" in opt)
    print("barrier_gates: " + msg)
    if not msg.startswith("already"):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(d, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
