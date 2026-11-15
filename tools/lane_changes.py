"""Lane changes along the taper (RT-4, docs/design/roads-true-to-life.md; TD-23): where a street
gains or loses a lane between two of its ways, or its lanes sit further to one side on the next way,
the lane graph's link across the node is stretched over the drawn taper, so a car moves over along
the asphalt instead of jumping sideways in the 3 m between the two ways.

    python3 -I tools/lane_changes.py [MAP.json] [--dry] [--list]
        rewrites the map in place (stamp-guarded: a map already done is left alone); --dry
        measures and writes nothing; --list prints every stretched link with its `--at=`.
    python3 -I tools/lane_changes.py --check [MAP.json]
        exit 1 unless the map carries the pass and at most CHECK_ABRUPT continuation links still
        move a lane over more steeply than 1:RATE (verify.sh step `lanechanges`; a ratchet: lower
        it, never raise it).

Why. OpenStreetMap cuts a street into ways, each with its own lane count and width, and the bake
gives every way's lanes their own place across its own drawn asphalt (bake_osm `extents_of`). Two
ways of one street meet at a node with a trim of 1.5 m on each side (bake_osm `trim`), so the link
between them is 3 m long. Where the lane count changes (road_truth R1: 379 on main, 2026-11-15) or
the lanes sit elsewhere on the next way, every car in a lane that does not line up swerved half a
lane or a whole lane sideways inside those 3 m: traffic, the rivals and the player's lane assist
alike. Meanwhile the asphalt itself already widens or narrows along a real taper (tools/lane_tapers.py,
1:10 to 1:15, the lane line ends where it begins), so the lanes ignored the road they were on.

What, on the finished map data (bake_osm.py calls `apply(out)` after lane_links; it also runs on a
baked map, as the cloud has no OpenStreetMap download):

1. Joins: an edge whose end node has one way on (no side road, as road_truth R1 sees it), turning
   under STRAIGHT rad, where a lane that goes straight on (with its RT-2 link) moves more than JUMP
   m sideways: the two edges share the node, so that is the difference of the lane's two offsets.
2. The span. The drawn asphalt is measured along both edges from the node (the roads' per-vertex
   `wv`/`cv` edges, so lane_tapers' tapers count): where its width settles within TAPER_TOL m is
   the end of the taper on that side. The link then runs from the start of the taper on the edge
   before the node to its end on the edge after it. Where the asphalt does not taper there (the
   lanes change inside one width: a painted lane change) the link is PAINT_RATIO m along for each
   metre aside, at least PAINT_MIN m, shared out over both edges.
3. Limits: each edge keeps at least MIN_DRIVE m to drive between its two links (road_truth R7) and
   gives at most END_SHARE of its length to one link; the link is shortened until the road turns
   by at most BEND_MAX rad between its two ends (a longer link would cut the bend: the Bezier
   joins the two lane ends in one curve, lane_graph.gd `connector`).
4. The trims are written (`s1` of the edge before the node, `s0` of the one after it; the bake's
   own trim is kept beside it in `s1o`/`s0o`, which only tools read). The RT-2
   links (`lk`, `tl`; tools/lane_links.py) stay as they are: the lanes keep their places across
   their edges, so a lane still lands in the lane its own line leads to. lane_links reads the turn
   arrows and judges its links at the bake's trims (`s1o`/`s0o` where this pass moved them), so it
   is a fixed point before and after this pass.

Nothing is drawn differently: no kerb, line or arrow moves; only where the cars drive. The links
stay inside the drawn asphalt because they follow its taper. Re-run tools/bake_sectors.py and
bake_city.gd after it (the graph is in the sectors' index). The lane graph is the racer AI's
too: re-run the racer bench on the Mac (the build gate does). Deterministic, standard library only.
"""
import json
import math
import os
import sys
from collections import defaultdict

TOOLS = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, TOOLS)
import lane_links as ll  # noqa: E402
import lane_tapers as lt  # noqa: E402
import road_smooth as rs  # noqa: E402

