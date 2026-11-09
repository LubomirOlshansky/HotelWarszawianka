"""Main's real road bugs (F, 2026-11-07: "main as base, small fixes"), fixed once for the whole map
on the finished map data, after tools/road_smooth.py. Nothing is redesigned: main's medians, islands,
arrows, cycle paths and lanes stay; only paint that is in the wrong place moves or goes.

    python3 -I tools/road_fixes.py [MAP.json] [--dry]
        fixes the map in place (idempotent: a map already fixed is left alone); --dry measures only.
    python3 -I tools/road_fixes.py --check [MAP.json]
        exit 1 unless the map is fixed and what is left is at most the CHECK_* ratchets (verify.sh
        step `fixes`; lower them when a change leaves fewer, never raise them).

The bugs (seen on the GUGiK photo against main at Marszałkowska x Królewska, Świętokrzyska x
Mazowiecka and x Jasna, docs/BACKLOG.md "Main's real bugs"), and what this does about each:

1. Lane lines through the junction (the photo: lines end at the stop line or the zebra, the box is
   bare). bake_roads cuts a street's lines only where another street's ribbon crosses them, so the
   strip between a junction's zebra (or stop line) and the junction kept its lane lines, and lines
   stitched or moved by road_smooth ran on into the box. Cut here: every lane, centre, solid and bus
   line, running along the street, between a zebra or stop line and the junction it guards (the
   "mouth": out to the last junction node of that crossing within MOUTH_REACH), and on another main
   street's ribbon crossing it (the box). A roundabout's own ring keeps its lines.
2. Turn arrows past the zebra (painted in the mouth, even on the stripes): an arrow there pointing
   into the junction goes back behind the zebra and the stop line in front of it (ARROW_BACK), or,
   where its lane already has an arrow there or there is no asphalt, is dropped.
3. Zebras that cover one carriageway of a dual one (the photo: kerb to median, then median to kerb):
   where a zebra ends at a median, island or tram bed at most PARTNER_GAP wide and the same street's
   other carriageway on its line has no zebra, that carriageway gets its piece, kerb to median. Ends
   still short of the kerb run on to it (as road_smooth.extend_zebras, with the same tests), and
   zebras under 1 m long (dots left by the asphalt clip, drawn as nothing) go.
4. Cycle crossings that are short red bars over part of the road (the photo: one band across the
   street beside the zebra): a cycle crossing beside a zebra runs on along its line over the asphalt
   as far as that zebra reaches, and a free end left in the middle of the asphalt runs on to the kerb.

5. Site fixes (SITES), where F pointed at one street: Andersa by Ratusz Arsenał (2026-11-07, F's
   screenshot), where the 4-lane street splits into its two carriageways round the median north of
   the junction. The kerb jogged out by the split (each OSM way's own width), the asphalt had a notch
   beside the tram stop where the 2-lane way met the 4-lane one, and the lane lines broke off, drifted
   and started again off line. Per F's lesson (kerbs stay straight, lanes change by paint): in the
   site's street frame the kerbs, the edge lines beside them and the lane lines are cut out of a
   stretch and joined again by one smooth curve (matching each stub's position and heading), the
   centre line runs on to the median's nose, and asphalt fills cover the ground between the old
   ribbons and the new kerbs. Shelters, platforms and the median are not touched.
   The same split elsewhere is found by itself (auto_sites: a two-way main way meeting two one-way
   ways of the same street, no other street there) and fixed the same way, side by side, all or
   nothing: a side whose new kerb would sit inside the asphalt, or whose fill would reach a tram bed
   or platform, keeps its old lines; lane lines are joined only where they pair up across the split.

6. Splits redrawn (fix_splits; F, 2026-11-08, two screenshots on Świętokrzyska between the metro
   and Rondo ONZ: doubled and crossed lane lines, a notch, a bike lane's red band jumping). OSM ends a
   street's two-way way and its two one-way carriageways at one node on the axis, so the legs fanned
   out from the middle of the wide street. Each such split is redrawn from its cross-sections: the
   wide street's kerbs, edge lines, bike lanes and lane lines each join the same line of their leg
   past the median's nose by one smooth curve, the centre line ends at the nose, the legs' inner
   kerbs meet there, and asphalt fills the ground up to the new kerbs. Where chevrons are painted on
   the nose, the inner edge lines meet at their tip and the centre line ends there; where one outer
   kerb already runs whole through the split, it stays and only the other side is redrawn (F,
   2026-11-08: "look for the similar pattern in other places": 27 splits). Forks (a leg turning
   away), splits with a mapped median, island, other hatching or a stop line before the ribbons
   part, and any split where a new kerb would leave asphalt outside it or new lines would cross
   others stay as they were.
   Round 2 (2026-11-09, the 33 left; Waryńskiego by Polna, three splits, worst): chevrons with their
   closed outline painted from the node on are the nose (nothing inside them is cut, the legs' edge
   lines ending on their outline stay); a stop line on a leg just before the nose (the legs reach a
   junction) is kept and the new lane lines end short of it; a side street's mouth in the old kerb
   stays open in the new one; asphalt that was already outside the old kerb does not stop a side;
   the legs' lines are picked up 8, 5 or 3 m past the nose (fewest lane lines left without a
   partner); new lines may meet others within SPLIT_TIP_R of the nose's tip.
   `--check` measures every split (split_defects: paint across the street, kerb gaps, loose line ends).

The dark patches in junction boxes (bug 5 in BACKLOG) are not in the game: every ribbon, area and
fill is one opaque colour at one height. They came from the flat comparison pictures, which draw the
ribbons half transparent over the photo, so two overlapping ribbons look darker there.

Deterministic, standard library only. Re-run tools/bake_sectors.py and bake_city.gd after it.
"""
import json
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import road_smooth as RS  # noqa: E402  (the asphalt tests, the tram beds, the polyline helpers)
import map_shape  # noqa: E402  (the map's outline: nothing runs on past it)

VERSION = 4  # 1: the whole-map fixes 1-4; 2: the site fixes (5); 3: the splits redrawn (6); 4: fix 6 round 2
# --check ratchets (2026-11-07, the whole map after the first pass). Lower them, never raise them.
CHECK_MOUTH_M = 5      # m of lane, centre, solid or bus line left in a junction's mouth
CHECK_BOX_M = 0        # m of such lines left on another main street's ribbon
CHECK_ARROWS = 0       # arrows left in a mouth pointing into the junction
CHECK_PARTNERS = 0     # dual carriageways crossed on one side only
CHECK_DOTS = 0         # zebras under 1 m
CHECK_SHORT_CYCLE = 1  # cycle crossings beside a zebra that stop short of it
CHECK_SITE_GAPS = 0    # m of a site's kerb stretch where no single kerb runs on (a jog or a notch)
# 2026-11-08, the whole map after fix 6 (split_defects; the forks and splits it leaves as they were
# keep theirs: lower these when a change fixes more of them)
CHECK_SPLIT_FAN_M = 105      # m of paint or kerb running across the street between a split's node and nose
CHECK_SPLIT_GAP_M = 510      # m of a split's outer edges with no kerb (the notch)
CHECK_SPLIT_ENDS = 86        # lane, centre and edge lines ending in the road inside a split

MINOR = {"service", "living_street"}
MAIN = {"motorway", "trunk", "primary", "secondary", "tertiary",
        "motorway_link", "trunk_link", "primary_link", "secondary_link", "tertiary_link"}
CUT_KINDS = ("lane", "centre", "solid", "bus")
ZEBRA_HALF = 1.8      # m: map_builder paints a zebra's stripes 3.6 m wide
ZEBRA_GAP = 0.6       # m: lines stop this far short of the stripes (bake_roads ZEBRA_GAP)
STOP_GAP = 0.3        # m: and this far past a stop line
MOUTH_REACH = 30.0    # m from a zebra or stop line to the junction node it guards...
MOUTH_GAP = 12.0      # ...with at most this much road between its far edge and the crossing street's
                      # ribbon (a crossing further out is mid-block: the lines carry on to the junction)...
MOUTH_GAP_SIGNAL = 20.0  # ...or this much at a signalised crossing (a stop line and a zebra together)
T_SLACK = 10.0        # m: a junction node this far past either end of a crossing still lies ahead of it
PAIR_REACH = 14.0     # m: a stop line and a zebra this near, parallel and side by side, are one crossing
NODE_STEP = 22.0      # m: the next junction node of the same crossing (a dual carriageway's other half)
ALONG_COS = 0.7       # a line runs along the street (cut in a mouth) when this parallel to its axis
CROSS_COS = 0.9       # another street's ribbon crosses a line when less parallel than this
BOX_INSET = 0.3       # m inside that ribbon's edge before a line is cut
LINE_STEP = 0.25      # m between samples along a line
LINE_MIN = 2.0        # m: a shorter piece left by a cut is dropped
CUT_MIN = 3.0         # m: a shorter cut in the middle of a line is not made
ARROW_BACK = 6.0      # m behind the zebra's (or stop line's) far edge an arrow is moved to
ARROW_LANE = 1.2      # m aside: the same lane
ARROW_NEAR = 8.0      # m: an arrow of that lane this close to the target already marks it
PARTNER_GAP = 8.0     # m: a median, island or tram bed this wide or less between two carriageways
PARTNER_RUN = 2.0     # m: the far carriageway at least this wide on the zebra's line
PARTNER_SEEN = 4.0    # m: a zebra this close to the far carriageway's middle already crosses it
EDGE_KEEP = 0.3       # m a zebra or cycle crossing stops short of the asphalt's edge
RUN_ON = 8.0          # m an end may run on to reach the kerb
CYCLE_BESIDE = 4.5    # m: a cycle crossing this far from a zebra's line, parallel, is beside it
CYCLE_COS = 0.94
SHORT_LEFT = 1.5      # m: a cycle crossing still this much shorter than its zebra (on no asphalt) is short
CYCLE_LINK = 1.0      # m: a cycle crossing's end this close to another's or a cycle path's is not free


def _ground(item):
    return int(item.get("dk", -1)) < 0


def _unit(a, b):
    return RS.unit(a, b)


def _chord(p):
    q = RS.pts_of(p["p"])
    return q[0], q[-1]


class Ribbons:
    """The ground's main and minor street ribbons as capsules (the drawn width, `c`/`cv` offsets),
    with each piece's road index and direction, on a 16 m grid."""

    def __init__(self, out, keep):
        self.grid = defaultdict(list)
        for ri, r in enumerate(out["roads"]):
            if not _ground(r) or not keep(r):
                continue
            q = RS.pts_of(r["p"])
            wv, cv = r.get("wv"), r.get("cv")
            for i in range(len(q) - 1):
                a, b = q[i], q[i + 1]
                u = _unit(a, b)
                if u is None:
                    continue
                w = min(wv[i], wv[i + 1]) if wv else r["w"]
                c = (cv[i] + cv[i + 1]) / 2 if cv else r.get("c", 0.0)
                nx, nz = -u[1], u[0]
                a2 = (a[0] + nx * c, a[1] + nz * c)
                b2 = (b[0] + nx * c, b[1] + nz * c)
                piece = (a2, b2, w / 2, ri, u)
                for cx in range(int(math.floor((min(a2[0], b2[0]) - w) / 16)), int(math.floor((max(a2[0], b2[0]) + w) / 16)) + 1):
                    for cz in range(int(math.floor((min(a2[1], b2[1]) - w) / 16)), int(math.floor((max(a2[1], b2[1]) + w) / 16)) + 1):
                        self.grid[(cx, cz)].append(piece)

    def at(self, x, z, inset=0.0):
        """The pieces whose ribbon holds (x, z), at least `inset` inside the edge."""
        out = []
        for a, b, hw, ri, u in self.grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()):
            if RS.seg_dist((x, z), a, b) < hw - inset:
                out.append((a, b, hw, ri, u))
        return out


def junction_nodes(out):
    """Junction nodes: points where ground streets (not service roads) of at least two names meet,
    or three or more ends and passes of them. {(x, z): set of road indices}."""
    at = defaultdict(list)
    for ri, r in enumerate(out["roads"]):
        if not _ground(r) or r["k"] in MINOR:
            continue
        p = RS.pts_of(r["p"])
        for j, (x, z) in enumerate(p):
            at[(round(x, 1), round(z, 1))].append((ri, 1 if j in (0, len(p) - 1) else 2))
    nodes = {}
    for key, refs in at.items():
        names = {out["roads"][ri]["name"] for ri, _ in refs if out["roads"][ri]["name"]}
        degree = sum(n for _, n in refs)
        if len(names) >= 2 or degree >= 3:
            nodes[key] = {ri for ri, _ in refs}
    return nodes


