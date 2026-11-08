"""road_design.py: build an area's roads from a design spec, from zero, instead of repairing OSM ribbons.

A street is one reference line (its `axis`, corners filleted with arcs) with a cross-section that
changes along it (`sections`); a junction is a shape of its own, made from its arms' kerbs and
corner arcs (kerb returns). The generator is the only writer of the area it designs: the old road
layers there (ribbons, carriage areas, kerbs, islands, medians, lines, arrows, zebras) are removed
and the new ones written in the same layers, so the renderer and both city paths are unchanged.
Research and the model: docs/design/road-design-system.md. Workflow: the `road-design` skill.

Usage:
  python3 -I tools/road_design.py AREA                 apply docs/roads/AREA.json to game/map/centrum.json
  python3 -I tools/road_design.py AREA --check         build it and run the checks; writes nothing
  python3 -I tools/road_design.py AREA --from BASE.json --out OUT.json   apply to BASE, write OUT
  python3 -I tools/road_design.py AREA --needs OSM.json                  the OSM evidence per street
  python3 -I tools/road_design.py --check-all          check every applied area (verify step `design`)

The map remembers what was applied (`road_design`: {area: version}); applying twice is refused
(take the map from before, e.g. `git show origin/main:game/map/centrum.json > base.json`, and use
--from). bake_osm.py runs `apply_all(out)` after road_smooth, so a re-bake keeps every area.

Spec (docs/roads/AREA.json), map metres, +x east, +z south; offsets are to the right of the axis
(the right as seen on the map from above when facing along it), negative to the left:
  {"area": "palace", "version": 1,
   "streets": [{"id": "marsz", "name": "Marszałkowska", "k": "secondary",
                "axis": [[x, z], ...], "fillet": 40,
                "sections": [{"s": 0, "taper": 25,
                              "cw": [{"l": -16.4, "r": -3.6, "lanes": [{"d": -1, "t": "T"}, {"d": -1, "k": "bus"}]},
                                     {"l": 3.6, "r": 16.4, "lanes": [...]}],
                              "med": ["tram"]}, ...],
                "crossings": [{"s": 120, "w": 4.0, "bs": 116, "bw": 2.2}],
                "openings": [{"s": 150, "side": 1, "w": 8, "r": 5}],
                "gaps": [{"s0": 140, "s1": 160}],
                "start": "j1", "end": "cut"}],
   "junctions": [{"id": "j1", "r": 9, "arms": {"marsz": {"x": 3.5}, ...}}]}
  lanes: d +1 along the axis, -1 against; k lane (default), bus, bike, park, gap (hatched; "plain":
  true for an unhatched strip between two solid lines); t turn arrows (L T R LT TR U);
  w width (else an equal share of what is left; "shift": true on a carriageway that moves
  sideways to the next section keeps its lane lines sliding with it). med: tram, grass, island (one per gap between
  carriageways; "none" for a painted gap). crossings: mid-block zebras (bs: a cycle crossing beside
  it). openings: a side road or driveway leaving one side (kerb break, two kerb returns). gaps: the
  median broken where a side street or U-turn crosses (paved; the lanes' paint runs on). closed:
  [{"s0", "s1", "side"}] where the map has a road crossing the kerb but the photo has an unbroken
  kerb (a footway-only service way, a plaza access): no automatic opening there.
  greens: [{"s0", "s1", "l", "r", "med"}] grass strips inside a tram median (offsets, or "edge" for
  the median's own edge on that side), raised and kerbed.
  A junction with "ring": {"c", "u", "ri", "rd", "track", "ro", "corners", "r", "lines"} is a
  roundabout: the island round c (ri, ri + rd on the diagonals of the frame u), the ring's outer
  edge a circle ro (per corner "a/b") met by each arm's kerbs in fillets of radius r, its dashed
  lane lines at the radii `lines`, all broken over a tram cross `track` m either side of the
  axes ("tram_axes": "v" for one tram line along v); "island": true draws the island itself (raised
  paving either side of the tram); "halves": true cuts the ring's asphalt in two along v instead of
  fanning it (for arms that leave the ring sideways); "radii" per corner "a/b" (a tight nose; where
  two arms' kerbs meet outside the circle the corner is a plain kerb return); an arm's "mouth" is where its medians end, "stop" where its stop line is.
  park_cars (area level): true puts parked cars along every `park` lane (road_design.park_cars).
  open_ends (area level): [{"x", "z", "note"}] path ends checked on the ortho that really stop at
  the kerb with no crossing; the continuity gate passes them.

Continuity (quality gate, F 2026-11-06): footways and cycle tracks stay continuous over the new
asphalt. Applying the design moves a pavement or cycle track the wider kerb covered out to the new
kerb, paints a zebra / cycle crossing where a side road's mouth cut one in two, and bends every
other cut end onto the nearest crossing of its kind; continuity() then fails any cut end that
stops at the kerb while its path goes on across the road (printed after --out, part of
--check-all, so tools/verify.sh `design` fails on it).
"""
import json
import math
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MAP = os.path.join(ROOT, "game", "map", "centrum.json")
SPECS = os.path.join(ROOT, "docs", "roads")

STEP = 1.0            # m between the axis' samples
TAPER = 25.0          # m: a kerb that moves between two sections does so over this (smoothstep)
CROSS_W = 4.0         # m: a zebra's width (P-10, 4 m in the centre)
CROSS_GAP = 1.0       # m between a crossing's near edge and the junction mouth
STOP_GAP = 1.2        # m between the stop line and the crossing (P-12)
SOLID = 20.0          # m of solid lane line before a stop line (P-2)
ARROWS = (6.0, 30.0)  # m before the stop line where the turn arrows go
BUS_EVERY = 60.0      # m between BUS words in a bus lane
BIKE_EVERY = 40.0     # m between bike symbols in a cycle lane
KERB_RETURN = 9.0     # m: default corner radius
FOOT_PAD = 2.5        # m round the designed asphalt where the old road layers are removed
MIN_MOUTH = 1.0       # m: an arm's carriageway starts at least this far from the corners' tangents
ISLAND_MIN = 1.0     # m: carriageways closer than this have no island between them (one carriageway)
NOSE = 1.2            # m: a median's rounded end stops this far behind a crossing
HATCH = 3.0           # m between a painted gap's bars
CHUNK = 8.0           # m: carriageway polygons in pieces this long (they drape on the terrain)


# --- small geometry -------------------------------------------------------------------------

def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, k):
    return (a[0] * k, a[1] * k)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1]


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def norm(a):
    n = math.hypot(a[0], a[1])
    return (a[0] / n, a[1] / n) if n > 1e-9 else (0.0, 0.0)


def right_of(d):
    """The right-hand normal (the map's right, x east and z south, seen from above)."""
    return (-d[1], d[0])


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def smoothstep(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3.0 - 2.0 * t)


def flat(pts, nd=2):
    out = []
    for p in pts:
        out += [round(p[0], nd), round(p[1], nd)]
    return out


def pts_of(f):
    return [(f[i], f[i + 1]) for i in range(0, len(f) - 1, 2)]


def plen(pts):
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def ring_area(p):
    return 0.5 * sum(p[i][0] * p[(i + 1) % len(p)][1] - p[(i + 1) % len(p)][0] * p[i][1] for i in range(len(p)))


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


def seg_hit(a, b, c, d):
    """Where segments ab and cd cross (t along ab), or None."""
    r = sub(b, a)
    s = sub(d, c)
    den = cross(r, s)
    if abs(den) < 1e-12:
        return None
    t = cross(sub(c, a), s) / den
    u = cross(sub(c, a), r) / den
    if 0.0 <= t <= 1.0 and 0.0 <= u <= 1.0:
        return t
    return None


def line_hit(p, d, q, e):
    """Where the lines p + u d and q + v e meet: (u, v), or None if parallel."""
    den = cross(d, e)
    if abs(den) < 1e-9:
        return None
    w = sub(q, p)
    return cross(w, e) / den, cross(w, d) / den


def fillet(pts, radius):
    """The polyline with each corner replaced by a circular arc (radius capped by the legs)."""
    if len(pts) < 3 or radius <= 0:
        return list(pts)
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[i], pts[i + 1]
        d1 = norm(sub(a, b))
        d2 = norm(sub(c, b))
        turn = math.acos(max(-1.0, min(1.0, dot(d1, d2))))   # the angle at the corner
        if turn > math.radians(178):
            out.append(b)
            continue
        half = turn / 2.0
        r = radius
        t = r / math.tan(half)
        cap = 0.45 * min(math.dist(a, b), math.dist(b, c))
        if t > cap:
            t = cap
            r = t * math.tan(half)
        p1 = add(b, mul(d1, t))
        p2 = add(b, mul(d2, t))
        centre = add(b, mul(norm(add(d1, d2)), r / math.sin(half)))
        a1 = math.atan2(p1[1] - centre[1], p1[0] - centre[0])
        a2 = math.atan2(p2[1] - centre[1], p2[0] - centre[0])
        sweep = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
        n = max(2, int(abs(sweep) * r / 1.5))
        for k in range(n + 1):
            ang = a1 + sweep * k / n
            out.append((centre[0] + r * math.cos(ang), centre[1] + r * math.sin(ang)))
    out.append(pts[-1])
    return out


def resample(pts, step):
    out = [pts[0]]
    carry = 0.0
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        L = math.dist(a, b)
        t = step - carry
        while t <= L:
            out.append(lerp(a, b, t / L))
            t += step
        carry = L - (t - step)
    if math.dist(out[-1], pts[-1]) > step * 0.3:
        out.append(pts[-1])
    else:
        out[-1] = pts[-1]
    return out


def arc(centre, r, a1, a2, step=1.0):
    sweep = (a2 - a1 + math.pi) % (2 * math.pi) - math.pi
    n = max(2, int(abs(sweep) * r / step))
    return [(centre[0] + r * math.cos(a1 + sweep * k / n), centre[1] + r * math.sin(a1 + sweep * k / n))
            for k in range(n + 1)]


# --- a street ---------------------------------------------------------------------------------