KEY = "lane_changes"
VERSION = 1
# --check (2026-11-15, first pass): continuation links that still move a lane over more steeply
# than 1:RATE. Lower it when a change leaves fewer, never raise it.
CHECK_ABRUPT = 84     # 586 on main before the pass
STRAIGHT = 0.5        # rad; road_truth R1: the one way on counts as the same street up to this turn
JUMP = 0.5            # m: a lane landing less than this aside of its own line does not jump
RATE = 6.0            # m along per m aside: a link at least this long for its shift is a lane change, not a swerve
PAINT_RATIO = 8.0     # m along per m aside where the asphalt does not taper (paint only)
PAINT_MIN = 10.0      # m
TAPER_TOL = 0.25      # m: the drawn width has settled once it stays within this of its value further on
LOOK = 70.0           # m from the node the taper is looked for
MIN_DRIVE = 3.5       # m an edge keeps to drive between its two links (road_truth SHORT_M)
END_SHARE = 0.45      # most of an edge's length one link may take
BEND_MAX = 0.15       # rad the road may turn between a stretched link's two ends (more than the node's own turn)
DRAW_REACH = 3.0      # m from a lane-graph centreline to the drawn road's centreline still read as that road
DRAW_COS = 0.9        # the drawn road runs along the edge
TRIM_ROUND = 2        # decimals of a written trim
LINE_CLEAR = 1.0      # m an edge keeps past a signal's stop line on it (a car stops before it, on the edge)
LINE_BEFORE = 6.0     # m before a stop line an edge's drive starts (a car entering it still sees the line ahead)
BUS_BEFORE = 0.5      # m before a bus stop's shelter an edge's drive starts (buses.gd moves the stop at most 3 m on)
BUS_AFTER = 7.0       # m an edge keeps past a bus stop's shelter (buses.gd: s + 6, clamped to s1 - 4)
SHELTER_REACH = 20.0  # m from an edge's centreline a shelter may be its bus stop
STOP_SIDE = (1.5, 10.0)   # buses.gd STOP_SIDE: m past the kerb lane's centre a shelter stands
SMALL = {"residential", "unclassified", "living_street"}   # lane_graph.gd class 2-3: no buses stop


# --- the drawn asphalt along an edge -----------------------------------------------------------

class Drawn:
    """The drawn roads (their per-vertex edges, lane_tapers.Way), read across a graph edge."""

    def __init__(self, out):
        self.roads = out["roads"]
        self.ways = [lt.Way(r) for r in self.roads]
        self.grid = lt.road_grid(self.roads)

    def width(self, p, d):
        """The drawn asphalt's width across direction d at point p (None where no drawn road runs
        along it). A road under a carriageway area (`hide`) counts: its strip is its width."""
        best = None
        for i, (s, off, dist) in lt._near_roads(self.grid, p[0], p[1], DRAW_REACH).items():
            w = self.ways[i]
            k = 0
            while k < len(w.cum) - 2 and w.cum[k + 1] < s:
                k += 1
            u = rs.unit(w.pts[k], w.pts[k + 1])
            if not u or abs(u[0] * d[0] + u[1] * d[1]) < DRAW_COS:
                continue
            if best is None or dist < best[0]:
                best = (dist, i, s)
        if best is None:
            return None
        _, i, s = best
        return self.ways[i].edge(s, 1) - self.ways[i].edge(s, 0)

    def taper(self, ge, from_end):
        """Metres from the node (ge's end when from_end, else its start) to where the drawn width
        along ge settles (0 when it is the same all along, None when nothing is drawn)."""
        look = min(LOOK, ge.len * END_SHARE + 1.0)
        vals = []
        s = 0.0
        while s <= look + 1e-6:
            at = ge.len - s if from_end else s
            at = min(max(at, 0.01), ge.len - 0.01)
            vals.append((s, self.width(ge.point(at, 0.0), ge.direction(at))))
            s += 1.0
        known = [v for _, v in vals if v is not None]
        if len(known) < 3:
            return None
        ref = known[-1]
        end = 0.0
        for s, v in vals:
            if v is not None and abs(v - ref) > TAPER_TOL:
                end = s + 1.0
        return min(end, look)


# --- the joins -----------------------------------------------------------------------------------

def joins(edges, G, outs, rev):
    """[(e, f, turn)] for every edge e whose end has one way on, f, turning under STRAIGHT rad."""
    inn = defaultdict(list)
    for i, e in enumerate(edges):
        if not int(e.get("cf", 0)):
            inn[int(e["b"])].append(i)
    found = []
    for i, e in enumerate(edges):
        if int(e.get("cf", 0)):
            continue
        b = int(e["b"])
        on = [f for f in outs[b] if f != rev[i]]
        ins = [x for x in inn[b] if not on or rev[x] != on[0]]
        if len(on) != 1 or len(ins) != 1 or int(edges[on[0]].get("cf", 0)):
            continue
        ge, gf = G[i], G[on[0]]
        turn = ll.angle(ge.direction(ge.s1), gf.direction(gf.s0))
        if abs(turn) < STRAIGHT:
            found.append((i, on[0], turn))
    return found


