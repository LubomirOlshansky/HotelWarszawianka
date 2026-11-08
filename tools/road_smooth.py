"""Smooth roads (F, 2026-11-05: "make the roads smooth, like it was hand designed"): the width
steps where two OpenStreetMap ways of one carriageway meet, tapered; the lane lines stitched
across those joins; small kinks in the lines rounded.

    python3 -I tools/road_smooth.py [MAP.json] [--dry] [--report]
        rewrites the map in place (idempotent: a map already smoothed is left alone);
        --dry measures and changes nothing; --report prints the steps and jogs left.
    python3 -I tools/road_smooth.py --check [MAP.json]
        exit 1 unless the map is smoothed and its edge steps and line jogs are at most
        CHECK_STEPS and CHECK_JOGS (verify.sh step `smooth`; a ratchet: lower them, never raise).

Why. The bake draws every OpenStreetMap way as its own ribbon (`roads[].w` wide, `c` off its
centreline) and paints its lane lines on its own (bake_roads.bake_lane_lines). Where the lane
count or the width changes at a join, the ribbon edge jumps sideways, the wider way's round end
cap bulges past the narrower one (the dark blob by the kerb), the kerb and the edge line, walked
round that outline, jog with it, and every lane line ends and starts again up to 1.6 m aside.
852 joins of the demo box stepped their edge by more than 0.3 m (588 by more than 1 m). A real
street opens or closes a lane with a taper: the edge drifts over 20-30 m, the lines with it.

What, on the finished map data (bake_osm.py calls `apply(out)` after car_free and the other
post-passes; this file also runs on a baked map, as the cloud has no OpenStreetMap download):

1. Chains: two drivable ways (not service or living streets) meet end to end at one point,
   carry on within CHAIN_COS, on the same deck level, with the same name and one-way flag.
2. Taper: at every join whose edge steps by STEP_MIN..STEP_MAX m, both ways get per-vertex
   widths and centre offsets (`wv`, `cv`, one per point of `p`; vertices are added every
   TAPER_STEP m on the taper without moving the line, so `hide` distances stay true). On each
   side the wider way keeps its edge to the node and the narrower one flares out to it along one
   smoothstep over L = TAPER_BASE + TAPER_PER_M * step (TAPER_MIN..TAPER_MAX m, at most half
   the way): where the wider way's round end cap bulged, a lane now opens or closes. The kerbs
   and lines of the wider way stay true. map_builder.gd draws `wv`/`cv` roads as one mitred
   band, so both ends are as wide at the node and no cap bulges.
3. Kerbs and edge lines: their points by a tapered join that lie on the old stepped edge (or the
   wider way's round cap, between the two edges) are moved onto the tapered edge, keeping their
   inset (resampled every metre first); not on a side where another road leaves the node (the
   kerb turns into it there). No flare on such a side either: the wider way's corner meets the
   other road's mouth there (a flare showed as a dark flag over a driveway, F's crop by PKiN).
   Where a side's kerb runs smoothly past the taper (left alone above), the asphalt edge follows
   that kerb instead of its smoothstep (fit_kerbs), so no wedge of road pokes past the kerb.
4. Lines: a lane, centre, edge or cycle line that ends where another of its kind starts within
   STITCH_GAP m ahead, at most STITCH_SIDE m aside and parallel, is joined to it with the same
   kind of S-curve (one polyline, no gap, no jump).
5. Kinks: a lane, centre or cycle line's corner turning ROUND_MIN..ROUND_MAX degrees is rounded
   into a short arc (cut at most ROUND_CUT m each side); ribbons keep their round joins.
6. Tram beds (F's ChatGPT target): a tram track's runs on its own bed (ballast surface or tram
   median) are marked (`trams[].bed`) for sleepers; a road, footway or a zebra's line that crosses
   a bed becomes a band over it (`tram_xings`) and the kerbs and lines inside it go; steps that
   end at a metro entrance name their deep end (`steps[].down`).
7. Openings (F's round 4): a road through a tram median (a U-turn link at least UTURN_W m) gets
   one paved footprint (`tram_xings[].foot`) with the median ended in rounded, kerbed noses
   (`tram_noses`); kerb stubs and line scraps left there go. At main-street crossings
   (crossing_kit) the lane arrows follow each lane's moves at the junction ahead, and stand
   clear of a U-turn link's mouth with a straight-and-U-turn arrow in the inner lane.

The lane graph, the carriageway areas, the junction boxes and the decks are not touched.
Deterministic, standard library only. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys
from collections import defaultdict

VERSION = 2
# --check (2026-11-05, the demo box after the first pass): 727 edge steps -> 15 (joins without room
# for a taper), 969 line jogs -> 16. Lower these when a change leaves fewer; never raise them.
CHECK_STEPS = 10
CHECK_JOGS = 23
CHECK_ZLINES = 1        # lane or centre lines still under a zebra (Unslop L4; 215 before the final cut; ratchet down)
CHECK_EDGEX = 400       # edge-line segments across a kerb (Unslop L3; 540 before seating; many are real corner mouths; ratchet down)
MINOR = {"service", "living_street"}
CHAIN_COS = 0.85        # ways carry on: their directions at the join within ~32 degrees
STEP_MIN = 0.3          # m: a smaller edge step is invisible
STEP_MAX = 6.0          # m: a bigger one is a different road shape (a slip, a bay), not a lane
TAPER_BASE = 20.0
TAPER_PER_M = 3.0
TAPER_MIN = 20.0
TAPER_MAX = 30.0
TAPER_STEP = 2.5        # m between the taper's vertices
JOG_MIN = 0.15          # m off its own chord: a line that jogs or bulges by the node
JOG_REACH = 1.5         # m past the node where the old jog's points still go onto the edge
SMOOTH_PASSES = 6       # light averaging of a moved line's points by the node
EDGE_BAND = 0.7         # m: a kerb point this close to the old edge (or between the two) follows
LINE_KINDS = ("lane", "centre", "edge", "cycle", "cyclefill", "bus")
STITCH_GAP = 3.0        # m: a line starting this far ahead (or 1 m behind) carries the one ending
STITCH_BACK = 1.0
STITCH_SIDE = 3.6       # m aside at most (a lane)
STITCH_COS = 0.96       # parallel within ~16 degrees
ROUND_KINDS = ("lane", "centre", "cycle", "cyclefill", "bus")
ROUND_MIN = 3.0
ROUND_MAX = 35.0
ROUND_CUT = 4.0
ROUND_SEG = 3.0         # degrees per arc piece
RAIL_GAP_MIN = 0.3      # m: a strip of ground narrower than this between asphalt and ballast is invisible
RAIL_GAP_MAX = 3.0      # m: a wider one is a real verge, a stop or a separator, kept
RAIL_COVER = 0.6        # share of the way's visible vertices that must find the bed
RAIL_JUMP = 0.3         # m per metre along: how fast the gap may change (a straight bed)
CHAIN_FILL_MAX = 150.0  # m: a longer way narrower than its neighbours may really be narrower
KERB_GAP = 10.0         # m: a kerb break along a tram bed this short is joined across
KERB_SIDE = 0.3


def pts_of(flat):
    return [(flat[i], flat[i + 1]) for i in range(0, len(flat) - 1, 2)]


def flat_of(pts, nd=2):
    out = []
    for x, z in pts:
        out += [round(x, nd), round(z, nd)]
    return out


def unit(a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dz)
    return None if ln < 1e-6 else (dx / ln, dz / ln)


def smooth(x):
    x = min(max(x, 0.0), 1.0)
    return x * x * (3.0 - 2.0 * x)


def taper_len(step):
    return min(max(TAPER_BASE + TAPER_PER_M * step, TAPER_MIN), TAPER_MAX)


def length(pts):
    return sum(math.dist(a, b) for a, b in zip(pts, pts[1:]))


def resample_between(pts, s0, s1, step):
    """`pts` with extra vertices at s0, s0 + step, ... and s1 (distances along it; none moved)."""
    marks = []
    u = s0
    while u < s1 - 1e-6:
        marks.append(u)
        u += step
    marks.append(s1)
    out = [pts[0]]
    s = 0.0
    for a, b in zip(pts, pts[1:]):
        ln = math.dist(a, b)
        for u in marks:
            if s + 0.3 < u < s + ln - 0.3:
                t = (u - s) / ln
                out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
        out.append(b)
        s += ln
    return out


def cumulative(pts):
    cum = [0.0]
    for a, b in zip(pts, pts[1:]):
        cum.append(cum[-1] + math.dist(a, b))
    return cum


class Grid:
    def __init__(self, cell=16.0):
        self.cell = cell
        self.g = defaultdict(list)

    def add(self, item, x, z):
        self.g[(int(math.floor(x / self.cell)), int(math.floor(z / self.cell)))].append(item)

    def near(self, x, z, r):
        c = self.cell
        for i in range(int(math.floor((x - r) / c)), int(math.floor((x + r) / c)) + 1):
            for j in range(int(math.floor((z - r) / c)), int(math.floor((z + r) / c)) + 1):
                yield from self.g.get((i, j), ())


# --- 1. chains -----------------------------------------------------------------------------

def _end(r, i, last):
    """An end of road r seen from its node: (node, away direction, left, right) in the away frame
    (left/right: the drawn edges' offsets from the centreline, + to the right of `away`)."""
    p = r["p"]
    c = float(r.get("c", 0.0))
    hw = float(r["w"]) * 0.5
    if "wv" in r:   # a way fit_rail_beds widened: its own end
        k = len(r["wv"]) - 1 if last else 0
        c, hw = float(r["cv"][k]), float(r["wv"][k]) * 0.5
    if not last:
        node = (p[0], p[1])
        away = unit(node, (p[2], p[3]))
        return node, away, c - hw, c + hw
    node = (p[-2], p[-1])
    away = unit(node, (p[-4], p[-3]))
    return node, away, -(c + hw), -(c - hw)


def find_joins(roads):
    """[(ia, last_a, ib, last_b, node, away_a, (la, ra), (lb', rb') in a's away frame)] for every
    join of two ways of one chain whose edge steps STEP_MIN..STEP_MAX m."""
    ends = defaultdict(list)
    for i, r in enumerate(roads):
        if r["k"] in MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away, lft, rgt = _end(r, i, last)
            if away is None:
                continue
            ends[(round(node[0], 1), round(node[1], 1))].append((i, last, node, away, lft, rgt))
    joins = []
    used = set()
    for key in sorted(ends):
        lst = ends[key]
        cands = []
        for x in range(len(lst)):
            for y in range(x + 1, len(lst)):
                ia, la_, na, aa, l1, r1 = lst[x]
                ib, lb_, nb, ab, l2, r2 = lst[y]
                if ia == ib:
                    continue
                A, B = roads[ia], roads[ib]
                if (A.get("name") or "") != (B.get("name") or "") or bool(A.get("oneway")) != bool(B.get("oneway")):
                    continue
                if not A.get("name") and A["k"] != B["k"]:
                    continue
                if int(A.get("dk", -1)) != int(B.get("dk", -1)):
                    continue
                cos = aa[0] * ab[0] + aa[1] * ab[1]
                if cos > -CHAIN_COS:
                    continue
                cands.append((cos, x, y))
        cands.sort()
        for cos, x, y in cands:
            if x in used_local(used, key) or y in used_local(used, key):
                continue
            ia, la_, na, aa, l1, r1 = lst[x]
            ib, lb_, nb, ab, l2, r2 = lst[y]
            # b's edges in a's away frame: b faces the other way, so its right is a's left.
            ob = (-r2, -l2)
            step = max(abs(l1 - ob[0]), abs(r1 - ob[1]))
            used.add((key, x))
            used.add((key, y))
            if STEP_MIN < step <= STEP_MAX:
                joins.append((ia, la_, ib, lb_, (na[0], na[1]), aa, (l1, r1), ob, step))
    return joins


def major_sides(roads, node, ia, ib, aa):
    """The sides (0 left, 1 right, in a's away frame) where a street (not a service road or a
    living street) other than ia and ib leaves `node`."""
    n = (-aa[1], aa[0])
    key = (round(node[0], 1), round(node[1], 1))
    out = set()
    for i in _NODE_ROADS.get(key, ()):
        if i in (ia, ib) or roads[i]["k"] in MINOR:
            continue
        p = roads[i]["p"]
        m = len(p) // 2
        for k in range(m):
            if (round(p[2 * k], 1), round(p[2 * k + 1], 1)) != key:
                continue
            for nb in ((k - 1,) if k == m - 1 else (k + 1,) if k == 0 else (k - 1, k + 1)):
                d = unit((p[2 * k], p[2 * k + 1]), (p[2 * nb], p[2 * nb + 1]))
                if d is not None:
                    out.add(1 if d[0] * n[0] + d[1] * n[1] > 0 else 0)
    return out


_NODE_ROADS = {}


def index_nodes(roads):
    """Which roads pass through each node (rounded to 0.1 m), for major_sides."""
    _NODE_ROADS.clear()
    for i, r in enumerate(roads):
        p = r["p"]
        for k in range(0, len(p) - 1, 2):
            _NODE_ROADS.setdefault((round(p[k], 1), round(p[k + 1], 1)), set()).add(i)


def branch_sides(roads, joins):
    """For each join, the sides (0 left, 1 right, in a's away frame) where another road leaves
    its node: the kerb there turns into that road (a corner return), so it is not moved."""
    at = defaultdict(list)
    for i, r in enumerate(roads):
        p = r["p"]
        n = len(p) // 2
        for k in range(n):
            key = (round(p[2 * k], 1), round(p[2 * k + 1], 1))
            for nb in ((k - 1,) if k == n - 1 else (k + 1,) if k == 0 else (k - 1, k + 1)):
                at[key].append((i, (p[2 * nb], p[2 * nb + 1])))
    out = []
    for ia, la_, ib, lb_, node, aa, ea, eb, step in joins:
        sides = set()
        n = (-aa[1], aa[0])
        for i, q in at[(round(node[0], 1), round(node[1], 1))]:
            if i in (ia, ib):
                continue
            d = unit(node, q)
            if d is None:
                continue
            sides.add(1 if d[0] * n[0] + d[1] * n[1] > 0 else 0)
        out.append(sides)
    return out


def used_local(used, key):
    return {x for k, x in used if k == key}


# --- 2. taper ------------------------------------------------------------------------------

def side_spans(ea, eb, L, la, lb):
    """Per side (left, right): where the edge moves, (metres on a, metres on b). The wider way
    keeps its edge to the node and the narrower one flares out to meet it (the wider way's round
    cap was drawn there; its kerb and lines are left as they are). At most half a way's length."""
    out = []
    for side in (0, 1):
        a_out = ea[side] < eb[side] if side == 0 else ea[side] > eb[side]
        if a_out:
            out.append((0.0, min(L, lb * 0.5)))
        else:
            out.append((min(L, la * 0.5), 0.0))
    return out


def taper_roads(roads, joins, ends):
    """Per-vertex `wv`/`cv` on both ways of every join. Returns the tapers for the kerbs:
    [(node, away_a, spans, (la, ra), (lb, rb), branch sides)] (b's edges in a's away frame;
    spans from side_spans); `ends` gets (ia, last_a, ib, last_b) per taper."""
    specs = defaultdict(list)   # road -> [(last, own spans, own(l, r), other(l, r))]
    out = []
    ends.clear()
    lens = {}
    blocked = branch_sides(roads, joins)
    for (ia, la_, ib, lb_, node, aa, ea, eb, step), sides in zip(joins, blocked):
        for i in (ia, ib):
            if i not in lens:
                lens[i] = length(pts_of(roads[i]["p"]))
        spans = side_spans(ea, eb, taper_len(step), lens[ia], lens[ib])
        if any(abs(ea[k] - eb[k]) > STEP_MIN and sum(spans[k]) < 4.0 for k in (0, 1)):
            continue   # no room for a taper: leave the join as it is
        # Loop 2: no flare on a side where a street leaves the node (its corner kerb turns into
        # that street). Loop 4 (F's crop of the PKiN driveway corner): a driveway or service road
        # there is drawn under the street (map_builder MINOR_ROAD_BIAS), so the flare runs on over
        # its mouth and the corner is smooth instead of a rounded notch.
        majors = major_sides(roads, node, ia, ib, aa)
        spans = [(0.0, 0.0) if k in majors else spans[k] for k in (0, 1)]
        specs[ia].append((la_, spans, ea, eb))
        # b in its own away frame: mirrored, so its left is a's right.
        mirrored = [(spans[1][1], spans[1][0]), (spans[0][1], spans[0][0])]
        specs[ib].append((lb_, mirrored, (-eb[1], -eb[0]), (-ea[1], -ea[0])))
        out.append((node, aa, spans, ea, eb, sides))
        ends.append((ia, la_, ib, lb_))
    for i, lst in specs.items():
        r = roads[i]
        pts = pts_of(r["p"])
        total = lens[i]
        # the way's own edges before the taper (fit_rail_beds may have set them per vertex)
        if "wv" in r:
            base_s = cumulative(pts)
            base = [(float(c) - float(w) * 0.5, float(c) + float(w) * 0.5) for w, c in zip(r["wv"], r["cv"])]
        else:
            base_s, base = None, None
        for last, spans, _, _ in lst:
            h = max(spans[0][0], spans[1][0])
            if h <= 0.0:
                continue
            if last:
                pts = resample_between(pts, total - h, total, TAPER_STEP)
            else:
                pts = resample_between(pts, 0.0, h, TAPER_STEP)
        cum = cumulative(pts)
        total = cum[-1]
        c0 = float(r.get("c", 0.0))
        hw = float(r["w"]) * 0.5
        wv, cv = [], []
        for s in cum:
            lft, rgt = c0 - hw, c0 + hw
            if base is not None:
                lft, rgt = _interp_edges(base_s, base, s)
            for last, spans, own, other in lst:
                u = total - s if last else s
                d = [0.0, 0.0]
                for k in (0, 1):
                    h, ho = spans[k]
                    if u < h:
                        d[k] = (other[k] - own[k]) * smooth((h - u) / (h + ho))
                    elif h <= 0.0 and u <= 0.0:
                        d[k] = 0.0
                if last:   # the away frame is mirrored: its left is the road's right
                    lft -= d[1]
                    rgt -= d[0]
                else:
                    lft += d[0]
                    rgt += d[1]
            wv.append(round(rgt - lft, 3))
            cv.append(round((rgt + lft) * 0.5, 3))
        r["p"] = flat_of(pts)
        r["wv"] = wv
        r["cv"] = cv
    return out


def _interp_edges(cum, edges, s):
    """The (left, right) edges at s m along, from per-vertex ones at the distances `cum`."""
    if s <= cum[0]:
        return edges[0]
    for k in range(1, len(cum)):
        if s <= cum[k]:
            f = (s - cum[k - 1]) / max(cum[k] - cum[k - 1], 1e-9)
            a, b = edges[k - 1], edges[k]
            return a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f
    return edges[-1]


def taper_edge(t, side, x):
    """Tapered edge offset (in a's away frame) at x m from the node (x > 0 on a, < 0 on b)."""
    node, aa, spans, ea, eb, _ = t
    ha, hb = spans[side]
    if ha + hb <= 0.0:
        return ea[side] if x > 0 else eb[side]
    # one smoothstep from a's edge (x = ha) to b's edge (x = -hb)
    f = smooth((ha - x) / (ha + hb))
    return ea[side] + (eb[side] - ea[side]) * f


# --- 3. kerbs and edge lines ---------------------------------------------------------------

def snap_lines(lines, tapers, get, put):
    """Moves the points of `lines` that lie on a taper's old stepped edge onto the new one."""
    grid = Grid(32.0)
    for k, t in enumerate(tapers):
        grid.add(k, t[0][0], t[0][1])
    moved = 0
    for li, line in enumerate(lines):
        pts = get(line)
        if len(pts) < 2:
            continue
        hits = set()
        for x, z in pts[:: max(1, len(pts) // 64)] + [pts[-1]]:
            for k in grid.near(x, z, 48.0):
                hits.add(k)
        if not hits:
            continue
        changed = False
        for k in sorted(hits):
            t = tapers[k]
            node, aa, spans, ea, eb, sides = t
            n = (-aa[1], aa[0])  # + is right of the direction, as bake_roads.offset_line and map_builder
            reach = max(max(sp) for sp in spans) + 1.5
            # resample near the node
            dense = []
            for a, b in zip(pts, pts[1:]):
                dense.append(a)
                if seg_dist(node, a, b) < reach + 30.0:
                    ln = math.dist(a, b)
                    m = int(ln)
                    for q in range(1, m):
                        dense.append((a[0] + (b[0] - a[0]) * q / m, a[1] + (b[1] - a[1]) * q / m))
            dense.append(pts[-1])
            # The line's own inset from the edge it follows (an edge line is painted ~0.3 m in
            # from the kerb), from its points on the old straight edges, kept on the new one.
            local = []
            for x, z in dense:
                dx, dz = x - node[0], z - node[1]
                ax = dx * aa[0] + dz * aa[1]
                if abs(ax) <= reach:
                    local.append((ax, dx * n[0] + dz * n[1]))
            inset = {}
            for side in (0, 1):
                # Only a line that really runs along this side's edge on the way that flares
                # (a kerb at a junction's corner or an island near it does not), at one inset.
                ha, hb = spans[side]
                if ha + hb <= 0.0 or abs(ea[side] - eb[side]) <= STEP_MIN:
                    continue
                # Its inset from the edge just past each end of the taper, where it is left as
                # it was; across the taper it follows the new edge, its inset blended between.
                xa = max(ha, JOG_REACH) + 0.5
                xb = -max(hb, JOG_REACH) - 0.5

                def at(x0, edge):
                    best = None
                    for ax, y in local:
                        if abs(ax - x0) <= 1.5 and abs(y - edge) <= EDGE_BAND:
                            if best is None or abs(ax - x0) < best[0]:
                                best = (abs(ax - x0), y - edge)
                    return None if best is None else best[1]
                ma, mb = at(xa, ea[side]), at(xb, eb[side])
                if ma is None or mb is None:
                    continue
                # A line that already runs smoothly across (the bake walked many a kerb at a
                # long slant) is left alone: only one that jogs or bulges by the node moves.
                ya, yb = ea[side] + ma, eb[side] + mb
                lo = min(ea[side], eb[side]) - EDGE_BAND
                hi = max(ea[side], eb[side]) + EDGE_BAND
                if not any(lo <= y <= hi and abs(y - (yb + (ya - yb) * (ax - xb) / (xa - xb))) > JOG_MIN
                           for ax, y in local if xb < ax < xa):
                    continue
                inset[side] = (ma, mb)
            new = []
            for q, (x, z) in enumerate(dense):
                dx, dz = x - node[0], z - node[1]
                ax = dx * aa[0] + dz * aa[1]
                y = dx * n[0] + dz * n[1]
                done = False
                for side in (0, 1):
                    if side in sides or side not in inset:
                        continue
                    ha, hb = spans[side]
                    # past the taper the edge is where it was; the step's own jog, just past
                    # the node on the wider way, goes onto that way's edge
                    if ax > max(ha, JOG_REACH) + 0.5 or ax < -max(hb, JOG_REACH) - 0.5:
                        continue
                    lo = min(ea[side], eb[side]) - EDGE_BAND
                    hi = max(ea[side], eb[side]) + EDGE_BAND
                    if lo <= y <= hi:
                        xa, xb = max(ha, JOG_REACH) + 0.5, -max(hb, JOG_REACH) - 0.5
                        f = (xa - ax) / (xa - xb)
                        ny = taper_edge(t, side, ax) + inset[side][0] + (inset[side][1] - inset[side][0]) * f
                        new.append((node[0] + aa[0] * ax + n[0] * ny, node[1] + aa[1] * ax + n[1] * ny))
                        done = True
                        moved += 1
                        changed = True
                        break
                if not done:
                    new.append((x, z))
            if moved_here(new, dense):
                # Even out what is left where the moved points meet the unmoved ones (a kerb
                # the bake drew at a slant, an inset that differs a little on the two ways).
                for _ in range(SMOOTH_PASSES):
                    out = [new[0]]
                    for q in range(1, len(new) - 1):
                        x, z = new[q]
                        if math.dist((x, z), node) <= reach + 4.0:
                            a, b = new[q - 1], new[q + 1]
                            x = 0.5 * x + 0.25 * (a[0] + b[0])
                            z = 0.5 * z + 0.25 * (a[1] + b[1])
                        out.append((x, z))
                    out.append(new[-1])
                    new = out
            pts = new
        if changed:
            put(line, simplify(pts, 0.03))
    return moved


def _poly_hit(pts, x, z):
    c = False
    n = len(pts)
    for i in range(n):
        ax, az = pts[i]
        bx, bz = pts[(i + 1) % n]
        if (az > z) != (bz > z) and x < ax + (z - az) * (bx - ax) / (bz - az):
            c = not c
    return c


def fit_rail_beds(out):
    """Loop 3 (F's red lines by Złota; Mapillary 2026-08-30: the asphalt runs right up to the tram
    bed): a street drawn narrower than it is leaves a strip of bare ground (RAIL_GAP_MIN..MAX m)
    between its edge and a tram bed's ballast. That side's edge goes out onto the ballast, vertex
    by vertex (`wv`/`cv`), so the kerb runs straight along the tracks and the next way's taper has
    less to make up. Only where the bed is found along most of the way (RAIL_COVER) and the gap
    changes gently (RAIL_JUMP per sample); not over a platform, an island or a tree in the strip.
    Kerb and edge-line points on the old edge move out with it. Returns (ways, sides)."""
    beds = [pts_of(su["p"]) for su in out.get("surfaces", []) if su.get("k") == "ballast"]
    keep = [pts_of(q["p"]) for q in out.get("platforms", []) + out.get("islands", [])]
    grid = Grid(64.0)
    for k, poly in enumerate(beds):
        xs = [x for x, _ in poly]
        zs = [z for _, z in poly]
        for gx in range(int(math.floor(min(xs) / 64.0)), int(math.floor(max(xs) / 64.0)) + 1):
            for gz in range(int(math.floor(min(zs) / 64.0)), int(math.floor(max(zs) / 64.0)) + 1):
                grid.g[(gx, gz)].append(k)
    kgrid = Grid(32.0)
    for k, poly in enumerate(keep):
        xs = [x for x, _ in poly]
        zs = [z for _, z in poly]
        for gx in range(int(math.floor(min(xs) / 32.0)), int(math.floor(max(xs) / 32.0)) + 1):
            for gz in range(int(math.floor(min(zs) / 32.0)), int(math.floor(max(zs) / 32.0)) + 1):
                kgrid.g[(gx, gz)].append(k)
    tgrid = Grid(16.0)
    for key, n in (("trees", 4), ("trees3d", 6)):
        t = out.get(key, [])
        for q in range(0, len(t) - n + 1, n):
            tgrid.add((t[q], t[q + 1]), t[q], t[q + 1])

    def gap_at(x, z, nrm, sgn, edge):
        ex, ez = x + nrm[0] * edge, z + nrm[1] * edge
        dx, dz = nrm[0] * sgn, nrm[1] * sgn
        best = None
        for k in set(grid.near(ex, ez, 1.0)):
            poly = beds[k]
            for q in range(len(poly)):
                a, b = poly[q], poly[(q + 1) % len(poly)]
                sx, sz = b[0] - a[0], b[1] - a[1]
                den = dx * sz - dz * sx
                if abs(den) < 1e-9:
                    continue
                t = ((a[0] - ex) * sz - (a[1] - ez) * sx) / den
                v = ((a[0] - ex) * dz - (a[1] - ez) * dx) / den
                if 0.0 <= v <= 1.0 and -0.2 <= t <= RAIL_GAP_MAX + 0.5 and (best is None or t < best):
                    best = t
        if best is None or not (RAIL_GAP_MIN <= best <= RAIL_GAP_MAX):
            return None
        for f in (0.25, 0.5, 0.75):
            mx, mz = ex + dx * best * f, ez + dz * best * f
            if any(_poly_hit(beds[k], mx, mz) for k in set(grid.near(mx, mz, 1.0))):
                return None   # the edge already meets the ballast (a bend of the bed's outline)
            if any(_poly_hit(keep[k], mx, mz) for k in set(kgrid.near(mx, mz, 1.0))):
                return None
        mx, mz = ex + dx * best * 0.5, ez + dz * best * 0.5
        if any(math.dist(t, (mx, mz)) < best * 0.5 + 0.8 for t in tgrid.near(mx, mz, 4.0)):
            return None
        return best

    moved = []   # (road points, sign, old edge, gap per vertex)
    ways, sides = 0, 0
    for r in out["roads"]:
        if r["k"] in MINOR or int(r.get("dk", -1)) >= 0 or "wv" in r or len(r["p"]) < 4:
            continue
        pts = pts_of(r["p"])
        total = length(pts)
        if total < 15.0:
            continue
        hide = r.get("hide", [])
        cum = cumulative(pts)
        c0, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
        lft = [c0 - hw] * len(pts)
        rgt = [c0 + hw] * len(pts)
        samples = []   # (distance along, point, direction)
        for v in range(len(pts)):
            if any(h0 <= cum[v] <= h1 for h0, h1 in hide):
                continue
            a = pts[max(v - 1, 0)]
            b = pts[min(v + 1, len(pts) - 1)]
            u = unit(a, b)
            if u is not None:
                samples.append((v, pts[v], u))
        if len(samples) < 4:
            continue
        changed = False
        for sgn in (-1.0, 1.0):   # left, right (+ is right of travel)
            edge = c0 + sgn * hw
            got = {}
            for v, (x, z), u in samples:
                g = gap_at(x, z, (-u[1], u[0]), sgn, edge)
                if g is not None:
                    got[v] = g
            if len(got) < RAIL_COVER * len(samples) or len(got) < 3:
                continue
            # every vertex: its own gap, else the nearest found one along the way
            keys = sorted(got)
            gv = []
            for v in range(len(pts)):
                if v in got:
                    gv.append(got[v])
                else:
                    near = min(keys, key=lambda q: abs(cum[q] - cum[v]))
                    gv.append(got[near] if abs(cum[near] - cum[v]) <= 6.0 else 0.0)
            if any(abs(gv[v + 1] - gv[v]) > RAIL_JUMP * max(1.0, cum[v + 1] - cum[v]) for v in range(len(pts) - 1)):
                continue   # the bed's outline turns away (a stop, a loop): not one straight kerb
            for v in range(len(pts)):
                if sgn < 0:
                    lft[v] -= gv[v]
                else:
                    rgt[v] += gv[v]
            moved.append((pts, sgn, [edge] * len(pts), gv))
            sides += 1
            changed = True
        if changed:
            ways += 1
            WIDENED.append((pts, [(c0 - hw, c0 + hw)] * len(pts), list(zip(lft, rgt))))
            r["wv"] = [round(b - a, 3) for a, b in zip(lft, rgt)]
            r["cv"] = [round((a + b) * 0.5, 3) for a, b in zip(lft, rgt)]
    move_with_edges(out, moved)
    return ways, sides


WIDENED = []   # (road points, old (left, right) per vertex, new (left, right) per vertex)
LANE_PAINT = ("lane", "centre", "bus")


def spread_lanes(out):
    """Loop 6 (F's satellite shots: lanes fill the street's kerbs): on a way widened above, its
    lane lines spread across the new width (each line keeps its share of the way, so the lanes
    widen evenly instead of leaving a bare margin by the kerb). Returns the points moved."""
    if not WIDENED:
        return 0
    grid = Grid(32.0)
    for k, (pts, _, _) in enumerate(WIDENED):
        for x, z in pts:
            grid.add(k, x, z)
    moved = 0
    for m in out.get("markings", []):
        if m["k"] not in LANE_PAINT:
            continue
        lp = pts_of(m["p"])
        # densify, so a long dash or line follows the change of width along the way
        dense = [lp[0]]
        for a, b in zip(lp, lp[1:]):
            n = max(1, int(math.dist(a, b) / 2.0))
            for t in range(1, n + 1):
                dense.append((a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n))
        new, hit = [], False
        for x, z in dense:
            out_p = (x, z)
            for k in set(grid.near(x, z, 40.0)):
                pts, old, nw = WIDENED[k]
                best = None
                for q, (a, b) in enumerate(zip(pts, pts[1:])):
                    u = unit(a, b)
                    if u is None:
                        continue
                    ln = math.dist(a, b)
                    al = (x - a[0]) * u[0] + (z - a[1]) * u[1]
                    if not (-0.5 <= al <= ln + 0.5):
                        continue
                    f = min(max(al / ln, 0.0), 1.0)
                    ol = old[q][0] + (old[q + 1][0] - old[q][0]) * f
                    orr = old[q][1] + (old[q + 1][1] - old[q][1]) * f
                    off = (x - a[0]) * -u[1] + (z - a[1]) * u[0]
                    if ol + 0.4 < off < orr - 0.4 and (best is None or abs(off - (ol + orr) / 2) < best[0]):
                        nl = nw[q][0] + (nw[q + 1][0] - nw[q][0]) * f
                        nr = nw[q][1] + (nw[q + 1][1] - nw[q][1]) * f
                        share = (off - ol) / max(orr - ol, 0.1)
                        best = (abs(off - (ol + orr) / 2), u, nl + share * (nr - nl) - off)
                if best is not None and abs(best[2]) > 0.02:
                    _, u, g = best
                    out_p = (x - u[1] * g, z + u[0] * g)
                    hit = True
                    moved += 1
                    break
            new.append(out_p)
        if hit:
            m["p"] = flat_of(simplify(new, 0.02))
    return moved


def move_with_edges(out, moved):
    """Kerbs, edge lines and tram-bed median strips standing on a road edge that moved out move
    with it. `moved`: [(road points, side sign, old edge offset per vertex, metres out per vertex)]."""
    if not moved:
        return
    lgrid = Grid(32.0)
    for k, (pts, _, _, _) in enumerate(moved):
        for x, z in pts:
            lgrid.add(k, x, z)
    lines = [(line, "p") for line in out.get("kerbs", [])] + \
        [(m, "p") for m in out.get("markings", []) if m["k"] == "edge"] + \
        [(m, "s") for m in out.get("medians", []) if m.get("k") != "grass"]
    for line, key in lines:
        lp = pts_of(line[key])
        new = []
        hit = False
        for x, z in lp:
            nx_, nz_ = x, z
            for k in set(lgrid.near(x, z, 40.0)):
                pts, sgn, edges, gv = moved[k]
                best = None
                for q, (a, b) in enumerate(zip(pts, pts[1:])):
                    u = unit(a, b)
                    if u is None:
                        continue
                    ln = math.dist(a, b)
                    al = (x - a[0]) * u[0] + (z - a[1]) * u[1]
                    if -0.5 <= al <= ln + 0.5:
                        f = min(max(al / ln, 0.0), 1.0)
                        edge = edges[q] + (edges[q + 1] - edges[q]) * f
                        off = (x - a[0]) * -u[1] + (z - a[1]) * u[0]
                        if abs(off - edge) <= 0.6 and (best is None or abs(off - edge) < best[0]):
                            best = (abs(off - edge), u, gv[q] + (gv[q + 1] - gv[q]) * f)
                if best is not None and best[2] > 0.0:
                    _, u, g = best
                    nx_, nz_ = x - u[1] * sgn * g, z + u[0] * sgn * g
                    hit = True
                    break
            new.append((nx_, nz_))
        if hit:
            line[key] = flat_of(new)


def _edges_of(r):
    """Per-vertex (left, right) edge offsets of a road."""
    n = len(r["p"]) // 2
    if "wv" in r:
        return [(float(c) - float(w) * 0.5, float(c) + float(w) * 0.5) for w, c in zip(r["wv"], r["cv"])]
    c, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
    return [(c - hw, c + hw)] * n


def fit_chain_widths(out):
    """Loop 5 (F's satellite shots, 2026-11-05: a street's kerbs run straight while its lanes
    come and go by paint): a way of a street drawn narrower on a side than the ways of the same
    street at BOTH its ends (its width came from its own lane count) takes that side's edge from
    them, blended along it, so the kerb runs on instead of stepping in and out again. Not under a
    carriageway area, at most CHAIN_FILL_MAX m long. Its lane lines stay; kerbs, edge lines and
    tram-bed strips on the old edge move out. Returns (ways, sides)."""
    roads = out["roads"]
    ends = defaultdict(list)
    for i, r in enumerate(roads):
        if r["k"] in MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away, _, _ = _end(r, i, last)
            if away is not None:
                ends[(round(node[0], 1), round(node[1], 1))].append((i, last, away))

    def partner(i, last):
        """The other way's edges at i's end, in i's own frame (left, right), or None."""
        r = roads[i]
        node, away, _, _ = _end(r, i, last)
        best = None
        for j, lj, aw in ends[(round(node[0], 1), round(node[1], 1))]:
            if j == i:
                continue
            q = roads[j]
            if (q.get("name") or "") != (r.get("name") or "") or bool(q.get("oneway")) != bool(r.get("oneway")):
                continue
            if int(q.get("dk", -1)) != int(r.get("dk", -1)) or away[0] * aw[0] + away[1] * aw[1] > -CHAIN_COS:
                continue
            # q's drawn edges at its end, in its own frame, then in i's
            ql, qr = _edges_of(q)[-1 if lj else 0]
            # i and q run the same way when one leaves the node and the other arrives at it
            same = last != lj
            el, er = (ql, qr) if same else (-qr, -ql)
            if best is None:
                best = (el, er)
        return best
    moved = []
    ways, sides = 0, 0
    for i, r in enumerate(roads):
        if r["k"] in MINOR or r.get("hide") or int(r.get("dk", -1)) >= 0 or len(r["p"]) < 4:
            continue
        pts = pts_of(r["p"])
        cum = cumulative(pts)
        total = cum[-1]
        if total > CHAIN_FILL_MAX or total < 1.0:
            continue
        a, b = partner(i, False), partner(i, True)
        if a is None or b is None:
            continue
        edges = _edges_of(r)
        new = [list(e) for e in edges]
        changed = False
        for side, sgn in ((0, -1.0), (1, 1.0)):
            ea, eb = a[side], b[side]
            own0, own1 = edges[0][side], edges[-1][side]
            # wider than this way at both ends, on this side, by a visible step but not a bay
            out0 = ea - own0 if side == 1 else own0 - ea
            out1 = eb - own1 if side == 1 else own1 - eb
            if not (STEP_MIN < out0 <= STEP_MAX and STEP_MIN < out1 <= STEP_MAX):
                continue
            gv = []
            for v, s_ in enumerate(cum):
                t = ea + (eb - ea) * (s_ / total)
                old = edges[v][side]
                g = (t - old) if side == 1 else (old - t)
                g = max(g, 0.0)
                new[v][side] = old + (g if side == 1 else -g)
                gv.append(g)
            moved.append((pts, sgn, [e[side] for e in edges], gv))
            sides += 1
            changed = True
        if changed:
            ways += 1
            WIDENED.append((pts, [tuple(e) for e in edges], [tuple(e) for e in new]))
            r["wv"] = [round(e[1] - e[0], 3) for e in new]
            r["cv"] = [round((e[0] + e[1]) * 0.5, 3) for e in new]
    move_with_edges(out, moved)
    return ways, sides


def bridge_rail_kerbs(out, kerbs, reach=0.6):
    """Loop 3: a kerb along a tram bed that breaks off for a few metres by a way join (the bake
    walked the old step round it) is joined across, straight: two kerb ends at most KERB_GAP m
    apart, in line (KERB_SIDE m aside, parallel), the gap along a ballast outline and crossed by
    no zebra or path (`reach`: how near the outline; an edge line is painted 0.3 m inside the
    kerb). Works on any list of lines (kerbs, edge lines); deletes the joined ones from it.
    Returns how many."""
    beds = [pts_of(su["p"]) for su in out.get("surfaces", []) if su.get("k") == "ballast"]
    bgrid = Grid(16.0)
    for k, poly in enumerate(beds):
        for q in range(len(poly)):
            a, b = poly[q], poly[(q + 1) % len(poly)]
            n = max(1, int(math.dist(a, b) / 8.0))
            for t in range(n + 1):
                bgrid.add((k, q), a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n)

    def on_bed(x, z):
        for k, q in set(bgrid.near(x, z, 10.0)):
            poly = beds[k]
            if seg_dist((x, z), poly[q], poly[(q + 1) % len(poly)]) <= reach:
                return True
        return False
    paths = [pts_of(pp["p"]) for pp in out.get("paths", [])]
    pgrid = Grid(32.0)
    for k, pts in enumerate(paths):
        for x, z in pts:
            pgrid.add(k, x, z)
    def find():
        ends = []
        grid = Grid(16.0)
        for i, kb in enumerate(kerbs):
            pts = pts_of(kb["p"])
            if len(pts) < 2 or int(kb.get("dk", -1)) >= 0:
                continue
            for last in (False, True):
                p = pts[-1] if last else pts[0]
                d = unit(pts[-2], pts[-1]) if last else unit(pts[1], pts[0])
                if d is None:
                    continue
                ends.append((i, last, p, d))
                grid.add(len(ends) - 1, p[0], p[1])
        found = []
        for e, (i, last, p, d) in enumerate(ends):
            for f in grid.near(p[0], p[1], KERB_GAP):
                if f <= e:
                    continue
                j, lj, q, dq = ends[f]
                if j == i or -(dq[0] * d[0] + dq[1] * d[1]) < 0.99:
                    continue
                dx, dz = q[0] - p[0], q[1] - p[1]
                along = dx * d[0] + dz * d[1]
                side = dx * -d[1] + dz * d[0]
                if not (0.5 <= along <= KERB_GAP) or abs(side) > KERB_SIDE:
                    continue
                if not all(on_bed(p[0] + dx * t, p[1] + dz * t) for t in (0.25, 0.5, 0.75)):
                    continue
                crossed = False
                for k in set(pgrid.near((p[0] + q[0]) * 0.5, (p[1] + q[1]) * 0.5, 40.0)):
                    if any(_segs_cross(p, q, a, b) for a, b in zip(paths[k], paths[k][1:])):
                        crossed = True
                        break
                if not crossed:
                    found.append((along, i, last, j, lj))
        return found
    done = 0
    while True:
        found = find()
        if not found:
            break
        _, i, last, j, lj = min(found)
        a = pts_of(kerbs[i]["p"])
        b = pts_of(kerbs[j]["p"])
        if not last:
            a = a[::-1]   # a now ends at the gap
        if lj:
            b = b[::-1]   # b now starts at it
        kerbs[i]["p"] = flat_of(a + b)
        del kerbs[j]
        done += 1
        if done > 5000:
            break
    return done


def _segs_cross(a, b, c, d):
    def orient(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return (orient(a, b, c) > 0) != (orient(a, b, d) > 0) and (orient(c, d, a) > 0) != (orient(c, d, b) > 0)


def fit_kerbs(roads, tapers, ends, kerbs):
    """Loop 2 (F's crop on Marszałkowska by Złota): where a side's kerb runs smoothly past a
    taper (the bake walked it at a long slant, so snap_lines left it), the asphalt follows that
    kerb instead of its own smoothstep, so no wedge of road pokes past the kerb into the ballast
    or the pavement. The kerb's inset at the taper's two ends is kept (the edge meets the
    untouched road there exactly). Returns the sides fitted."""
    grid = Grid(32.0)
    segs = []
    for k in kerbs:
        pts = pts_of(k["p"])
        for a, b in zip(pts, pts[1:]):
            segs.append((a, b))
            grid.add(len(segs) - 1, (a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5)
    fitted = 0
    for t, (ia, la_, ib, lb_) in zip(tapers, ends):
        node, aa, spans, ea, eb, sides = t
        n = (-aa[1], aa[0])
        reach = max(max(sp) for sp in spans) + 4.0

        def loc(p):
            dx, dz = p[0] - node[0], p[1] - node[1]
            return dx * aa[0] + dz * aa[1], dx * n[0] + dz * n[1]
        local = []
        for q in set(grid.near(node[0], node[1], reach + 20.0)):
            a, b = loc(segs[q][0]), loc(segs[q][1])
            if min(a[0], b[0]) <= reach and max(a[0], b[0]) >= -reach and abs(a[0] - b[0]) > 1e-6:
                local.append((a, b))
        for side in (0, 1):
            ha, hb = spans[side]
            if side in sides or ha + hb <= 0.0 or abs(ea[side] - eb[side]) <= STEP_MIN:
                continue
            lo = min(ea[side], eb[side]) - EDGE_BAND
            hi = max(ea[side], eb[side]) + EDGE_BAND

            def kerb(x):
                want = taper_edge(t, side, x)
                best = None
                for a, b in local:
                    if (a[0] - x) * (b[0] - x) > 0.0:
                        continue
                    y = a[1] + (b[1] - a[1]) * (x - a[0]) / (b[0] - a[0])
                    if lo <= y <= hi and (best is None or abs(y - want) < abs(best - want)):
                        best = y
                return best
            xs = [ha - (ha + hb) * q / max(1, int(ha + hb)) for q in range(max(1, int(ha + hb)) + 1)]
            ks = [kerb(x) for x in xs]
            if any(k is None for k in ks):
                continue
            ka, kb = ks[0] - ea[side], ks[-1] - eb[side]

            def edge(x):
                f = (ha - x) / (ha + hb)
                return kerb(x) - (ka + (kb - ka) * f)
            if max(abs(edge(x) - taper_edge(t, side, x)) for x in xs) <= 0.1:
                continue
            # Each way's vertices on the taper, their edge on this side (a's frame -> the road's).
            for i, last, mirror in ((ia, la_, False), (ib, lb_, True)):
                r = roads[i]
                if "wv" not in r:
                    continue
                pts = pts_of(r["p"])
                flip = mirror != last   # the road's own right is a's frame left
                j = (1 - side) if flip else side
                sign = -1.0 if flip else 1.0
                for v, p in enumerate(pts):
                    ax, y0 = loc(p)
                    if not (-hb - 1e-6 <= ax <= ha + 1e-6) or math.dist(p, node) > reach:
                        continue
                    if (ax > 1e-6 and mirror) or (ax < -1e-6 and not mirror):
                        continue
                    k = kerb(ax)
                    if k is None:
                        continue
                    e = sign * (edge(ax) - y0)
                    c, hw = float(r["cv"][v]), float(r["wv"][v]) * 0.5
                    lft, rgt = c - hw, c + hw
                    if j == 0:
                        lft = e
                    else:
                        rgt = e
                    r["wv"][v] = round(rgt - lft, 3)
                    r["cv"][v] = round((rgt + lft) * 0.5, 3)
            fitted += 1
    return fitted


def moved_here(new, dense):
    return any(a != b for a, b in zip(new, dense))


def simplify(pts, tol):
    if len(pts) < 3:
        return pts
    keep = [False] * len(pts)
    keep[0] = keep[-1] = True
    stack = [(0, len(pts) - 1)]
    while stack:
        i, j = stack.pop()
        a, b = pts[i], pts[j]
        best, bi = -1.0, -1
        for k in range(i + 1, j):
            d = seg_dist(pts[k], a, b)
            if d > best:
                best, bi = d, k
        if best > tol:
            keep[bi] = True
            stack += [(i, bi), (bi, j)]
    return [p for p, k in zip(pts, keep) if k]


def seg_dist(p, a, b):
    abx, abz = b[0] - a[0], b[1] - a[1]
    l2 = abx * abx + abz * abz
    t = 0.0 if l2 < 1e-12 else min(max(((p[0] - a[0]) * abx + (p[1] - a[1]) * abz) / l2, 0.0), 1.0)
    return math.hypot(p[0] - a[0] - abx * t, p[1] - a[1] - abz * t)


# --- 4. stitch -----------------------------------------------------------------------------

def _line_end(m, last):
    pts = pts_of(m["p"])
    if last:
        return pts[-1], unit(pts[-2], pts[-1])
    return pts[0], unit(pts[1], pts[0])


def _kind(m):
    """A line's kind for pairing its ends: a lane line's solid approach (crossing_kit) carries on
    the dashed line it was cut from."""
    return "lane" if m["k"] == "solid" else m["k"]


def jogs(marks):
    """[(i, last_i, j, last_j, along, side)]: line ends with a start of their kind just ahead."""
    grid = Grid(16.0)
    ends = []
    for i, m in enumerate(marks):
        if _kind(m) not in LINE_KINDS or len(m["p"]) < 4:
            continue
        for last in (False, True):
            p, d = _line_end(m, last)
            if d is None:
                continue
            ends.append((i, last, p, d))
            grid.add(len(ends) - 1, p[0], p[1])
    found = []
    for e, (i, last, p, d) in enumerate(ends):
        if not last:
            continue  # pair each outgoing end (a line's last point) with an incoming one
        best = None
        for f in grid.near(p[0], p[1], STITCH_GAP + STITCH_SIDE):
            j, lj, q, dq = ends[f]
            if j == i or _kind(marks[j]) != _kind(marks[i]) or marks[j].get("dk", -1) != marks[i].get("dk", -1):
                continue
            # q's outward direction points back at p: its line carries on along d
            if -(dq[0] * d[0] + dq[1] * d[1]) < STITCH_COS:
                continue
            dx, dz = q[0] - p[0], q[1] - p[1]
            along = dx * d[0] + dz * d[1]
            side = dx * -d[1] + dz * d[0]
            if not (-STITCH_BACK <= along <= STITCH_GAP) or abs(side) > STITCH_SIDE:
                continue
            if marks[j]["k"] in ("cyclefill",) and abs(float(marks[j].get("w", 0)) - float(marks[i].get("w", 0))) > 0.3:
                continue
            key = (abs(side), abs(along))
            if best is None or key < best[0]:
                best = (key, j, lj, along, side)
        if best is not None:
            found.append((i, last, best[1], best[2], best[3], best[4]))
    return found


def stitch(marks):
    """Joins every line with the one carrying it on; returns how many joins."""
    pairs = jogs(marks)
    # one partner per end, the smallest jump first
    pairs.sort(key=lambda x: (abs(x[5]), abs(x[4])))
    taken = set()
    nxt = {}
    for i, li, j, lj, along, side in pairs:
        if (i, li) in taken or (j, lj) in taken:
            continue
        taken.add((i, li))
        taken.add((j, lj))
        nxt[i] = (j, lj)
    has_prev = {j for j, _ in nxt.values()}
    dead = set()
    joined = 0
    for i in sorted(nxt):
        if i in has_prev or i in dead:
            continue
        chain = pts_of(marks[i]["p"])
        cur = i
        seen = {i}
        while cur in nxt:
            j, lj = nxt[cur]
            if j in seen:
                break
            seen.add(j)
            q = pts_of(marks[j]["p"])
            if lj:   # its incoming end is its last point: walk it backwards
                q = q[::-1]
            chain = blend(chain, q)
            dead.add(j)
            joined += 1
            cur = j
        marks[i]["p"] = flat_of(chain)
    # lines in a loop (every one has a predecessor) stay as they are
    for j in sorted(dead, reverse=True):
        del marks[j]
    return joined


def blend(a, b):
    """a then b, with one S-curve between them (a's end to b's start), shifting both."""
    pe = a[-1]
    d = unit(a[-2], a[-1]) or (1.0, 0.0)
    n = (-d[1], d[0])
    q = b[0]
    side = (q[0] - pe[0]) * n[0] + (q[1] - pe[1]) * n[1]
    L = taper_len(abs(side))
    la, lb = length(a), length(b)
    ha = min(L * 0.5, la * 0.5)
    hb = min(L * 0.5, lb * 0.5)
    if abs(side) < 0.05 or ha + hb < 1.0:
        return a + b[1:] if math.dist(pe, q) < 0.05 else a + b
    A = resample_between(a, la - ha, la, 1.0)
    B = resample_between(b, 0.0, hb, 1.0)
    ca, cb = cumulative(A), cumulative(B)
    out = []
    for p, s in zip(A, ca):
        u = la - s
        if u < ha:
            f = smooth((ha - u) / (ha + hb))
            p = (p[0] + n[0] * side * f, p[1] + n[1] * side * f)
        out.append(p)
    for k, (p, s) in enumerate(zip(B, cb)):
        if s < hb:
            f = smooth((ha + s) / (ha + hb))
            p = (p[0] - n[0] * side * (1.0 - f), p[1] - n[1] * side * (1.0 - f))
        if k == 0 and math.dist(p, out[-1]) < 0.3:
            continue
        out.append(p)
    return simplify(out, 0.02)


# --- 5. kinks ------------------------------------------------------------------------------

def turn_deg(a, b, c):
    u, v = unit(a, b), unit(b, c)
    if u is None or v is None:
        return 0.0
    return abs(math.degrees(math.atan2(u[0] * v[1] - u[1] * v[0], u[0] * v[0] + u[1] * v[1])))


def round_line(pts):
    if len(pts) < 3:
        return pts, 0
    out = [pts[0]]
    n = 0
    for k in range(1, len(pts) - 1):
        a, b, c = out[-1], pts[k], pts[k + 1]
        ang = turn_deg(a, b, c)
        if not (ROUND_MIN <= ang <= ROUND_MAX):
            out.append(b)
            continue
        cut = min(ROUND_CUT, math.dist(a, b) * 0.45, math.dist(b, c) * 0.45)
        if cut < 0.3:
            out.append(b)
            continue
        u, v = unit(b, a), unit(b, c)
        p0 = (b[0] + u[0] * cut, b[1] + u[1] * cut)
        p1 = (b[0] + v[0] * cut, b[1] + v[1] * cut)
        m = max(2, int(math.ceil(ang / ROUND_SEG)))
        for q in range(m + 1):
            t = q / m
            x = (1 - t) * (1 - t) * p0[0] + 2 * (1 - t) * t * b[0] + t * t * p1[0]
            z = (1 - t) * (1 - t) * p0[1] + 2 * (1 - t) * t * b[1] + t * t * p1[1]
            out.append((x, z))
        n += 1
    out.append(pts[-1])
    return out, n


# --- measuring -----------------------------------------------------------------------------

def drawn_edges(r, last):
    """The drawn edges at a road's end in its away frame (with `wv`/`cv` if it has them)."""
    p = r["p"]
    if "wv" in r:
        k = len(r["wv"]) - 1 if last else 0
        c, hw = float(r["cv"][k]), float(r["wv"][k]) * 0.5
    else:
        c, hw = float(r.get("c", 0.0)), float(r["w"]) * 0.5
    if last:
        return -(c + hw), -(c - hw)
    return c - hw, c + hw


def edge_steps(roads, near=None, every=None):
    """Joins of one chain whose drawn edge still steps more than STEP_MIN m: [(node, step)]
    (not on a side where another road leaves the node: its mouth meets the step there; `every`:
    the whole road list to find those roads in, when `roads` is a part of it)."""
    ends = defaultdict(list)
    legs = defaultdict(list)   # node -> [(road, direction away)] of every road through it
    for r in (roads if every is None else every):
        p = r["p"]
        m = len(p) // 2
        for k in range(m):
            key = (round(p[2 * k], 1), round(p[2 * k + 1], 1))
            for nb in ((k - 1,) if k == m - 1 else (k + 1,) if k == 0 else (k - 1, k + 1)):
                d = unit((p[2 * k], p[2 * k + 1]), (p[2 * nb], p[2 * nb + 1]))
                if d is not None:
                    legs[key].append((id(r), d))
    for i, r in enumerate(roads):
        if r["k"] in MINOR or len(r["p"]) < 4:
            continue
        for last in (False, True):
            node, away, _, _ = _end(r, i, last)
            if away is None or (near is not None and not near(node)):
                continue
            ends[(round(node[0], 1), round(node[1], 1))].append((i, last, node, away))
    out = []
    for key, lst in ends.items():
        best = None
        for x in range(len(lst)):
            for y in range(x + 1, len(lst)):
                ia, la_, na, aa = lst[x]
                ib, lb_, nb, ab = lst[y]
                A, B = roads[ia], roads[ib]
                if ia == ib or (A.get("name") or "") != (B.get("name") or "") or bool(A.get("oneway")) != bool(B.get("oneway")):
                    continue
                if int(A.get("dk", -1)) != int(B.get("dk", -1)) or aa[0] * ab[0] + aa[1] * ab[1] > -CHAIN_COS:
                    continue
                l1, r1 = drawn_edges(A, la_)
                l2, r2 = drawn_edges(B, lb_)
                nrm = (-aa[1], aa[0])
                side = {1 if d[0] * nrm[0] + d[1] * nrm[1] > 0 else 0 for j, d in legs[key] if j not in (id(A), id(B))}
                if max(abs(l1 + r2), abs(r1 + l2)) > STEP_MAX:
                    continue   # a different road shape (a bay, a slip), as find_joins
                step = max([abs(l1 + r2)] * (0 not in side) + [abs(r1 + l2)] * (1 not in side) + [0.0])
                if best is None or step < best[1]:
                    best = (na, step)
        if best is not None and STEP_MIN < best[1] <= STEP_MAX:
            out.append(best)
    return out


def measure(d):
    return {"steps": len(edge_steps(d["roads"])),
            "jogs": len([j for j in jogs(d["markings"]) if abs(j[5]) > STEP_MIN]),
            "zlines": cut_zebras(d, dry=True),
            "edgex": seat_edges(d, dry=True)}


TRAM_BED_STEP = 1.0   # m between the samples along a track
TRAM_BED_MIN = 3.0    # m: shorter runs on a bed are left plain


def densify(pts, step):
    """The polyline with a point at least every `step` metres."""
    out = [pts[0]]
    for a, b in zip(pts, pts[1:]):
        n = max(1, int(math.ceil(math.hypot(b[0] - a[0], b[1] - a[1]) / step)))
        for q in range(1, n + 1):
            out.append((a[0] + (b[0] - a[0]) * q / n, a[1] + (b[1] - a[1]) * q / n))
    return out


def _bed_index(out):
    """The tram beds (ballast surfaces, tram medians' quads) and a 50 m grid over them."""
    polys = [pts_of(su["p"]) for su in out.get("surfaces", []) if su.get("k") == "ballast"]
    for m in out.get("medians", []):
        if m.get("k") == "grass":
            continue
        s4 = m["s"]
        for i in range(0, len(s4) - 7, 4):
            polys.append([(s4[i], s4[i + 1]), (s4[i + 2], s4[i + 3]), (s4[i + 6], s4[i + 7]), (s4[i + 4], s4[i + 5])])
    cells = {}
    for k, poly in enumerate(polys):
        xs = [p[0] for p in poly]
        zs = [p[1] for p in poly]
        for cx in range(int(math.floor(min(xs) / 50)), int(math.floor(max(xs) / 50)) + 1):
            for cz in range(int(math.floor(min(zs) / 50)), int(math.floor(max(zs) / 50)) + 1):
                cells.setdefault((cx, cz), []).append(k)

    def on_bed(x, z):
        return any(_poly_hit(polys[k], x, z) for k in cells.get((int(math.floor(x / 50)), int(math.floor(z / 50))), ()))
    return on_bed


def _runs_on(pts, on_bed, step):
    """[from, to] metres along a polyline where it lies on a tram bed."""
    runs = []
    start = None
    s = 0.0
    for i in range(len(pts) - 1):
        (ax, az), (bx, bz) = pts[i], pts[i + 1]
        seg = math.hypot(bx - ax, bz - az)
        n = max(1, int(math.ceil(seg / step)))
        for j in range(n):
            f = (j + 0.5) / n
            here = on_bed(ax + (bx - ax) * f, az + (bz - az) * f)
            at = s + seg * j / n
            if here and start is None:
                start = at
            elif not here and start is not None:
                runs.append([start, at])
                start = None
        s += seg
    if start is not None:
        runs.append([start, s])
    return runs


def _cut(pts, s0, s1):
    """The part of a polyline from s0 to s1 metres along it."""
    out = []
    s = 0.0
    for i in range(len(pts) - 1):
        (ax, az), (bx, bz) = pts[i], pts[i + 1]
        seg = math.hypot(bx - ax, bz - az)
        if seg > 0 and s + seg >= s0 and s <= s1:
            f0 = min(max((s0 - s) / seg, 0.0), 1.0)
            f1 = min(max((s1 - s) / seg, 0.0), 1.0)
            if not out:
                out.append((ax + (bx - ax) * f0, az + (bz - az) * f0))
            out.append((ax + (bx - ax) * f1, az + (bz - az) * f1))
        s += seg
    return out


def tram_beds(out, on_bed):
    """Loop 7 (F's ChatGPT target, 2026-11-05): where a tram track runs on its own bed (a tram
    median or a ballast surface), mark the run (`trams[].bed`, [from, to] metres along it) so
    map_builder lays sleepers under the rails there; in the street's asphalt the rails stay bare."""
    marked = 0
    for t in out.get("trams", []):
        runs = [[round(a, 2), round(b, 2)] for a, b in _runs_on(pts_of(t["p"]), on_bed, TRAM_BED_STEP)
                if b - a >= TRAM_BED_MIN]
        t.pop("bed", None)
        if runs:
            t["bed"] = runs
            marked += 1
    return marked


UTURN_W = 6.0     # m: a U-turn link through a tram median, wide enough for the car's turning path
XING_MAX = 30.0   # m: a longer run on a bed runs along it, not across
XING_PAD = 0.4    # m the crossing's paving reaches past the bed's edge
XING_MIN = 3.0    # m: a shorter run only grazes the bed's edge
XING_COS = 0.82   # a run within ~35 degrees of the tracks runs along them
ZEBRA_LINK = 16.0  # m: the farthest a zebra's end is joined to the next across a tram bed
WALK_W = 4.0      # m: a footway's crossing of a tram bed (as wide as a zebra)


METRO_STEP_REACH = 2.5   # m from a flight's end to a metro entrance's point


def metro_steps(out):
    """Loop 7 (F's ChatGPT target): a flight of steps that ends at a metro entrance goes down
    into it; `steps[].down` names its deep end (0 first point, 1 last), so map_builder darkens
    the treads towards it. Returns the count."""
    mouths = [(p["x"], p["z"]) for p in out.get("pois", []) if p.get("k") == "subway_entrance"]
    n = 0
    for st in out.get("steps", []):
        st.pop("down", None)
        p = pts_of(st["p"])
        if len(p) != 2:
            continue
        for mx, mz in mouths:
            if math.hypot(p[1][0] - mx, p[1][1] - mz) < METRO_STEP_REACH:
                st["down"] = 1
            elif math.hypot(p[0][0] - mx, p[0][1] - mz) < METRO_STEP_REACH:
                st["down"] = 0
        n += "down" in st
    return n


def _near_mid(x, mid, reach=2.5):
    p = pts_of(x["p"])
    return any(math.hypot(q[0] - mid[0], q[1] - mid[1]) < reach for q in densify(p, 1.0))


def tram_crossings(out, on_bed):
    """Loop 7 (F's ChatGPT target): a road or a footway that crosses a tram bed was drawn under
    it (the bed lies over the roads), so only its edge lines and kerbs showed, curving across the
    tracks. Each such crossing becomes a band of concrete track panels over the bed
    (`tram_xings`, drawn under the rails and over the sleepers), and the lines and kerbs inside
    it go. Returns (crossings, line points dropped)."""
    tsegs = {}
    for t in out.get("trams", []):
        tp = pts_of(t["p"])
        for a, b in zip(tp, tp[1:]):
            key = (int(math.floor((a[0] + b[0]) / 100)), int(math.floor((a[1] + b[1]) / 100)))
            tsegs.setdefault(key, []).append((a, b))

    def across(pts):
        """Whether a run crosses the tracks (XING_COS off their line), not grazes along them."""
        (ax, az), (bx, bz) = pts[0], pts[-1]
        l = math.hypot(bx - ax, bz - az)
        if l < XING_MIN:
            return False
        mx, mz = (ax + bx) / 2, (az + bz) / 2
        best, cos = 1e9, 1.0
        cx, cz = int(math.floor(mx / 50)), int(math.floor(mz / 50))
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for (px, pz), (qx, qz) in tsegs.get((cx + i, cz + j), ()):
                    dx, dz = qx - px, qz - pz
                    l2 = dx * dx + dz * dz or 1e-9
                    t = min(max(((mx - px) * dx + (mz - pz) * dz) / l2, 0.0), 1.0)
                    dd = math.hypot(mx - px - dx * t, mz - pz - dz * t)
                    if dd < best:
                        best = dd
                        cos = abs(((bx - ax) * dx + (bz - az) * dz) / (l * math.sqrt(l2)))
        return best < 8.0 and cos < XING_COS

    xings = []
    for r in out["roads"]:
        if r.get("dk", -1) not in (-1, None) and int(r.get("dk", -1)) >= 0:
            continue
        pts = pts_of(r["p"])
        w = max(r.get("wv", [r["w"]]))
        for a, b in _runs_on(pts, on_bed, 0.5):
            run = _cut(pts, max(a - XING_PAD, 0.0), b + XING_PAD)
            if b - a <= XING_MAX and across(run):
                if r["k"].endswith("_link") and r.get("oneway"):
                    # F (round 4): a U-turn's opening through the median, wide enough for the
                    # car's turning path (the link's own asphalt stays as mapped)
                    w = max(w, UTURN_W)
                xings.append({"p": flat_of(run), "w": round(w + 0.4, 2), "k": "road"})
    for pa in out.get("paths", []):
        if pa["k"] != "foot":
            continue
        pts = pts_of(pa["p"])
        for a, b in _runs_on(pts, on_bed, 0.5):
            run = _cut(pts, max(a - XING_PAD, 0.0), b + XING_PAD)
            if b - a <= XING_MAX and across(run):
                xings.append({"p": flat_of(run), "w": WALK_W, "k": "walk"})
    # A zebra stops at the carriageway's edge; where the walk goes on across a tram bed to the
    # next zebra (in line, or staggered along the street), a band of paving joins their ends.
    zebras = [pts_of(pa["p"]) for pa in out.get("paths", []) if pa["k"] == "zebra" and len(pa["p"]) >= 4]
    ends = []
    for zi, zp in enumerate(zebras):
        for e, f in ((zp[0], zp[1]), (zp[-1], zp[-2])):
            ends.append((zi, e, f))
    egrid = defaultdict(list)
    for k, (zi, e, f) in enumerate(ends):
        egrid[(int(e[0] // 20), int(e[1] // 20))].append(k)
    paired = set()
    for k, (zi, e, f) in enumerate(ends):
        l = math.dist(e, f)
        if l < 0.5:
            continue
        ux, uz = (e[0] - f[0]) / l, (e[1] - f[1]) / l
        if not on_bed(e[0] + ux * 1.0, e[1] + uz * 1.0):
            continue   # this end does not face a tram bed
        best = None
        cx, cz = int(e[0] // 20), int(e[1] // 20)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for k2 in egrid.get((cx + i, cz + j), ()):
                    zj, e2, f2 = ends[k2]
                    if zj == zi:
                        continue
                    dd = math.dist(e, e2)
                    if not (1.5 < dd <= ZEBRA_LINK):
                        continue
                    # the other end faces back across the bed, and the walk between lies on it
                    l2 = math.dist(e2, f2)
                    if l2 < 0.5 or ((e2[0] - f2[0]) * ux + (e2[1] - f2[1]) * uz) / l2 > -0.5:
                        continue
                    mid = ((e[0] + e2[0]) / 2, (e[1] + e2[1]) / 2)
                    if not on_bed(*mid):
                        continue
                    if best is None or dd < best[0]:
                        best = (dd, k2, e2)
        if best is None or (min(k, best[1]), max(k, best[1])) in paired:
            continue
        paired.add((min(k, best[1]), max(k, best[1])))
        e2 = best[2]
        dx, dz = e2[0] - e[0], e2[1] - e[1]
        dl = math.hypot(dx, dz)
        run = [(e[0] - dx / dl * XING_PAD, e[1] - dz / dl * XING_PAD), (e2[0] + dx / dl * XING_PAD, e2[1] + dz / dl * XING_PAD)]
        mid = ((e[0] + e2[0]) / 2, (e[1] + e2[1]) / 2)
        if any(x["k"] == "walk" and _near_mid(x, mid) for x in xings):
            continue
        xings.append({"p": flat_of(run), "w": WALK_W, "k": "walk"})
    xings = [x for x in xings if len(x["p"]) >= 4]
    out["tram_xings"] = xings
    segs = []
    for x in xings:
        p = pts_of(x["p"])
        for i in range(len(p) - 1):
            segs.append((p[i], p[i + 1], x["w"] * 0.5 + 0.3))

    def in_xing(x, z):
        if not on_bed(x, z):
            return False
        for (ax, az), (bx, bz), hw in segs:
            if abs(x - ax) > hw + 40 and abs(x - bx) > hw + 40:
                continue
            dx, dz = bx - ax, bz - az
            l2 = dx * dx + dz * dz or 1e-9
            t = min(max(((x - ax) * dx + (z - az) * dz) / l2, 0.0), 1.0)
            if math.hypot(x - ax - dx * t, z - az - dz * t) <= hw:
                return True
        return False

    dropped = 0

    def split(lines):
        nonlocal dropped
        keep = []
        for line in lines:
            pts = pts_of(line["p"])
            dense = densify(pts, 0.5)
            flags = [in_xing(x, z) for x, z in dense]
            if not any(flags):
                keep.append(line)
                continue
            dropped += sum(flags)
            cur = []
            for q, f in zip(dense, flags):
                if f:
                    if len(cur) >= 2:
                        keep.append(dict(line, p=flat_of(simplify(cur, 0.02))))
                    cur = []
                else:
                    cur.append(q)
            if len(cur) >= 2:
                keep.append(dict(line, p=flat_of(simplify(cur, 0.02))))
        return keep

    out["kerbs"] = split(out.get("kerbs", []))
    lines = [m for m in out["markings"] if m["k"] in ("edge", "lane", "centre", "stripe")]
    other = [m for m in out["markings"] if m["k"] not in ("edge", "lane", "centre", "stripe")]
    out["markings"] = other + split(lines)
    return len(xings), dropped

POCKET_CELL = 0.5     # m: the grid a junction's asphalt is sampled on
POCKET_WIN = 20.0     # m: half the window round a junction
POCKET_MAX = 40.0     # m2: a bigger bare patch is a real place (a pavement corner, a lawn)
POCKET_MIN = 0.75     # m2: smaller is lost in the kerbs' and discs' own overlap


def _hull(pts):
    pts = sorted(set(pts))
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, hi = [], []
    for q in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], q) <= 0:
            lo.pop()
        lo.append(q)
    for q in reversed(pts):
        while len(hi) >= 2 and cross(hi[-2], hi[-1], q) <= 0:
            hi.pop()
        hi.append(q)
    return lo[:-1] + hi[:-1]


def _asphalt_sampler(out):
    """Two tests on the finished data: whether a point lies on asphalt (a road band, its `wv`/`cv`
    widths, or a carriageway area) and whether it lies in a mapped area, island or building."""
    roads = out["roads"]
    segs = defaultdict(list)
    for r in roads:
        if int(r.get("dk", -1)) >= 0:
            continue
        pts = pts_of(r["p"])
        n = len(pts)
        wv = r.get("wv")
        cv = r.get("cv")
        hide = r.get("hide", [])
        s_at = 0.0
        for i in range(n - 1):
            w = min(wv[i], wv[i + 1]) if wv else r["w"]
            c = (cv[i] + cv[i + 1]) / 2 if cv else r.get("c", 0.0)
            (ax, az), (bx, bz) = pts[i], pts[i + 1]
            l = math.hypot(bx - ax, bz - az)
            s0, s_at = s_at, s_at + l
            if l < 1e-6:
                continue
            # a stretch under a carriageway area is not drawn (the area has the exact shape)
            if any(h0 <= s0 and s_at <= h1 for h0, h1 in hide):
                continue
            nx, nz = -(bz - az) / l, (bx - ax) / l
            a2 = (ax + nx * c, az + nz * c)
            b2 = (bx + nx * c, bz + nz * c)
            for cx in range(int(math.floor(min(a2[0], b2[0]) / 20)) - 1, int(math.floor(max(a2[0], b2[0]) / 20)) + 2):
                for cz in range(int(math.floor(min(a2[1], b2[1]) / 20)) - 1, int(math.floor(max(a2[1], b2[1]) / 20)) + 2):
                    segs[(cx, cz)].append((a2, b2, w / 2))
    polys = defaultdict(list)
    for c in out.get("carriage", []):
        if c.get("k") in ("emergency", "prohibited") or int(c.get("dk", -1)) >= 0:
            continue   # a hatched area is paint, not a lane (check_streets HATCH)
        q = pts_of(c["p"])
        xs = [a[0] for a in q]
        zs = [a[1] for a in q]
        for cx in range(int(math.floor(min(xs) / 20)), int(math.floor(max(xs) / 20)) + 1):
            for cz in range(int(math.floor(min(zs) / 20)), int(math.floor(max(zs) / 20)) + 1):
                polys[(cx, cz)].append(q)
    blocks = defaultdict(list)
    # (a park or plaza outline wraps its paved corners too: only what is drawn as its own patch)
    for a in [a for a in out.get("areas", []) if a.get("k") not in ("park", "plaza")] + out.get("islands", []) + out.get("buildings", []):
        q = pts_of(a["p"])
        if len(q) < 3:
            continue
        xs = [p[0] for p in q]
        zs = [p[1] for p in q]
        for cx in range(int(math.floor(min(xs) / 20)), int(math.floor(max(xs) / 20)) + 1):
            for cz in range(int(math.floor(min(zs) / 20)), int(math.floor(max(zs) / 20)) + 1):
                blocks[(cx, cz)].append(q)

    def asphalt(x, z):
        key = (int(math.floor(x / 20)), int(math.floor(z / 20)))
        for (ax, az), (bx, bz), hw in segs.get(key, ()):
            dx, dz = bx - ax, bz - az
            l2 = dx * dx + dz * dz
            t = min(max(((x - ax) * dx + (z - az) * dz) / l2, 0.0), 1.0)
            if (x - ax - dx * t) ** 2 + (z - az - dz * t) ** 2 <= hw * hw:
                return True
        return any(_poly_hit(q, x, z) for q in polys.get(key, ()))

    def blocked(x, z):
        key = (int(math.floor(x / 20)), int(math.floor(z / 20)))
        return any(_poly_hit(q, x, z) for q in blocks.get(key, ()))

    return asphalt, blocked


def fill_pockets(out):
    """Round 3 (F, 2026-11-05: "remove wedges and patches ... one clean asphalt surface"): where
    a driveway or side road leaves a street, two branches and the street's edge can close a small
    triangle of bare pavement between them (the pale wedge by the PKiN driveway). Round every node
    where a minor road meets a street, the asphalt is sampled on a POCKET_CELL grid; a patch of
    bare ground walled in by asphalt on every side, POCKET_MIN..POCKET_MAX m2 and in no mapped
    area (lawn, island, plaza), is filled with asphalt (`asphalt_fills`). Returns the count."""
    roads = out["roads"]
    asphalt, blocked = _asphalt_sampler(out)

    nodes = defaultdict(set)
    for r in roads:
        if int(r.get("dk", -1)) >= 0:
            continue
        p = r["p"]
        for k in range(0, len(p) - 1, 2):
            nodes[(round(p[k], 1), round(p[k + 1], 1))].add(r["k"] in MINOR)
    centres = [n for n, kinds in nodes.items() if kinds == {True, False}]
    done = set()
    fills = []
    n_cells = int(2 * POCKET_WIN / POCKET_CELL)
    for (ox, oz) in centres:
        x0, z0 = ox - POCKET_WIN, oz - POCKET_WIN
        grid = [[asphalt(x0 + (i + 0.5) * POCKET_CELL, z0 + (j + 0.5) * POCKET_CELL) for j in range(n_cells)]
                for i in range(n_cells)]
        seen = [[False] * n_cells for _ in range(n_cells)]
        for i in range(n_cells):
            for j in range(n_cells):
                if grid[i][j] or seen[i][j]:
                    continue
                comp, stack, edge = [], [(i, j)], False
                seen[i][j] = True
                while stack:
                    a, b = stack.pop()
                    comp.append((a, b))
                    if a in (0, n_cells - 1) or b in (0, n_cells - 1) or len(comp) * POCKET_CELL ** 2 > POCKET_MAX:
                        edge = True
                    for da, db in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                        u, v = a + da, b + db
                        if 0 <= u < n_cells and 0 <= v < n_cells and not grid[u][v] and not seen[u][v]:
                            seen[u][v] = True
                            stack.append((u, v))
                area = len(comp) * POCKET_CELL ** 2
                if edge or area < POCKET_MIN:
                    continue
                cells = [(round(x0 + (a + 0.5) * POCKET_CELL, 1), round(z0 + (b + 0.5) * POCKET_CELL, 1)) for a, b in comp]
                if any(blocked(x, z) for x, z in cells[:: max(1, len(cells) // 12)]):
                    continue
                key = min(cells)
                if key in done:
                    continue
                done.add(key)
                h = POCKET_CELL * 0.75
                ring = [(x + dx, z + dz) for x, z in cells for dx in (-h, h) for dz in (-h, h)]
                fills.append({"p": flat_of(_hull(ring))})
    out["asphalt_fills"] = fills
    # The kerbs that ran round a filled pocket go with it.
    hulls = [pts_of(f["p"]) for f in fills]
    boxes = [(min(p[0] for p in h) - 0.5, max(p[0] for p in h) + 0.5, min(p[1] for p in h) - 0.5, max(p[1] for p in h) + 0.5) for h in hulls]

    def in_fill(x, z):
        return any(b[0] <= x <= b[1] and b[2] <= z <= b[3] and _poly_hit(h, x, z) for h, b in zip(hulls, boxes))
    # (their edge lines stay: round the new asphalt they read as a painted island's outline)
    out["kerbs"] = _drop_inside(out.get("kerbs", []), in_fill)
    return len(fills)


ZEBRA_REACH = 8.0   # m a zebra may run on to reach the far kerb


def _in_map(out, x, z, margin=2.0):
    """Inside the map (centrum.json `bounds` less its `outside` corner notches), margin m in."""
    x0, z0, x1, z1 = out.get("bounds", (-1e9, -1e9, 1e9, 1e9))
    if not (x0 + margin <= x <= x1 - margin and z0 + margin <= z <= z1 - margin):
        return False
    return not any(o[0] - margin <= x <= o[2] + margin and o[1] - margin <= z <= o[3] + margin
                   for o in out.get("outside", []))


def extend_zebras(out, asphalt, blocked):
    """Round 3 (F: "your zebras cover only part of each carriageway"): a zebra was cut to the
    way's width in the bake; where the street has since been widened to its kerbs, the zebra stops
    short. Each end runs on along its line while the asphalt does (to 0.3 m short of the edge).
    Returns the metres added."""
    added = 0.0
    for pa in out.get("paths", []):
        if pa["k"] != "zebra":
            continue
        pts = pts_of(pa["p"])
        if len(pts) < 2:
            continue
        for end, prev in ((len(pts) - 1, len(pts) - 2), (0, 1)):
            (bx, bz), (ax, az) = pts[end], pts[prev]
            l = math.hypot(bx - ax, bz - az)
            if l < 0.5:
                continue
            ux, uz = (bx - ax) / l, (bz - az) / l
            t = 0.0
            while t < ZEBRA_REACH and asphalt(bx + ux * (t + 0.55), bz + uz * (t + 0.55)) \
                    and not blocked(bx + ux * (t + 0.55), bz + uz * (t + 0.55)):
                t += 0.25
            nx_, nz_ = bx + ux * t, bz + uz * t
            if t >= 0.5 and _in_map(out, nx_, nz_):
                pts[end] = (nx_, nz_)
                added += t
        # an end left off the asphalt (moved beside a cycle crossing where the street narrows)
        # comes back to it, at most 3 m
        for end, nxt in ((len(pts) - 1, len(pts) - 2), (0, 1)):
            (bx, bz), (ax, az) = pts[end], pts[nxt]
            l = math.hypot(bx - ax, bz - az)
            if l < 1.0:
                continue
            ux, uz = (ax - bx) / l, (az - bz) / l
            t = 0.0
            while t < min(3.0, l - 0.5) and not (asphalt(bx + ux * t, bz + uz * t) and not blocked(bx + ux * t, bz + uz * t)):
                t += 0.25
            if t > 0.0:
                pts[end] = (bx + ux * (t + 0.15), bz + uz * (t + 0.15))
        pa["p"] = flat_of(pts)
    return round(added)


def _drop_inside(lines, test):
    """The lines with their points where test(x, z) holds cut out (split into pieces)."""
    keep = []
    for line in lines:
        pts = pts_of(line["p"])
        if len(pts) < 2:
            keep.append(line)
            continue
        dense = densify(pts, 0.5)
        flags = [test(x, z) for x, z in dense]
        if not any(flags):
            keep.append(line)
            continue
        cur = []
        for q, f in zip(dense, flags):
            if f:
                if len(cur) >= 2:
                    keep.append(dict(line, p=flat_of(simplify(cur, 0.02))))
                cur = []
            else:
                cur.append(q)
        if len(cur) >= 2:
            keep.append(dict(line, p=flat_of(simplify(cur, 0.02))))
    return keep


KIT_ROADS = {"primary", "secondary", "tertiary", "primary_link", "secondary_link", "trunk"}
KIT_LANES = 2         # lanes one way (or a one-way street's) from which a crossing has lights
KIT_SIGNAL_NEAR = 30.0  # m: a mapped signal this near means the crossing has its own
KIT_STOP_GAP = 1.0    # m between a stop line and the first band painted across (zebra, cycle crossing)
KIT_ARROW = 9.0       # m before the stop line to the lane arrows' middle
KIT_SOLID = 18.0      # m of solid lane line before a stop line (P-2b)
KIT_AHEAD = 35.0      # m past a crossing searched for the junction its lanes turn at
KIT_TURN_COS = 0.8    # a way leaving within this cosine of straight on is straight on
KIT_UTURN_GAP = 6.0   # m before a U-turn link's mouth to its arrows (not in the mouth)


def _seg_x(a, b, c, d):
    """Where segments ab and cd cross: (t along ab, u along cd), or None."""
    rx, rz = b[0] - a[0], b[1] - a[1]
    sx, sz = d[0] - c[0], d[1] - c[1]
    den = rx * sz - rz * sx
    if abs(den) < 1e-9:
        return None
    t = ((c[0] - a[0]) * sz - (c[1] - a[1]) * sx) / den
    u = ((c[0] - a[0]) * rz - (c[1] - a[1]) * rx) / den
    if 0 <= t <= 1 and 0 <= u <= 1:
        return t, u
    return None


def crossing_kit(out, asphalt):
    """Round 3 (F's priorities 4 and 6): a zebra across a main street of KIT_LANES+ lanes each way
    with no mapped signal near is a signal-controlled crossing in central Warsaw: it gets a stop
    line KIT_STOP_GAP m before it and any cycle crossing beside it on each approach, straight-on
    arrows in its lanes KIT_ARROW m before that, the lane lines solid for KIT_SOLID m before
    that, and a signal pole at the kerb by each stop line (appended to `signals` after the mapped
    ones, so the traffic's lamp groups, which pair with the mapped poles by index, are untouched:
    these are poles without a controller). Returns (crossings, stop lines, poles)."""
    sig = out.get("signals", [])
    mapped = [(sig[i], sig[i + 1]) for i in range(0, len(sig) - 2, 3)]
    sgrid = defaultdict(list)
    for x, z in mapped:
        sgrid[(int(x // 50), int(z // 50))].append((x, z))
    stops = [pts_of(m["p"]) for m in out["markings"] if m["k"] == "stop"]
    stgrid = defaultdict(list)
    for p in stops:
        stgrid[(int(p[0][0] // 50), int(p[0][1] // 50))].append(p[0])

    def near(grid, x, z, r):
        cx, cz = int(x // 50), int(z // 50)
        return any(math.hypot(q[0] - x, q[1] - z) < r for i in (-1, 0, 1) for j in (-1, 0, 1)
                   for q in grid.get((cx + i, cz + j), ()))

    rgrid = defaultdict(list)
    for k, r in enumerate(out["roads"]):
        if r["k"] not in KIT_ROADS or int(r.get("dk", -1)) >= 0:
            continue
        p = pts_of(r["p"])
        for i in range(len(p) - 1):
            rgrid[(int(p[i][0] // 50), int(p[i][1] // 50))].append((k, i))
    new_stops, poles, crossings, arrows = [], [], 0, []
    cgrid = defaultdict(list)
    for pa in out.get("paths", []):
        if pa["k"] == "cyclecross" and int(pa.get("dk", -1)) < 0:
            q = pts_of(pa["p"])
            if len(q) >= 2:
                cgrid[(int(q[0][0] // 30), int(q[0][1] // 30))].append((q[0], q[-1]))

    def cycles_near(x, z):
        cx_, cz_ = int(x // 30), int(z // 30)
        return [c for i in (-1, 0, 1) for j in (-1, 0, 1) for c in cgrid.get((cx_ + i, cz_ + j), ())
                if math.dist(((c[0][0] + c[1][0]) / 2, (c[0][1] + c[1][1]) / 2), (x, z)) < 20.0]
    # Round 4 (F): arrows from where each lane actually leads. The ways leaving each node, as
    # (road, direction away); a one-way street only away from its start.
    leave = defaultdict(list)
    for k, r in enumerate(out["roads"]):
        if r["k"] in MINOR or int(r.get("dk", -1)) >= 0:
            continue
        p = pts_of(r["p"])
        for i, q in enumerate(p):
            key = (round(q[0], 1), round(q[1], 1))
            if i + 1 < len(p):
                leave[key].append((k, p[i + 1]))
            if i > 0 and not r.get("oneway"):
                leave[key].append((k, p[i - 1]))

    def u_link(k2, tx, tz):
        """Whether road k2 is a one-way link that ends heading back against (tx, tz): a U-turn
        through a median."""
        r2 = out["roads"][k2]
        if not (r2["k"].endswith("_link") and r2.get("oneway")):
            return False
        q = pts_of(r2["p"])
        dx, dz = q[-1][0] - q[-2][0], q[-1][1] - q[-2][1]
        return (dx * tx + dz * tz) / (math.hypot(dx, dz) or 1e-9) < -0.5

    def moves(k, p, v, f, sgn):
        """The moves ('L', 'T', 'R') open at the junction within KIT_AHEAD m past (v, f) on road k
        travelled sgn, and the distance back from (v, f) to a U-turn link's mouth before it, if any."""
        ux, uz = p[v + 1][0] - p[v][0], p[v + 1][1] - p[v][1]
        l = math.hypot(ux, uz) or 1e-9
        tx, tz = ux / l * sgn, uz / l * sgn
        here = (p[v][0] + ux * f, p[v][1] + uz * f)
        order = range(v + 1, len(p)) if sgn > 0 else range(v, -1, -1)
        found, run, prev = set(), 0.0, here
        for i in order:
            run += math.dist(prev, p[i])
            prev = p[i]
            if run > KIT_AHEAD:
                break
            for k2, nb in leave.get((round(p[i][0], 1), round(p[i][1], 1)), ()):
                if k2 == k:
                    continue
                dx, dz = nb[0] - p[i][0], nb[1] - p[i][1]
                dl = math.hypot(dx, dz) or 1e-9
                cos = (dx * tx + dz * tz) / dl
                if cos > KIT_TURN_COS:
                    found.add("T")
                elif cos > -0.9:
                    found.add("R" if (dx * -tz + dz * tx) / dl > 0 else "L")
            nxt = i + 1 if sgn > 0 else i - 1
            if 0 <= nxt < len(p):
                found.add("T")   # the way itself goes on
            if "L" in found or "R" in found:
                break
        # a U-turn link leaving up to KIT_ARROW + 14 m before here
        back = None
        order = range(v, -1, -1) if sgn > 0 else range(v + 1, len(p))
        run, prev = 0.0, here
        for i in order:
            run += math.dist(prev, p[i])
            prev = p[i]
            if run > KIT_ARROW + 14.0:
                break
            if any(u_link(k2, tx, tz) for k2, _ in leave.get((round(p[i][0], 1), round(p[i][1], 1)), ()) if k2 != k):
                back = run
                break
        return found or {"T"}, back

    SHAPES = {frozenset("T"): "T", frozenset("L"): "L", frozenset("R"): "R", frozenset("LT"): "LT",
              frozenset("TR"): "TR", frozenset("LR"): "LR", frozenset("LTR"): "LTR"}

    solid_cuts = []   # (x, z, ux, uz, half width): stretches of lane line to make solid
    for pa in out.get("paths", []):
        if pa["k"] != "zebra" or int(pa.get("dk", -1)) >= 0:
            continue
        zp = pts_of(pa["p"])
        if len(zp) < 2:
            continue
        za, zb = zp[0], zp[-1]
        mx, mz = (za[0] + zb[0]) / 2, (za[1] + zb[1]) / 2
        if near(sgrid, mx, mz, KIT_SIGNAL_NEAR) or near(stgrid, mx, mz, 15.0):
            continue
        cx, cz = int(mx // 50), int(mz // 50)
        hits = set()
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for k, v in rgrid.get((cx + i, cz + j), ()):
                    hits.add((k, v))
        done_here = False
        for k, v in sorted(hits):
            r = out["roads"][k]
            p = pts_of(r["p"])
            x = _seg_x(p[v], p[v + 1], za, zb)
            if not x:
                continue
            lanes = int(r.get("lanes", 1))
            oneway = bool(r.get("oneway"))
            if (lanes if oneway else lanes // 2) < KIT_LANES:
                continue
            (ax, az), (bx, bz) = p[v], p[v + 1]
            l = math.hypot(bx - ax, bz - az)
            ux, uz = (bx - ax) / l, (bz - az) / l
            nx, nz = -uz, ux   # + is right of travel
            w = (r["wv"][v] + r["wv"][v + 1]) / 2 if "wv" in r else r["w"]
            c = (r["cv"][v] + r["cv"][v + 1]) / 2 if "cv" in r else r.get("c", 0.0)
            ox, oz = ax + ux * l * x[0], az + uz * l * x[0]
            # the approaches: (direction along the way, from offset, to offset)
            ways = [(1, c - w / 2 + 0.3, c + w / 2 - 0.3)] if oneway else [(1, c, c + w / 2 - 0.3), (-1, c - w / 2 + 0.3, c)]
            for sgn, o0, o1 in ways:
                # before every band painted across here (the zebra, a cycle crossing beside it),
                # in the direction of travel
                back = ZEBRA_HALF
                for (ca, cb) in cycles_near(mx, mz):
                    cmx, cmz = (ca[0] + cb[0]) / 2, (ca[1] + cb[1]) / 2
                    cl = math.dist(ca, cb)
                    if cl < 0.5 or abs(((cb[0] - ca[0]) * nx + (cb[1] - ca[1]) * nz) / cl) < 0.9:
                        continue   # not across this way
                    up = -((cmx - ox) * ux + (cmz - oz) * uz) * sgn
                    if 0.0 < up < 8.0:
                        back = max(back, up + CYCLE_HALF)
                back += KIT_STOP_GAP
                bxp, bzp = ox - ux * sgn * back, oz - uz * sgn * back
                a = (bxp + nx * o0, bzp + nz * o0)
                b = (bxp + nx * o1, bzp + nz * o1)
                new_stops.append({"k": "stop", "p": flat_of([a, b])})
                # an arrow in each lane, KIT_ARROW m before the stop line, for where it leads at
                # the junction past the crossing: the leftmost lane takes the left turn, the
                # rightmost the right one, the rest go straight on; before a U-turn link's mouth
                # (round 4) the arrows stand clear of it and the leftmost lane shows the U-turn too
                n_l = max(1, lanes if oneway else lanes // 2)
                open_, u_back = moves(k, p, v, x[0], sgn)
                ahead = KIT_ARROW
                # (a mouth up to KIT_UTURN_GAP m upstream of where the arrows would stand counts)
                at_u = u_back is not None and u_back < KIT_ARROW + back + KIT_UTURN_GAP
                if at_u:
                    ahead = u_back - back + KIT_UTURN_GAP
                ax_, az_ = bxp - ux * sgn * ahead, bzp - uz * sgn * ahead
                for li in range(n_l):
                    lo = o0 + (li + 0.5) * (o1 - o0) / n_l
                    mv = {"T"} & open_ or set()
                    if li == 0 and "L" in open_:
                        mv.add("L")
                    if li == n_l - 1 and "R" in open_:
                        mv.add("R")
                    if not mv:
                        mv = set(open_) if n_l == 1 else {"L"} if li == 0 and "L" in open_ else {"R"} if "R" in open_ else {"L"}
                    t = SHAPES.get(frozenset(mv), "T")
                    if at_u and li == 0:
                        t = "TU" if "T" in mv and len(mv) == 1 else "U" if mv == {"L"} else t
                    arrows.append({"k": "arrow", "t": t, "x": round(ax_ + nx * lo, 2), "z": round(az_ + nz * lo, 2),
                                   "d": [round(ux * sgn, 3), round(uz * sgn, 3)]})
                # the pole on the kerb past the stop line's right end (as the driver sees it)
                for out_by in (1.0, 1.6, 2.2):
                    kerb = o1 + out_by if sgn > 0 else o0 - out_by
                    px, pz = bxp + nx * kerb, bzp + nz * kerb
                    if not asphalt(px, pz):
                        yaw = math.atan2(-ux * sgn, -uz * sgn)
                        poles += [round(px, 2), round(pz, 2), round(yaw, 3)]
                        break
                solid_cuts.append((bxp, bzp, ux * sgn, uz * sgn, abs(o1 - o0) / 2 + 0.5, (o0 + o1) / 2, nx, nz))
            done_here = True
        crossings += done_here
    out["markings"] += new_stops
    out.setdefault("symbols", []).extend(arrows)
    out.setdefault("signals", [])
    out["signals"] = list(out["signals"]) + poles

    # Lane lines solid on the approach: the part of a lane line within KIT_SOLID m before a stop
    # line, across its lanes, becomes kind "solid" (map_builder draws unknown kinds solid).
    def on_approach(x, z):
        for bxp, bzp, ux, uz, half, mid, nx, nz in solid_cuts:
            dx, dz = x - bxp, z - bzp
            back = -(dx * ux + dz * uz)
            side = dx * nx + dz * nz - mid
            if 0.0 <= back <= KIT_SOLID and abs(side) <= half:
                return True
        return False
    lanes = [m for m in out["markings"] if m["k"] == "lane"]
    rest = [m for m in out["markings"] if m["k"] != "lane"]
    pieces = []
    for m in lanes:
        pts = pts_of(m["p"])
        if not any(on_approach(x, z) for x, z in densify(pts, 2.0)):
            pieces.append(m)
            continue
        dense = densify(pts, 0.5)
        cur, kind = [], None
        for q in dense:
            kq = "solid" if on_approach(*q) else "lane"
            if kind is not None and kq != kind:
                cur.append(q)
                if len(cur) >= 2:
                    pieces.append(dict(m, k=kind, p=flat_of(simplify(cur, 0.02))))
                cur = [q]
            else:
                cur.append(q)
            kind = kq
        if len(cur) >= 2:
            pieces.append(dict(m, k=kind, p=flat_of(simplify(cur, 0.02))))
    out["markings"] = rest + pieces
    return crossings, len(new_stops), len(poles) // 3


PAINT_ISLAND_MAX = 12.0   # m2: a kerbed island this small by a driveway becomes paint
PAINT_MINOR_NEAR = 6.0    # m from its middle to a driveway or service road
HATCH_GAP = 1.1           # m between the hatching's stripes


PAINT_STRAY_KERB = 10.0  # m: a kerb up to this long all within 2 m of a painted island goes with it
PAINT_TAPER = 8.0   # m a painted island runs on along the street's edge at each end


def _major_cos(out, x, z, ux, uz, reach=6.0):
    """|cos| between (ux, uz) and the nearest non-minor road within reach m of (x, z), or None."""
    best = None
    for r in out["roads"]:
        if r["k"] in MINOR or int(r.get("dk", -1)) >= 0:
            continue
        p = r["p"]
        for k in range(0, len(p) - 3, 2):
            ax, az, bx, bz = p[k], p[k + 1], p[k + 2], p[k + 3]
            if abs(ax - x) > 80 or abs(az - z) > 80:
                continue
            dx, dz = bx - ax, bz - az
            l2 = dx * dx + dz * dz or 1e-9
            t = min(max(((x - ax) * dx + (z - az) * dz) / l2, 0.0), 1.0)
            dd = math.hypot(x - ax - dx * t, z - az - dz * t)
            if dd < reach + r["w"] and (best is None or dd < best[0]):
                best = (dd, abs(dx * ux + dz * uz) / math.sqrt(l2))
    return None if best is None else best[1]


def _stretch(q, i, pa_, pb_):
    """Polygon q with its side q[i-1] -> q[i] run on to pa_ (before) and pb_ (after)."""
    out = list(q)
    out[i - 1] = pa_
    out[i] = pb_
    return out


def paint_islands(out, asphalt):
    """Round 3 (F, the pale triangle beside the lower-left junction): a tiny kerbed island left
    between a driveway's two branches and the street reads as a stray wedge of pavement. It
    becomes a painted island: asphalt (`asphalt_fills`), an edge line round it and diagonal
    hatching across it (`stripe`, P-21). Returns the count."""
    minor = []
    for r in out["roads"]:
        if r["k"] in MINOR:
            minor.append(pts_of(r["p"]))

    def near_minor(x, z):
        for q in minor:
            for a, b in zip(q, q[1:]):
                if abs(a[0] - x) > 60 or abs(a[1] - z) > 60:
                    continue
                dx, dz = b[0] - a[0], b[1] - a[1]
                l2 = dx * dx + dz * dz or 1e-9
                t = min(max(((x - a[0]) * dx + (z - a[1]) * dz) / l2, 0.0), 1.0)
                if math.hypot(x - a[0] - dx * t, z - a[1] - dz * t) < PAINT_MINOR_NEAR:
                    return True
        return False

    keep, painted = [], 0
    for isl in out.get("islands", []):
        q = pts_of(isl["p"])
        if len(q) > 2 and q[0] == q[-1]:
            q = q[:-1]
        area = abs(sum(q[i][0] * q[i - 1][1] - q[i - 1][0] * q[i][1] for i in range(len(q)))) / 2
        cx = sum(p[0] for p in q) / len(q)
        cz = sum(p[1] for p in q) / len(q)
        if area > PAINT_ISLAND_MAX or not near_minor(cx, cz):
            keep.append(isl)
            continue
        ring = densify(q + [q[0]], 0.5)
        around = [asphalt(x + (x - cx) / (math.hypot(x - cx, z - cz) or 1) * 0.6,
                          z + (z - cz) / (math.hypot(x - cx, z - cz) or 1) * 0.6) for x, z in ring]
        if sum(around) < 0.5 * len(around):
            keep.append(isl)
            continue
        painted += 1
        # F (round 3): a hatched triangle floating in the asphalt reads as a stray; it tapers
        # out along the street's edge, PAINT_TAPER m each way on its side most along a street
        # (a painted taper into the edge line, as Warsaw paints a driveway's mouth).
        # (an island traced round its rounded corners has many points: its corners decide)
        if len(q) > 8:
            qs = simplify(q + [q[0]], 0.35)[:-1]
            if 3 <= len(qs) <= 8:
                q = qs
        if len(q) <= 8:
            best = None
            for i in range(len(q)):
                a, b = q[i - 1], q[i]
                l = math.dist(a, b)
                if l < 1.0:
                    continue
                ux, uz = (b[0] - a[0]) / l, (b[1] - a[1]) / l
                mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
                d_major = _major_cos(out, mx, mz, ux, uz)
                if d_major is not None and (best is None or d_major > best[0]):
                    best = (d_major, i, ux, uz, l)
            if best and best[0] > 0.97:
                _, i, ux, uz, l = best
                a, b = q[i - 1], q[i]
                pa_ = (a[0] - ux * PAINT_TAPER, a[1] - uz * PAINT_TAPER)
                pb_ = (b[0] + ux * PAINT_TAPER, b[1] + uz * PAINT_TAPER)
                if asphalt(*pa_) and asphalt(*pb_):
                    q = _stretch(q, i, pa_, pb_)
        out.setdefault("asphalt_fills", []).append({"p": flat_of(q)})
        box = (min(p[0] for p in q) - 1, max(p[0] for p in q) + 1, min(p[1] for p in q) - 1, max(p[1] for p in q) + 1)
        out["kerbs"] = _drop_inside(out.get("kerbs", []), lambda x, z: box[0] <= x <= box[1] and box[2] <= z <= box[3]
                                    and _near_ring(q, x, z, 0.4))
        # and a short kerb left standing in the asphalt beside it (the street's kerb across the
        # driveway's mouth, now the taper's side)
        def stray(k):
            kq = pts_of(k["p"])
            if sum(math.dist(a, b) for a, b in zip(kq, kq[1:])) > PAINT_STRAY_KERB:
                return False
            return all(_near_ring(q, x, z, 2.0) or _poly_hit(q, x, z) for x, z in densify(kq, 0.5))
        out["kerbs"] = [k for k in out["kerbs"] if not stray(k)]
        out["markings"].append({"k": "edge", "p": flat_of(q + [q[0]])})
        # the hatching: lines at 45 degrees to the island's longest side, clipped to it
        i = max(range(len(q)), key=lambda k: math.dist(q[k], q[k - 1]))
        ax, az = q[i][0] - q[i - 1][0], q[i][1] - q[i - 1][1]
        l = math.hypot(ax, az)
        ux, uz = (ax / l + az / l) / math.sqrt(2), (az / l - ax / l) / math.sqrt(2)
        nx, nz = -uz, ux
        span = max(math.hypot(p[0] - cx, p[1] - cz) for p in q) + 1.0
        k = -span
        while k <= span:
            line = [(cx + nx * k + ux * t, cz + nz * k + uz * t) for t in [j * 0.25 - span for j in range(int(8 * span) + 1)]]
            run = []
            for pt in line:
                if _poly_hit(q, *pt):
                    run.append(pt)
                elif run:
                    break
            if len(run) >= 3:
                # 0.3 m in from the edge line on each end
                a, b = run[0], run[-1]
                lr = math.dist(a, b)
                if lr > 0.8:
                    f = 0.3 / lr
                    a2 = (a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
                    b2 = (b[0] - (b[0] - a[0]) * f, b[1] - (b[1] - a[1]) * f)
                    out["markings"].append({"k": "stripe", "p": flat_of([a2, b2])})
            k += HATCH_GAP
    out["islands"] = keep
    return painted


def _near_ring(q, x, z, reach):
    """Whether (x, z) lies inside polygon q or within reach of its outline."""
    if _poly_hit(q, x, z):
        return True
    for a, b in zip(q, q[1:] + q[:1]):
        dx, dz = b[0] - a[0], b[1] - a[1]
        l2 = dx * dx + dz * dz or 1e-9
        t = min(max(((x - a[0]) * dx + (z - a[1]) * dz) / l2, 0.0), 1.0)
        if math.hypot(x - a[0] - dx * t, z - a[1] - dz * t) <= reach:
            return True
    return False


def _street_tests(out):
    """check_streets.py's own asphalt and raised-ground tests on this data (S1, S2 judge with
    them), so a zebra or pole this pass moves passes them exactly."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import check_streets
    return check_streets.pole_tests(out)


POLE_STEP_MAX = 8.0   # m a lamp or pole may step back off the asphalt


SCOOTER_RAMP = 3.0   # m: tools/check_pois.py Q3 keeps a lying scooter (0.8 m more: its own half length) this far from a crossing's end


def clear_scooters(out, asphalt):
    """A zebra run on to the kerb (extend_zebras) can end beside a lying scooter (a kerb ramp,
    check_pois Q3): the scooter steps away from the crossing's end along the pavement, as the
    poles do. Returns the count moved."""
    ends = []
    for pa in out.get("paths", []):
        if pa["k"] in ("zebra", "cyclecross"):
            q = pts_of(pa["p"])
            if len(q) >= 2:
                ends += [q[0], q[-1]]
    grid = defaultdict(list)
    for e in ends:
        grid[(int(e[0] // 20), int(e[1] // 20))].append(e)

    def near(x, z):
        cx, cz = int(x // 20), int(z // 20)
        return [e for i in (-1, 0, 1) for j in (-1, 0, 1) for e in grid.get((cx + i, cz + j), ())
                if math.dist(e, (x, z)) < SCOOTER_RAMP + 0.8]
    moved = 0
    for po in out.get("pois", []):
        if po.get("k") != "scooter" or po.get("p") != "lie":
            continue
        hit = near(po["x"], po["z"])
        if not hit:
            continue
        e = hit[0]
        dx, dz = po["x"] - e[0], po["z"] - e[1]
        a0 = math.atan2(dz, dx) if dx or dz else 0.0
        for da in (0.0, 0.5, -0.5, 1.0, -1.0, 1.6, -1.6):
            for r in (4.6, 5.0, 5.4):
                x, z = e[0] + math.cos(a0 + da) * r, e[1] + math.sin(a0 + da) * r
                if not asphalt(x, z) and not near(x, z):
                    po["x"], po["z"] = round(x, 2), round(z, 2)
                    moved += 1
                    break
            else:
                continue
            break
    return moved


def clear_poles(out, asphalt):
    """A street lamp or signal pole the widened or tapered asphalt now reaches (it stood on the
    old kerb) steps back off it, away from the nearest road's centreline, at most POLE_STEP_MAX m;
    a lamp that cannot is taken away, a signal stays (check_streets S1 names it). Returns the
    count moved or taken."""
    segs = defaultdict(list)
    for r in out["roads"]:
        if int(r.get("dk", -1)) >= 0:
            continue
        p = pts_of(r["p"])
        for a, b in zip(p, p[1:]):
            segs[(int(a[0] // 20), int(a[1] // 20))].append((a, b))
    moved = 0
    for key, stride in (("lamps", 2), ("signals", 3)):
        v = out.get(key, [])
        drop = set()
        for k in range(0, len(v) - stride + 1, stride):
            x, z = v[k], v[k + 1]
            if not asphalt(x, z):
                continue
            best = None
            cx, cz = int(x // 20), int(z // 20)
            for i in (-1, 0, 1):
                for j in (-1, 0, 1):
                    for a, b in segs.get((cx + i, cz + j), ()):
                        dx, dz = b[0] - a[0], b[1] - a[1]
                        l2 = dx * dx + dz * dz or 1e-9
                        t = min(max(((x - a[0]) * dx + (z - a[1]) * dz) / l2, 0.0), 1.0)
                        qx, qz = a[0] + dx * t, a[1] + dz * t
                        dd = math.hypot(x - qx, z - qz)
                        if best is None or dd < best[0]:
                            best = (dd, qx, qz)
            if best is None or best[0] < 0.3:
                if key == "lamps":
                    drop.add(k)
                continue
            ux, uz = (x - best[1]) / best[0], (z - best[2]) / best[0]
            step = 0.25
            while step <= POLE_STEP_MAX and asphalt(x + ux * step, z + uz * step):
                step += 0.25
            nx_, nz_ = round(x + ux * (step + 0.5), 2), round(z + uz * (step + 0.5), 2)
            if step > POLE_STEP_MAX or asphalt(nx_, nz_):
                # in a junction's middle: the shortest way off, round the compass
                for t in [i * 0.25 for i in range(1, int(POLE_STEP_MAX * 4) + 1)]:
                    hit = next(((x + math.cos(a) * (t + 0.5), z + math.sin(a) * (t + 0.5))
                                for a in [i * math.pi / 8 for i in range(16)]
                                if not asphalt(x + math.cos(a) * t, z + math.sin(a) * t)
                                and not asphalt(x + math.cos(a) * (t + 0.5), z + math.sin(a) * (t + 0.5))), None)
                    if hit:
                        step, nx_, nz_ = t, round(hit[0], 2), round(hit[1], 2)
                        break
            if step <= POLE_STEP_MAX and not asphalt(nx_, nz_):
                v[k], v[k + 1] = nx_, nz_
                moved += 1
            elif key == "lamps":
                drop.add(k)   # a lamp left in the road goes (a signal keeps its index: its lamps)
        if drop:
            out[key] = [q for i in range(0, len(v) - stride + 1, stride) if i not in drop for q in v[i:i + stride]]
            moved += len(drop)
    return moved


BESIDE_GAP = 0.3     # m of road between a cycle crossing's edge and the zebra's stripes
CYCLE_HALF = 1.35    # m: map_builder's cycle crossing, 2.2 m of red and its rows of white squares
ZEBRA_HALF = 1.8     # m: map_builder's zebra stripes are 3.6 m long
BESIDE_MAX = 12.0    # m: a zebra farther from its cycle crossing is a crossing of its own


def zebras_beside_cycles(out):
    """F (2026-11-05, the ChatGPT reference): a zebra runs right beside the cycle crossing next to
    it, one band across the street, as Warsaw paints them. A zebra parallel to a cycle crossing
    up to BESIDE_MAX m away (and overlapping it along the street) moves across to BESIDE_GAP m
    from its edge, on the side it was. Returns the count moved."""
    cyc = []
    for pa in out.get("paths", []):
        if pa["k"] == "cyclecross":
            q = pts_of(pa["p"])
            if len(q) >= 2 and math.dist(q[0], q[-1]) > 1.0:
                cyc.append((q[0], q[-1], float(pa.get("w", 2.0))))
    grid = defaultdict(list)
    for k, (a, b, w) in enumerate(cyc):
        grid[(int((a[0] + b[0]) / 2 // 30), int((a[1] + b[1]) / 2 // 30))].append(k)
    moved = 0
    cands = []
    for pa in out.get("paths", []):
        if pa["k"] != "zebra":
            continue
        q = pts_of(pa["p"])
        if len(q) < 2:
            continue
        za, zb = q[0], q[-1]
        zl = math.dist(za, zb)
        if zl < 1.0:
            continue
        ux, uz = (zb[0] - za[0]) / zl, (zb[1] - za[1]) / zl
        mx, mz = (za[0] + zb[0]) / 2, (za[1] + zb[1]) / 2
        best = None
        cx, cz = int(mx // 30), int(mz // 30)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for k in grid.get((cx + i, cz + j), ()):
                    a, b, w = cyc[k]
                    cl = math.dist(a, b)
                    vx, vz = (b[0] - a[0]) / cl, (b[1] - a[1]) / cl
                    if abs(vx * ux + vz * uz) < 0.94:
                        continue
                    # offset of the zebra's middle from the cycle line, and overlap along it
                    off = (mx - a[0]) * -vz + (mz - a[1]) * vx
                    t0 = (za[0] - a[0]) * vx + (za[1] - a[1]) * vz
                    t1 = (zb[0] - a[0]) * vx + (zb[1] - a[1]) * vz
                    if max(t0, t1) < 0 or min(t0, t1) > cl:
                        continue
                    if abs(off) > BESIDE_MAX:
                        continue
                    if best is None or abs(off) < abs(best[0]):
                        best = (off, w, -vz, vx, a[0], a[1])
        if best is None:
            continue
        off, w, nx, nz, ax_, az_ = best
        # the cycle crossing's line, as one key for every piece of it across the street
        if nx < 0 or (nx == 0 and nz < 0):
            nx, nz, off = -nx, -nz, -off
        const = nx * ax_ + nz * az_
        cands.append((pa, q, off, nx, nz, (round(math.degrees(math.atan2(nz, nx)) / 4), round(const / 2.0))))
    # Both carriageways' zebras on the same side of the cycle crossing (F: one band across the
    # street, the walk straight through the median): the side most of them already have.
    side = defaultdict(float)
    for pa, q, off, nx, nz, key in cands:
        side[key] += math.copysign(1.0, off) / (1.0 + abs(off))
    for pa, q, off, nx, nz, key in cands:
        want = math.copysign(CYCLE_HALF + BESIDE_GAP + ZEBRA_HALF, side[key] or off)
        shift = want - off
        if abs(shift) < 0.3:
            continue
        nq = [(x + nx * shift, z + nz * shift) for x, z in q]
        if not all(_in_map(out, x, z) for x, z in nq):
            continue
        pa["p"] = flat_of(nq)
        moved += 1
    return moved


NOSE_STEP = 0.25      # m between the samples across a bed
NOSE_SIDE = 2.5      # m the opening's paving runs past the bed's measured edges (its gravel verge, a bent track's sleepers)
SCRAP_LEN = 4.0       # m: a line this short by an opening is a scrap
NOSE_ARC = 10         # points on a median nose's half circle


def shape_openings(out, on_bed):
    """F (round 4): where a road crosses a tram median (a U-turn, a side street), the opening has
    one footprint: the paved crossing (`tram_xings`) runs on past the road's edges by half the bed's
    width, and each side of it ends the median in a rounded nose: a half circle of the bed's width
    (`tram_noses`, gravel, drawn over the paving) kerbed round (`kerbs`, the bed on its right).
    The rails run on through (they lie over everything). Returns the count of noses."""
    tsegs = []
    for t in out.get("trams", []):
        tp = pts_of(t["p"])
        tsegs += list(zip(tp, tp[1:]))

    def tram_dir(x, z):
        best = None
        for (ax, az), (bx, bz) in tsegs:
            if abs(ax - x) > 60 or abs(az - z) > 60:
                continue
            dx, dz = bx - ax, bz - az
            l2 = dx * dx + dz * dz or 1e-9
            t = min(max(((x - ax) * dx + (z - az) * dz) / l2, 0.0), 1.0)
            dd = math.hypot(x - ax - dx * t, z - az - dz * t)
            if best is None or dd < best[0]:
                l = math.sqrt(l2)
                best = (dd, dx / l, dz / l)
        return None if best is None or best[0] > 10 else best[1:]

    noses, arcs, feet = [], [], []
    for x in out.get("tram_xings", []):
        if x["k"] != "road":
            continue
        p = pts_of(x["p"])
        mid = p[len(p) // 2] if len(p) > 2 else ((p[0][0] + p[1][0]) / 2, (p[0][1] + p[1][1]) / 2)
        td = tram_dir(*mid)
        if td is None:
            continue
        tx, tz = td
        nx, nz = -tz, tx
        # the bed's two edges through the crossing's middle, across the tracks
        if not on_bed(*mid):
            continue
        # (sampled across the crossing and a few metres each way along the tracks, the widest
        # taken: a median that flares at the opening left gravel wedges past a middle-only width)
        lo = hi = 0.0
        for s_ in (0.0, -2.0, 2.0, -(x["w"] / 2), x["w"] / 2):
            bx_, bz_ = mid[0] + tx * s_, mid[1] + tz * s_
            if not on_bed(bx_, bz_):
                continue
            l_ = h_ = 0.0
            while l_ > -15 and on_bed(bx_ + nx * (l_ - NOSE_STEP), bz_ + nz * (l_ - NOSE_STEP)):
                l_ -= NOSE_STEP
            while h_ < 15 and on_bed(bx_ + nx * (h_ + NOSE_STEP), bz_ + nz * (h_ + NOSE_STEP)):
                h_ += NOSE_STEP
            if h_ - l_ <= 14.0:
                lo, hi = min(lo, l_), max(hi, h_)
        width = hi - lo
        if width < 2.0 or width > 14.0:
            continue
        cx, cz = mid[0] + nx * (lo + hi) / 2, mid[1] + nz * (lo + hi) / 2
        r = width / 2
        half = x["w"] / 2
        # the paved footprint: the crossing's band as long as the road is wide plus a nose radius
        # each way along the tracks, across the bed's whole width
        foot = [(cx + tx * s1 + nx * s2, cz + tz * s1 + nz * s2) for s1, s2 in
                ((-(half + r), -r - NOSE_SIDE), (half + r, -r - NOSE_SIDE), (half + r, r + NOSE_SIDE), (-(half + r), r + NOSE_SIDE))]
        x["foot"] = flat_of(foot)
        feet.append(foot)
        for sg in (-1, 1):
            # the nose's centre, r beyond the road's edge along the tracks
            ox, oz = cx + tx * sg * (half + r), cz + tz * sg * (half + r)
            ring = []
            for k in range(NOSE_ARC + 1):
                a = math.pi * k / NOSE_ARC
                # from the bed's lo edge round through the tip (towards the road) to its hi edge
                ring.append((ox - tx * sg * r * math.sin(a) + nx * (-r * math.cos(a)),
                             oz - tz * sg * r * math.sin(a) + nz * (-r * math.cos(a))))
            back = [(ox + tx * sg * 0.6 + nx * r, oz + tz * sg * 0.6 + nz * r),
                    (ox + tx * sg * 0.6 - nx * r, oz + tz * sg * 0.6 - nz * r)]
            noses.append({"p": flat_of(ring + back)})
            # the kerb round the nose, the bed (the nose's inside) on its right
            arc = list(ring)
            mx_, mz_ = arc[len(arc) // 2]
            ax_, az_ = arc[len(arc) // 2 - 1]
            # right of travel is (-dz, dx); the nose's centre must lie there
            dx, dz = mx_ - ax_, mz_ - az_
            if (-dz) * (ox - ax_) + dx * (oz - az_) < 0:
                arc.reverse()
            arcs.append({"p": flat_of(arc)})
    out["tram_noses"] = noses
    # the bed's straight kerbs and edge lines stop where the footprint begins; the noses' own
    # kerbs take over
    def in_foot(x_, z_):
        return any(_poly_hit(f, x_, z_) for f in feet)
    out["kerbs"] = _drop_inside(out.get("kerbs", []), in_foot) + arcs
    edges = [m for m in out["markings"] if m["k"] == "edge"]
    out["markings"] = [m for m in out["markings"] if m["k"] != "edge"] + _drop_inside(edges, in_foot)
    # and the scraps of line left by an opening (a U-turn's edge lines cut to a few metres)
    boxes = [(min(q[0] for q in f) - 4, max(q[0] for q in f) + 4, min(q[1] for q in f) - 4, max(q[1] for q in f) + 4) for f in feet]

    def scrap(m):
        if m["k"] not in ("edge", "lane", "centre", "solid"):
            return False
        q = pts_of(m["p"])
        if sum(math.dist(a, b) for a, b in zip(q, q[1:])) > SCRAP_LEN:
            return False
        return any(b[0] <= x_ <= b[1] and b[2] <= z_ <= b[3] for x_, z_ in q for b in boxes)
    out["markings"] = [m for m in out["markings"] if not scrap(m)]
    # and the stubs of kerb the cut leaves beside the footprint (pale slivers in the opening)
    def stub(k):
        if k in arcs:
            return False
        q = pts_of(k["p"])
        if sum(math.dist(a, b) for a, b in zip(q, q[1:])) > SCRAP_LEN:
            return False
        return any(b[0] <= x_ <= b[1] and b[2] <= z_ <= b[3] for x_, z_ in q for b in boxes)
    out["kerbs"] = [k for k in out["kerbs"] if not stub(k)]
    return len(noses)


# --- Unslop (Świętokrzyska round, 2026-11-06): lane lines cut at the zebras' final shape -------

ZEBRA_CUT = 2.4        # m from a zebra's path: bake_roads ZEBRA_HALF + ZEBRA_GAP (stripes 3.6 m wide)
ZEBRA_CUT_STEP = 0.25  # m between the samples along a line
ZEBRA_CUT_MIN = 2.0    # m: a shorter piece left between two zebras is dropped (a stub)
ZEBRA_CUT_KINDS = ("lane", "centre")


def cut_zebras(out, dry=False):
    """Cuts every lane and centre line where it runs under a zebra. bake_roads cuts the lines it paints
    when it draws them, but the smoothing then stitches, spreads and rounds lines, and lines it moved
    or joined can run through a zebra again, and zebras it moved beside a cycle crossing or ran on to
    the kerbs cover ground its lines had not been cut for (check L4). Returns the number of lines cut
    (dry: the number that would be, nothing changed)."""
    cell = 12.0
    grid = defaultdict(list)
    for w in out.get("paths", []):
        if w.get("k") != "zebra":
            continue
        q = pts_of(w["p"])
        for a, b in zip(q, q[1:]):
            for i in range(math.floor((min(a[0], b[0]) - ZEBRA_CUT) / cell), math.floor((max(a[0], b[0]) + ZEBRA_CUT) / cell) + 1):
                for j in range(math.floor((min(a[1], b[1]) - ZEBRA_CUT) / cell), math.floor((max(a[1], b[1]) + ZEBRA_CUT) / cell) + 1):
                    grid[(i, j)].append((a, b, w.get("dk", -1)))

    def under(x, z, lv):
        for a, b, zlv in grid.get((math.floor(x / cell), math.floor(z / cell)), ()):
            if zlv == lv and seg_dist((x, z), a, b) < ZEBRA_CUT:
                return True
        return False

    kept = []
    cut = 0
    for m in out["markings"]:
        if m["k"] not in ZEBRA_CUT_KINDS:
            kept.append(m)
            continue
        lv = m.get("dk", -1)
        pts = pts_of(m["p"])
        dense = []
        for a, b in zip(pts, pts[1:]):
            n = max(1, math.ceil(math.hypot(b[0] - a[0], b[1] - a[1]) / ZEBRA_CUT_STEP))
            for i in range(n):
                dense.append((a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n))
        dense.append(pts[-1])
        if not any(under(x, z, lv) for x, z in dense):
            kept.append(m)
            continue
        runs, run = [], []
        for x, z in dense:
            if under(x, z, lv):
                if run:
                    runs.append(run)
                run = []
            else:
                run.append((x, z))
        if run:
            runs.append(run)
        cut += 1
        if dry:
            kept.append(m)
            continue
        for r in runs:
            if len(r) >= 2 and length(r) >= ZEBRA_CUT_MIN:
                piece = dict(m)
                piece["p"] = flat_of(simplify(r, 0.05))
                kept.append(piece)
    out["markings"] = kept
    return cut


SEAT_MARGIN = 0.15     # m: an edge line sits this far inside the kerb it runs along
SEAT_SHIFT_MAX = 0.3   # m: a point is moved at most this far (a bigger shift shows as a line jog; the edge is really elsewhere)


def seat_edges(out, dry=False):
    """Settles every edge line on the inside of the kerb it runs along. The kerbs and the edge lines
    are moved by different rules (fit_kerbs, snap_lines), so where a line runs within centimetres of its
    kerb it can wander across it and the paint ends up on the kerb (check L3). A segment of an edge line
    that crosses a kerb segment gets its end points that lie on the wrong side (the side most of the
    segment is on) or closer than SEAT_MARGIN moved onto the right side, SEAT_MARGIN from the kerb.
    Returns the number of edge-line points moved (dry: the number of edge-line segments that cross a
    kerb, nothing changed)."""
    cell = 8.0
    segs = []
    grid = defaultdict(list)
    for k in out.get("kerbs", []):
        q = pts_of(k["p"])
        for a, b in zip(q, q[1:]):
            segs.append((a, b))
            n = len(segs) - 1
            for i in range(math.floor((min(a[0], b[0]) - 1.0) / cell), math.floor((max(a[0], b[0]) + 1.0) / cell) + 1):
                for j in range(math.floor((min(a[1], b[1]) - 1.0) / cell), math.floor((max(a[1], b[1]) + 1.0) / cell) + 1):
                    grid[(i, j)].append(n)

    def side(c, e, p):
        ux, uz = e[0] - c[0], e[1] - c[1]
        L = math.hypot(ux, uz)
        if L < 1e-6:
            return 0.0, (0.0, 0.0)
        return ((p[0] - c[0]) * -uz + (p[1] - c[1]) * ux) / L, (-uz / L, ux / L)

    moved = 0
    for m in out["markings"]:
        if m["k"] != "edge":
            continue
        pts = pts_of(m["p"])
        changed = False
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            for n in grid.get((math.floor(mid[0] / cell), math.floor(mid[1] / cell)), ()):
                c, e = segs[n]
                if not _segs_cross(a, b, c, e):
                    continue
                if dry:
                    moved += 1
                    break
                sa, nrm = side(c, e, a)
                sb, _ = side(c, e, b)
                if abs(sa) < 1e-6 and abs(sb) < 1e-6:
                    continue
                sg = 1.0 if (sa if abs(sa) >= abs(sb) else sb) > 0 else -1.0
                for j, sv in ((i, sa), (i + 1, sb)):
                    if sv * sg < SEAT_MARGIN and SEAT_MARGIN - sv * sg <= SEAT_SHIFT_MAX:
                        p = pts[j]
                        pts[j] = (p[0] + nrm[0] * sg * (SEAT_MARGIN - sv * sg), p[1] + nrm[1] * sg * (SEAT_MARGIN - sv * sg))
                        moved += 1
                        changed = True
                break
        if changed:
            m["p"] = flat_of(pts)
    return moved


def apply(out):
    """Smooths the finished map data in place; returns a one-line summary."""
    if int(out.get("road_smooth", 0)) >= VERSION:
        return "already smoothed"
    if out.get("road_smooth"):
        raise SystemExit("road_smooth: the map was smoothed by an older version; take the unsmoothed "
                         "map (the other side's centrum.json, or a re-bake) and run this again")
    before = measure(out)
    WIDENED.clear()
    beds, bed_sides = fit_rail_beds(out)
    chain_ways, chain_sides = fit_chain_widths(out)
    spread = spread_lanes(out)
    joins = find_joins(out["roads"])
    index_nodes(out["roads"])
    ends = []
    tapers = taper_roads(out["roads"], joins, ends)
    km = snap_lines(out.get("kerbs", []), tapers, lambda k: pts_of(k["p"]), lambda k, p: k.__setitem__("p", flat_of(p)))
    fit = fit_kerbs(out["roads"], tapers, ends, out.get("kerbs", []))
    bridged = bridge_rail_kerbs(out, out.get("kerbs", []))
    edge_idx = [k for k, m in enumerate(out["markings"]) if m["k"] == "edge"]
    edge_lines = [out["markings"][k] for k in edge_idx]
    before_n = len(edge_lines)
    bridged += bridge_rail_kerbs(out, edge_lines, reach=1.0)
    if len(edge_lines) != before_n:   # drop the edge lines that were joined onto others
        alive = {id(m) for m in edge_lines}
        out["markings"] = [m for k, m in enumerate(out["markings"]) if m["k"] != "edge" or id(m) in alive]
    edges = [m for m in out.get("markings", []) if m["k"] in ("edge",)]
    em = snap_lines(edges, tapers, lambda m: pts_of(m["p"]), lambda m, p: m.__setitem__("p", flat_of(p)))
    joined = stitch(out["markings"])
    rounded = 0
    for m in out["markings"]:
        if m["k"] in ROUND_KINDS:
            p, n = round_line(pts_of(m["p"]))
            if n:
                m["p"] = flat_of(p)
                rounded += n
    on_bed = _bed_index(out)
    sleepers = tram_beds(out, on_bed)
    beside = zebras_beside_cycles(out)
    zebra_m = extend_zebras(out, *_street_tests(out))
    xings, xing_cut = tram_crossings(out, on_bed)
    noses = shape_openings(out, on_bed)
    stairs = metro_steps(out)
    pockets = fill_pockets(out)
    painted = paint_islands(out, _asphalt_sampler(out)[0])
    kit = crossing_kit(out, _street_tests(out)[0])
    zcut = cut_zebras(out)
    seated = seat_edges(out)
    poles = clear_poles(out, _street_tests(out)[0])
    scooters = clear_scooters(out, _street_tests(out)[0])
    after = measure(out)
    out["road_smooth"] = VERSION
    return (f"{beds} ways ({bed_sides} sides) widened onto the tram bed, {chain_ways} ways ({chain_sides} sides) "
            f"widened to their street's kerbs ({spread} lane-line points spread), {len(tapers)} joins tapered, {km} kerb and {em} edge-line points moved, {fit} edges fitted to "
            f"their kerbs, {bridged} kerb breaks by a tram bed closed, {joined} lines "
            f"stitched, {rounded} line kinks rounded; edge steps {before['steps']} -> {after['steps']}, "
            f"line jogs {before['jogs']} -> {after['jogs']}; {sleepers} tram tracks on a bed, {xings} crossings of a bed paved ({xing_cut} line points under them dropped), {noses} median noses rounded, {stairs} metro stairs, {pockets} bare pockets between roads filled, {painted} driveway islands painted, {beside} zebras moved beside their cycle crossing, zebras run on {zebra_m} m to the kerbs, {kit[0]} main-street crossings given {kit[1]} stop lines and {kit[2]} signal poles, {poles} lamps and poles stepped off the asphalt, {zcut} lane lines cut at zebras, {seated} edge-line points seated inside their kerbs")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    path = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        d = json.load(fh)
    if "--check" in sys.argv:
        m = measure(d)
        ok = bool(d.get("road_smooth")) and m["steps"] <= CHECK_STEPS and m["jogs"] <= CHECK_JOGS and m["zlines"] <= CHECK_ZLINES and m["edgex"] <= CHECK_EDGEX
        why = "" if d.get("road_smooth") else " (the map was never smoothed: run tools/road_smooth.py)"
        print(f"road_smooth: {'OK' if ok else 'FAIL'}: edge steps {m['steps']} (max {CHECK_STEPS}), "
              f"line jogs {m['jogs']} (max {CHECK_JOGS}), lines under zebras {m['zlines']} (max {CHECK_ZLINES}), "
              f"edge lines across kerbs {m['edgex']} (max {CHECK_EDGEX}){why}")
        return 0 if ok else 1
    if "--report" in sys.argv or "--dry" in sys.argv:
        m = measure(d)
        print(f"road_smooth: {path}: edge steps {m['steps']}, line jogs {m['jogs']}, "
              f"smoothed {'yes' if d.get('road_smooth') else 'no'}")
        if "--dry" in sys.argv:
            return 0
    if "--dry" not in sys.argv:
        print("road_smooth: " + apply(d))
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(d, fh, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