class Street:
    """One street: a filleted, resampled axis and its cross-section as functions of s."""

    def __init__(self, spec):
        self.spec = spec
        self.id = spec["id"]
        self.k = spec.get("k", "secondary")
        axis = [tuple(p) for p in spec["axis"]]
        self.pts = resample(fillet(axis, spec.get("fillet", 40.0)), STEP)
        self.cum = [0.0]
        for i in range(1, len(self.pts)):
            self.cum.append(self.cum[-1] + math.dist(self.pts[i - 1], self.pts[i]))
        self.L = self.cum[-1]
        self.tan = []
        for i in range(len(self.pts)):
            a = self.pts[max(0, i - 1)]
            b = self.pts[min(len(self.pts) - 1, i + 1)]
            self.tan.append(norm(sub(b, a)))
        self.sections = sorted(spec["sections"], key=lambda s: s["s"])
        n = len(self.sections[0]["cw"])
        for sec in self.sections:
            if len(sec["cw"]) != n:
                raise SystemExit("road_design: %s: every section needs %d carriageways" % (self.id, n))
        self.ncw = n
        self.meds = self.sections[0].get("med", ["none"] * (n - 1))
        self.s0 = 0.0          # the mouths (set by the junctions)
        self.s1 = self.L
        self.kerb_from = {}    # (end, side) -> metres from that end where the outer kerb starts (roundabouts)

    def at(self, s):
        """(point, tangent) on the axis s metres along."""
        s = min(max(s, 0.0), self.L)
        i = min(int(s / STEP), len(self.pts) - 2)
        while i > 0 and self.cum[i] > s:
            i -= 1
        while i < len(self.pts) - 2 and self.cum[i + 1] < s:
            i += 1
        seg = self.cum[i + 1] - self.cum[i]
        t = (s - self.cum[i]) / seg if seg > 0 else 0.0
        p = lerp(self.pts[i], self.pts[i + 1], t)
        d = norm(lerp(self.tan[i], self.tan[i + 1], t))
        if s <= 0.0:
            # the axis carries on straight past its ends (for the corner fits)
            pass
        return p, d

    def ext(self, s):
        """(point, tangent) also beyond the ends, straight on."""
        if s < 0.0:
            p, d = self.at(0.0)
            return add(p, mul(d, s)), d
        if s > self.L:
            p, d = self.at(self.L)
            return add(p, mul(d, s - self.L)), d
        return self.at(s)

    def cw_blend(self, nxt, i, s, edge=""):
        """How far (0..1) carriageway i has moved towards section `nxt` at s: over the section's
        taper before its s, or the carriageway's own ("at": where it arrives, "taper"; "l_at",
        "l_taper", "r_at", "r_taper" for one kerb) so a kerb can step square at a stairwell
        while the rest bends slowly."""
        cb = nxt["cw"][i]
        end = float(cb.get(edge + "at", cb.get("at", nxt["s"])))
        tp = float(cb.get(edge + "taper", cb.get("taper", nxt.get("taper", TAPER))))
        if s <= end - tp:
            return 0.0
        if s >= end:
            return 1.0
        return smoothstep((s - (end - tp)) / tp)

    def edges(self, s):
        """[(l, r)] of every carriageway at s, tapered."""
        idx = 0
        for k, x in enumerate(self.sections):
            if x["s"] <= s + 1e-6:
                idx = k
        cur = self.sections[idx]
        nxt = self.sections[idx + 1] if idx + 1 < len(self.sections) else None
        out = []
        for i in range(self.ncw):
            ca = cur["cw"][i]
            if nxt is None:
                out.append((ca["l"], ca["r"]))
                continue
            cb = nxt["cw"][i]
            tl = self.cw_blend(nxt, i, s, "l_")
            tr = self.cw_blend(nxt, i, s, "r_")
            out.append((ca["l"] + (cb["l"] - ca["l"]) * tl, ca["r"] + (cb["r"] - ca["r"]) * tr))
        return out

    def bounds(self, sec, s):
        """Each carriageway's lanes and lane boundaries for section `sec` at s: [(lanes, [x0..xn])].
        The widths come from the section's own kerbs (its nominal l and r); where the kerbs are
        tapering at s, only the outer lanes take up the change, so the lane lines stay put."""
        out = []
        for i, (l, r) in enumerate(self.edges(s)):
            cw = sec["cw"][i]
            L, R = float(cw["l"]), float(cw["r"])
            lanes = cw["lanes"]
            fixed = sum(float(x.get("w", 0.0)) for x in lanes)
            free = [x for x in lanes if "w" not in x]
            share = (R - L - fixed) / len(free) if free else 0.0
            k = (R - L) / fixed if (not free and fixed > 0) else 1.0
            xs = [L]
            for x in lanes:
                xs.append(xs[-1] + (float(x["w"]) * k if "w" in x else share))
            xs[0], xs[-1] = l, r
            out.append((lanes, xs))
        return out

    def lanes(self, s):
        """The lanes of each carriageway at s: [(lane spec, left offset, right offset)] per carriageway.
        The paint follows the section that holds s (lanes change by paint, at the section's start).
        Over the taper before the next section, every lane line that carries on into it (one within
        2 m of a line there) slides across to meet it, so no line jogs at the section change."""
        idx = 0
        for k, x in enumerate(self.sections):
            if x["s"] <= s + 1e-6:
                idx = k
        sec = self.sections[idx]
        rows = self.bounds(sec, s)
        nxt = self.sections[idx + 1] if idx + 1 < len(self.sections) else None
        if nxt is not None:
            ahead = here = None
            for i, (lanes, xs) in enumerate(rows):
                t = self.cw_blend(nxt, i, s)
                if max(t, self.cw_blend(nxt, i, s, "l_"), self.cw_blend(nxt, i, s, "r_")) <= 0.0:
                    continue
                if ahead is None:
                    ahead = self.bounds(nxt, nxt["s"])
                    here = self.bounds(nxt, s)
                at_end = self.bounds(sec, nxt["s"])[i][1]
                target = ahead[i][1][1:-1]
                used = set()
                if len(target) == len(xs) - 2 and sec["cw"][i].get("shift") is not None:
                    # a carriageway that moves sideways ("shift": true) keeps its lanes: each
                    # line slides to the same line of the next section (at once where a kerb
                    # steps on its own: the lanes share the carriageway between its kerbs)
                    own = any(k in nxt["cw"][i] for k in ("l_at", "r_at", "l_taper", "r_taper"))
                    nom = ahead[i][1]
                    for b in range(1, len(xs) - 1):
                        if own:
                            f = (nom[b] - nom[0]) / (nom[-1] - nom[0])
                            xs[b] = xs[0] + (xs[-1] - xs[0]) * f
                        else:
                            xs[b] = xs[b] + (here[i][1][b] - xs[b]) * t
                    continue
                for b in range(1, len(xs) - 1):
                    best = None
                    for c, y in enumerate(target):
                        if c in used:
                            continue
                        dd = abs(y - at_end[b])
                        if dd <= 2.0 and (best is None or dd < best[0]):
                            best = (dd, c)
                    if best is not None:
                        used.add(best[1])
                        goal = here[i][1][best[1] + 1]
                        xs[b] = xs[b] + (goal - xs[b]) * t
        out = []
        for lanes, xs in rows:
            out.append([(x, xs[n], xs[n + 1]) for n, x in enumerate(lanes)])
        return out

    def point(self, s, off):
        p, d = self.ext(s)
        return add(p, mul(right_of(d), off))

    def line(self, s0, s1, off_fn, step=STEP):
        """A polyline from s0 to s1 at the offset off_fn(s)."""
        if s1 < s0:
            return list(reversed(self.line(s1, s0, off_fn, step)))
        n = max(1, int(math.ceil((s1 - s0) / step)))
        return [self.point(s0 + (s1 - s0) * k / n, off_fn(s0 + (s1 - s0) * k / n)) for k in range(n + 1)]

    def outer(self, s, side):
        """The outer kerb's offset at s: side -1 the leftmost, +1 the rightmost."""
        e = self.edges(s)
        return e[0][0] if side < 0 else e[-1][1]


# --- the design -------------------------------------------------------------------------------