def lanes_of(edges, i, f, ge, gf, turn):
    """[(k, j)]: lane k of edge i lands in lane j of f (the RT-2 link, else lane_graph's old rule),
    for the lanes that may go straight on."""
    e = edges[i]
    lk = e.get("lk")
    js = None
    if lk:
        step = ge.n + 1
        for x in range(0, len(lk), step):
            if lk[x] == f:
                js = lk[x + 1:x + step]
                break
    if js is None:
        js = [ll.old_lane(ge.n, k, gf.n, turn) for k in range(ge.n)]
    tl = e.get("tl")
    return [(k, min(max(int(j), 0), gf.n - 1)) for k, j in enumerate(js)
            if not tl or k >= len(tl) or ll.allows(tl[k], turn)]


def shift_of(ge, gf, pairs):
    """The largest sideways move (m) of any lane in `pairs` across a continuation node: the two
    edges share the node, so a lane moves by the difference of its two offsets from the line."""
    return max((abs(gf.lane_off(j) - ge.lane_off(k)) for k, j in pairs), default=0.0)


def link_len(e, f, ge, gf):
    """Metres along the road the link across the node spans: the two trims as the game drives
    them (lane_links.Edge holds the bake's own)."""
    return (ge.len - float(e["s1"])) + float(f["s0"])


def stops_on(out, edges, G, ids):
    """{edge: ([stop line s, ...], [bus stop s, ...])} along the given edges, which a stretched
    link keeps clear of: the bake's signal stop lines (`st`: traffic.gd `_red_gap` reads them only
    while a car is on the edge) and the shelters buses.gd `stop_from` snaps onto it."""
    sh = out.get("shelters", [])
    pts = [(sh[k], sh[k + 1]) for k in range(0, len(sh) - 2, 3)]
    found = {}
    for i in ids:
        lines = [float(st[0]) for st in edges[i].get("st", [])]
        bus = []
        ge = G[i]
        if edges[i].get("k") not in SMALL:
            xs = [p[0] for p in ge.P]
            zs = [p[1] for p in ge.P]
            for p in pts:
                if not (min(xs) - SHELTER_REACH <= p[0] <= max(xs) + SHELTER_REACH
                        and min(zs) - SHELTER_REACH <= p[1] <= max(zs) + SHELTER_REACH):
                    continue
                d, sv, side, _ = ge.project(p)
                # as buses.gd takes it: on the right, STOP_SIDE m past the kerb lane's centre,
                # beside the line (not off one of its ends)
                out_m = side - ge.lane_off(ge.n - 1)
                if STOP_SIDE[0] <= out_m <= STOP_SIDE[1] and abs(d - abs(side)) <= 2.0:
                    bus.append(sv)
        if lines or bus:
            found[i] = (lines, bus)
    return found


def plan(edges, G, outs, rev, drawn, listing=None, out=None):
    """{(edge, 's0'|'s1'): new trim value} for every join whose lanes jump, and the counts."""
    trims = {}
    stats = defaultdict(int)
    found = joins(edges, G, outs, rev)
    stops = stops_on(out or {}, edges, G, {i for j in found for i in j[:2]})
    for i, f, turn in found:
        ge, gf = G[i], G[f]
        pairs = lanes_of(edges, i, f, ge, gf, turn)
        if not pairs:
            continue
        shift = shift_of(ge, gf, pairs)
        if shift <= JUMP:
            continue
        stats["jumps"] += 1
        before = ge.len - ge.s1        # metres of e already in the link
        after = gf.s0                  # metres of f already in it
        te = drawn.taper(ge, True)
        tf = drawn.taper(gf, False)
        want_e = max(before, te or 0.0)
        want_f = max(after, tf or 0.0)
        paint = max(PAINT_MIN, PAINT_RATIO * shift)
        if want_e + want_f < paint:
            # the asphalt does not taper (enough) here: a painted lane change, shared out
            stats["paint"] += 1
            extra = paint - want_e - want_f
            want_e += extra * 0.5
            want_f += extra * 0.5
        else:
            stats["taper"] += 1
        # each edge's room; what one side cannot take, the other may
        le = min(want_e, ge.s1 - ge.s0 - MIN_DRIVE + before, ge.len * END_SHARE)
        lf = min(want_f, gf.s1 - gf.s0 - MIN_DRIVE + after, gf.len * END_SHARE)
        le, lf = max(le, before), max(lf, after)
        short = (want_e + want_f) - (le + lf)
        if short > 0:
            le = max(le, min(le + short, ge.s1 - ge.s0 - MIN_DRIVE + before, ge.len * END_SHARE))
            lf = max(lf, min(lf + (want_e + want_f) - (le + lf), gf.s1 - gf.s0 - MIN_DRIVE + after, gf.len * END_SHARE))
        # a signal's stop line stays on its edge with room for a car before it, and a bus stop
        # where a bus still pulls in by its shelter (buses.gd clamps it to s0 + 8 .. s1 - 4)
        if i in stops:
            lines, bus = stops[i]
            last = max([v + LINE_CLEAR for v in lines] + [v + BUS_AFTER for v in bus], default=None)
            if last is not None:
                le = max(before, min(le, ge.len - last))
        if f in stops:
            lines, bus = stops[f]
            first = min([v - LINE_BEFORE for v in lines] + [v - BUS_BEFORE for v in bus], default=None)
            if first is not None:
                lf = max(after, min(lf, first))
        # the road may not bend much more inside the link than at the node itself
        bend_cap = max(BEND_MAX, abs(turn) + 0.02)
        for _ in range(40):
            d0 = ge.direction(max(ge.len - le, 0.01))
            d1 = gf.direction(min(lf, gf.len - 0.01))
            if abs(ll.angle(d0, d1)) <= bend_cap or (le <= before + 1e-6 and lf <= after + 1e-6):
                break
            le = max(before, le * 0.85)
            lf = max(after, lf * 0.85)
        if le <= before + 0.05 and lf <= after + 0.05:
            stats["no_room"] += 1
            continue
        # an edge end belongs to one node, so each key is set once; the Edge objects take the new
        # trims at once, so a later join on the same edge sees what is left to drive
        v1 = round(ge.len - le, TRIM_ROUND)
        v0 = round(lf, TRIM_ROUND)
        trims[(i, "s1")] = v1
        trims[(f, "s0")] = v0
        ge.s1 = min(ge.s1, v1)
        gf.s0 = max(gf.s0, v0)
        stats["stretched"] += 1
        if listing is not None:
            p = ge.P[-1]
            listing.append("--at=%.0f,%.0f  %s: %d into %d lanes, %.1f m aside, link %.1f -> %.1f m (%s)"
                           % (p[0], p[1], edges[i].get("name") or "(no name)", ge.n, gf.n, shift,
                              before + after, le + lf, "taper" if te or tf else "paint"))
    return trims, stats