def _rondo(out, ri):
    return out["roads"][ri]["name"].startswith("Rondo")


def mouths(out, nodes, ribbons):
    """Every zebra's and stop line's mouth: (a, b, n, d0, d1, t0, t1, kind, stop) where a->b is its chord,
    n the unit normal towards the junction, the mouth the points P with t = (P-a).u in [t0, t1] and
    d = (P-a).n in (d0, d1]."""
    node_grid = defaultdict(list)
    for key in nodes:
        node_grid[(int(key[0] // 40), int(key[1] // 40))].append(key)

    def near_nodes(x, z, r):
        cx, cz = int(x // 40), int(z // 40)
        k = int(r // 40) + 1
        for i in range(cx - k, cx + k + 1):
            for j in range(cz - k, cz + k + 1):
                for key in node_grid.get((i, j), ()):
                    if math.dist(key, (x, z)) <= r:
                        yield key

    crossings = []
    for p in out.get("paths", []):
        if p["k"] == "zebra" and _ground(p):
            crossings.append((_chord(p), ZEBRA_HALF + ZEBRA_GAP, "zebra"))
    for m in out.get("markings", []):
        if m["k"] == "stop" and _ground(m):
            crossings.append((_chord(m), STOP_GAP, "stop"))
    # A signalised crossing's stop line stands before its zebra: the junction is on the zebra's
    # side of the stop line, and on the side of the zebra away from the stop line.
    cgrid = defaultdict(list)
    for k, ((a, b), half, kind) in enumerate(crossings):
        cgrid[(int(((a[0] + b[0]) / 2) // 20), int(((a[1] + b[1]) / 2) // 20))].append(k)

    def facing(k, a, b, u, n0, kind):
        """+1 / -1: the junction lies along +n0 / -n0 (a stop line and its zebra say so); 0: unknown."""
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        L = math.dist(a, b)
        vote = 0.0
        stops = [0.0, 0.0]   # the farthest stop line behind it on the +n0 / -n0 side
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for o in cgrid.get((int(mid[0] // 20) + i, int(mid[1] // 20) + j), ()):
                    (oa, ob), _, okind = crossings[o]
                    if okind == kind:
                        continue
                    ol = math.dist(oa, ob)
                    if ol < 1.0:
                        continue
                    ou = ((ob[0] - oa[0]) / ol, (ob[1] - oa[1]) / ol)
                    if abs(ou[0] * u[0] + ou[1] * u[1]) < 0.9:
                        continue
                    om = ((oa[0] + ob[0]) / 2, (oa[1] + ob[1]) / 2)
                    off = (om[0] - a[0]) * n0[0] + (om[1] - a[1]) * n0[1]
                    t = (om[0] - a[0]) * u[0] + (om[1] - a[1]) * u[1]
                    if not 0.5 <= abs(off) <= PAIR_REACH or t < -1.0 or t > L + 1.0:
                        continue
                    # a stop line votes for the zebra's side; a zebra for the side away from its stop line
                    vote += math.copysign(1.0, off) * (1.0 if kind == "stop" else -1.0)
                    if okind == "stop":
                        side_i = 0 if off > 0 else 1
                        stops[side_i] = max(stops[side_i], abs(off))
        side = 0 if vote == 0 else (1 if vote > 0 else -1)
        # the stop line stands on the side away from the junction
        return side, (stops[1] if side > 0 else stops[0]) if side else 0.0

    found = []
    for k, ((a, b), half, kind) in enumerate(crossings):
        L = math.dist(a, b)
        if L < 1.0:
            continue
        u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        n0 = (-u[1], u[0])
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        # the street it crosses: the ribbons under its middle running across it
        under = [pc for pc in ribbons.at(*mid) if abs(pc[4][0] * u[0] + pc[4][1] * u[1]) < 0.6
                 and out["roads"][pc[3]]["k"] not in MINOR]
        if not under:
            continue
        roads = {pc[3] for pc in under}
        if any(_rondo(out, ri) for ri in roads):
            continue
        # (by name: the way under a crossing often ends at a join short of the junction)
        rnames = {out["roads"][ri]["name"] for ri in roads}
        side, stop_back = facing(k, a, b, u, n0, kind)
        gap_max = MOUTH_GAP_SIGNAL if side else MOUTH_GAP
        # the junction it guards: the nearest node on that street ahead of it (on its side, if known)
        best = None
        for key in near_nodes(mid[0], mid[1], MOUTH_REACH):
            if not (nodes[key] & roads or rnames & {out["roads"][ri]["name"] for ri in nodes[key]} - {""}):
                continue
            d = (key[0] - a[0]) * n0[0] + (key[1] - a[1]) * n0[1]
            t = (key[0] - a[0]) * u[0] + (key[1] - a[1]) * u[1]
            if abs(d) <= half or t < -T_SLACK or t > L + T_SLACK or d * side < 0:
                continue
            others = [out["roads"][ri] for ri in nodes[key] if ri not in roads and out["roads"][ri]["name"] not in rnames]
            box = max((r["w"] * 0.5 + abs(r.get("c", 0.0)) for r in others), default=0.0)
            if abs(d) - box - half > gap_max:
                continue
            if best is None or abs(d) < abs(best[0]):
                best = (d, key)
        if best is None:
            continue
        sg = 1.0 if best[0] > 0 else -1.0
        n = (n0[0] * sg, n0[1] * sg)
        # out to the last node of the same crossing (a dual carriageway's other half)
        names = {out["roads"][ri]["name"] for ri in nodes[best[1]] if ri not in roads} - rnames - {""}
        reach = abs(best[0])
        last = best[1]
        while True:
            nxt = None
            for key in near_nodes(last[0], last[1], NODE_STEP):
                d = (key[0] - a[0]) * n[0] + (key[1] - a[1]) * n[1]
                t = (key[0] - a[0]) * u[0] + (key[1] - a[1]) * u[1]
                if d <= reach + 0.5 or d > MOUTH_REACH + NODE_STEP or t < -T_SLACK or t > L + T_SLACK:
                    continue
                if not names & {out["roads"][ri]["name"] for ri in nodes[key]}:
                    continue
                if nxt is None or d < nxt[0]:
                    nxt = (d, key)
            if nxt is None:
                break
            reach, last = nxt
        found.append((a, b, n, half, reach, -0.5, L + 0.5, kind, stop_back))
    return found


class MouthIndex:
    def __init__(self, ms):
        self.ms = ms
        self.grid = defaultdict(list)
        for k, (a, b, n, d0, d1, t0, t1, kind, stop) in enumerate(ms):
            xs = [a[0], b[0], a[0] + n[0] * d1, b[0] + n[0] * d1]
            zs = [a[1], b[1], a[1] + n[1] * d1, b[1] + n[1] * d1]
            for cx in range(int(math.floor((min(xs) - 1) / 16)), int(math.floor((max(xs) + 1) / 16)) + 1):
                for cz in range(int(math.floor((min(zs) - 1) / 16)), int(math.floor((max(zs) + 1) / 16)) + 1):
                    self.grid[(cx, cz)].append(k)

    def hit(self, x, z, along=None, d_from=None):
        """The mouth holding (x, z) (and, given `along`, whose street that direction runs along), or None.
        d_from overrides d0 (an arrow on the stripes counts too)."""
        for k in self.grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()):
            a, b, n, d0, d1, t0, t1, kind, stop = self.ms[k]
            L = math.dist(a, b)
            u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
            t = (x - a[0]) * u[0] + (z - a[1]) * u[1]
            d = (x - a[0]) * n[0] + (z - a[1]) * n[1]
            lo = d0 if d_from is None else d_from
            if t0 <= t <= t1 and lo < d <= d1:
                if along is not None and abs(along[0] * n[0] + along[1] * n[1]) < ALONG_COS:
                    continue
                return k
        return None


def in_box(out, main_ribbons, x, z, d):
    """On another main street's ribbon crossing direction d (not a roundabout's ring, not a way of
    the line's own street: two ways of one street meeting at an angle are a merge, not a junction)."""
    hits = main_ribbons.at(x, z, BOX_INSET)
    if not hits or any(_rondo(out, h[3]) for h in hits):
        return False
    own = {out["roads"][h[3]]["name"] for h in main_ribbons.at(x, z) if abs(h[4][0] * d[0] + h[4][1] * d[1]) >= CROSS_COS}
    for a, b, hw, ri, u in hits:
        name = out["roads"][ri]["name"]
        if abs(u[0] * d[0] + u[1] * d[1]) < CROSS_COS and name and own and name not in own:
            return True
    return False


def cut_lines(out, mi, main_ribbons, dry=False):
    """Cuts lane, centre, solid and bus lines out of mouths and boxes. Returns (m in mouths, m in boxes)."""
    kept = []
    cut = {}
    m_mouth = m_box = 0.0
    for m in out["markings"]:
        if m["k"] not in CUT_KINDS or not _ground(m):
            kept.append(m)
            continue
        pts = RS.pts_of(m["p"])
        if len(pts) < 2:
            kept.append(m)
            continue
        flags = []
        dense = []
        for a, b in zip(pts, pts[1:]):
            u = _unit(a, b)
            L = math.dist(a, b)
            if u is None:
                continue
            k = max(1, int(math.ceil(L / LINE_STEP)))
            for i in range(k):
                x, z = a[0] + (b[0] - a[0]) * i / k, a[1] + (b[1] - a[1]) * i / k
                dense.append((x, z))
                if mi.hit(x, z, u) is not None:
                    flags.append("m")
                    m_mouth += L / k
                elif in_box(out, main_ribbons, x, z, u):
                    flags.append("b")
                    m_box += L / k
                else:
                    flags.append("")
        if not dense:
            kept.append(m)
            continue
        dense.append(pts[-1])
        flags.append(flags[-1])
        # a short flagged stretch with paint on both sides is a line grazing a mouth's or a box's
        # corner: cutting it would only break the line (road_smooth's line jogs)
        i = 0
        while i < len(flags):
            if not flags[i]:
                i += 1
                continue
            j = i
            while j < len(flags) and flags[j]:
                j += 1
            if i > 0 and j < len(flags) and (j - i) * LINE_STEP < CUT_MIN:
                for k in range(i, j):
                    if flags[k] == "m":
                        m_mouth -= LINE_STEP
                    else:
                        m_box -= LINE_STEP
                    flags[k] = ""
            i = j
        if dry or not any(flags):
            kept.append(m)
            continue
        run = []
        cut[id(m)] = (m, [])
        for p, f in zip(dense, flags):
            if f:
                if len(run) >= 2 and RS.length(run) >= LINE_MIN:
                    kept.append(dict(m, p=RS.flat_of(RS.simplify(run, 0.002))))
                    cut[id(m)][1].append(kept[-1])
                run = []
            else:
                run.append(p)
        if len(run) >= 2 and RS.length(run) >= LINE_MIN:
            kept.append(dict(m, p=RS.flat_of(RS.simplify(run, 0.002))))
            cut[id(m)][1].append(kept[-1])
    if dry:
        return round(m_mouth), round(m_box)
    # A cut end that now reads as a line jog (another lane's line starting just aside: road_smooth's
    # K2 check) means the line was a turn's guide stitched to its neighbour: that line stays whole.
    before = _jog_ends(out["markings"])
    piece_of = {id(q): orig for orig, pieces in cut.values() for q in pieces}
    cut_ends = defaultdict(list)
    for orig, pieces in cut.values():
        for last in (False, True):
            p, _ = RS._line_end(orig, last)
            cut_ends[(round(p[0]), round(p[1]))].append((p, orig))
    restore = set()
    for i, last, j, lj, along, side in RS.jogs(kept):
        if abs(side) <= RS.STEP_MIN:
            continue
        for k, end in ((i, last), (j, lj)):
            if _end_key(kept[k], end) in before:
                continue
            orig = piece_of.get(id(kept[k]))
            if orig is not None:
                restore.add(id(orig))
            # ...and the line it carried on into, if the cut took it
            p, _ = RS._line_end(kept[k], end)
            for dx in (-1, 0, 1):
                for dz in (-1, 0, 1):
                    for q, o in cut_ends.get((round(p[0]) + dx, round(p[1]) + dz), ()):
                        if math.dist(p, q) < 0.5:
                            restore.add(id(o))
    if restore:
        keep2 = []
        for q in kept:
            orig = piece_of.get(id(q))
            if orig is not None and id(orig) in restore:
                if q is cut[id(orig)][1][0]:
                    keep2.append(orig)
                    length = RS.length(RS.pts_of(orig["p"])) - sum(RS.length(RS.pts_of(x["p"])) for x in cut[id(orig)][1])
                    m_mouth -= max(0.0, length)
                continue
            keep2.append(q)
        # a restored line whose every piece was too short to keep
        for oid in restore - {id(piece_of[id(q)]) for q in kept if id(q) in piece_of}:
            keep2.append(cut[oid][0])
        kept = keep2
    out["markings"] = kept
    return round(m_mouth), round(m_box)


def _end_key(m, last):
    p, _ = RS._line_end(m, last)
    return (m["k"], round(p[0], 1), round(p[1], 1))


def _jog_ends(marks):
    """The line ends road_smooth already counts as jogs (they stay as they are)."""
    out = set()
    for i, last, j, lj, along, side in RS.jogs(marks):
        if abs(side) <= RS.STEP_MIN:
            continue
        out.add(_end_key(marks[i], last))
        out.add(_end_key(marks[j], lj))
    return out


def move_arrows(out, mi, asphalt, dry=False):
    """Arrows in a mouth (or on its stripes) pointing into the junction go back behind the zebra or
    stop line, or are dropped. Returns (moved, dropped, left)."""
    syms = out.get("symbols", [])
    arrows = [s for s in syms if s["k"] == "arrow" and _ground(s)]
    moved = dropped = 0
    drop = set()
    for s in arrows:
        k = mi.hit(s["x"], s["z"], d_from=-ZEBRA_HALF - 0.5)
        if k is None:
            continue
        a, b, n, d0, d1, t0, t1, kind, stop = mi.ms[k]
        dx, dz = s["d"]
        cosn = dx * n[0] + dz * n[1]
        if cosn < 0.5:
            continue
        d = (s["x"] - a[0]) * n[0] + (s["z"] - a[1]) * n[1]
        back = (d + max(d0, stop + STOP_GAP) + ARROW_BACK) / cosn
        tx, tz = s["x"] - dx * back, s["z"] - dz * back
        # behind the stop line too, where it stands further back than the zebra's mouth reaches
        for _ in range(3):
            k2 = mi.hit(tx, tz, d_from=-ZEBRA_HALF - 0.5)
            if k2 is None:
                break
            a2, b2, n2, d02, d12, t02, t12, kind2, stop2 = mi.ms[k2]
            c2 = dx * n2[0] + dz * n2[1]
            if c2 < 0.5:
                break
            back2 = ((tx - a2[0]) * n2[0] + (tz - a2[1]) * n2[1] + d02 + ARROW_BACK) / c2
            tx, tz = tx - dx * back2, tz - dz * back2
        if dry:
            moved += 1
            continue
        lane = any(o is not s and id(o) not in drop and o["d"][0] * dx + o["d"][1] * dz > 0.9
                   and abs((o["x"] - tx) * -dz + (o["z"] - tz) * dx) < ARROW_LANE
                   and abs((o["x"] - tx) * dx + (o["z"] - tz) * dz) < ARROW_NEAR for o in arrows)
        if lane or not asphalt(tx, tz) or mi.hit(tx, tz, d_from=-ZEBRA_HALF - 0.5) is not None:
            drop.add(id(s))
            dropped += 1
            continue
        s["x"], s["z"] = round(tx, 2), round(tz, 2)
        moved += 1
    if drop:
        out["symbols"] = [s for s in syms if id(s) not in drop]
    return moved, dropped


def _tests(out):
    """The asphalt and raised tests, the asphalt only inside the map's outline (a crossing run on
    to the kerb never leaves the map: check_outline O1)."""
    asphalt, raised = RS._street_tests(out)
    shape = map_shape.of(out)
    return (lambda x, z: shape.contains(x, z) and asphalt(x, z)), raised


def _run_from(test, x, z, ux, uz, limit, step=0.25):
    """How far from (x, z) along (ux, uz) test() holds (sampled every step), at most limit."""
    t = 0.0
    while t < limit and test(x + ux * (t + step), z + uz * (t + step)):
        t += step
    return t


def fix_zebras(out, asphalt, raised, on_bed, ribbons, dry=False):
    """Drops dot zebras, runs short ends on to the kerb, adds the other carriageway's piece.
    Returns (dots, metres run on, pieces added)."""
    paths = out["paths"]
    road = lambda x, z: asphalt(x, z) and not raised(x, z)  # noqa: E731
    dots = [p for p in paths if p["k"] == "zebra" and RS.length(RS.pts_of(p["p"])) < 1.0]
    if not dry:
        out["paths"] = paths = [p for p in paths if not (p["k"] == "zebra" and RS.length(RS.pts_of(p["p"])) < 1.0)]
    zebras = [p for p in paths if p["k"] == "zebra" and _ground(p)]
    run_on = 0.0
    for p in zebras:
        q = RS.pts_of(p["p"])
        for end, prev in ((len(q) - 1, len(q) - 2), (0, 1)):
            u = _unit(q[prev], q[end])
            if u is None:
                continue
            t = _run_from(road, q[end][0], q[end][1], u[0], u[1], RUN_ON)
            if t - EDGE_KEEP >= 0.5 and RS._in_map(out, q[end][0] + u[0] * t, q[end][1] + u[1] * t):
                run_on += t - EDGE_KEEP
                q[end] = (q[end][0] + u[0] * (t - EDGE_KEEP), q[end][1] + u[1] * (t - EDGE_KEEP))
        if not dry:
            p["p"] = RS.flat_of(q)
    # the other carriageway
    segs = [_chord(p) for p in zebras]
    grid = defaultdict(list)
    for k, (a, b) in enumerate(segs):
        for cx in range(int(math.floor(min(a[0], b[0]) / 16)) - 1, int(math.floor(max(a[0], b[0]) / 16)) + 2):
            for cz in range(int(math.floor(min(a[1], b[1]) / 16)) - 1, int(math.floor(max(a[1], b[1]) / 16)) + 2):
                grid[(cx, cz)].append(k)

    def crossed(x, z):
        return any(RS.seg_dist((x, z), *segs[k]) < PARTNER_SEEN for k in grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()))

    def names(x, z):
        return {out["roads"][h[3]]["name"] for h in ribbons.at(x, z) if out["roads"][h[3]]["k"] not in MINOR} - {""}

    added = []
    for p, (a, b) in zip(zebras, segs):
        L = math.dist(a, b)
        if L < 1.0:
            continue
        u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        mine = names((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
        if not mine:
            continue
        for e, s in ((b, 1.0), (a, -1.0)):
            ux, uz = u[0] * s, u[1] * s
            # across a median, island or tram bed: never across bare pavement or a building
            t = EDGE_KEEP
            ok = True
            while t < PARTNER_GAP + EDGE_KEEP and not road(e[0] + ux * t, e[1] + uz * t):
                x, z = e[0] + ux * t, e[1] + uz * t
                if not (raised(x, z) or on_bed(x, z)):
                    ok = False
                    break
                t += 0.25
            if not ok or t >= PARTNER_GAP + EDGE_KEEP or t < 0.5:
                continue
            g = t
            t = g + _run_from(road, e[0] + ux * g, e[1] + uz * g, ux, uz, 30.0)
            if t - g < PARTNER_RUN:
                continue
            s0, s1 = g + EDGE_KEEP, t - EDGE_KEEP
            mid = (e[0] + ux * (s0 + s1) / 2, e[1] + uz * (s0 + s1) / 2)
            if not (mine & names(*mid)) or crossed(*mid):
                continue
            pa = (e[0] + ux * s0, e[1] + uz * s0)
            pb = (e[0] + ux * s1, e[1] + uz * s1)
            if not (RS._in_map(out, *pa) and RS._in_map(out, *pb)):
                continue
            piece = {k: v for k, v in p.items() if k != "p"}
            piece["p"] = RS.flat_of([pa, pb])
            added.append(piece)
            segs.append((pa, pb))
            k = len(segs) - 1
            grid[(int(math.floor(mid[0] / 16)), int(math.floor(mid[1] / 16)))].append(k)
    if not dry:
        out["paths"].extend(added)
    return len(dots), round(run_on), len(added)


def fix_cycle_crossings(out, asphalt, raised, dry=False):
    """Cycle crossings beside a zebra run on as far as the zebra reaches; free ends on the asphalt run
    on to the kerb. Returns (beside ones lengthened, free ends run on, metres added, short left)."""
    road = lambda x, z: asphalt(x, z) and not raised(x, z)  # noqa: E731
    paths = out["paths"]
    zebras = [_chord(p) for p in paths if p["k"] == "zebra" and _ground(p)]
    zgrid = defaultdict(list)
    for k, (a, b) in enumerate(zebras):
        zgrid[(int(((a[0] + b[0]) / 2) // 30), int(((a[1] + b[1]) / 2) // 30))].append(k)
    ends = defaultdict(list)
    for p in paths:
        if p["k"] in ("cycle", "cyclecross") and _ground(p):
            q = RS.pts_of(p["p"])
            for e in (q[0], q[-1]):
                ends[(int(e[0] // 4), int(e[1] // 4))].append((e, id(p)))
    # a cycle path running along the street touches the crossing's middle, not just its ends
    cyc_segs = defaultdict(list)
    for p in paths:
        if p["k"] == "cycle" and _ground(p):
            q = RS.pts_of(p["p"])
            for s0, s1 in zip(q, q[1:]):
                cyc_segs[(int(((s0[0] + s1[0]) / 2) // 30), int(((s0[1] + s1[1]) / 2) // 30))].append((s0, s1, id(p)))

    def linked(e, me):
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for o, pid in ends.get((int(e[0] // 4) + i, int(e[1] // 4) + j), ()):
                    if pid != me and math.dist(o, e) < CYCLE_LINK:
                        return True
        cx, cz = int(e[0] // 30), int(e[1] // 30)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for s0, s1, pid in cyc_segs.get((cx + i, cz + j), ()):
                    if pid != me and RS.seg_dist(e, s0, s1) < CYCLE_LINK:
                        return True
        return False

    beside = free = 0
    added = 0.0
    short = 0
    for p in paths:
        if p["k"] != "cyclecross" or not _ground(p):
            continue
        q = RS.pts_of(p["p"])
        a, b = q[0], q[-1]
        L = math.dist(a, b)
        if L < 1.0:
            continue
        u = ((b[0] - a[0]) / L, (b[1] - a[1]) / L)
        n = (-u[1], u[0])
        mx, mz = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        # the zebra beside it: parallel, its line within CYCLE_BESIDE, overlapping along it
        want0, want1 = 0.0, L
        cx, cz = int(mx // 30), int(mz // 30)
        for i in (-1, 0, 1):
            for j in (-1, 0, 1):
                for k in zgrid.get((cx + i, cz + j), ()):
                    za, zb = zebras[k]
                    zl = math.dist(za, zb)
                    if zl < 1.0:
                        continue
                    zu = ((zb[0] - za[0]) / zl, (zb[1] - za[1]) / zl)
                    if abs(zu[0] * u[0] + zu[1] * u[1]) < CYCLE_COS:
                        continue
                    off = ((za[0] + zb[0]) / 2 - a[0]) * n[0] + ((za[1] + zb[1]) / 2 - a[1]) * n[1]
                    if abs(off) > CYCLE_BESIDE:
                        continue
                    ta = (za[0] - a[0]) * u[0] + (za[1] - a[1]) * u[1]
                    tb = (zb[0] - a[0]) * u[0] + (zb[1] - a[1]) * u[1]
                    lo, hi = min(ta, tb), max(ta, tb)
                    if hi < -1.0 or lo > L + 1.0:
                        continue
                    want0, want1 = min(want0, lo), max(want1, hi)
        grew = False
        for end, prev, want, sgn in ((len(q) - 1, len(q) - 2, want1 - L, 1.0), (0, 1, -want0, -1.0)):
            uu = _unit(q[prev], q[end])
            if uu is None:
                continue
            e = q[end]
            if linked(e, id(p)):
                continue   # it carries on as the next piece of the crossing, or as the cycle path
            if want > 0.5:
                # beside a zebra that reaches further: on along the asphalt, as far as it reaches
                t = min(_run_from(road, e[0], e[1], uu[0], uu[1], want + EDGE_KEEP) - EDGE_KEEP, want)
                if want - max(t, 0.0) > SHORT_LEFT:
                    short += 1
                if t >= 0.5:
                    q[end] = (e[0] + uu[0] * t, e[1] + uu[1] * t)
                    added += t
                    grew = True
                    beside += 1
                continue
            if road(e[0], e[1]):
                t = _run_from(road, e[0], e[1], uu[0], uu[1], RUN_ON) - EDGE_KEEP
                if t >= 0.5:
                    q[end] = (e[0] + uu[0] * t, e[1] + uu[1] * t)
                    added += t
                    grew = True
                    free += 1
        if grew and not dry:
            p["p"] = RS.flat_of(q)
    return beside, free, round(added), short


# --- 5. site fixes ---------------------------------------------------------------------------------

# Each site is a straight street frame: `a` a point on the axis, `u` the axis (north to south here),
# the normal n = (u.z, -u.x) (east of a south-running axis is +n). Stretches are in metres along the
# axis (s) and across it (n). A kerb or edge line in a side's band is cut out of [s0, s1] and joined
# again; lane and centre lines in the lane band are cut out of the lane stretch and joined in pairs,
# north stub to south stub in order across the street.
SITES = [
    {
        "name": "Andersa by Ratusz Arsenał",
        "a": (-1601.3, -1214.4), "u": (0.4854, 0.8742),
        "near": 70.0,   # m from `a`: features further away are never looked at
        # west kerb: tapers 6.5 -> 12.2 m off the axis (the third southbound lane opens by paint)
        "west": {"band": (-16.0, -4.5), "s": (-25.0, 22.0)},
        # east kerb: one straight line along the tram platform (the notch was here)
        "east": {"band": (3.0, 9.0), "s": (-5.0, 30.0)},
        "lanes": {"band": (-7.5, 5.5), "s": (-10.0, 30.0)},
        "centre_to": (16.0, -1.9),  # (s, n): the median's nose, where the centre line ends
        "fill_in": {"west": -3.5, "east": 2.5},
    },
]
SITE_STEP = 1.0  # m between the points of a joining curve


class Frame:
    def __init__(self, site):
        self.a = site["a"]
        ux, uz = site["u"]
        k = math.hypot(ux, uz)
        self.u = (ux / k, uz / k)
        self.n = (self.u[1], -self.u[0])

    def sn(self, x, z):
        dx, dz = x - self.a[0], z - self.a[1]
        return dx * self.u[0] + dz * self.u[1], dx * self.n[0] + dz * self.n[1]

    def xz(self, s, n):
        return (self.a[0] + s * self.u[0] + n * self.n[0], self.a[1] + s * self.u[1] + n * self.n[1])


def _dense(pts, step=LINE_STEP):
    out = []
    for a, b in zip(pts, pts[1:]):
        k = max(1, int(math.ceil(math.dist(a, b) / step)))
        for i in range(k):
            out.append((a[0] + (b[0] - a[0]) * i / k, a[1] + (b[1] - a[1]) * i / k))
    out.append(pts[-1])
    return out


def _site_cut(items, fr, band, s_rng, near):
    """Cuts the points in the stretch out of each polyline in `items` (in place). Returns the stubs:
    (item, piece points, end that touches the cut: 'tail' or 'head'), and the metres cut."""
    stubs = []
    cut_m = 0.0
    keep = []
    for m in items:
        pts = RS.pts_of(m["p"])
        if len(pts) < 2 or not _ground(m) or min(math.dist(p, fr.a) for p in pts) > near:
            keep.append(m)
            continue
        dense = _dense(pts)
        inside = []
        for x, z in dense:
            s, n = fr.sn(x, z)
            inside.append(s_rng[0] <= s <= s_rng[1] and band[0] <= n <= band[1])
        if not any(inside):
            keep.append(m)
            continue
        runs, run, flags = [], [], []
        for p, f in zip(dense, inside):
            if f:
                cut_m += LINE_STEP
                if run:
                    runs.append(run)
                run = []
            else:
                run.append(p)
        if run:
            runs.append(run)
        for r in runs:
            if len(r) < 2 or RS.length(r) < LINE_MIN:
                continue
            piece = dict(m, p=RS.flat_of(RS.simplify(r, 0.002)))
            keep.append(piece)
            head_cut = r[0] != dense[0]
            tail_cut = r[-1] != dense[-1]
            if tail_cut:
                stubs.append((piece, "tail"))
            if head_cut:
                stubs.append((piece, "head"))
    items[:] = keep
    return stubs, cut_m


def _stub_end(fr, piece, end):
    """The stub's end at the cut, in the frame: (s, n, dn/ds), and its direction of travel in s."""
    q = RS.pts_of(piece["p"])
    if end == "tail":
        p, b = q[-1], _back(q, True)
    else:
        p, b = q[0], _back(q, False)
    s, n = fr.sn(*p)
    sb, nb = fr.sn(*b)
    slope = (n - nb) / (s - sb) if abs(s - sb) > 0.05 else 0.0
    return s, n, slope


def _back(q, tail):
    """A point about 3 m back from the stub's cut end, for its heading."""
    seq = list(reversed(q)) if tail else list(q)
    d = 0.0
    for a, b in zip(seq, seq[1:]):
        d += math.dist(a, b)
        if d >= 3.0:
            return b
    return seq[-1]


def _hermite(fr, p0, p1):
    """Points from p0 = (s, n, dn/ds) to p1 along the axis, matching both positions and headings."""
    s0, n0, m0 = p0
    s1, n1, m1 = p1
    L = s1 - s0
    k = max(2, int(math.ceil(abs(L) / SITE_STEP)))
    out = []
    for i in range(k + 1):
        t = i / k
        h00, h10 = 2 * t ** 3 - 3 * t ** 2 + 1, t ** 3 - 2 * t ** 2 + t
        h01, h11 = -2 * t ** 3 + 3 * t ** 2, t ** 3 - t ** 2
        out.append(fr.xz(s0 + L * t, h00 * n0 + h10 * L * m0 + h01 * n1 + h11 * L * m1))
    return out


def _join(items, fr, stubs, label, notes, directed=False):
    """Joins each stub north of the cut to one south of it (in order across the street): the two
    stubs and the curve between them become one line, running the way the stubs run."""
    north = sorted([x for x in stubs if _stub_end(fr, *x)[0] < _mid(fr, stubs)], key=lambda x: _stub_end(fr, *x)[1])
    south = sorted([x for x in stubs if _stub_end(fr, *x)[0] >= _mid(fr, stubs)], key=lambda x: _stub_end(fr, *x)[1])
    if len(north) != len(south):
        notes.append(f"{label}: {len(north)} north stubs, {len(south)} south: not joined")
        return []
    made = []
    for (pa, ea), (pb, eb) in zip(north, south):
        a, b = _stub_end(fr, pa, ea), _stub_end(fr, pb, eb)
        curve = _hermite(fr, a, b)
        qa, qb = RS.pts_of(pa["p"]), RS.pts_of(pb["p"])
        # the stubs run the same way (a kerb's pavement is on its right): north to south if the north
        # stub's cut end is its tail
        if ea == "tail" and eb == "head":
            line = qa + curve[1:-1] + qb
        elif ea == "head" and eb == "tail":
            line = qb + list(reversed(curve))[1:-1] + qa
        elif directed:
            notes.append(f"{label}: stubs run opposite ways: not joined")
            continue
        elif ea == "tail":  # paint has no way: the south stub turns round
            line = qa + curve[1:-1] + list(reversed(qb))
        else:
            line = list(reversed(qa)) + curve[1:-1] + qb
        items.remove(pa)
        if pb is not pa:
            items.remove(pb)
        new = dict(pa, p=RS.flat_of(RS.simplify(line, 0.002)))
        items.append(new)
        made.append(curve)
    return made


def _mid(fr, stubs):
    ss = sorted(_stub_end(fr, *x)[0] for x in stubs)
    return (ss[0] + ss[-1]) / 2 if ss else 0.0


def site_gaps(out):
    """m of each site's kerb stretches (both sides) not covered by one kerb line running through
    the whole stretch: a jog or a notch leaves its kerb in pieces or off the band."""
    gaps = 0
    for site in SITES:
        fr = Frame(site)
        for side in ("west", "east"):
            band, (s0, s1) = site[side]["band"], site[side]["s"]
            best = 0
            for k in out.get("kerbs", []):
                q = RS.pts_of(k["p"])
                if len(q) < 2 or not _ground(k) or min(math.dist(p, fr.a) for p in q) > site["near"]:
                    continue
                hit = set()
                for x, z in _dense(q):
                    s, n = fr.sn(x, z)
                    if s0 <= s <= s1 and band[0] <= n <= band[1]:
                        hit.add(int(math.floor(s - s0)))
                best = max(best, len(hit))
            gaps += max(0, int(s1 - s0) - best)
    return gaps


def auto_sites(out, taken):
    """Site fix 5 found by itself: every mid-block split of a main street, where one two-way way
    meets two one-way ways of the same name at a node and no other street leaves there, framed
    like Andersa's (axis along the two-way way, bands from its half width). Nodes within 40 m of a
    site in `taken` are left to it."""
    ends = defaultdict(list)
    names_at = defaultdict(set)
    for i, r in enumerate(out["roads"]):
        if not _ground(r):
            continue
        q = RS.pts_of(r["p"])
        for x, z in q:
            names_at[(round(x, 1), round(z, 1))].add(r.get("name") or r["k"])
        if r["k"] not in MAIN or len(q) < 2:
            continue
        ends[(round(q[0][0], 1), round(q[0][1], 1))].append((i, 0))
        ends[(round(q[-1][0], 1), round(q[-1][1], 1))].append((i, 1))
    sites = []
    for node, lst in sorted(ends.items()):
        if len(names_at[node]) != 1 or any(math.dist(node, t) < 40 for t in taken):
            continue
        rs = [(out["roads"][i], e) for i, e in lst]
        name = rs[0][0].get("name")
        if not name or any(r.get("name") != name for r, _ in rs):
            continue
        two = [(r, e) for r, e in rs if not r["oneway"]]
        if len(two) != 1 or len(rs) != 3:
            continue
        r, e = two[0]
        q = RS.pts_of(r["p"])
        if e == 0:
            q = q[::-1]
        # a point 15 m back along the two-way way from the node
        back, d = q[-1], 0.0
        for a2, b2 in zip(reversed(q[:-1]), reversed(q[1:])):
            d += math.dist(a2, b2)
            back = a2
            if d >= 15.0:
                break
        u = _unit(back, node)
        if u is None or d < 10.0:
            continue
        h = r["w"] / 2
        inner = max(h - 3.5, 2.5)
        sites.append({
            "name": f"{name} split at {node[0]:.0f},{node[1]:.0f}", "a": node, "u": u, "near": 60.0,
            "west": {"band": (-(h + 9.5), -inner), "s": (-25.0, 25.0)},
            "east": {"band": (inner, h + 9.5), "s": (-25.0, 25.0)},
            "lanes": {"band": (-(h + 1.0), h + 1.0), "s": (-10.0, 30.0)},
            "centre_to": None,
            "fill_in": {"west": -max(h - 3.5, 0.5), "east": max(h - 3.5, 0.5)},
        })
    return sites


def _kerb_clear(out, fr, curve, ribbons, name):
    """True when the pavement side (right of travel) of a new kerb curve is off the street's own
    asphalt: a kerb drawn inside a ribbon would leave asphalt poking out past it."""
    for a, b in zip(curve, curve[1:]):
        u = _unit(a, b)
        if u is None:
            continue
        x, z = (a[0] + b[0]) / 2 - u[1] * 0.8, (a[1] + b[1]) / 2 + u[0] * 0.8
        for piece in ribbons.at(x, z, 0.1):
            if out["roads"][piece[3]].get("name") == name:
                return False
    return True


class Beds:
    """Tram beds and platforms on a 16 m grid: a new kerb or fill must keep off them."""

    def __init__(self, out):
        self.grid = defaultdict(list)
        segs = []
        for t in out.get("trams", []):
            if _ground(t) and t.get("bed"):
                q = RS.pts_of(t["p"])
                segs += [(a, b, 2.2) for a, b in zip(q, q[1:])]
        for pl in out.get("platforms", []):
            q = RS.pts_of(pl["p"])
            segs += [(a, b, 0.5) for a, b in zip(q, q[1:] + q[:1])]
        for a, b, r in segs:
            for cx in range(int(math.floor(min(a[0], b[0]) / 16)) - 1, int(math.floor(max(a[0], b[0]) / 16)) + 2):
                for cz in range(int(math.floor(min(a[1], b[1]) / 16)) - 1, int(math.floor(max(a[1], b[1]) / 16)) + 2):
                    self.grid[(cx, cz)].append((a, b, r))

    def hit(self, x, z):
        return any(RS.seg_dist((x, z), a, b) < r for a, b, r in self.grid.get((int(math.floor(x / 16)), int(math.floor(z / 16))), ()))


def _area_clear(beds, fr, curve, inner):
    """True when the strip between a new kerb and the fill's inner line keeps off tram beds."""
    for x, z in curve:
        s, n = fr.sn(x, z)
        for t in (0.0, 0.33, 0.66, 1.0):
            if beds.hit(*fr.xz(s, n + (inner - n) * t)):
                return False
    return True


def fix_sites(out):
    """The site fixes (5), F's sites then the splits found by auto_sites. Each group (a side's kerb,
    its edge line, the lane lines) is all or nothing: one that cannot be joined cleanly keeps the old
    lines. Returns (sites fixed, m of kerb and paint redrawn, notes)."""
    notes = []
    fixed = 0
    redrawn = 0.0
    ribbons = Ribbons(out, lambda r: True)
    beds = Beds(out)
    sites = list(SITES)
    sites += auto_sites(out, [s["a"] for s in SITES])
    for site in sites:
        fr = Frame(site)
        near = site["near"]
        street = site["name"].split(" split at ")[0] if " split at " in site["name"] else None
        marks = out.get("markings", [])
        edges = [m for m in marks if m["k"] == "edge"]
        lanes = [m for m in marks if m["k"] in ("lane", "centre")]
        rest = [m for m in marks if m["k"] not in ("edge", "lane", "centre")]
        new_kerb = {}
        done = 0
        for side in ("west", "east"):
            band, s_rng = site[side]["band"], site[side]["s"]
            for label in ("kerb", "edge"):
                if label == "edge" and side not in new_kerb:
                    continue
                items = out["kerbs"] if label == "kerb" else edges
                keep = list(items)
                stubs, _ = _site_cut(items, fr, band, s_rng, near)
                made = []
                if len(stubs) == 2:
                    made = _join(items, fr, stubs, f"{site['name']} {side} {label}", notes if not street else [],
                                 directed=label == "kerb")
                if len(made) != 1 or (label == "kerb" and street and (
                        not _kerb_clear(out, fr, made[0], ribbons, street)
                        or not _area_clear(beds, fr, made[0], site["fill_in"][side]))):
                    items[:] = keep
                    if label == "kerb" and not street:
                        notes.append(f"{site['name']} {side} kerb: {len(stubs)} stubs, not joined")
                    continue
                redrawn += RS.length(made[0])
                done += 1
                if label == "kerb":
                    new_kerb[side] = made[0]
        # lane lines: joined in pairs; the centre line's stub runs on to the median's nose (F's sites)
        band, s_rng = site["lanes"]["band"], site["lanes"]["s"]
        keep = list(lanes)
        stubs, _ = _site_cut(lanes, fr, band, s_rng, near)
        centre = [x for x in stubs if x[0]["k"] == "centre"]
        lane_stubs = [x for x in stubs if x[0]["k"] == "lane"]
        made = _join(lanes, fr, lane_stubs, f"{site['name']} lanes", notes if not street else []) if lane_stubs else []
        if (lane_stubs and len(made) * 2 != len(lane_stubs)) or (centre and not site["centre_to"]):
            lanes[:] = keep
        else:
            redrawn += sum(RS.length(c) for c in made)
            for pc, ec in centre:
                s, n, mm = _stub_end(fr, pc, ec)
                ts, tn = site["centre_to"]
                curve = _hermite(fr, (s, n, mm), (ts, tn, 0.0))
                q = RS.pts_of(pc["p"])
                line = q + curve[1:] if ec == "tail" else list(reversed(curve))[:-1] + q
                lanes.remove(pc)
                lanes.append(dict(pc, p=RS.flat_of(RS.simplify(line, 0.002))))
                redrawn += RS.length(curve)
        out["markings"] = rest + edges + lanes
        # asphalt from the old ribbons out to the new kerbs
        for side, kerb in new_kerb.items():
            inner = site["fill_in"][side]
            ss = [fr.sn(*p)[0] for p in kerb]
            ring_in = [fr.xz(s, inner) for s in reversed(ss)]
            out.setdefault("asphalt_fills", []).append({"p": RS.flat_of(list(kerb) + ring_in)})
        if done:
            fixed += 1
            if street:
                out.setdefault("road_fix_sites", []).append(site["name"])
    return fixed, round(redrawn), notes

# --- 6. split legs ----------------------------------------------------------------------------------

# F, 2026-11-08 (two screenshots on Świętokrzyska between the metro and Rondo ONZ): where a two-way
# street splits into its two one-way carriageways, OpenStreetMap ends all three ways at one node on
# the wide way's axis. bake_roads draws each way round its own centreline, so both legs fan out from
# the middle of the wide street: their lane lines run diagonally across the wide street's lanes (the
# doubled, crossed lines), their kerbs and edge lines start inside its asphalt, the outer kerb steps
# in by half the wide street's width minus the leg's (the notch), and a bike lane's red band jumps
# sideways. Fix 5 only joined kerbs inside fixed bands, so where a crossing stood near the node, the
# legs ran apart slowly or a centre line was left, it fixed half a split or none.
# This redraws the split from its real cross-sections: each line of the wide street (s < 0) is
# joined by one smooth curve to the same line of its leg past the median's nose (lane lines in order
# from the centre, kerbs, edge lines and bike lanes from the outside), the centre line ends at the
# nose, the legs' inner kerbs and edge lines meet at the nose, and asphalt fills the ground between
# the new outer kerbs and the nose. Each split is all or nothing.
SPLIT_BACK = (10.0, 7.0, 4.0)  # m back along the wide way where the redraw may start (first that works)
SPLIT_PAD = 1.0       # m past a ribbon's edge a kerb or line still belongs to it
SPLIT_AFTER = 8.0     # m past the median's nose where the legs' lines are picked up (and a fork is told)
SPLIT_AFTERS = (SPLIT_AFTER, 5.0, 3.0)  # pick-ups tried (fix_split)
SPLIT_NOSE_GAP = 0.4  # m between the legs' ribbons: the median's nose
SPLIT_EDGE_BACK = 1.2  # m in front of the nose where the legs' inner edge lines meet
SPLIT_HATCH_N = 3.0   # m: hatching this near the nose's middle is the nose's own chevrons
SPLIT_HATCH_FROM = 2.0  # m past the node where those chevrons may begin
SPLIT_NOSE_MAX = 70.0  # m: legs still side by side further than this are not a split
SPLIT_END = 1.5       # m: a cut end this near s_a or s_b is a stub there
SPLIT_KINDS = ("lane", "solid", "centre", "edge", "cycle", "cyclefill")
SPLIT_NEAR = 40.0     # m from the node: the check counts crossed lines this near
SPLIT_SLOPE = 0.36    # a leg moving sideways faster than this (20 degrees) at its pick-up is a fork
# round 2 (2026-11-09, the 33 splits round 1 left):
SPLIT_ISLAND_PAD = 0.5  # m round a painted nose (chevrons and their outline) where nothing is cut
SPLIT_TOUCH = 0.6     # m: an edge line ending this near the painted nose's outline is that nose's own
SPLIT_TIP_R = 2.5     # m round the nose's tip where the new lines meeting there may touch others
SPLIT_STOP_BEFORE = 5.0  # m: a stop line no further than this before the nose is on a leg (a junction just past it)


class _Leg:
    """A way's drawn centreline in a split's frame, as n (and half width) by s."""

    def __init__(self, fr, chain):
        """chain: [(road, end at the near side)], the way at the node first and the ways it runs on into."""
        self.sn, self.hw = [], []
        for r, end in chain:
            q = RS.pts_of(r["p"])
            n = len(q)
            wv = r.get("wv") if r.get("wv") and len(r["wv"]) == n else [r["w"]] * n
            cv = r.get("cv") if r.get("cv") and len(r["cv"]) == n else [r.get("c", 0.0)] * n
            mid = []
            for i in range(n):
                a, b = (q[i], q[i + 1]) if i < n - 1 else (q[i - 1], q[i])
                u = _unit(a, b) or (1.0, 0.0)
                mid.append((q[i][0] - u[1] * cv[i], q[i][1] + u[0] * cv[i]))
            if end == 1:
                mid, wv = mid[::-1], wv[::-1]
            skip = 1 if self.sn else 0
            self.sn += [fr.sn(*p) for p in mid[skip:]]
            self.hw += [w / 2 for w in wv[skip:]]


    def at(self, s):
        """(n, half width) at s, or None past the way's reach."""
        for (s0, n0), (s1, n1), h0, h1 in zip(self.sn, self.sn[1:], self.hw, self.hw[1:]):
            if min(s0, s1) - 1e-6 <= s <= max(s0, s1) + 1e-6 and abs(s1 - s0) > 1e-6:
                t = (s - s0) / (s1 - s0)
                return n0 + (n1 - n0) * t, h0 + (h1 - h0) * t
        return None


def _chain(out, ri, end, reach=150.0):
    """The way ri from its `end` on, and the ways of its name it runs on into (one at each node, no
    junction), up to `reach` m: [(road, near end)]."""
    name = out["roads"][ri].get("name")
    at = defaultdict(list)
    for i, r in enumerate(out["roads"]):
        if r.get("name") != name or not _ground(r):
            continue
        q = RS.pts_of(r["p"])
        at[(round(q[0][0], 1), round(q[0][1], 1))].append((i, 0))
        at[(round(q[-1][0], 1), round(q[-1][1], 1))].append((i, 1))
    chain, seen, d = [], {ri}, 0.0
    while True:
        r = out["roads"][ri]
        chain.append((r, end))
        q = RS.pts_of(r["p"])
        d += RS.length(q)
        far = q[-1] if end == 0 else q[0]
        nxt = [(i, e) for i, e in at[(round(far[0], 1), round(far[1], 1))] if i not in seen]
        if d >= reach or len(nxt) != 1:
            return chain
        ri, end = nxt[0]
        seen.add(ri)

def split_nodes(out):
    """Every mid-block split of a main street: one two-way way and two one-way ways of the same name
    end at a node no other street reaches (as auto_sites). [(node, wide index, wide end, legs)]"""
    ends = defaultdict(list)
    names_at = defaultdict(set)
    for i, r in enumerate(out["roads"]):
        if not _ground(r):
            continue
        q = RS.pts_of(r["p"])
        for x, z in q:
            names_at[(round(x, 1), round(z, 1))].add(r.get("name") or r["k"])
        if r["k"] not in MAIN or len(q) < 2:
            continue
        ends[(round(q[0][0], 1), round(q[0][1], 1))].append((i, 0))
        ends[(round(q[-1][0], 1), round(q[-1][1], 1))].append((i, 1))
    found = []
    for node, lst in sorted(ends.items()):
        if len(lst) != 3 or len(names_at[node]) != 1:
            continue
        name = out["roads"][lst[0][0]].get("name")
        if not name or any(out["roads"][i].get("name") != name for i, _ in lst):
            continue
        two = [(i, e) for i, e in lst if not out["roads"][i]["oneway"]]
        if len(two) != 1:
            continue
        legs = [(i, e) for i, e in lst if (i, e) != two[0]]
        found.append((node, two[0][0], two[0][1], legs))
    return found


def _split_frame(out, node, wi, we):
    q = RS.pts_of(out["roads"][wi]["p"])
    if we == 0:
        q = q[::-1]
    back, d = q[-1], 0.0
    for a2, b2 in zip(reversed(q[:-1]), reversed(q[1:])):
        d += math.dist(a2, b2)
        back = a2
        if d >= 15.0:
            break
    u = _unit(back, node)
    if u is None or d < 8.0:
        return None, 0.0
    return Frame({"a": node, "u": u}), RS.length(q)


def _cut_corridor(items, inside, near_pt, end_ok, kinds=None):
    """Cuts the points `inside(x, z)` out of each ground polyline (kinds: the markings' k to cut, None
    for kerbs). Returns (kept items, stubs [(piece, end, (x, z))]). A line whose cut leaves an end
    where `end_ok` says no (it runs out of the corridor sideways: a driveway's kerb, a crossing) is
    kept whole."""
    keep, stubs = [], []
    for m in items:
        if kinds is not None and m.get("k") not in kinds:
            keep.append(m)
            continue
        pts = RS.pts_of(m["p"])
        if len(pts) < 2 or not _ground(m) or min(math.dist(p, near_pt) for p in pts) > 140.0:
            keep.append(m)
            continue
        dense = _dense(pts)
        flags = [inside(x, z) for x, z in dense]
        if not any(flags):
            keep.append(m)
            continue
        runs, run = [], []
        for p, f in zip(dense, flags):
            if f:
                if run:
                    runs.append(run)
                run = []
            else:
                run.append(p)
        if run:
            runs.append(run)
        mine_keep, mine_stubs = [], []
        for r in runs:
            if len(r) < 2 or RS.length(r) < LINE_MIN:
                continue
            piece = dict(m, p=RS.flat_of(RS.simplify(r, 0.002)))
            mine_keep.append(piece)
            if r[-1] != dense[-1]:
                mine_stubs.append((piece, "tail", r[-1]))
            if r[0] != dense[0]:
                mine_stubs.append((piece, "head", r[0]))
        if all(end_ok(p) for _, _, p in mine_stubs):
            keep += mine_keep
            stubs += mine_stubs
        else:
            keep.append(m)
    return keep, stubs


def _hermite_sn(p0, p1, step=SITE_STEP):
    """(s, n) points from p0 = (s, n, dn/ds) to p1, matching positions and headings."""
    s0, n0, m0 = p0
    s1, n1, m1 = p1
    L = s1 - s0
    k = max(2, int(math.ceil(abs(L) / step)))
    out = []
    for i in range(k + 1):
        t = i / k
        h00, h10 = 2 * t ** 3 - 3 * t ** 2 + 1, t ** 3 - 2 * t ** 2 + t
        h01, h11 = -2 * t ** 3 + 3 * t ** 2, t ** 3 - t ** 2
        out.append((s0 + L * t, h00 * n0 + h10 * L * m0 + h01 * n1 + h11 * L * m1))
    return out


def _seq(piece, end, last):
    """The piece's points, ordered so its cut end comes last (last=True) or first."""
    q = RS.pts_of(piece["p"])
    cut_last = end == "tail"
    return q if cut_last == last else q[::-1]


def _joined(fr, a, b, curve_sn, directed):
    """One line: stub a, the curve (s, n points from a's cut end to b's), stub b. None when a kerb's
    two stubs run opposite ways."""
    (pa, ea, _), (pb, eb, _) = a, b
    curve = [fr.xz(s, n) for s, n in curve_sn]
    line = _seq(pa, ea, True) + curve[1:-1] + _seq(pb, eb, False)
    if ea == "tail" and eb == "head":
        pass
    elif ea == "head" and eb == "tail":
        line = line[::-1]
    elif directed:
        return None
    return dict(pa, p=RS.flat_of(RS.simplify(line, 0.002)))


def _stub_sn(fr, stub):
    piece, end, p = stub
    s, n = fr.sn(*p)
    q = _seq(piece, end, True)
    b = _back(q[::-1], False) if len(q) > 1 else q[0]
    sb, nb = fr.sn(*b)
    slope = (n - nb) / (s - sb) if abs(s - sb) > 0.05 else 0.0
    return s, n, max(-0.6, min(0.6, slope))


def _crossings(lines):
    """Crossings between segments of different lines (each line a list of points)."""
    segs = []
    for li, q in enumerate(lines):
        segs += [(li, a, b) for a, b in zip(q, q[1:])]
    hits = 0
    for i in range(len(segs)):
        li, a, b = segs[i]
        for j in range(i + 1, len(segs)):
            lj, c, d = segs[j]
            if li != lj and RS._segs_cross(a, b, c, d):
                hits += 1
    return hits


def _split_geom(out, node, wi, we, legs):
    """A split's frame, its ways as seen from the node and the median's nose (where the legs'
    ribbons part): (frame, wide way length, wide, [leg, leg], nose), or (None, why)."""
    fr, wlen = _split_frame(out, node, wi, we)
    if fr is None:
        return None, "wide way too short"
    wide = _Leg(fr, [(out["roads"][wi], 1 - we)])  # from the node back: s < 0 along it
    ls = [_Leg(fr, _chain(out, i, e)) for i, e in legs]
    s = 0.5
    while s <= SPLIT_NOSE_MAX:
        a, b = ls[0].at(s), ls[1].at(s)
        if a is None or b is None:
            return None, "a leg ends before the legs part"
        lo, hi = (a, b) if a[0] < b[0] else (b, a)
        if (hi[0] - hi[1]) - (lo[0] + lo[1]) >= SPLIT_NOSE_GAP:
            return (fr, wlen, wide, ls, s), None
        s += 0.5
    return None, "the legs never part"


def _painted_bins(out, fr, hatch, tip, s_b):
    """The painted nose's extent across the street by half-metre bins of s, from its tip on: the
    chevrons and their closed outline (the lines along it stay as they are)."""
    pts = list(hatch)
    outline = []
    for m in out.get("markings", []):
        if m.get("k") not in SPLIT_KINDS + ("stripe",) or not _ground(m):
            continue
        q = RS.pts_of(m["p"])
        closed = len(q) > 3 and math.dist(q[0], q[-1]) < 0.5
        if m["k"] != "stripe" and not closed:
            continue
        sn = [fr.sn(x, z) for x, z in _dense(q, 0.25)]
        if any(abs(a - tip[0]) < 0.5 and abs(b - tip[1]) < 0.5 for a, b in sn) or \
                (m["k"] == "stripe" and all(tip[0] - 0.5 <= a <= s_b + 6.0 and abs(b - tip[1]) < SPLIT_HATCH_N + 1.0 for a, b in sn)):
            pts += [(a, b) for a, b in sn if tip[0] - 0.5 <= a <= s_b + 6.0]
            if closed:
                outline += _dense(q, 0.25)
    bins = {}
    for a, b in pts:
        k = int(math.floor(a * 2))
        lo, hi = bins.get(k, (b, b))
        bins[k] = (min(lo, b), max(hi, b))
    if not bins:
        return {}, []
    ks = sorted(bins)
    for k in range(ks[0], ks[-1] + 1):  # gaps between the chevrons: the neighbours' extent
        if k not in bins:
            lo = max(j for j in ks if j < k)
            hi = min(j for j in ks if j > k)
            bins[k] = (min(bins[lo][0], bins[hi][0]), max(bins[lo][1], bins[hi][1]))
    return bins, outline


def fix_split(out, node, wi, we, legs, ribbons, beds):
    """Redraws one split (see above). Returns (True, metres redrawn) or (False, why). The legs' lines
    are picked up SPLIT_AFTERS past the nose; the pick-up leaving fewest lane lines without a partner
    across the split wins (a leg's line that ends soon after the nose, at a stop line, still pairs)."""
    best, why = None, None
    for after in SPLIT_AFTERS:
        res = _fix_split_at(out, node, wi, we, legs, ribbons, beds, after)
        if not res[0]:
            why = why or res[1]
            continue
        if best is None or res[3] < best[3]:
            best = res
        if res[3] == 0:
            break
    if best is None:
        return False, why
    best[2]()
    return True, best[1]


def _fix_split_at(out, node, wi, we, legs, ribbons, beds, after):
    """fix_split with the legs' lines picked up `after` m past the nose: (True, metres, commit,
    lane lines left without a partner) or (False, why); the map is changed only by commit()."""
    geom, why = _split_geom(out, node, wi, we, legs)
    if geom is None:
        return False, why
    fr, wlen, wide, ls, nose = geom
    s_b = nose + after
    at_b = [lg.at(s_b) for lg in ls]
    if None in at_b:
        return False, "a leg is shorter than its nose"
    # a dual carriageway's split, not a fork: both legs still run along the street past the nose
    for lg in ls:
        a2, b2 = lg.at(nose + SPLIT_AFTER - 4.0), lg.at(nose + SPLIT_AFTER)
        if b2 is None:
            b2, a2 = lg.at(s_b), lg.at(s_b - 4.0)
        if a2 is None or abs(b2[0] - a2[0]) / 4.0 > SPLIT_SLOPE:
            return False, "a leg turns away (a fork, not a split)"
    # a mapped median or island before the ribbons part: its nose is the real one
    for m in out.get("medians", []):
        for x, z in RS.pts_of(m["s"]):
            ms, mn = fr.sn(x, z)
            if 0.0 < ms < nose - 1.0 and abs(mn) < 12.0:
                return False, "a median starts before the legs' ribbons part"
    for isl in out.get("islands", []):
        for x, z in RS.pts_of(isl["p"]):
            ms, mn = fr.sn(x, z)
            if 0.0 < ms < nose - 1.0 and abs(mn) < 12.0:
                return False, "an island starts before the legs' ribbons part"
    L, R = (0, 1) if at_b[0][0] < at_b[1][0] else (1, 0)
    a_nose, b_nose = ls[L].at(nose), ls[R].at(nose)
    n_nose = ((a_nose[0] + a_nose[1]) + (b_nose[0] - b_nose[1])) / 2
    # hatching painted on the median's nose (chevrons between the legs) is the painted nose: the
    # legs' inner edge lines meet at its tip and the centre line ends there. Any other hatching, or a
    # stop line, inside the split is a junction of its own: left as it is.
    paint = (nose - SPLIT_EDGE_BACK, n_nose)
    hatch, stops = [], []
    for m in out.get("markings", []):
        if m.get("k") in ("stripe", "stop", "stopkerb") and _ground(m):
            win = [(ms, mn) for ms, mn in (fr.sn(x, z) for x, z in RS.pts_of(m["p"]))
                   if -2.0 < ms < nose - 1.0 and abs(mn) < 12.0]
            if not win:
                continue
            if m["k"] in ("stop", "stopkerb") and all(ms > nose - SPLIT_STOP_BEFORE for ms, mn in win):
                stops.append(m)
                continue
            if m["k"] != "stripe" or any(ms < SPLIT_HATCH_FROM or abs(mn - n_nose) > SPLIT_HATCH_N for ms, mn in win):
                return False, "hatching or a stop line in the split"
            hatch += win
        elif m.get("k") in SPLIT_KINDS and _ground(m):
            # the chevrons' painted outline: one closed line round them
            q = RS.pts_of(m["p"])
            if len(q) > 3 and math.dist(q[0], q[-1]) < 0.5:
                hatch += [(ms, mn) for ms, mn in (fr.sn(x, z) for x, z in q)
                          if SPLIT_HATCH_FROM < ms < nose and abs(mn - n_nose) < SPLIT_HATCH_N]
    painted, outline = {}, []
    if hatch:
        tip = min(hatch)
        paint = (min(paint[0], tip[0] - 0.3), tip[1])
        painted, outline = _painted_bins(out, fr, hatch, tip, s_b)
    why = "the wide way is too short"
    w0 = wide.at(-0.01) or wide.at(0.0)
    if w0 is None:
        return False, "no wide way at the node"
    for s_back in SPLIT_BACK:
        if s_back > wlen - 2.0:
            continue
        s_a = -s_back

        def inside(x, z, s_a=s_a):
            s, n = fr.sn(x, z)
            if s < s_a or s > s_b:
                return False
            if painted:
                rng = painted.get(int(math.floor(s * 2)))
                if rng and rng[0] - SPLIT_ISLAND_PAD <= n <= rng[1] + SPLIT_ISLAND_PAD:
                    return False
            if s <= 0:
                w = wide.at(s)
                return w is not None and abs(n - w[0]) <= w[1] + SPLIT_PAD
            lo, hi = ls[L].at(s), ls[R].at(s)
            if lo is None or hi is None:
                return False
            # out to the wide street's kerbs too: the new kerbs run from those to the legs'
            if not (min(lo[0] - lo[1], w0[0] - w0[1]) - SPLIT_PAD <= n <= max(hi[0] + hi[1], w0[0] + w0[1]) + SPLIT_PAD):
                return False
            if s < nose:
                return True
            return n <= lo[0] + lo[1] + SPLIT_PAD or n >= hi[0] - hi[1] - SPLIT_PAD
        inside.outline = outline
        inside.stops = stops
        res = _try_split(out, fr, node, inside, s_a, s_b, nose, n_nose, paint, ls, L, R, ribbons, beds,
                         out["roads"][wi].get("name"))
        if res[0]:
            return res
        why = res[1]
    return False, why


def _try_split(out, fr, node, inside, s_a, s_b, nose, n_nose, paint, ls, L, R, ribbons, beds, name):
    """fix_split's work for one start s_a: (True, metres redrawn) or (False, why); the map is
    changed only on success."""
    def end_ok(p):
        s = fr.sn(*p)[0]
        return abs(s - s_a) < SPLIT_END or abs(s - s_b) < SPLIT_END

    kerbs, k_stubs = _cut_corridor(out["kerbs"], inside, node, end_ok)
    outline = getattr(inside, "outline", None) or []
    def touches(m):
        q = RS.pts_of(m["p"])
        return m.get("k") == "edge" and any(min(math.dist(e, o) for o in outline) < SPLIT_TOUCH for e in (q[0], q[-1]))
    held = [m for m in out["markings"] if outline and touches(m)]
    hid = {id(m) for m in held}
    marks, m_stubs = _cut_corridor([m for m in out["markings"] if id(m) not in hid], inside, node, end_ok, SPLIT_KINDS)
    marks += held
    mid_b = (ls[L].at(s_b)[0] + ls[R].at(s_b)[0]) / 2

    def group(stubs, kinds=None):
        a, bl, br = [], [], []
        for st in stubs:
            if kinds is not None and st[0].get("k") not in kinds:
                continue
            sn = _stub_sn(fr, st)
            if abs(sn[0] - s_a) < SPLIT_END:
                a.append((st, sn))
            elif sn[1] < mid_b:
                bl.append((st, sn))
            else:
                br.append((st, sn))
        key = lambda x: x[1][1]
        return sorted(a, key=key), sorted(bl, key=key), sorted(br, key=key)

    new_k, new_m, gone = [], [], []
    lonely = 0
    curves = {}
    redrawn = 0.0

    def join(a, b, directed):
        nonlocal redrawn
        sn = _hermite_sn(a[1], b[1])
        line = _joined(fr, a[0], b[0], sn, directed)
        if line is None:
            return None
        gone.extend([a[0][0], b[0][0]])
        redrawn += RS.length([fr.xz(*q) for q in sn])
        return line, sn

    def to_nose(stubs, directed, at):
        """The legs' inner lines meet at `at` (one line round it when both are there): kerbs at the
        nose, edge lines at the painted nose, in front of it, so they stay on the asphalt."""
        nonlocal redrawn
        parts = [(st, sn, _hermite_sn((at[0], at[1], 0.0), sn)) for st, sn in stubs]
        if len(parts) == 2:
            (sa, _, ca), (sb, _, cb) = parts
            curve = list(reversed(ca)) + cb[1:]
            line = _joined(fr, sa, sb, curve, directed)
            if line is None:
                return None
            gone.extend([sa[0], sb[0]])
            redrawn += RS.length([fr.xz(*q) for q in curve])
            return [line]
        made = []
        for st, sn, c in parts:
            pts = [fr.xz(*q) for q in c]
            q = _seq(st[0], st[1], False)
            line = pts[:-1] + q
            if st[1] == "tail":
                line = line[::-1]
            gone.append(st[0])
            redrawn += RS.length(pts)
            made.append(dict(st[0], p=RS.flat_of(RS.simplify(line, 0.002))))
        return made

    # kerbs: the wide street's two, each leg's outer one and its inner one (the median's). An outer
    # kerb already whole through the split (one kerb from the wide street on along a leg) stays.
    a, bl, br = group(k_stubs)
    whole = {}
    if len(a) == 1:
        side = "hi" if a[0][1][1] < 0.0 else "lo"  # the frame runs along the wide way's axis
        w = _whole_kerb(fr, kerbs, inside, s_a, s_b, side, mid_b)
        if w is None:
            return False, f"kerb stubs {len(a)}/{len(bl)}/{len(br)}"
        whole[side] = w
    lo_cut, hi_cut = "lo" not in whole, "hi" not in whole
    if (len(a) != lo_cut + hi_cut or not lo_cut <= len(bl) <= lo_cut + 1
            or not hi_cut <= len(br) <= hi_cut + 1):
        return False, f"kerb stubs {len(a)}/{len(bl)}/{len(br)}"
    # the old kerbs' outermost line on each side, by metre of s (their pieces inside the corridor)
    old_kerb = {"lo": {}, "hi": {}}
    for k in out["kerbs"]:
        if not _ground(k):
            continue
        for x, z in _dense(RS.pts_of(k["p"]), 0.5):
            if not inside(x, z):
                continue
            ks, kn = fr.sn(x, z)
            sd = "lo" if kn < mid_b else "hi"
            o = old_kerb[sd].get(int(math.floor(ks)))
            sg = -1.0 if sd == "lo" else 1.0
            if o is None or sg * kn > sg * o:
                old_kerb[sd][int(math.floor(ks))] = kn
    pairs = []
    if lo_cut:
        pairs.append((a[0], bl[0], "lo"))
    if hi_cut:
        pairs.append((a[-1], br[-1], "hi"))
    curves.update(whole)
    for (sa, sb, side) in pairs:
        j = join(sa, sb, True)
        if j is None:
            return False, "kerb stubs run opposite ways"
        curves[side] = j[1]
        out_n = -1.0 if side == "lo" else 1.0
        # a side street's mouth (another street's ribbon just outside, where the old kerb had its
        # gap) stays open: the new kerb is cut there as the old one was
        gaps = {int(math.floor(q[0])) for q in j[1] if old_kerb[side].get(int(math.floor(q[0]))) is None}
        mouth = set()
        for q in j[1]:
            k = int(math.floor(q[0]))
            if k in gaps and any(out["roads"][pc[3]].get("name") != name
                                 for pc in ribbons.at(*fr.xz(q[0], q[1] + out_n * 0.8), 0.1)):
                mouth.add(k)
        for k in sorted(mouth):  # the whole gap round it
            for step in (1, -1):
                k2 = k + step
                while k2 in gaps and k2 not in mouth:
                    mouth.add(k2)
                    k2 += step
        if mouth:
            piece, run = [], []
            for p in _dense(RS.pts_of(j[0]["p"]), 0.25):
                if int(math.floor(fr.sn(*p)[0])) in mouth:
                    if len(run) > 1 and RS.length(run) >= LINE_MIN:
                        piece.append(run)
                    run = []
                else:
                    run.append(p)
            if len(run) > 1 and RS.length(run) >= LINE_MIN:
                piece.append(run)
            new_k += [dict(j[0], p=RS.flat_of(RS.simplify(r, 0.002))) for r in piece]
        else:
            new_k.append(j[0])
        # no asphalt of the street just outside it (up to the nose: past it the legs' ribbons and
        # kerbs are as they were, a ribbon a little wider than its kerb among them), unless the old
        # kerb already ran there (that asphalt was outside a kerb before) or it is a side street's mouth
        g = (ls[L] if side == "lo" else ls[R]).at(s_b)
        over = max(0.0, out_n * (g[0] + out_n * g[1] - sb[1][1]))  # the leg's ribbon past its kerb

        def was_out(q):
            k = int(math.floor(q[0]))
            o = old_kerb[side].get(k)
            return k in mouth or (o is not None and out_n * o <= out_n * q[1] + 0.3)
        if any(out["roads"][pc[3]].get("name") == name
               for q in j[1] if not was_out(q)
               for pc in ribbons.at(*fr.xz(q[0], q[1] + out_n * (0.8 + (over if q[0] > nose - 5.0 else 0.0))), 0.1)):
            return False, "a new kerb would leave asphalt outside it"
    inner = ([bl[-1]] if len(bl) == lo_cut + 1 else []) + ([br[0]] if len(br) == hi_cut + 1 else [])
    made = to_nose(inner, True, (nose, n_nose)) if inner else []
    if made is None:
        return False, "the median's kerbs run opposite ways"
    new_k += made
    inner_sn = {}
    for st, sn in inner:
        inner_sn["lo" if sn[1] < mid_b else "hi"] = _hermite_sn((nose, n_nose, 0.0), sn)
    c_a = None
    # centre line: on to the nose
    a_c, _, _ = group(m_stubs, ("centre",))
    for st, sn in a_c:
        c_a = sn[1] if c_a is None else c_a
        # it ends where the legs' inner edge lines meet, just in front of the nose
        curve = [fr.xz(*q) for q in _hermite_sn(sn, (paint[0] - 0.5, paint[1] + sn[1] - a_c[0][1][1], 0.0))]
        line = _seq(st[0], st[1], True) + curve[1:]
        if st[1] == "head":
            line = line[::-1]
        gone.append(st[0])
        redrawn += RS.length(curve)
        new_m.append(dict(st[0], p=RS.flat_of(RS.simplify(line, 0.002))))
    if c_a is None:
        c_a = (curves["lo"][0][1] + curves["hi"][0][1]) / 2
    # lane lines: in order from the centre
    a_l, bl_l, br_l = group(m_stubs, ("lane", "solid"))
    for xs, ys in (([x for x in reversed(a_l) if x[1][1] < c_a], list(reversed(bl_l))),
                   ([x for x in a_l if x[1][1] >= c_a], br_l)):
        for sa, sb in zip(xs, ys):
            line, sn = join(sa, sb, False)
            if sa[0][0].get("k") == sb[0][0].get("k"):
                new_m.append(line)
                continue
            # a dashed lane line meeting a leg's solid one (no changing lanes before the junction):
            # the curve stays the wide street's kind, the leg's line stays as it was
            del gone[next(i for i, g in enumerate(gone) if g is sb[0][0])]
            pts = _seq(sa[0][0], sa[0][1], True) + [fr.xz(*q) for q in sn[1:]]
            new_m.append(dict(sa[0][0], p=RS.flat_of(RS.simplify(pts, 0.002))))
        # a lane that only one side has (a lane added or dropped at the split) starts or ends at the
        # nose beside the kerb, as a line, never in the middle of the road
    for xs, ys, side in (([x for x in reversed(a_l) if x[1][1] < c_a], list(reversed(bl_l)), "lo"),
                         ([x for x in a_l if x[1][1] >= c_a], br_l, "hi")):
        lonely += abs(len(ys) - len(xs))
        for st, sn in ys[len(xs):]:
            new_m.append(_beside(fr, st, sn, curves[side], nose, gone))
        for st, sn in xs[len(ys):]:
            new_m.append(_beside(fr, st, sn, curves[side], nose, gone))
    # edge lines, bike lanes: in order from the outside; an unpaired one runs on beside the kerb
    for kinds in (("edge",), ("cycle",), ("cyclefill",)):
        a_e, bl_e, br_e = group(m_stubs, kinds)
        if kinds == ("edge",):
            in_l = [bl_e.pop()] if len(bl_e) >= 2 else []
            in_r = [br_e.pop(0)] if len(br_e) >= 2 else []
            nose_made = to_nose(in_l + in_r, False, paint)
            new_m += nose_made or []
        for xs, ys, side in (([x for x in a_e if x[1][1] < c_a], bl_e, "lo"),
                             (list(reversed([x for x in a_e if x[1][1] >= c_a])), list(reversed(br_e)), "hi")):
            for sa, sb in zip(xs, ys):
                new_m.append(join(sa, sb, False)[0])
            for st, sn in ys[len(xs):]:
                new_m.append(_beside(fr, st, sn, curves[side], max(s_a, 0.0), gone))
            for st, sn in xs[len(ys):]:
                new_m.append(_beside(fr, st, sn, curves[side], nose, gone))
    # a stop line on a leg (the legs reach a junction just past the nose): lane and centre lines
    # stop STOP_GAP short of it, as fix 1 cuts them in a junction's mouth
    for st in getattr(inside, "stops", None) or []:
        sq = sorted(fr.sn(x, z) for x, z in RS.pts_of(st["p"]))
        sq = sorted(sq, key=lambda p: p[1])
        n_lo, n_hi = sq[0][1], sq[-1][1]

        def past(p):
            ps, pn = fr.sn(*p)
            if not n_lo - 0.3 <= pn <= n_hi + 0.3:
                return False
            t = (pn - n_lo) / (n_hi - n_lo) if n_hi - n_lo > 1e-6 else 0.0
            return ps > sq[0][0] + (sq[-1][0] - sq[0][0]) * t - STOP_GAP
        clipped = []
        for m in new_m:
            if m.get("k") not in ("lane", "solid", "centre"):
                clipped.append(m)
                continue
            q = _dense(RS.pts_of(m["p"]))
            if not any(past(p) for p in q):
                clipped.append(m)
                continue
            if past(q[0]):
                q = q[::-1]
            run = []
            for p in q:
                if past(p):
                    break
                run.append(p)
            if len(run) > 1 and RS.length(run) >= LINE_MIN:
                clipped.append(dict(m, p=RS.flat_of(RS.simplify(run, 0.002))))
        new_m = clipped
    # and never under a zebra (road_smooth.cut_zebras, its ratchet): a leg's crossing just past the nose
    zl = {"paths": out.get("paths", []), "markings": [m for m in new_m if m.get("k") in RS.ZEBRA_CUT_KINDS]}
    if zl["markings"] and RS.cut_zebras(zl):
        new_m = [m for m in new_m if m.get("k") not in RS.ZEBRA_CUT_KINDS] + zl["markings"]
    # nothing crossed: the lines left and made in the corridor
    ids = {id(g) for g in gone}
    kept_m = [m for m in marks if id(m) not in ids]
    def crossed(ms):
        near = [RS.pts_of(m["p"]) for m in ms
                if m["k"] in ("lane", "solid", "centre", "edge") and _ground(m)
                and any(inside(x, z) or math.dist((x, z), node) < 6.0 for x, z in _dense(RS.pts_of(m["p"]), 2.0))]
        tip_xz = fr.xz(*paint)
        clipped = [[p for p in q if math.dist(p, node) < SPLIT_NEAR + 20 and math.dist(p, tip_xz) > SPLIT_TIP_R]
                   for q in near]
        return _crossings([q for q in clipped if len(q) >= 2])
    # only the new lines count: a painted island's outline that crossed lines before stays as it was
    if crossed(kept_m + new_m) > crossed(kept_m):
        return False, "lines would still cross"
    # asphalt between the new outer kerbs and the nose
    fills = []
    centre = _hermite_sn((s_a, c_a, 0.0), (nose, n_nose, 0.0))
    for side in ("lo", "hi"):
        out_sn = curves[side]
        leg = ls[L] if side == "lo" else ls[R]
        inner_pts = list(centre)
        if side in inner_sn:
            inner_pts += inner_sn[side][1:]
        else:
            for k in range(1, int(s_b - nose) + 1):
                g = leg.at(nose + k)
                inner_pts.append((nose + k, g[0] + (g[1] if side == "lo" else -g[1])))
        ring = [fr.xz(*q) for q in out_sn] + [fr.xz(*q) for q in reversed(inner_pts)]
        if any(beds.hit(x, z) for x, z in ring):
            return False, "a fill would reach a tram bed"
        fills.append({"p": RS.flat_of(ring)})
    kerbs = [k for k in kerbs if id(k) not in ids] + new_k

    def commit():
        out["kerbs"] = kerbs
        out["markings"] = kept_m + new_m
        out.setdefault("asphalt_fills", []).extend(fills)
    return True, redrawn, commit, lonely


def _whole_kerb(fr, kerbs, inside, s_a, s_b, side, mid_b):
    """The outer kerb on `side` that already runs whole through a split (from before s_a to past
    s_b, never crossing to the other side): its (s, n) points from s_a to s_b, or None."""
    for k in kerbs:
        if not _ground(k):
            continue
        sn = [fr.sn(x, z) for x, z in _dense(RS.pts_of(k["p"]))]
        run = [(s, n) for s, n in sn if s_a <= s <= s_b]
        if len(run) < 4 or not any(inside(*fr.xz(s, n)) for s, n in run[::4]):
            continue
        if min(s for s, _ in sn) > s_a + SPLIT_END or max(s for s, _ in sn) < s_b - SPLIT_END:
            continue
        if any((n < mid_b) != (side == "lo") for _, n in run):
            continue
        if any(b[0] <= a[0] for a, b in zip(run, run[1:])):
            run = run[::-1]
            if any(b[0] <= a[0] for a, b in zip(run, run[1:])):
                continue
        return run
    return None


def _beside(fr, st, sn, kerb_sn, s_to, gone):
    """A line with no partner across the split runs on to s_to at its distance from the new kerb."""
    def kerb_n(s):
        for (s0, n0), (s1, n1) in zip(kerb_sn, kerb_sn[1:]):
            if s0 <= s <= s1:
                return n0 + (n1 - n0) * ((s - s0) / (s1 - s0) if s1 > s0 else 0.0)
        return kerb_sn[0][1] if s < kerb_sn[0][0] else kerb_sn[-1][1]
    off = sn[1] - kerb_n(sn[0])
    k = max(2, int(abs(sn[0] - s_to) / SITE_STEP))
    pts = [fr.xz(sn[0] + (s_to - sn[0]) * i / k, kerb_n(sn[0] + (s_to - sn[0]) * i / k) + off) for i in range(k + 1)]
    line = _seq(st[0], st[1], True) + pts[1:]
    if st[1] == "head":
        line = line[::-1]
    gone.append(st[0])
    return dict(st[0], p=RS.flat_of(RS.simplify(line, 0.002)))


def fix_splits(out, skip=()):
    """Fix 6 over the whole map: (splits redrawn, m redrawn, the ones left with why). `skip`: the
    splits already redrawn ("name at x,z", as road_split_fixes lists them)."""
    ribbons = Ribbons(out, lambda r: True)
    beds = Beds(out)
    done, metres, left = 0, 0.0, []
    for node, wi, we, legs in split_nodes(out):
        name = out["roads"][wi].get("name")
        if f"{name} at {node[0]:.0f},{node[1]:.0f}" in skip:
            continue
        ok, res = fix_split(out, node, wi, we, legs, ribbons, beds)
        if ok:
            done += 1
            metres += res
            out.setdefault("road_split_fixes", []).append(f"{name} at {node[0]:.0f},{node[1]:.0f}")
        else:
            left.append(f"{name} at {node[0]:.0f},{node[1]:.0f}: {res}")
    return done, round(metres), left


def split_defects(out):
    """What F saw at a split, measured over every split the fix takes on (split_nodes with a nose):
    `fan_m`, metres of lane, centre, edge and bike-lane paint and of kerb between the node and the
    nose running across the street (steeper than SPLIT_SLOPE: the legs' lines fanning out from the
    middle, the bike lane's jump), `kerb_gap_m`, metres of that stretch (from 4 m before the node to
    4 m past the nose) where no kerb runs along a side's outer edge (the notch), and `loose_ends`,
    lane, centre and edge lines ending in the road there (the wide street's lines stopping at the
    node and the legs' starting from it, crossed and doubled)."""
    fan = gap = 0.0
    ends = 0
    kinds = ("lane", "solid", "centre", "edge", "cycle", "cyclefill")
    for node, wi, we, legs in split_nodes(out):
        geom, _ = _split_geom(out, node, wi, we, legs)
        if geom is None:
            continue
        fr, _, wide, ls, nose = geom
        w0 = wide.at(-0.01) or wide.at(0.0)
        if w0 is None:
            continue
        reach = w0[1] + 2.0
        near = [m for m in out.get("markings", []) if m.get("k") in kinds and _ground(m)] + \
               [k for k in out.get("kerbs", []) if _ground(k)]
        covered = {"lo": set(), "hi": set()}
        for m in near:
            q = RS.pts_of(m["p"])
            if min(math.dist(p, node) for p in q) > nose + 30.0:
                continue
            sn = [fr.sn(*p) for p in _dense(q, 0.5)]
            for (s0, n0), (s1, n1) in zip(sn, sn[1:]):
                if not (0.5 <= s0 <= nose and 0.5 <= s1 <= nose and abs(n0) <= reach and abs(n1) <= reach):
                    continue
                if abs(n1 - n0) > SPLIT_SLOPE * abs(s1 - s0):
                    fan += math.hypot(s1 - s0, n1 - n0)
            if m in out.get("kerbs", []):
                for s0, n0 in sn:
                    if -4.0 <= s0 <= nose + 4.0:
                        lo, hi = ls[0].at(max(s0, 0.5)), ls[1].at(max(s0, 0.5))
                        if lo is None or hi is None:
                            continue
                        lo, hi = (lo, hi) if lo[0] < hi[0] else (hi, lo)
                        if s0 < 0.5:
                            e_lo, e_hi = w0[0] - w0[1], w0[0] + w0[1]
                        else:
                            e_lo = min(lo[0] - lo[1], w0[0] - w0[1])
                            e_hi = max(hi[0] + hi[1], w0[0] + w0[1])
                        if abs(n0 - e_lo) <= 1.5:
                            covered["lo"].add(int(math.floor(s0 + 4.0)))
                        if abs(n0 - e_hi) <= 1.5:
                            covered["hi"].add(int(math.floor(s0 + 4.0)))
            if m.get("k") in ("lane", "solid", "centre", "edge"):
                for e_s, e_n in (sn[0], sn[-1]):
                    if -3.0 < e_s < nose - 2.5 and abs(e_n - w0[0]) < w0[1] - 1.0:
                        ends += 1
        span = int(math.floor(nose + 8.0)) + 1
        gap += sum(max(0, span - len(c)) for c in covered.values())
    return {"fan_m": round(fan), "kerb_gap_m": gap, "loose_ends": ends}


def measure(out):
    """What is left (the --check numbers)."""
    asphalt, raised = _tests(out)
    on_bed = RS._bed_index(out)
    nodes = junction_nodes(out)
    all_ribbons = Ribbons(out, lambda r: True)
    main_ribbons = Ribbons(out, lambda r: r["k"] in MAIN)
    mi = MouthIndex(mouths(out, nodes, all_ribbons))
    m_mouth, m_box = cut_lines(out, mi, main_ribbons, dry=True)
    arrows, _ = move_arrows(out, mi, asphalt, dry=True)
    probe = json.loads(json.dumps({k: out[k] for k in ("paths", "roads", "bounds", "outside") if k in out}))
    dots, _, partners = fix_zebras(probe, asphalt, raised, on_bed, all_ribbons, dry=True)
    _, _, _, short = fix_cycle_crossings(probe, asphalt, raised, dry=True)
    sd = split_defects(out)
    return {"mouth_m": m_mouth, "box_m": m_box, "arrows": arrows, "partners": partners, "dots": dots, "short_cycle": short,
            "site_gaps": site_gaps(out), "split_fan_m": sd["fan_m"], "split_gap_m": sd["kerb_gap_m"],
            "split_ends": sd["loose_ends"]}


def apply(out):
    """Fixes the finished map data in place; returns a one-line summary."""
    done = int(out.get("road_fixes", 0))
    if done >= VERSION:
        return "already fixed"
    said = []
    if done < 1:
        said.append(_apply_v1(out))
    if done < 2:
        sites, redrawn, notes = fix_sites(out)
        said.append(f"{sites} sites fixed ({redrawn} m of kerb and paint redrawn)" + "".join("; " + n for n in notes))
    if done < 4:
        # a map fixed to version 3 keeps round 1's splits and redraws the ones it left
        splits, metres, left = fix_splits(out, set(out.get("road_split_fixes", [])) if done == 3 else ())
        said.append(f"{splits} splits redrawn ({metres} m of kerb and paint), {len(left)} left as they were")
    out["road_fixes"] = VERSION
    return "; ".join(said)


def _apply_v1(out):
    asphalt, raised = _tests(out)
    on_bed = RS._bed_index(out)
    all_ribbons = Ribbons(out, lambda r: True)
    dots, run_on, partners = fix_zebras(out, asphalt, raised, on_bed, all_ribbons)
    beside, free, cyc_m, short = fix_cycle_crossings(out, asphalt, raised)
    nodes = junction_nodes(out)
    main_ribbons = Ribbons(out, lambda r: r["k"] in MAIN)
    mi = MouthIndex(mouths(out, nodes, all_ribbons))
    moved, dropped = move_arrows(out, mi, asphalt)
    m_mouth, m_box = cut_lines(out, mi, main_ribbons)
    return (f"{dots} dot zebras dropped, zebras run on {run_on} m to the kerbs, {partners} far carriageways given "
            f"their zebra; {beside} cycle crossing ends run on beside their zebra and {free} free ends to the kerb "
            f"({cyc_m} m, {short} still short); {len(mi.ms)} junction mouths: {moved} arrows moved behind the stop "
            f"line, {dropped} dropped; lane lines cut: {m_mouth} m in mouths, {m_box} m in junction boxes")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    root = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    path = args[0] if args else os.path.join(root, "game", "map", "centrum.json")
    with open(path, encoding="utf-8") as fh:
        d = json.load(fh)
    if "--check" in sys.argv:
        m = measure(d)
        limits = {"mouth_m": CHECK_MOUTH_M, "box_m": CHECK_BOX_M, "arrows": CHECK_ARROWS,
                  "partners": CHECK_PARTNERS, "dots": CHECK_DOTS, "short_cycle": CHECK_SHORT_CYCLE,
                  "site_gaps": CHECK_SITE_GAPS, "split_fan_m": CHECK_SPLIT_FAN_M, "split_gap_m": CHECK_SPLIT_GAP_M,
                  "split_ends": CHECK_SPLIT_ENDS}
        ok = int(d.get("road_fixes", 0)) >= VERSION and all(m[k] <= v for k, v in limits.items())
        why = "" if int(d.get("road_fixes", 0)) >= VERSION else " (the map is not fixed to this version: run tools/road_fixes.py)"
        print(f"road_fixes: {'OK' if ok else 'FAIL'}: " + ", ".join(f"{k} {m[k]} (max {v})" for k, v in limits.items()) + why)
        sys.exit(0 if ok else 1)
    if "--dry" in sys.argv:
        print("road_fixes (dry): " + json.dumps(measure(d)))
        return
    print("road_fixes: " + apply(d))
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(d, fh, separators=(",", ":"), ensure_ascii=False)


if __name__ == "__main__":
    main()