class Design:
    def __init__(self, spec, roads=None):
        self.spec = spec
        self.roads = roads      # the map's road ribbons: side roads found on them get openings
        self.area = spec["area"]
        self.streets = {s["id"]: Street(s) for s in spec["streets"]}
        self.out = {k: [] for k in ("carriage", "kerbs", "islands", "medians", "markings", "symbols",
                                    "zebras", "cyclecross", "tram_xings")}
        self.footprint = []     # polygons of designed asphalt and medians
        self.ring_islands = []  # (centre, radius) of roundabout islands the design draws itself
        self.mouths = []        # side-road mouths: old kerbs and lines go, the side road stays
        self.crossings = {}     # street id -> [(s0, s1)] where kerbs and lines break
        self.stops = {}         # street id -> [(s of the stop line, direction of the lanes it stops)]
        self.notes = []

    # junctions -----------------------------------------------------------------------------

    def arms(self, j):
        """The arms of a junction: (street, end, s at the end, direction leaving the junction)."""
        out = []
        for sid in j["arms"]:
            st = self.streets[sid]
            if st.spec.get("start") == j["id"]:
                p, d = st.at(0.0)
                out.append({"st": st, "end": 0, "p": p, "dir": d, "cfg": j["arms"][sid]})
            if st.spec.get("end") == j["id"]:
                p, d = st.at(st.L)
                out.append({"st": st, "end": 1, "p": p, "dir": mul(d, -1.0), "cfg": j["arms"][sid]})
        for a in out:
            a["ang"] = math.atan2(a["dir"][1], a["dir"][0])
        out.sort(key=lambda a: a["ang"])
        return out

    @staticmethod
    def arm_s(a, dist):
        """The street's s that lies `dist` metres out from the junction along the arm."""
        return dist if a["end"] == 0 else a["st"].L - dist

    @staticmethod
    def arm_kerb(a, side, dist):
        """A point of the arm's outer kerb `dist` out: side +1 the kerb towards the next arm
        (counter-clockwise in atan2 terms, the arm direction turned +90 degrees), -1 the other."""
        st = a["st"]
        s = Design.arm_s(a, dist)
        street_side = side if a["end"] == 0 else -side
        return st.point(s, st.outer(min(max(s, 0.0), st.L), street_side))

    def build_junction(self, j):
        arms = self.arms(j)
        n = len(arms)
        ring_spec = j.get("ring")
        if ring_spec:
            # round a roundabout the arms go in the order of where they meet the ring
            C = tuple(ring_spec["c"])
            for a in arms:
                q = add(a["p"], mul(a["dir"], 30.0))
                a["ang"] = math.atan2(q[1] - C[1], q[0] - C[0])
            arms.sort(key=lambda a: a["ang"])
        corners = self.ring_corners(j, arms) if ring_spec else self.plain_corners(j, arms)
        self._finish_junction(j, arms, corners)
        if ring_spec:
            self.ring_details(j)
        return arms

    def plain_corners(self, j, arms):
        """Kerb returns: each pair of neighbouring arms meets in an arc of radius r (j.r, radii)."""
        R = float(j.get("r", KERB_RETURN))
        n = len(arms)
        corners = []
        for i in range(n):
            a, b = arms[i], arms[(i + 1) % n]
            gap = (b["ang"] - a["ang"]) % (2 * math.pi) if n > 1 else 2 * math.pi
            r = float(j.get("radii", {}).get("%s/%s" % (a["st"].id, b["st"].id), R))
            pa = self.arm_kerb(a, +1, 0.0)
            pb = self.arm_kerb(b, -1, 0.0)
            if gap >= math.radians(170):
                # nearly straight on (or the outside of a bend): the kerb runs straight across
                corners.append({"a": a, "b": b, "ta": 0.0, "tb": 0.0, "arc": []})
                continue
            hit = line_hit(pa, a["dir"], pb, b["dir"])
            if hit is None:
                corners.append({"a": a, "b": b, "ta": 0.0, "tb": 0.0, "arc": []})
                continue
            corner = add(pa, mul(a["dir"], hit[0]))
            phi = gap
            t = r / math.tan(phi / 2.0)
            ta = hit[0] + t       # distance out along a's kerb (from the arm's end point)
            tb = hit[1] + t
            p1 = add(corner, mul(a["dir"], t))
            p2 = add(corner, mul(b["dir"], t))
            centre = add(corner, mul(norm(add(a["dir"], b["dir"])), r / math.sin(phi / 2.0)))
            a1 = math.atan2(p1[1] - centre[1], p1[0] - centre[0])
            a2 = math.atan2(p2[1] - centre[1], p2[0] - centre[0])
            corners.append({"a": a, "b": b, "ta": ta, "tb": tb, "arc": arc(centre, r, a1, a2)})
        return corners

    def _kerb_return(self, a, b, r):
        """A corner arc of radius r between arm a's +1 kerb and arm b's -1 kerb, or None."""
        pa = self.arm_kerb(a, +1, 0.0)
        pb = self.arm_kerb(b, -1, 0.0)
        hit = line_hit(pa, a["dir"], pb, b["dir"])
        if hit is None:
            return None
        phi = math.acos(max(-1.0, min(1.0, dot(a["dir"], b["dir"]))))
        if phi < 1e-3 or phi > math.radians(170):
            return None
        corner = add(pa, mul(a["dir"], hit[0]))
        t = r / math.tan(phi / 2.0)
        p1 = add(corner, mul(a["dir"], t))
        p2 = add(corner, mul(b["dir"], t))
        centre = add(corner, mul(norm(add(a["dir"], b["dir"])), r / math.sin(phi / 2.0)))
        a1 = math.atan2(p1[1] - centre[1], p1[0] - centre[0])
        a2 = math.atan2(p2[1] - centre[1], p2[0] - centre[0])
        return {"a": a, "b": b, "ta": hit[0] + t, "tb": hit[1] + t, "arc": arc(centre, r, a1, a2)}

    # roundabouts ---------------------------------------------------------------------------

    @staticmethod
    def ring_frame(g):
        """(centre, u, v) of a roundabout: u along one street through it, v square to u."""
        C = tuple(g["c"])
        u = norm(tuple(g.get("u", (0.0, 1.0))))
        return C, u, (u[1], -u[0])

    def ring_island(self, g, phi):
        """The central island's edge at frame angle phi: ri at the tram cross, ri + rd on the
        diagonals (the Rondo Dmowskiego island, landmarks.gd _rondo_r)."""
        C, u, v = self.ring_frame(g)
        r = float(g["ri"]) + float(g.get("rd", 0.0)) * math.sin(2.0 * phi) ** 2
        return add(C, add(mul(v, r * math.cos(phi)), mul(u, r * math.sin(phi))))

    def ring_phi(self, g, p):
        C, u, v = self.ring_frame(g)
        q = sub(p, C)
        return math.atan2(dot(q, u), dot(q, v))

    def _ring_fillet(self, C, a, side, rc, r):
        """Where arm a's outer kerb (side +1 towards the next arm) turns into the ring's outer
        circle rc: (distance out along the arm, kerb tangent point, circle tangent point, centre)."""
        d = a["dir"]
        nrm = (-d[1], d[0]) if side > 0 else (d[1], -d[0])
        # the distance out along the arm where a circle of radius r on the pavement side of the
        # kerb touches the ring's circle from outside (bisection: the arm need not point at C,
        # an arm that leaves the ring sideways ends on the ring, not at its centre)
        f = lambda t: math.dist(add(self.arm_kerb(a, side, t), mul(nrm, r)), C) - (rc + r)
        lo, hi = 0.0, 120.0
        if f(lo) >= 0.0:
            hi = lo
        for _ in range(50):
            if hi - lo < 0.01:
                break
            mid = (lo + hi) / 2.0
            if f(mid) < 0.0:
                lo = mid
            else:
                hi = mid
        t = hi
        k = self.arm_kerb(a, side, t)
        centre = add(k, mul(nrm, r))
        q = add(C, mul(sub(centre, C), rc / math.dist(centre, C)))
        return t, k, q, centre

    def ring_corners(self, j, arms):
        """A roundabout's outer edge: between two arms a circle round the centre (ring.ro, or
        ring.corners["a/b"] for that corner), met by each arm's kerb in a fillet of radius ring.r
        (ring.radii["a/b"] for that corner: a tight nose where an arm leaves the ring sideways)."""
        g = j["ring"]
        C = tuple(g["c"])
        r = float(g.get("r", KERB_RETURN))
        n = len(arms)
        corners = []
        for i in range(n):
            a, b = arms[i], arms[(i + 1) % n]
            key = "%s/%s" % (a["st"].id, b["st"].id)
            rc = float(g.get("corners", {}).get(key, g["ro"]))
            rr = float(g.get("radii", {}).get(key, r))
            ta, ka, qa, ca = self._ring_fillet(C, a, +1, rc, rr)
            tb, kb, qb, cb = self._ring_fillet(C, b, -1, rc, rr)
            ang = lambda c, p: math.atan2(p[1] - c[1], p[0] - c[0])
            arc_a = arc(ca, rr, ang(ca, ka), ang(ca, qa))
            a1, a2 = ang(C, qa), ang(C, qb)
            sweep = (a2 - a1) % (2 * math.pi)
            if sweep > 1.5 * math.pi:
                # the two fillets overlap: the arms' kerbs meet outside the ring's circle, so the
                # corner is a plain kerb return between them (an arm beside another's mouth)
                plain = self._kerb_return(a, b, rr)
                if plain:
                    corners.append(plain)
                    continue
            m = max(2, int(sweep * rc / 1.0))
            circ = [add(C, (rc * math.cos(a1 + sweep * k / m), rc * math.sin(a1 + sweep * k / m))) for k in range(m + 1)]
            arc_b = arc(cb, rr, ang(cb, qb), ang(cb, kb))
            corners.append({"a": a, "b": b, "ta": ta, "tb": tb, "arc": dedupe(arc_a + circ + arc_b)})
        return corners

    def ring_pieces(self, g, loop):
        """The ring's asphalt without its island: the outer edge `loop` (counter-clockwise in
        atan2 terms round the centre) fanned in to the island edge, in pieces of about 10 degrees.
        A piece ends only at a vertex no earlier vertex passes in angle and no later one falls
        back behind (a kerb running out along an arm turns back a little), so the straight edge
        from the island to that vertex never crosses the outer edge."""
        C = tuple(g["c"])
        th = []
        for p in loop:
            a = math.atan2(p[1] - C[1], p[0] - C[0])
            if th:
                a = th[-1] + (a - th[-1] + math.pi) % (2 * math.pi) - math.pi
            th.append(a)
        loop = loop + [loop[0]]
        th = th + [th[0] + 2 * math.pi]
        n = len(loop)
        pre = list(th)
        for k in range(1, n):
            pre[k] = max(pre[k - 1], th[k])
        suf = list(th)
        for k in range(n - 2, -1, -1):
            suf[k] = min(suf[k + 1], th[k])
        cuts = [k for k in range(n) if pre[k] <= th[k] + 1e-9 and th[k] <= suf[k] + 1e-9]
        _, u, v = self.ring_frame(g)

        def island(a):
            w = (math.cos(a), math.sin(a))
            return self.ring_island(g, math.atan2(dot(w, u), dot(w, v)))
        pieces = []
        i = cuts[0]
        for j in cuts[1:]:
            if th[j] - th[i] < math.radians(10.0) and j != cuts[-1] and j - i < 40:
                continue
            outer = loop[i:j + 1]
            m = max(1, int(math.degrees(th[j] - th[i]) / 2.0))
            inner = [island(th[j] - (th[j] - th[i]) * k / m) for k in range(m + 1)]
            piece = dedupe(outer + inner)
            if len(piece) >= 3 and abs(ring_area(piece)) > 0.05:
                pieces.append(piece)
            i = j
        return pieces

    def ring_halves(self, g, loop):
        """The ring's asphalt as two pieces cut along the frame's v axis (where the arms along
        it cross the ring): for a ring whose outer edge runs out and back along arms that leave
        it sideways, where a fan from the centre would cross itself. None if a cut ray does
        not cross the outer edge exactly once."""
        C, u, v = self.ring_frame(g)
        n = len(loop)
        hits = []
        for sgn in (1.0, -1.0):
            ray = mul(v, sgn)
            found = []
            for i in range(n):
                p, q = loop[i], loop[(i + 1) % n]
                h = line_hit(C, ray, p, sub(q, p))
                if h and h[0] > 0.0 and 0.0 <= h[1] < 1.0:
                    found.append((i, add(p, mul(sub(q, p), h[1])), sgn))
            if len(found) != 1:
                return None
            hits.append(found[0])
        pieces = []
        for (i0, p0, s0), (i1, p1, s1) in (hits, hits[::-1]):
            chain = [p0]
            k = i0
            while k != i1:
                k = (k + 1) % n
                chain.append(loop[k])
            chain.append(p1)
            # back along the island, through the same half as the chain: from the far cut's
            # side (phi 0 on +v, pi on -v) to the near one's
            mid = chain[len(chain) // 2]
            upper = dot(sub(mid, C), u) > 0.0          # the half with phi in (0, pi)
            phi1 = 0.0 if s1 > 0 else math.pi
            phi0 = 0.0 if s0 > 0 else math.pi
            if upper:
                a1, a2 = phi1, phi0                    # both in [0, pi]
            else:
                a1 = phi1 + (2 * math.pi if phi1 == 0.0 else 0.0)
                a2 = phi0 + (2 * math.pi if phi0 == 0.0 else 0.0)   # both in [pi, 2 pi]
            m = max(4, int(abs(a2 - a1) * float(g["ri"]) / 1.0))
            inner = [self.ring_island(g, a1 + (a2 - a1) * k / m) for k in range(m + 1)]
            piece = dedupe(chain + inner)
            pieces.append(piece)
        return pieces

    def ring_details(self, j):
        """The island's kerb (broken where the tram runs through it) and the ring's dashed lane
        lines (ring.lines: radii), broken over the tracks (ring.track: their half width;
        ring.tram_axes "uv" for a tram cross, "v" for one line along v)."""
        g = j["ring"]
        track = float(g.get("track", 0.0))
        cross = bool(g.get("tram", track > 0.0))
        sectors = (4 if g.get("tram_axes", "uv") == "uv" else 2) if cross else 1
        size = 2 * math.pi / sectors
        r0 = float(g["ri"])
        gap = math.asin(min(0.9, track / r0)) if cross else 0.0
        for q in range(sectors):
            span = size - 2 * gap
            n = max(4, int(span * r0 / 1.0))
            pts = [self.ring_island(g, q * size + gap + span * k / n) for k in range(n + 1)]
            self.out["kerbs"].append({"p": flat(pts)})          # the island on its right
            if g.get("island") and cross:
                # a paved island the tram crosses at grade: one raised piece either side
                self.out["islands"].append({"p": flat(pts)})
        if g.get("island"):
            self.ring_islands.append((tuple(g["c"]), float(g["ri"]) + float(g.get("rd", 0.0))))
        C, u, v = self.ring_frame(g)
        for rl in g.get("lines", []):
            rl = float(rl)
            gl = math.asin(min(0.9, (track + 0.5) / rl)) if cross else 0.0
            for q in range(sectors):
                p0 = q * size + gl
                span = size - 2 * gl
                n = max(4, int(span * rl / 1.0))
                pts = [add(C, add(mul(v, rl * math.cos(p0 + span * k / n)), mul(u, rl * math.sin(p0 + span * k / n))))
                       for k in range(n + 1)]
                self.out["markings"].append({"k": "lane", "p": flat(pts)})

    def _finish_junction(self, j, arms, corners):
        n = len(arms)
        ring_spec = j.get("ring")
        # each arm's mouth: past both of its corners' tangents
        for i, a in enumerate(arms):
            right = corners[i]["ta"]                  # this arm is corner i's `a`
            left = corners[(i - 1) % n]["tb"]         # and corner i-1's `b`
            a["mouth"] = max(right, left, 0.0) + MIN_MOUTH
            a["mouth"] = max(a["mouth"], float(a["cfg"].get("mouth", 0.0)))
            if ring_spec and "mouth" in a["cfg"]:
                # a roundabout arm's medians end at the ring's edge, inside the corner fillets
                a["mouth"] = float(a["cfg"]["mouth"])
                # its outer kerbs start where the corner fillets leave them, not at the mouth
                st = a["st"]
                for side, t in ((+1, right), (-1, left)):
                    street_side = side if a["end"] == 0 else -side
                    st.kerb_from[(a["end"], street_side)] = t
            cfg = a["cfg"]
            spans = []          # (near, far) metres out: the zebra and the cycle crossing
            a["zebra"] = None
            a["cycle"] = None
            if cfg.get("cross", True):
                w = float(cfg.get("w", CROSS_W))
                x = float(cfg.get("x", a["mouth"] + CROSS_GAP + w / 2.0))
                a["zebra"] = (x, w)
                spans.append((x - w / 2.0, x + w / 2.0))
                if "bx" in cfg:
                    bw = float(cfg.get("bw", 2.2))
                    a["cycle"] = (float(cfg["bx"]), bw)
                    spans.append((float(cfg["bx"]) - bw / 2.0, float(cfg["bx"]) + bw / 2.0))
            a["near"] = min([sp[0] for sp in spans] + [a["mouth"]]) if spans else a["mouth"]
            a["near"] = max(a["near"], a["mouth"]) if not spans else min(sp[0] for sp in spans)
            a["throat"] = max([sp[1] for sp in spans] + [a["mouth"]])
            st = a["st"]
            if a["end"] == 0:
                st.s0 = a["mouth"]
                st.t0 = a["throat"]
            else:
                st.s1 = st.L - a["mouth"]
                st.t1 = st.L - a["throat"]
        # the junction's asphalt: round the arms' mouths and the corner arcs
        ring = []
        halves = bool(ring_spec and ring_spec.get("halves"))
        for i, a in enumerate(arms):
            if halves:
                # the outer edge crosses each arm where its corner fillets leave the kerbs (the
                # throat covers the rest down to the mouth), so it never doubles back on a kerb
                # that flares out towards the ring
                ring.append(self.arm_kerb(a, -1, max(a["mouth"], corners[(i - 1) % n]["tb"])))
                ring.append(self.arm_kerb(a, +1, max(a["mouth"], corners[i]["ta"])))
                ring.append(self.arm_kerb(a, +1, corners[i]["ta"]))
                ring += corners[i]["arc"]
                continue
            ring.append(self.arm_kerb(a, -1, a["mouth"]))
            ring.append(self.arm_kerb(a, +1, a["mouth"]))
            c = corners[i]
            ring += [self.arm_kerb(a, +1, d) for d in self._down(a["mouth"], c["ta"])]
            ring += c["arc"]
            ring += [self.arm_kerb(c["b"], -1, d) for d in self._up(c["tb"], c["b"]["mouth"])]
        ring = dedupe(ring)
        if ring_spec:
            pieces = self.ring_halves(ring_spec, ring) if ring_spec.get("halves") else None
            for piece in pieces or self.ring_pieces(ring_spec, ring):
                self.out["carriage"].append({"k": j.get("k", "secondary"), "p": flat(piece)})
                self.footprint.append(piece)
        else:
            self.out["carriage"].append({"k": j.get("k", "secondary"), "p": flat(ring)})
            self.footprint.append(ring)
        # corner kerbs: from one arm's nearest crossing round the arc into the next arm's
        for i, c in enumerate(corners):
            a, b = c["a"], c["b"]
            run = [self.arm_kerb(a, +1, d) for d in self._down(a["throat"], c["ta"])]
            run += c["arc"]
            run += [self.arm_kerb(b, -1, d) for d in self._up(c["tb"], b["throat"])]
            run = dedupe(run)
            if len(run) >= 2:
                # the pavement on the line's right: run from b's kerb round the arc to a's
                self.out["kerbs"].append({"p": flat(list(reversed(run)))})
        for a in arms:
            self.arm_details(j, a)

    @staticmethod
    def _down(d0, d1, step=1.0):
        if d0 <= d1:
            return []
        n = max(1, int(math.ceil((d0 - d1) / step)))
        return [d0 - (d0 - d1) * k / n for k in range(n + 1)]

    @staticmethod
    def _up(d0, d1, step=1.0):
        if d1 <= d0:
            return []
        n = max(1, int(math.ceil((d1 - d0) / step)))
        return [d0 + (d1 - d0) * k / n for k in range(n + 1)]

    def arm_details(self, j, a):
        """The throat (full-width asphalt from the mouth to past the crossings), the crossings,
        the stop line of the lanes coming in."""
        st = a["st"]
        sm = self.arm_s(a, a["mouth"])
        sth = self.arm_s(a, a["throat"])
        lo, hi = min(sm, sth), max(sm, sth)
        if hi - lo > 0.05:
            ring = st.line(lo, hi, lambda s: st.outer(s, -1)) + st.line(hi, lo, lambda s: st.outer(s, +1))
            self.out["carriage"].append({"k": st.k, "p": flat(ring)})
            self.footprint.append(ring)
        if a["zebra"]:
            x, w = a["zebra"]
            self.zebra(st, self.arm_s(a, x), w)
        if a["cycle"]:
            x, w = a["cycle"]
            self.cycle_crossing(st, self.arm_s(a, x), w)
        if a["zebra"] or a["cycle"] or "stop" in a["cfg"]:
            # the lanes heading into the junction stop STOP_GAP behind the farthest crossing
            # (cfg stop: x metres out, where a signalled arm has a stop line but no crossing)
            d_in = -1 if a["end"] == 0 else 1
            s_stop = self.arm_s(a, float(a["cfg"]["stop"]) if "stop" in a["cfg"] else a["throat"] + STOP_GAP)
            self.stops.setdefault(st.id, []).append((s_stop, d_in))
            for row in st.lanes(s_stop):
                run = [x for x in row if int(x[0].get("d", 1)) == d_in and x[0].get("k", "lane") in ("lane", "bus")]
                if run:
                    l = min(x[1] for x in run)
                    r = max(x[2] for x in run)
                    self.out["markings"].append({"k": "stop", "p": flat([st.point(s_stop, l + 0.15), st.point(s_stop, r - 0.15)])})

    def zebra(self, st, s, w):
        """A zebra (P-10) across every carriageway at s, w wide; over a tram bed a pale walkway."""
        self.crossings.setdefault(st.id, []).append((s - w / 2.0, s + w / 2.0))
        edges = st.edges(s)
        for (l, r) in edges:
            self.out["zebras"].append({"p": flat([st.point(s, l + 0.3), st.point(s, r - 0.3)]), "w": w})
        for i in range(len(edges) - 1):
            if st.meds[i] == "tram":
                self.out["tram_xings"].append({"k": "walk", "w": w, "p": flat([st.point(s, edges[i][1]), st.point(s, edges[i + 1][0])])})

    def cycle_crossing(self, st, s, w):
        """A cycle crossing (P-11) across the whole street at s."""
        self.crossings.setdefault(st.id, []).append((s - w / 2.0, s + w / 2.0))
        edges = st.edges(s)
        self.out["cyclecross"].append({"p": flat([st.point(s, edges[0][0]), st.point(s, edges[-1][1])])})

    # streets -------------------------------------------------------------------------------

    def build_street(self, st):
        for sx in st.spec.get("crossings", []):
            self.zebra(st, sx["s"], float(sx.get("w", CROSS_W)))
            if "bs" in sx:
                self.cycle_crossing(st, sx["bs"], float(sx.get("bw", 2.2)))
        t0 = getattr(st, "t0", st.s0)
        t1 = getattr(st, "t1", st.s1)
        if t1 - t0 < 1.0:
            return
        # carriageways in chunks, each between its own kerbs
        for i in range(st.ncw):
            for (u0, u1) in chunks(t0, t1):
                ring = st.line(u0, u1, lambda s, i=i: st.edges(s)[i][0]) + st.line(u1, u0, lambda s, i=i: st.edges(s)[i][1])
                self.out["carriage"].append({"k": st.k, "p": flat(ring)})
                self.footprint.append(ring)
        # medians between carriageways
        gaps = [(float(g["s0"]), float(g["s1"])) for g in st.spec.get("gaps", [])]
        for i, kind in enumerate(st.meds):
            if kind == "none":
                continue
            ml = lambda s, i=i: st.edges(s)[i][1]
            mr = lambda s, i=i: st.edges(s)[i + 1][0]
            if kind == "tram":
                m0, m1 = t0, t1
                strip = []
                for s in frange(m0, m1, 2.0):
                    strip += list(st.point(s, ml(s))) + list(st.point(s, mr(s)))
                self.out["medians"].append({"k": "paving", "s": [round(v, 2) for v in strip]})
                for (u0, u1) in self.kerb_runs(st, m0, m1):
                    self.out["kerbs"].append({"p": flat(st.line(u0, u1, ml))})   # the bed on its right
                    self.out["kerbs"].append({"p": flat(st.line(u1, u0, mr))})
                self.footprint.append(st.line(m0, m1, ml) + st.line(m1, m0, mr))
                # grass strips inside the tram median (greens: s0, s1, l, r; "edge" for the
                # median's own edge on that side), raised and kerbed like a grass median
                for gr in st.spec.get("greens", []):
                    if int(gr.get("med", 0)) != i:
                        continue
                    g0, g1 = max(m0, float(gr["s0"])), min(m1, float(gr["s1"]))
                    if g1 - g0 < 2.0:
                        continue
                    gl = ml if gr["l"] == "edge" else (lambda s, v=float(gr["l"]): v)
                    gr_ = mr if gr["r"] == "edge" else (lambda s, v=float(gr["r"]): v)
                    strip = []
                    for s in frange(g0, g1, 2.0):
                        strip += list(st.point(s, gl(s))) + list(st.point(s, gr_(s)))
                    self.out["medians"].append({"k": "grass", "s": [round(v, 2) for v in strip]})
            else:
                # a raised median (grass or paving) with rounded noses short of the crossings,
                # broken where a side street crosses (gaps), the break paved as carriageway
                # where a section brings the carriageways together (under ISLAND_MIN apart) there is
                # no island: the street is one carriageway there, its middle paved
                narrow = []
                for sx in frange(t0, t1, 1.0):
                    if mr(sx) - ml(sx) < ISLAND_MIN:
                        if narrow and sx - narrow[-1][1] <= 1.01:
                            narrow[-1][1] = sx
                        else:
                            narrow.append([sx, sx])
                narrow = [(max(t0, a - 0.5), min(t1, b + 0.5)) for a, b in narrow]
                for (g0, g1) in gaps + narrow:
                    ring = st.line(g0, g1, ml) + st.line(g1, g0, mr)
                    self.out["carriage"].append({"k": st.k, "p": flat(ring)})
                    self.footprint.append(ring)
                for (u0, u1) in self.runs_minus(t0, t1, self.crossings.get(st.id, []) + gaps + narrow):
                    m0, m1 = u0 + NOSE, u1 - NOSE
                    if m1 - m0 < 2.0:
                        continue
                    ring = nose_round(st.line(m0, m1, ml), st.line(m1, m0, mr))
                    if kind == "grass":
                        strip = []
                        for s in frange(m0, m1, 2.0):
                            strip += list(st.point(s, ml(s))) + list(st.point(s, mr(s)))
                        self.out["medians"].append({"k": "grass", "s": [round(v, 2) for v in strip]})
                    self.out["islands"].append({"p": flat(ring)})
                    self.footprint.append(ring)
        # outer kerbs, continuous past the crossings (the renderer lowers them under each zebra,
        # map_builder _lowered_kerb, and lays the tactile pads on them); open at side roads
        breaks = []
        for op in self.openings_of(st):
            breaks.append(self.opening(st, op))
        for side in (-1, +1):
            own = [b for b in breaks if not (isinstance(b, tuple) and len(b) == 3 and b[2] != side)]
            k0 = max(t0, st.kerb_from.get((0, side), 0.0))
            k1 = min(t1, st.L - st.kerb_from.get((1, side), 0.0))
            for (u0, u1) in self.runs_minus(k0, k1, [(b[0], b[1]) for b in own]):
                if side < 0:
                    self.out["kerbs"].append({"p": flat(st.line(u1, u0, lambda s: st.outer(s, -1)))})
                else:
                    self.out["kerbs"].append({"p": flat(st.line(u0, u1, lambda s: st.outer(s, +1)))})
        self.paint(st, t0, t1)

    def opening(self, st, op):
        """A side road or driveway leaving the street: the kerb opens, two small kerb returns
        lead into it and a patch of asphalt fills its mouth. Returns the kerb break (s0, s1, side)."""
        side = int(op["side"])
        s = float(op["s"])
        w = float(op.get("w", 6.0))
        r = float(op.get("r", 4.0))
        depth = float(op.get("depth", r + 1.5))
        p, d = st.at(s)
        nrm = mul(right_of(d), side)               # pointing out of the street, into the side road
        off = st.outer(s, side)
        edge = add(p, mul(right_of(d), off))
        # the side road's own direction out of the street (an angled road gets an angled mouth),
        # kept within 65 degrees of square so the corners stay buildable
        v = norm(tuple(op["dir"])) if op.get("dir") else nrm
        if dot(v, nrm) < 0.26:
            along = 1.0 if dot(v, d) > 0 else -1.0
            v = norm(add(mul(nrm, 0.26), mul(d, along * 0.966)))
        nv = right_of(v)
        if dot(nv, d) < 0:
            nv = mul(nv, -1.0)
        kerbs = []
        span = []
        for sgn in (-1, +1):
            # where this edge of the side road meets the street's kerb line
            q = mul(nv, sgn * w / 2.0)
            det = d[0] * (-v[1]) - d[1] * (-v[0])
            u = (q[0] * (-v[1]) - q[1] * (-v[0])) / det if abs(det) > 1e-6 else sgn * w / 2.0
            I = add(edge, mul(d, u))
            u1 = mul(d, float(sgn))                # along the kerb, away from the mouth
            phi = math.acos(max(-1.0, min(1.0, dot(u1, v))))
            T = r / math.tan(phi / 2.0)
            A = add(I, mul(u1, T))
            B = add(I, mul(v, T))
            c = add(I, mul(norm(add(u1, v)), r / math.sin(phi / 2.0)))
            a1 = math.atan2(A[1] - c[1], A[0] - c[0])
            a2 = math.atan2(B[1] - c[1], B[0] - c[0])
            pts = arc(c, r, a1, a2, 0.7) + [add(B, mul(v, 0.5))]
            kerbs.append(pts)
            span.append(u + sgn * T)
        ring = kerbs[0] + list(reversed(kerbs[1]))
        self.out["carriage"].append({"k": op.get("k", "service"), "p": flat(ring)})
        links = op.get("links", [])
        if op.get("merged"):
            links = [([add(edge, mul(v, 1.0)), add(edge, mul(v, 9.0))], w)]
        for pts, lw in links:
            band = strip(pts, lw / 2.0)
            if band:
                self.out["carriage"].append({"k": op.get("k", "service"), "p": flat(band)})
                self.mouths.append(band)
        self.mouths.append(ring)
        # kerb returns: the pavement on the line's right
        for sgn, pts in zip((-1, +1), kerbs):
            run = pts if (sgn * side) < 0 else list(reversed(pts))
            self.out["kerbs"].append({"p": flat(run)})
        return (s + min(span), s + max(span), side)

    def runs_minus(self, s0, s1, holes):
        runs = [(s0, s1)]
        for (c0, c1) in sorted(holes):
            nxt = []
            for (u0, u1) in runs:
                if c1 <= u0 or c0 >= u1:
                    nxt.append((u0, u1))
                    continue
                if c0 - u0 > 0.5:
                    nxt.append((u0, c0))
                if u1 - c1 > 0.5:
                    nxt.append((c1, u1))
            runs = nxt
        return runs

    def kerb_runs(self, st, s0, s1):
        """[s0, s1] minus the crossings (lowered kerbs)."""
        return self.runs_minus(s0, s1, self.crossings.get(st.id, []))

    def paint(self, st, s0, s1):
        """Lane lines (lane boundaries), bus, cycle and parking lanes, hatched gaps, arrows, words."""
        stops = self.stops.get(st.id, [])
        runs = {}
        s = s0
        while s <= s1 + 1e-6:
            for ci, row in enumerate(st.lanes(s)):
                for li in range(len(row) - 1):
                    a, b = row[li][0], row[li + 1][0]
                    kind = boundary_kind(a, b)
                    if kind is None:
                        continue
                    d = int(a.get("d", 1))
                    for (ss, din) in stops:
                        if kind == "lane" and din == d and int(b.get("d", 1)) == d and 0.0 <= (ss - s) * din <= SOLID:
                            kind = "solid"
                    if self.in_crossing(st, s) or self.past_stop(st, s, d, int(b.get("d", 1))):
                        kind = None
                    key = (ci, li, id(a), id(b))
                    runs.setdefault(key, []).append(None if kind is None else (kind, st.point(s, row[li][2])))
                for (x, l, r) in row:
                    if x.get("k") == "bike":
                        item = None if self.in_crossing(st, s) else ("cyclefill", st.point(s, (l + r) / 2.0), r - l)
                        runs.setdefault(("fill", ci, id(x)), []).append(item)
            s += STEP
        for key, seq in runs.items():
            cur = []
            last = None
            for item in seq + [None]:
                k = item[0] if item else None
                if item is None or (last is not None and k != last):
                    if len(cur) >= 2:
                        m = {"k": last, "p": flat([c[1] for c in cur])}
                        if last == "cyclefill":
                            m["w"] = round(cur[0][2] - 0.1, 2)
                        self.out["markings"].append(m)
                    cur = [] if item is None else ([cur[-1], item] if cur and k != "cyclefill" and last is not None else [item])
                    last = k
                    continue
                cur.append(item)
                last = k
        self.hatch(st, s0, s1)
        # arrows before every stop line
        for (ss, din) in stops:
            for back in ARROWS:
                sa = ss - din * back
                if not (s0 + 3 < sa < s1 - 3) or self.in_crossing(st, sa):
                    continue
                for row in st.lanes(sa):
                    for (x, l, r) in row:
                        if int(x.get("d", 1)) != din or x.get("k", "lane") != "lane" or not x.get("t"):
                            continue
                        p, d = st.at(sa)
                        c = add(p, mul(right_of(d), (l + r) / 2.0))
                        dd = mul(d, din)
                        self.out["symbols"].append({"k": "arrow", "x": round(c[0], 2), "z": round(c[1], 2),
                                                    "d": [round(dd[0], 3), round(dd[1], 3)], "t": x["t"]})
        # BUS words and bike symbols
        for kind, every in (("bus", BUS_EVERY), ("bike", BIKE_EVERY)):
            s = s0 + every / 2.0
            while s < s1 - 8:
                if not self.in_crossing(st, s) and not any(abs(s - ss) < 8 for (ss, _) in stops):
                    for row in st.lanes(s):
                        for (x, l, r) in row:
                            if x.get("k", "lane") == kind:
                                p, d = st.at(s)
                                c = add(p, mul(right_of(d), (l + r) / 2.0))
                                dd = mul(d, int(x.get("d", 1)))
                                self.out["symbols"].append({"k": kind, "x": round(c[0], 2), "z": round(c[1], 2),
                                                            "d": [round(dd[0], 3), round(dd[1], 3)]})
                s += every

    def hatch(self, st, s0, s1):
        """Painted gaps (P-21): diagonal bars every HATCH metres between the gap's edges."""
        s = s0 + 1.0
        while s < s1 - 1.0:
            if not self.in_crossing(st, s):
                for row in st.lanes(s):
                    for (x, l, r) in row:
                        if x.get("k") == "gap" and not x.get("plain") and r - l > 0.8:
                            a = st.point(s, l + 0.2)
                            b = st.point(min(s + (r - l) * 0.8, s1), r - 0.2)
                            self.out["markings"].append({"k": "stripe", "p": flat([a, b])})
            s += HATCH

    def in_crossing(self, st, s):
        return any(c0 - 0.3 <= s <= c1 + 0.3 for (c0, c1) in self.crossings.get(st.id, []))

    def past_stop(self, st, s, d, d2):
        """Between a stop line and its junction (the crossing and the throat): no lane lines."""
        for (ss, din) in self.stops.get(st.id, []):
            if (d == din or d2 == din) and (s - ss) * din > 0:
                return True
        return False

    def openings_of(self, st):
        """The street's side-road openings: found on the map's own roads where one crosses the
        street's outer kerb (when the map is given), plus any the spec marks "keep"; else the spec's."""
        if self.roads is None:
            return st.spec.get("openings", [])
        if not hasattr(st, "auto_open"):
            shut = st.spec.get("closed", [])
            st.auto_open = [o for o in self.find_openings(st)
                            if not any(c["s0"] <= o["s"] <= c["s1"] and int(c.get("side", o["side"])) == o["side"]
                                       for c in shut)] + \
                [o for o in st.spec.get("openings", []) if o.get("keep")]
        return st.auto_open

    def find_openings(self, st):
        names = {x.spec.get("name") for x in self.streets.values()}
        t0 = getattr(st, "t0", st.s0)
        t1 = getattr(st, "t1", st.s1)
        xs = [p[0] for p in st.pts]
        zs = [p[1] for p in st.pts]
        box = (min(xs) - 40, min(zs) - 40, max(xs) + 40, max(zs) + 40)
        hits = []
        for r in self.roads:
            if r.get("bridge") or r.get("name") in names or r.get("k") in SIDE_SKIP:
                continue
            p = pts_of(r["p"])
            if not any(box[0] < x < box[2] and box[1] < z < box[3] for x, z in p):
                continue
            prev = None
            for q in dense(p, 1.0):
                s, off = project(st, q)
                if s is None or not (t0 + 4.0 < s < t1 - 4.0):
                    prev = None
                    continue
                side = 1 if off > 0 else -1
                out = side * (off - st.outer(s, side))      # > 0: beyond the kerb, on the pavement
                if prev is not None and prev[2] == side and (prev[1] > 0) != (out > 0) and abs(off) < 60:
                    hits.append((side, (s + prev[0]) / 2.0, float(r.get("w", 4.0)), r.get("k", "service"), r, q))
                prev = (s, out, side)
        # one opening per side road mouth; the road must run on at least 3 m past the kerb
        found = []
        for side, s, w, k, r, at in sorted(hits, key=lambda h: (h[0], h[1])):
            ok = False
            for q in pts_of(r["p"]):
                ss, off = project(st, q)
                if ss is not None and abs(ss - s) < 40 and side * (off - st.outer(ss, side)) > 3.0:
                    ok = True
                    break
            if not ok:
                continue
            # the side road's own line from the kerb out (8 m): paved, so a road meeting the street at
            # an angle still reaches the mouth
            out_pts = []
            for q in dense(pts_of(r["p"]), 0.5):
                ss, off = project(st, q)
                if ss is not None and math.dist(q, at) < 9.0 and side * (off - st.outer(ss, side)) > -1.0:
                    out_pts.append(q)
            links = [(out_pts, w)] if len(out_pts) >= 2 else []
            far = max(out_pts, key=lambda q: math.dist(q, at)) if out_pts else None
            vdir = norm(sub(far, at)) if far is not None and math.dist(far, at) > 1.0 else None
            if found and found[-1]["side"] == side and abs(found[-1]["s"] - s) < (found[-1]["w"] + w) / 2.0 + 4.0:
                f = found[-1]                       # two ribbons of one mouth (in and out): one wider mouth
                f.setdefault("sum_w", f["w"] - 0.8)
                lo, hi = min(f["s"] - f["w"] / 2.0, s - w / 2.0), max(f["s"] + f["w"] / 2.0, s + w / 2.0)
                f["s"], f["w"] = (lo + hi) / 2.0, hi - lo
                # a Y of two one-way ribbons: one mouth as wide as both roads (not the gap between them),
                # paved straight out along the mean direction to where the ribbons join
                f["links"] = []
                f["merged"] = True
                f["sum_w"] = f.get("sum_w", f["w"] - 0.8) + w
                f["w"] = min(hi - lo, f["sum_w"] + 0.8)
                if vdir and f.get("dir"):
                    f["dir"] = list(norm(add(tuple(f["dir"]), vdir)))
                continue
            found.append({"s": s, "side": side, "w": max(3.5, w + 0.8),
                          "r": 3.0 if k in ("service", "living_street", "track", "pedestrian") else 5.0, "auto": True,
                          "links": links, "dir": list(vdir) if vdir else None})
        return found

    def build(self):
        for j in self.spec.get("junctions", []):
            self.build_junction(j)
        for st in self.streets.values():
            self.build_street(st)
        return self


def strip(pts, half):
    """A polygon `half` either side of a polyline."""
    if len(pts) < 2:
        return None
    left, right = [], []
    for i, p in enumerate(pts):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        d = norm(sub(b, a))
        n = right_of(d)
        left.append(add(p, mul(n, -half)))
        right.append(add(p, mul(n, half)))
    return left + list(reversed(right))


SIDE_SKIP = ("footway", "path", "cycleway", "steps", "pedestrian", "platform", "corridor")


def boundary_kind(a, b):
    ka, kb = a.get("k", "lane"), b.get("k", "lane")
    da, db = int(a.get("d", 1)), int(b.get("d", 1))
    if "gap" in (ka, kb):
        return "solid"
    if "park" in (ka, kb):
        return "edge"
    if "bike" in (ka, kb):
        return "cycle"
    if "bus" in (ka, kb):
        return "bus"
    if da != db:
        return "centre"
    return "lane"


def frange(a, b, step):
    n = max(1, int(math.ceil((b - a) / step)))
    return [a + (b - a) * k / n for k in range(n + 1)]


def chunks(a, b):
    n = max(1, int(math.ceil((b - a) / CHUNK)))
    return [(a + (b - a) * k / n, a + (b - a) * (k + 1) / n) for k in range(n)]


def dedupe(ring, eps=0.05):
    out = []
    for p in ring:
        if not out or math.dist(out[-1], p) > eps:
            out.append(p)
    if len(out) > 2 and math.dist(out[0], out[-1]) <= eps:
        out.pop()
    return out


NOSE_R = 0.8          # m: corner radius of a median's square end (as kerbed in Warsaw)


def nose_round(left, right, rc=NOSE_R):
    """A median outline (left edge forward, right edge back) with square ends, their two corners
    rounded by `rc` (Warsaw's medians end square across the lane, not in a half circle)."""
    def corner(a, P, b):
        # quadratic curve from a to b with P as the control: a rounded corner at P
        return [add(add(mul(a, (1 - t) ** 2), mul(P, 2 * (1 - t) * t)), mul(b, t * t))
                for t in (k / 6.0 for k in range(7))]

    def toward(P, Q, d):
        L = math.dist(P, Q)
        return lerp(P, Q, min(0.45, d / L)) if L > 0 else P

    w0 = math.dist(left[-1], right[0])
    w1 = math.dist(right[-1], left[0])
    r0 = max(0.05, min(rc, w0 / 2.0 - 0.05))
    r1 = max(0.05, min(rc, w1 / 2.0 - 0.05))
    body_l, body_r = left[1:-1], right[1:-1]
    out = []
    # start corner (left[0]), coming from right[-1]
    out += corner(toward(left[0], right[-1], r1), left[0], toward(left[0], left[1], r1))
    out += body_l
    out += corner(toward(left[-1], left[-2], r0), left[-1], toward(left[-1], right[0], r0))
    out += corner(toward(right[0], left[-1], r0), right[0], toward(right[0], right[1], r0))
    out += body_r
    out += corner(toward(right[-1], right[-2], r1), right[-1], toward(right[-1], left[0], r1))
    return out


# --- applying to the map ----------------------------------------------------------------------

class Footprint:
    """Point-in-footprint tests on a grid of the designed polygons, padded."""

    def __init__(self, polys, pad):
        self.polys = []
        self.grid = {}
        self.pad = pad
        for k, p in enumerate(polys):
            xs = [q[0] for q in p]
            zs = [q[1] for q in p]
            box = (min(xs) - pad, min(zs) - pad, max(xs) + pad, max(zs) + pad)
            self.polys.append((p, box))
            for gx in range(int(box[0] // 20), int(box[2] // 20) + 1):
                for gz in range(int(box[1] // 20), int(box[3] // 20) + 1):
                    self.grid.setdefault((gx, gz), []).append(k)

    def has(self, x, z):
        for k in self.grid.get((int(x // 20), int(z // 20)), []):
            p, box = self.polys[k]
            if not (box[0] <= x <= box[2] and box[1] <= z <= box[3]):
                continue
            if inside(x, z, p):
                return True
            if self.pad > 0 and near_ring(x, z, p, self.pad):
                return True
        return False


def near_ring(x, z, ring, r):
    for i in range(len(ring)):
        a, b = ring[i], ring[(i + 1) % len(ring)]
        ab = sub(b, a)
        L2 = dot(ab, ab)
        t = 0.0 if L2 == 0 else max(0.0, min(1.0, dot(sub((x, z), a), ab) / L2))
        q = add(a, mul(ab, t))
        if math.dist(q, (x, z)) <= r:
            return True
    return False


def dense(pts, step=1.0):
    out = [pts[0]]
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        n = max(1, int(math.ceil(math.dist(a, b) / step)))
        out += [lerp(a, b, k / n) for k in range(1, n + 1)]
    return out


def clip_line(pts, fp):
    """The parts of a polyline outside the footprint (sampled every metre)."""
    d = dense(pts)
    keep = [not fp.has(x, z) for (x, z) in d]
    runs, cur = [], []
    for p, k in zip(d, keep):
        if k:
            cur.append(p)
        elif cur:
            runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)
    return [simplify_run(r) for r in runs if len(r) >= 2 and plen(r) > 0.6]


def simplify_run(pts, tol=0.03):
    if len(pts) < 3:
        return pts
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[i], pts[i + 1]
        if abs(cross(sub(b, a), norm(sub(c, a)))) > tol:
            out.append(b)
    out.append(pts[-1])
    return out


def hide_ranges(road, fp):
    """The metres along a road's centreline that lie in the footprint (merged with its old ones)."""
    pts = pts_of(road["p"])
    cum = [0.0]
    for i in range(1, len(pts)):
        cum.append(cum[-1] + math.dist(pts[i - 1], pts[i]))
    spans = []
    start = None
    s = 0.0
    total = cum[-1]
    while s <= total + 1e-6:
        i = 0
        while i < len(cum) - 2 and cum[i + 1] < s:
            i += 1
        seg = cum[i + 1] - cum[i] if len(cum) > 1 else 0
        p = lerp(pts[i], pts[i + 1], (s - cum[i]) / seg) if seg > 0 else pts[i]
        hit = fp.has(p[0], p[1])
        if hit and start is None:
            start = max(0.0, s - 0.5)
        if not hit and start is not None:
            spans.append([round(start, 2), round(min(total, s - 0.5), 2)])
            start = None
        s += 1.0
    if start is not None:
        spans.append([round(start, 2), round(total, 2)])
    old = [list(h) for h in road.get("hide", [])]
    allh = sorted(old + spans)
    merged = []
    for h in allh:
        if merged and h[0] <= merged[-1][1] + 0.01:
            merged[-1][1] = max(merged[-1][1], h[1])
        else:
            merged.append(h)
    return merged


VERSION = 1


# point objects (flat lists, STRIDE values each, x and z first) that stand by the kerb: the ones the
# old OSM street left on what is now carriageway are moved onto the new pavement (Unslop's and the
# bakes' furniture is kept; only its place changes). Medians and islands keep theirs.
OBJECT_LAYERS = {"lamps": 2, "signals": 3, "shelters": 3, "benches": 3, "bins": 3, "bikes": 3, "columns": 3,
                 "trees3d": 6}
KERB_SET = 0.8        # m behind the kerb where a moved object stands
SLIDE_STEPS = (0.0, -2.0, 2.0, -4.0, 4.0, -6.0, 6.0)   # m along the kerb to get out of a mouth


def reseat_objects(out, d):
    asphalt = Footprint([pts_of(c["p"]) for c in d.out["carriage"]], 0.2)
    moved = 0
    for layer, k in OBJECT_LAYERS.items():
        v = out.get(layer)
        if not v or not isinstance(v[0], (int, float)):
            continue
        for i in range(0, len(v) - 1, k):
            x, z = v[i], v[i + 1]
            if not asphalt.has(x, z):
                continue
            best = None
            for st in d.streets.values():
                s, off = project(st, (x, z))
                if s is None or not (st.s0 <= s <= st.s1):
                    continue
                side = 1 if off > 0 else -1
                gap = abs(off) - abs(st.outer(s, side))
                if gap > 0.5:
                    continue             # beyond this street (on another's asphalt)
                if best is None or abs(gap) < abs(best[3]):
                    best = (st, s, side, gap)
            if best is None:
                continue                 # in a junction box or a mouth: left as it is
            st, s, side, _ = best
            # Behind the kerb, or slid along it out of a driveway's mouth (Krucza's lamp by the
            # one at s 374, 2026-11-06), up to SLIDE m either way.
            q = None
            for ds in SLIDE_STEPS:
                c = st.point(s + ds, st.outer(s + ds, side) + side * KERB_SET)
                if st.s0 <= s + ds <= st.s1 and not asphalt.has(c[0], c[1]):
                    q = c
                    break
            if q is None:
                continue                 # by a junction or a corner: no pavement there to move to
            v[i], v[i + 1] = round(q[0], 2), round(q[1], 2)
            moved += 1
    return moved


PARK_EVERY = 5.8     # m between parked cars' middles in a parking lane (a 4.6 m car and its gap)
PARK_FILL = 0.72     # of the spaces taken (deterministic by place), as on the street photos
PARK_CLEAR = 6.0     # m kept free each side of a crossing's middle and beyond a mouth's half width
PARK_LANE_GAP = 2.7  # m at least from a parked car's middle to any traffic lane's middle (half a
                     # bus, 1.3, and a car, 0.9, with room): where the lanes swing out (a taper, a
                     # free end blending back), the space stays empty
PARK_END = 20.0      # m from either end of a street with no parked car: past a free end the
                     # lanes blend back to the old ones (BLEND) and a bus's 12 m box cuts the bend
CAR_COLOURS = 10     # tools/bake_osm.py's parked-car palette


def offset_line(p, off):
    """Polyline p moved `off` metres to its right (the lane graph's lane offsets: +x east, +z
    south, so the right of heading (dx, dz) is (-dz, dx))."""
    q = []
    for i in range(len(p)):
        a, b = p[max(0, i - 1)], p[min(len(p) - 1, i + 1)]
        h = norm(sub(b, a))
        q.append((p[i][0] - h[1] * off, p[i][1] + h[0] * off))
    return q


def park_cars(out, d):
    """Cars along every `park` lane of the designed streets (Krucza, 2026-11-06: the photos' rows of
    parked cars), parallel to the kerb and facing the lane's way, a space every PARK_EVERY m, some
    empty; none on a crossing, in a side road's mouth or past the street's ends. The map's parked
    cars that stood on the new asphalt (OSM car parks the wider street now covers) go first.
    Only for an area whose spec says "park_cars": true (the Palace's parking lanes stay empty).
    Returns (taken off, added)."""
    asphalt = Footprint([pts_of(c["p"]) for c in d.out["carriage"]], 0.2)
    v = out.get("parked", [])
    keep, gone = [], 0
    for i in range(0, len(v) - 3, 4):
        if asphalt.has(v[i], v[i + 1]):
            gone += 1
        else:
            keep += v[i:i + 4]
    # every traffic lane's middle line near the designed streets (retarget_graph has run)
    lane_cells = {}
    near = Footprint([pts_of(c["p"]) for c in d.out["carriage"]], 8.0)
    for e in out.get("graph", {}).get("edges", []):
        p = pts_of(e["p"])
        if not any(near.has(*q) for q in p[::4] + p[-1:]):
            continue
        for k in range(int(e.get("n", 1))):
            off = float(e.get("o", 0.0)) + float(e.get("lw", 3.0)) * k
            for q in dense(offset_line(p, off), 1.0):
                lane_cells.setdefault((int(q[0] // 4), int(q[1] // 4)), []).append(q)

    def in_lane(q):
        gx, gz = int(q[0] // 4), int(q[1] // 4)
        return any(math.dist(q, r) < PARK_LANE_GAP for i in (-1, 0, 1) for j in (-1, 0, 1)
                   for r in lane_cells.get((gx + i, gz + j), []))

    added = 0
    for st in d.streets.values():
        stops = [(float(c["s"]), PARK_CLEAR) for c in st.spec.get("crossings", [])]
        stops += [(float(o["s"]), float(o.get("w", 8.0)) / 2 + float(o.get("r", 4.0)) + 1.0)
                  for o in d.openings_of(st)]
        s = st.s0 + PARK_EVERY
        while s < st.s1 - PARK_EVERY:
            if s < st.s0 + PARK_END or s > st.s1 - PARK_END or any(abs(s - c) < r for c, r in stops):
                s += PARK_EVERY
                continue
            p, t = st.at(s)
            for cw in st.lanes(s):
                for lane, l, r in cw:
                    if lane.get("k") != "park":
                        continue
                    q = st.point(s, (l + r) / 2.0)
                    h = (math.sin(q[0] * 3.1 + q[1] * 1.7) * 43758.5453) % 1.0
                    if h >= PARK_FILL or in_lane(q):
                        continue
                    f = mul(t, float(lane.get("d", 1)))
                    keep += [round(q[0], 1), round(q[1], 1), round(math.atan2(-f[0], -f[1]), 2),
                             int(h * 1000) % CAR_COLOURS]
                    added += 1
            s += PARK_EVERY
    out["parked"] = keep
    return gone, added


PATH_SET = 1.3    # m from the kerb to the middle of a footway / cycle track moved off the new asphalt


def reseat_paths(paths, d):
    """A footway or cycle track running along a street that the new, wider kerb now covers moves
    out to the new kerb (its middle PATH_SET beyond it), so the pavement and the cycle track go on
    beside the street instead of being cut away. Paths across the street stay (the crossings carry
    them); in a junction box or a mouth nothing moves."""
    asphalt = Footprint([pts_of(c["p"]) for c in d.out["carriage"]], 0.2)
    # the cycle tracks, so a moved footway goes on beyond a cycle track, not on top of it
    bikes = {}
    for f in paths:
        if f.get("k") == "cycle":
            for q in dense(pts_of(f["p"]), 1.0):
                bikes.setdefault((int(q[0] // 4), int(q[1] // 4)), []).append(q)

    def by_bike(r):
        gx, gz = int(r[0] // 4), int(r[1] // 4)
        return any(math.dist(r, q) < 1.8 for i in (-1, 0, 1) for j in (-1, 0, 1)
                   for q in bikes.get((gx + i, gz + j), []))

    moved = 0
    for f in paths:
        if f.get("k") not in ("foot", "cycle") or f.get("dk") is not None:
            continue
        p = dense(pts_of(f["p"]), 1.0)
        if not any(asphalt.has(*q) for q in p):
            continue
        hit = False
        newp = []
        for i, q in enumerate(p):
            if not asphalt.has(*q):
                newp.append(q)
                continue
            a, b = p[max(0, i - 1)], p[min(len(p) - 1, i + 1)]
            h = norm(sub(b, a))
            best = None
            for st in d.streets.values():
                s, off = project(st, q)
                if s is None or not (st.s0 + 1.0 <= s <= st.s1 - 1.0):
                    continue
                t = norm(sub(st.point(min(s + 1.0, st.L), 0.0), st.point(max(s - 1.0, 0.0), 0.0)))
                if abs(dot(h, t)) < 0.85:
                    continue                 # across the street: a crossing's job
                side = 1 if off > 0 else -1
                gap = abs(off) - abs(st.outer(s, side))
                if gap > 0.5:
                    continue
                if best is None or abs(gap) < abs(best[3]):
                    best = (st, s, side, gap)
            if best is None:
                newp.append(q)
                continue
            st, s, side, _ = best
            r = st.point(s, st.outer(s, side) + side * PATH_SET)
            if f["k"] == "foot" and by_bike(r):
                r = st.point(s, st.outer(s, side) + side * (PATH_SET + 2.6))
            if asphalt.has(*r):
                newp.append(q)
                continue
            newp.append(r)
            hit = True
        if hit:
            f["p"] = flat(simplify_run(newp, 0.1))
            moved += 1
    return moved


LEAD_R = 14.0     # m: a cut footway / cycle track end this close to a crossing's end walks to it
LEAD_BACK = 6.0   # m back along the path where the bend to the crossing starts


def lead_to_crossings(paths, d):
    """Footways and cycle tracks cut by the new asphalt end where the old zebras were, which the
    design may have moved: bend each cut end over its last metres onto the end of the nearest
    crossing of its kind (a footway to a zebra, a cycle track to a cycle crossing) that it heads
    across, so every path meets its crossing at the kerb."""
    ends = {"foot": [], "cycle": []}
    for z in d.out["zebras"]:
        q = pts_of(z["p"])
        u = norm(sub(q[-1], q[0]))
        ends["foot"] += [(q[0], u, float(z.get("w", CROSS_W))), (q[-1], u, float(z.get("w", CROSS_W)))]
    for z in d.out["cyclecross"]:
        q = pts_of(z["p"])
        u = norm(sub(q[-1], q[0]))
        ends["cycle"] += [(q[0], u, 2.2), (q[-1], u, 2.2)]
    # and the map's own crossings the design kept (past its free ends)
    for z in paths:
        if z["k"] in ("zebra", "cyclecross"):
            q = pts_of(z["p"])
            if len(q) >= 2 and math.dist(q[0], q[-1]) > 0.5:
                u = norm(sub(q[-1], q[0]))
                ends["foot" if z["k"] == "zebra" else "cycle"] += [(q[0], u, CROSS_W), (q[-1], u, 2.2)]
    asphalt = Footprint(d.footprint, -0.2)
    moved = 0
    for g in paths:
        cut = g.get("_cut")
        if not cut or g["k"] not in ends:
            continue
        p = pts_of(g["p"])
        for at_end in (0, 1):
            if cut[at_end] not in (True, "near"):
                continue
            run = p if at_end else list(reversed(p))     # run[-1] is the cut end
            E = run[-1]
            back = dense(run, 0.5)
            # heading at the cut: from 3 m back to the end
            k3 = max(0, len(back) - 7)
            head = norm(sub(E, back[k3]))
            best = None
            for n, (T, u, w) in enumerate(ends[g["k"]]):
                dd = math.dist(E, T)
                if dd > LEAD_R:
                    continue
                # beyond a few metres the path must head on over the crossing (u_in: from this end
                # into the road), not along the kerb or back from it
                u_in = u if n % 2 == 0 else mul(u, -1.0)
                if dd > 8.0 and dot(head, norm(sub(T, E))) < -0.2:
                    continue                 # behind the end: another way's crossing
                if dd > 10.0 and (abs(dot(head, u)) < 0.3 or dot(head, u_in) < -0.3):
                    continue
                if best is None or dd < best[0]:
                    best = (dd, T, u_in)
            if best is None or best[0] < 0.6:
                continue
            _, T, u_in = best
            # meet the kerb straight on: the last metre runs on the crossing's line, outside it
            T_in = sub(T, mul(u_in, 1.2))
            lead = min(max(LEAD_BACK, 1.5 * best[0]), 0.7 * plen(back))
            acc, keep = 0.0, [back[-1]]
            for i in range(len(back) - 1, 0, -1):
                acc += math.dist(back[i], back[i - 1])
                keep.append(back[i - 1])
                if acc >= lead:
                    break
            keep.reverse()
            start = keep[0]
            if len(back) - len(keep) < 1:
                start = back[0]
            stem = back[:max(1, len(back) - len(keep) + 1)]
            # the bend runs on the pavement: a lead that would cut over the asphalt is no lead
            if sum(1 for q in dense([stem[-1], T_in], 0.5) if asphalt.has(*q)) > (4 if best[0] <= 8.0 else 2):
                continue
            new = simplify_run(stem + [T_in, T])
            p = new if at_end else list(reversed(new))
            cut[at_end] = "led"
            moved += 1
        g["p"] = flat(p)
    return moved


def on_street(d, q):
    """Whether q lies on a designed street's own carriageways (not a junction, not a mouth)."""
    for st in d.streets.values():
        s, off = project(st, q)
        if s is None or not (st.s0 <= s <= st.s1):
            continue
        if any(l - 0.3 <= off <= r + 0.3 for (l, r) in st.edges(s)):
            return True
    return False


NEAR_END = 3.0    # m: a footway / cycle track ending this close to the new asphalt is led to a crossing
SERVE_R = 15.0    # m: a crossing end with no path of its kind gets one from the nearest such path


def kerb_ends(d):
    """The ends of the design's zebras and cycle crossings that sit on a kerb with pavement behind
    (not on a median or a tram island): (kind, end, outward direction)."""
    asphalt = Footprint(d.footprint, -0.2)
    islands = Footprint([pts_of(f["p"]) for f in d.out.get("islands", []) + d.out.get("medians", [])
                         if len(f.get("p", [])) >= 6], 0.3)
    out = []
    for kind, layer in (("foot", "zebras"), ("cycle", "cyclecross")):
        for z in d.out[layer]:
            q = pts_of(z["p"])
            if len(q) < 2 or math.dist(q[0], q[-1]) < 1.0:
                continue
            u = norm(sub(q[-1], q[0]))
            for T, uo in ((q[0], mul(u, -1.0)), (q[-1], u)):
                b = add(T, mul(uo, 1.5))
                if not asphalt.has(*b) and not islands.has(*b):
                    out.append((kind, T, uo))
    return out


def serve_crossings(paths, d):
    """Every zebra and cycle crossing end on a kerb meets a path of its kind: where none arrives
    (the old path went to the old crossing elsewhere), a short link runs from the crossing end
    straight out over the kerb and on to the nearest point of the nearest such path, never over
    asphalt. A cycle crossing that meets a painted cycle lane is served by it."""
    asphalt = Footprint(d.footprint, -0.2)
    lanes = [pts_of(m["p"]) for m in d.out["markings"] if m.get("k") == "cyclefill"]
    made = 0
    for kind, T, uo in kerb_ends(d):
        own = [pts_of(g["p"]) for g in paths if g.get("k") == kind and g.get("dk") is None]
        if near_any(T, own, 1.5) or (kind == "cycle" and near_any(T, lanes, 2.5)):
            continue
        T_out = add(T, mul(uo, 1.2))
        best = None
        for g in paths:
            if g.get("k") != kind or g.get("dk") is not None:
                continue
            for Q in dense(pts_of(g["p"]), 1.0):
                dd = math.dist(T_out, Q)
                if dd > SERVE_R or (best is not None and dd >= best[0]):
                    continue
                if dot(sub(Q, T), uo) < -0.5:
                    continue             # behind the crossing: over the road
                if sum(1 for x in dense([T_out, Q], 0.5) if asphalt.has(*x)) > 1:
                    continue
                best = (dd, Q, g)
        if best is None:
            continue
        paths.append({"k": kind, "w": best[2].get("w", 2.2 if kind == "foot" else 2.0),
                      "p": flat([T, T_out, best[1]])})
        made += 1
    return made


def bridge_mouths(paths, d):
    """A pavement or a cycle track along the street that a side road's mouth cut in two: the two
    cut ends face each other across the mouth's asphalt, so the design paints the crossing there
    (a zebra for a footway, a cycle crossing for a cycle track), as Warsaw does at side streets."""
    asphalt = Footprint(d.footprint, 0.3)
    ends = []
    for g in paths:
        cut = g.get("_cut")
        if not cut or g["k"] not in ("foot", "cycle"):
            continue
        p = pts_of(g["p"])
        for at_end in (0, 1):
            if cut[at_end] is not True:
                continue
            run = p if at_end else list(reversed(p))
            back = dense(run, 0.5)
            head = norm(sub(back[-1], back[max(0, len(back) - 7)]))
            ends.append((g, at_end, back[-1], head))
    made = 0
    used = set()
    xpaths = [pts_of(z["p"]) for z in d.out["zebras"] + d.out["cyclecross"]] + \
        [pts_of(g["p"]) for g in paths if g.get("k") in ("zebra", "cyclecross")]
    for i, (g1, e1, E1, h1) in enumerate(ends):
        best = None
        for j, (g2, e2, E2, h2) in enumerate(ends):
            if j <= i or g2["k"] != g1["k"] or g2 is g1 or j in used or i in used:
                continue
            dd = math.dist(E1, E2)
            if not 2.0 < dd < 18.0:
                continue
            v = norm(sub(E2, E1))
            if dot(h1, v) < 0.7 or dot(h2, v) > -0.7:
                continue                 # not facing each other across the gap
            mid = dense([E1, E2], 1.0)[1:-1]
            if not mid or sum(1 for q in mid if asphalt.has(*q)) < 0.6 * len(mid):
                continue
            if any(on_street(d, q) for q in mid):
                continue                 # over a designed street's lanes: not a side road's mouth
            if near_any(lerp(E1, E2, 0.5), xpaths, 8.0) or near_any(E1, xpaths, 6.0) or near_any(E2, xpaths, 6.0):
                continue                 # a crossing is already there: the ends are led to it
            if best is None or dd < best[0]:
                best = (dd, j, E2)
        if best is None:
            continue
        used |= {i, best[1]}
        g2, e2 = ends[best[1]][0], ends[best[1]][1]
        g1["_cut"][e1] = "led"
        g2["_cut"][e2] = "led"
        if g1["k"] == "foot":
            d.out["zebras"].append({"p": flat([E1, best[2]]), "w": 3.0})
        else:
            d.out["cyclecross"].append({"p": flat([E1, best[2]])})
        made += 1
    return made


def clip_half(ring, p, d):
    """The part of a polygon on the side of the line through p (normal d) that d points to."""
    def side(q):
        return (q[0] - p[0]) * d[0] + (q[1] - p[1]) * d[1]
    out = []
    n = len(ring)
    for i in range(n):
        a, b = ring[i], ring[(i + 1) % n]
        sa, sb = side(a), side(b)
        if sa >= 0:
            out.append(a)
        if (sa >= 0) != (sb >= 0):
            t = sa / (sa - sb)
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
    return out


def ring_area(ring):
    return 0.5 * sum(ring[i][0] * ring[(i + 1) % len(ring)][1] - ring[(i + 1) % len(ring)][0] * ring[i][1]
                     for i in range(len(ring)))


def apply_design(out, d):
    """Removes the old road layers in the design's footprint and writes the design's own."""
    fp = Footprint(d.footprint + d.mouths, FOOT_PAD)
    fp_tight = Footprint(d.footprint, 0.3)
    stats = {}

    def drop(layer, test):
        before = len(out.get(layer, []))
        out[layer] = [f for f in out.get(layer, []) if not test(f)]
        stats[layer] = before - len(out[layer])

    def centre_in(f, key="p"):
        p = pts_of(f[key])
        cx = sum(q[0] for q in p) / len(p)
        cz = sum(q[1] for q in p) / len(p)
        return fp.has(cx, cz)

    def mostly_in(f, key="p", share=0.5):
        p = dense(pts_of(f[key]), 2.0)
        n = sum(1 for q in p if fp_tight.has(*q))
        return n >= share * len(p)

    # roads: hide where they run in the footprint (the graph and everything else keep them)
    hidden = 0
    for r in out["roads"]:
        if r.get("dk") is not None or r.get("bridge"):
            continue
        h = hide_ranges(r, fp_tight)
        if h != r.get("hide", []):
            r["hide"] = h
            hidden += 1
    stats["roads hidden"] = hidden
    old_carriage = out.get("carriage", [])
    drop("carriage", lambda f: f.get("dk") is None and mostly_in(f))
    # an old carriage piece that ran on past a designed street's free end: the part beyond the
    # end stays (cut square at the end's cross-section), or the street would stop in a hole
    kept = {id(f) for f in out["carriage"]}
    ends = []
    for st in d.streets.values():
        if st.spec.get("start") is None:
            p, dd = st.at(0.0)
            ends.append((p, mul(dd, -1.0)))
        if st.spec.get("end") is None:
            p, dd = st.at(st.L)
            ends.append((p, dd))
    tails = 0
    for f in old_carriage:
        if id(f) in kept:
            continue
        ring = pts_of(f["p"])
        for p, dd in ends:
            if min(math.dist(p, q) for q in ring) > 80.0:
                continue
            piece = clip_half(ring, p, dd)
            if len(piece) >= 3 and abs(ring_area(piece)) > 2.0:
                out["carriage"].append({"k": f.get("k", "secondary"), "p": flat(piece)})
                tails += 1
    stats["carriage kept past free ends"] = tails
    drop("asphalt_fills", lambda f: centre_in(f))
    def in_ring_island(f):
        p = pts_of(f["p"])
        c = (sum(q[0] for q in p) / len(p), sum(q[1] for q in p) / len(p))
        return any(math.dist(c, rc) < rr for rc, rr in d.ring_islands)
    drop("islands", lambda f: f.get("dk") is None and (centre_in(f) or in_ring_island(f)))
    drop("tram_noses", lambda f: centre_in(f))
    drop("tram_xings", lambda f: centre_in(f))
    drop("medians", lambda f: f.get("dk") is None and centre_in(f, "s"))
    drop("symbols", lambda f: f.get("dk") is None and fp.has(f["x"], f["z"]))
    # the old medians' grass and planter walls (the design draws its own medians)
    drop("areas", lambda f: f.get("k") in ("grass", "park") and mostly_in(f, share=0.6))
    drop("paths", lambda f: f["k"] in ("zebra", "cyclecross") and f.get("dk") is None
         and any(fp_tight.has(*q) for q in dense(pts_of(f["p"]), 1.0)))
    # footways and cycle tracks: clipped where they cross the new asphalt (the zebras and the
    # cycle crossings carry them over it)
    stats["paths moved out to the new kerb"] = reseat_paths(out.get("paths", []), d)
    paths = []
    cut = 0
    for f in out.get("paths", []):
        if f["k"] not in ("foot", "cycle") or f.get("dk") is not None:
            paths.append(f)
            continue
        p = pts_of(f["p"])
        if not any(fp_tight.has(*q) for q in dense(p, 1.0)):
            paths.append(f)
            continue
        cut += 1
        for run in clip_line(p, fp_tight):
            g = dict(f)
            g["p"] = flat(run)
            # which ends the asphalt cut (not the path's own ends): those walk to a crossing
            g["_cut"] = [math.dist(run[0], p[0]) > 0.5 and math.dist(run[0], p[-1]) > 0.5,
                         math.dist(run[-1], p[0]) > 0.5 and math.dist(run[-1], p[-1]) > 0.5]
            paths.append(g)
    # paths that end by the new kerb without being cut ended at the old crossings: they are
    # led to the new ones too
    near = Footprint(d.footprint, NEAR_END)
    for g in paths:
        if g.get("k") not in ("foot", "cycle") or g.get("dk") is not None or g.get("_cut"):
            continue
        q = pts_of(g["p"])
        if len(q) >= 2 and (near.has(*q[0]) or near.has(*q[-1])):
            g["_cut"] = ["near" if near.has(*q[0]) else False, "near" if near.has(*q[-1]) else False]
    stats["crossings over side-road mouths"] = bridge_mouths(paths, d)
    stats["path ends led to a crossing"] = lead_to_crossings(paths, d)
    stats["crossing ends given a path"] = serve_crossings(paths, d)
    # a short stub that led to an old crossing and now leads nowhere, off a path that goes on: gone
    nodes = {}
    for g in paths:
        if g.get("k") in ("foot", "cycle"):
            for e in (g["p"][0:2], g["p"][-2:]):
                nodes[(round(e[0]), round(e[1]), g["k"])] = nodes.get((round(e[0]), round(e[1]), g["k"]), 0) + 1
    keep, dropped = [], 0
    for g in paths:
        c = g.get("_cut")
        if c and g.get("k") in ("foot", "cycle") and plen(pts_of(g["p"])) < 10.0:
            q = pts_of(g["p"])
            for i, (e, o) in enumerate(((q[0], q[-1]), (q[-1], q[0]))):
                if c[i] in (True, "near") and nodes.get((round(o[0]), round(o[1]), g["k"]), 0) >= 2:
                    dropped += 1
                    break
            else:
                keep.append(g)
            continue
        keep.append(g)
    paths[:] = keep
    stats["dead stubs removed"] = dropped
    # the ends the asphalt cut, kept for the continuity gate (continuity(), --check-all)
    cut_ends = []
    for g in paths:
        c = g.pop("_cut", None)
        if c:
            q = pts_of(g["p"])
            for e, k, o in ((q[0], c[0], q[1]), (q[-1], c[1], q[-2])):
                if k:
                    h = norm(sub(e, o))
                    cut_ends.append([round(e[0], 2), round(e[1], 2), g["k"], round(h[0], 3), round(h[1], 3)])
    out.setdefault("road_design_ends", {})[d.area] = cut_ends
    out["paths"] = paths
    stats["paths clipped"] = cut
    # kerbs and painted lines: clipped to outside the footprint
    walls = []
    cut = 0
    for f in out.get("lines", []):
        p = pts_of(f["p"])
        if f.get("k") not in ("wall", "fence", "hedge") or not any(fp_tight.has(*q) for q in dense(p, 1.0)):
            walls.append(f)
            continue
        cut += 1
        for run in clip_line(p, fp_tight):
            g = dict(f)
            g["p"] = flat(run)
            walls.append(g)
    out["lines"] = walls
    stats["walls clipped"] = cut
    for layer in ("kerbs", "markings"):
        keep = []
        cut = 0
        for f in out.get(layer, []):
            if f.get("dk") is not None:
                keep.append(f)
                continue
            p = pts_of(f["p"])
            if not any(fp.has(*q) for q in dense(p, 2.0)):
                keep.append(f)
                continue
            cut += 1
            for run in clip_line(p, fp):
                g = dict(f)
                g["p"] = flat(run)
                keep.append(g)
        out[layer] = keep
        stats[layer + " clipped"] = cut
    # the design's own
    o = d.out
    out["carriage"] += o["carriage"]
    out["kerbs"] += o["kerbs"]
    out["islands"] += o["islands"]
    out["medians"] += o["medians"]
    out["markings"] += o["markings"]
    out["symbols"] += o["symbols"]
    out["paths"] += [{"k": "zebra", "p": z["p"], "w": z.get("w", CROSS_W)} for z in o["zebras"]]
    out["paths"] += [{"k": "cyclecross", "p": z["p"]} for z in o["cyclecross"]]
    out.setdefault("tram_xings", [])
    out["tram_xings"] += o["tram_xings"]
    stats["traffic edges on the designed lanes"] = retarget_graph(out, d)
    stats["objects moved off the new asphalt"] = reseat_objects(out, d)
    if d.spec.get("park_cars"):
        stats["parked cars off the new asphalt"], stats["parked cars in the parking lanes"] = park_cars(out, d)
    out.setdefault("road_design", {})[d.area] = d.spec.get("version", VERSION)
    return stats


BLEND = 12.0          # m: at a street's free end the traffic lanes blend back to the old ones


def drive_lanes(st, s, d):
    """(centre offset, count, mean width) of the lanes driven in direction d at s (lane and bus)."""
    xs = []
    for row in st.lanes(s):
        for (x, l, r) in row:
            if int(x.get("d", 1)) == d and x.get("k", "lane") in ("lane", "bus"):
                xs.append((l, r))
    if not xs:
        return None
    lo = min(l for l, r in xs)
    hi = max(r for l, r in xs)
    return ((lo + hi) / 2.0, len(xs), sum(r - l for l, r in xs) / len(xs))


def retarget_graph(out, d):
    """Moves the traffic graph's edges on the designed streets onto the designed lanes: the edge's
    line follows the middle of its direction's lanes, with their count and width (the graph's
    junctions and links stay as they were). Returns how many edges moved."""
    g = out.get("graph")
    if not g:
        return 0
    moved = 0
    for e in g["edges"]:
        if e.get("br"):
            continue
        for st in d.streets.values():
            if e.get("name") != st.spec.get("name"):
                continue
            p = dense(pts_of(e["p"]), 2.0)
            proj = []
            for q in p:
                ss, off = project(st, q)
                ok = ss is not None and 0.0 <= ss <= st.L and math.dist(q, st.point(ss, off)) < 0.6 and abs(off) < 30
                proj.append((ss, off) if ok else None)
            on = [x for x in proj if x is not None]
            if len(on) < max(3, len(p) // 2):
                continue
            dirn = 1 if on[-1][0] > on[0][0] else -1
            mid = drive_lanes(st, on[len(on) // 2][0], dirn)
            if mid is None:
                continue
            # the edge must already run on its direction's side (a two-way street's lanes share a line)
            if abs(on[len(on) // 2][1] - mid[0]) > 9.0:
                continue
            free0 = st.spec.get("start") is None
            free1 = st.spec.get("end") is None
            new = []
            for q, x in zip(p, proj):
                if x is None:
                    new.append(q)
                    continue
                ss = x[0]
                lane = drive_lanes(st, ss, dirn)
                if lane is None:
                    new.append(q)
                    continue
                w = 1.0
                if free0:
                    w = min(w, ss / BLEND)
                if free1:
                    w = min(w, (st.L - ss) / BLEND)
                w = max(0.0, min(1.0, w))
                new.append(lerp(q, st.point(ss, lane[0]), w))
            old_len = plen(pts_of(e["p"]))
            new_len = plen(new)
            e["s1"] = round(max(float(e["s0"]) + 0.1, new_len - (old_len - float(e["s1"]))), 2)
            e["p"] = flat(new)
            e["n"] = mid[1]
            e["lw"] = round(mid[2], 2)
            e["o"] = round(-(mid[1] - 1) / 2.0 * mid[2], 2)
            moved += 1
            break
    return moved


def load_spec(area):
    with open(os.path.join(SPECS, area + ".json"), encoding="utf-8") as f:
        return json.load(f)


def apply_all(out):
    """bake_osm.py: every area in docs/roads/ (a fresh bake has none applied)."""
    done = []
    if not os.path.isdir(SPECS):
        return "no areas"
    for name in sorted(os.listdir(SPECS)):
        if not name.endswith(".json"):
            continue
        area = name[:-5]
        if area in out.get("road_design", {}):
            continue
        d = Design(load_spec(area), out["roads"]).build()
        apply_design(out, d)
        problems = check(d)
        done.append("%s (%d problems)" % (area, len(problems)))
    return "designed " + (", ".join(done) if done else "nothing new")


# --- checks -----------------------------------------------------------------------------------

def check(d):
    """The design's own rules: polygons simple, kerbs never cross each other, every lane line
    inside asphalt, every zebra end on a kerb or a median edge."""
    problems = []
    for c in d.out["carriage"]:
        p = pts_of(c["p"])
        if self_crossing(p):
            problems.append("carriage polygon crosses itself near (%.0f, %.0f)" % p[0])
    asphalt = Footprint([pts_of(c["p"]) for c in d.out["carriage"]], 0.25)
    for m in d.out["markings"]:
        if m["k"] in ("lane", "solid", "centre", "bus", "stop", "cycle"):
            for q in dense(pts_of(m["p"]), 2.0):
                if not asphalt.has(*q):
                    problems.append("%s line off the asphalt at (%.1f, %.1f)" % (m["k"], q[0], q[1]))
                    break
    kerbs = [pts_of(k["p"]) for k in d.out["kerbs"]]
    for i in range(len(kerbs)):
        for j in range(i + 1, len(kerbs)):
            x = polylines_cross(kerbs[i], kerbs[j])
            if x:
                problems.append("kerbs cross at (%.1f, %.1f)" % x)
    return problems


def near_any(E, lines, r, along=None):
    """Whether a polyline passes within r of E (with along: only its segments running within 60
    degrees of that direction)."""
    for q in lines:
        for a, b in zip(q, q[1:]):
            ab = sub(b, a)
            if along is not None and abs(dot(norm(ab), along)) < 0.5:
                continue
            t = max(0.0, min(1.0, dot(sub(E, a), ab) / (dot(ab, ab) or 1e-9)))
            if math.dist(E, add(a, mul(ab, t))) < r:
                return True
    return False


def continuity(out, d):
    """Footways and cycle tracks are continuous. Every end the designed asphalt cut off a path
    (apply_design keeps them in the map's road_design_ends) must be one of: on a crossing of its
    kind (a footway on a zebra, a cycle track on a cycle crossing), joined to another path of its
    kind, a cycle track running into a painted cycle lane, or an end at the kerb with no path of
    its kind straight across the road (a pavement link, not a way over). A path that stops at the
    kerb while it goes on across the road is the fault: people would cross off any crossing."""
    kinds = {"foot": "zebra", "cycle": "cyclecross"}
    xs = {"zebra": [], "cyclecross": []}
    own = {"foot": [], "cycle": []}
    for f in out.get("paths", []):
        if f["k"] in xs:
            xs[f["k"]].append(pts_of(f["p"]))
        elif f["k"] in own and f.get("dk") is None:
            own[f["k"]].append(pts_of(f["p"]))
    lanes = [pts_of(m["p"]) for m in out.get("markings", []) if m.get("k") == "cyclefill"]
    asphalt = Footprint(d.footprint, 0.3)
    open_ends = [(float(e["x"]), float(e["z"])) for e in d.spec.get("open_ends", [])]
    problems = []
    # every crossing end on a kerb has a path of its kind arriving
    allp = {"foot": [], "cycle": []}
    for f in out.get("paths", []):
        if f["k"] in allp:
            allp[f["k"]].append(pts_of(f["p"]))
    fills = [pts_of(m["p"]) for m in out.get("markings", []) if m.get("k") == "cyclefill"]
    for kind, T, uo in kerb_ends(d):
        if any(math.dist(T, o) < 3.0 for o in open_ends):
            continue
        if not near_any(T, allp[kind], 1.5) and not (kind == "cycle" and near_any(T, fills, 2.5)):
            problems.append("%s at (%.1f, %.1f) has no %s arriving" % (
                "zebra" if kind == "foot" else "cycle crossing", T[0], T[1], "footway" if kind == "foot" else "cycle track"))
    if d.area in out.get("road_design", {}) and d.area not in out.get("road_design_ends", {}):
        problems.append("%s applied without its cut path ends: apply it again from the map before" % d.area)
    for row in out.get("road_design_ends", {}).get(d.area, []):
        x, z, k = row[0], row[1], row[2]
        E = (x, z)
        if any(math.dist(E, o) < 3.0 for o in open_ends):
            continue                     # checked on the ortho: no crossing painted there
        if near_any(E, xs[kinds[k]], 1.5):
            continue
        if near_any(E, [q for q in own[k] if math.dist(q[0], E) > 0.05 and math.dist(q[-1], E) > 0.05], 1.2):
            continue
        if k == "cycle" and near_any(E, lanes, 2.5):
            continue
        if len(row) < 5:
            problems.append("%s path stops at the road off any %s at (%.1f, %.1f)" % (k, kinds[k], x, z))
            continue
        h = (row[3], row[4])
        # straight on over the asphalt: does a path of its kind go on from the far kerb?
        t, on = 0.0, False
        while t < 45.0:
            t += 0.5
            q = add(E, mul(h, t))
            if asphalt.has(*q):
                on = True
            elif on:
                break
            elif t > 3.0:
                break
        if on and near_any(add(E, mul(h, t)), own[k] + xs[kinds[k]], 4.0, along=h):
            problems.append("%s path stops at the road off any %s at (%.1f, %.1f) and goes on across it" % (
                k, kinds[k], x, z))
    return problems


def self_crossing(p):
    n = len(p)
    if n < 4:
        return False
    for i in range(n):
        a, b = p[i], p[(i + 1) % n]
        for k in range(i + 2, n):
            if (k + 1) % n == i:
                continue
            c, e = p[k], p[(k + 1) % n]
            if seg_hit(a, b, c, e) is not None:
                return True
    return False


def polylines_cross(a, b):
    ba = (min(q[0] for q in a), min(q[1] for q in a), max(q[0] for q in a), max(q[1] for q in a))
    bb = (min(q[0] for q in b), min(q[1] for q in b), max(q[0] for q in b), max(q[1] for q in b))
    if ba[2] < bb[0] or bb[2] < ba[0] or ba[3] < bb[1] or bb[3] < ba[1]:
        return None
    for i in range(len(a) - 1):
        for k in range(len(b) - 1):
            t = seg_hit(a[i], a[i + 1], b[k], b[k + 1])
            if t is not None and 0.02 < t < 0.98:
                return lerp(a[i], a[i + 1], t)
    return None


# --- evidence ---------------------------------------------------------------------------------

LAT0, LON0 = 52.2340, 21.0240
ML = 110574.0
MO = 111320.0 * math.cos(math.radians(LAT0))


def needs(area, osm_path):
    """The OSM tags of every way of the area's streets, ordered along their axes."""
    spec = load_spec(area)
    with open(osm_path, encoding="utf-8") as f:
        els = json.load(f)["elements"]
    nodes = {e["id"]: e for e in els if e["type"] == "node"}

    def xz(n):
        return ((n["lon"] - LON0) * MO, (LAT0 - n["lat"]) * ML)
    for sspec in spec["streets"]:
        st = Street(sspec)
        rows = []
        for e in els:
            t = e.get("tags", {})
            if e["type"] != "way" or "highway" not in t:
                continue
            pts = [xz(nodes[n]) for n in e["nodes"] if n in nodes]
            if len(pts) < 2:
                continue
            mid = pts[len(pts) // 2]
            s, off = project(st, mid)
            if s is None or abs(off) > 30 or not (-10 <= s <= st.L + 10):
                continue
            if t["highway"] in ("footway", "path", "steps", "pedestrian") and t.get("footway") != "crossing":
                continue
            keys = {k: v for k, v in t.items() if k.startswith(("lanes", "turn", "placement", "oneway", "cycleway",
                                                                  "bus", "psv", "width", "crossing", "footway"))}
            rows.append((s, off, e["id"], t.get("highway"), t.get("name", ""), keys))
        print("== %s (%s), %.0f m" % (st.id, sspec.get("name", ""), st.L))
        for s, off, wid, hw, name, keys in sorted(rows):
            print("  s %6.1f off %+6.1f  way %s %s %s %s" % (s, off, wid, hw, name, keys))
        for e in els:
            if e["type"] == "node" and e.get("tags", {}).get("highway") in ("crossing", "traffic_signals"):
                s, off = project(st, xz(e))
                if s is not None and abs(off) < 25 and -5 <= s <= st.L + 5:
                    print("  s %6.1f off %+6.1f  node %s %s" % (s, off, e["id"], e["tags"]))


def project(st, p):
    best = None
    for i in range(len(st.pts) - 1):
        a, b = st.pts[i], st.pts[i + 1]
        ab = sub(b, a)
        L2 = dot(ab, ab)
        if L2 == 0:
            continue
        t = max(0.0, min(1.0, dot(sub(p, a), ab) / L2))
        q = add(a, mul(ab, t))
        dd = math.dist(q, p)
        if best is None or dd < best[0]:
            off = cross(norm(ab), sub(p, a))
            best = (dd, st.cum[i] + t * math.sqrt(L2), off)
    return (best[1], best[2]) if best else (None, None)


def main(argv):
    if "--check-all" in argv:
        with open(MAP, encoding="utf-8") as f:
            out = json.load(f)
        bad = 0
        for area in sorted(out.get("road_design", {})):
            d = Design(load_spec(area)).build()
            probs = check(d)
            # on the map as applied: footways and cycle tracks continuous over the new asphalt
            probs += continuity(out, Design(load_spec(area), out["roads"]).build())
            bad += len(probs)
            for p in probs[:20]:
                print("  %s: %s" % (area, p))
        print("road_design: %s, %d problems" % (", ".join(sorted(out.get("road_design", {}))) or "no areas", bad))
        return 1 if bad else 0
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__)
        return 2
    area = args[0]
    if "--needs" in argv:
        needs(area, argv[argv.index("--needs") + 1])
        return 0
    d = Design(load_spec(area)).build()
    probs = check(d)
    for p in probs[:40]:
        print("  " + p)
    print("road_design: %s: %d carriage, %d kerbs, %d lines, %d arrows/words, %d zebras, %d problems" % (
        area, len(d.out["carriage"]), len(d.out["kerbs"]), len(d.out["markings"]), len(d.out["symbols"]),
        len(d.out["zebras"]), len(probs)))
    if "--check" in argv:
        return 1 if probs else 0
    src = argv[argv.index("--from") + 1] if "--from" in argv else MAP
    dst = argv[argv.index("--out") + 1] if "--out" in argv else MAP
    with open(src, encoding="utf-8") as f:
        out = json.load(f)
    if area in out.get("road_design", {}):
        raise SystemExit("road_design: %s is already applied to %s; use --from with the map from before" % (area, src))
    # built again on the map: the side roads' mouths come from the map's own roads
    d = Design(load_spec(area), out["roads"]).build()
    for st in d.streets.values():
        for o in getattr(st, "auto_open", []):
            print("  opening %s s %.0f %s w %.1f" % (st.id, o["s"], "right" if o["side"] > 0 else "left", o["w"]))
    stats = apply_design(out, d)
    print("road_design: removed " + ", ".join("%s %d" % kv for kv in stats.items()))
    gaps = continuity(out, d)
    for p in gaps[:40]:
        print("  " + p)
    print("road_design: continuity: %d path ends at the road off a crossing" % len(gaps))
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