def abrupt(edges, G, outs, rev):
    """[(e, f, shift, span)] of the continuation links that still move a lane over more steeply
    than 1:RATE (the measure --check ratchets; road_truth R1 and R3 judge the same)."""
    found = []
    for i, f, turn in joins(edges, G, outs, rev):
        ge, gf = G[i], G[f]
        pairs = lanes_of(edges, i, f, ge, gf, turn)
        if not pairs:
            continue
        shift = shift_of(ge, gf, pairs)
        span = link_len(edges[i], edges[f], ge, gf)
        if shift > JUMP and span < RATE * shift:
            found.append((i, f, shift, span))
    return found


def apply(out, listing=None, force=False):
    """Stretches the jumping continuation links of the finished map in place; one-line summary."""
    if int(out.get(KEY, 0)) >= VERSION and not force:
        return "already done"
    edges, G, outs, rev = ll.build(out)
    before = len(abrupt(edges, G, outs, rev))
    drawn = Drawn(out)
    trims, stats = plan(edges, G, outs, rev, drawn, listing, out)
    for (i, key), v in trims.items():
        e = edges[i]
        old = float(e[key])
        nv = min(old, v) if key == "s1" else max(old, v)
        if abs(nv - old) > 1e-6:
            e.setdefault(key + "o", old)   # lane_links judges its links at the bake's own trims
            e[key] = nv
    edges, G, outs, rev = ll.build(out)
    after = len(abrupt(edges, G, outs, rev))
    out[KEY] = VERSION
    return ("%d continuation links jumped a lane sideways: %d stretched over the drawn taper, %d as a painted change, "
            "%d without room; abrupt %d -> %d"
            % (stats["jumps"], stats["taper"], stats["paint"], stats["no_room"], before, after))


def check(out):
    if int(out.get(KEY, 0)) < VERSION:
        print("lane_changes: the map does not carry the pass (run python3 -I tools/lane_changes.py)")
        return 1
    edges, G, outs, rev = ll.build(out)
    n = len(abrupt(edges, G, outs, rev))
    if n > CHECK_ABRUPT:
        print("lane_changes: %d continuation links move a lane over steeper than 1:%.0f (ratchet %d)" % (n, RATE, CHECK_ABRUPT))
        return 1
    print("lane_changes: OK (%d abrupt continuation links, ratchet %d)" % (n, CHECK_ABRUPT))
    return 0


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    path = args[0] if args else os.path.join(TOOLS, "..", "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        out = json.load(fh)
    if "--check" in argv:
        return check(out)
    listing = [] if "--list" in argv else None
    print("lane_changes: " + apply(out, listing, force="--force" in argv))
    for line in listing or []:
        print(line)
    if "--dry" not in argv:
        with open(path, "w", encoding="utf-8") as fh:
            json.dump(out, fh, ensure_ascii=False, separators=(",", ":"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
