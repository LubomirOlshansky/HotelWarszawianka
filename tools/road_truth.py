"""Roads true to life (F, 2026-11-13; docs/design/roads-true-to-life.md): finds the places where
the lanes, turns, roundabouts and bends of the baked map do not behave like a real street. It only
measures; it changes nothing. The paint and kerbs at way joins are road_smooth's and road_fixes'.

    python3 -I tools/road_truth.py [MAP.json] [--list[=R3,R5]] [--json=OUT.json] [--streets]
        measures the map (game/map/centrum.json) and prints one count per rule; --list prints
        every finding with its `--at=`; --streets ranks the named streets by findings per km;
        --json writes the findings for the dev console and for plots.
    python3 -I tools/road_truth.py --check [MAP.json]
        exit 1 when a rule's count is over its CHECK ratchet (verify.sh step `roadtruth`;
        lower a ratchet when a change leaves fewer findings, never raise one).
    python3 -I tools/road_truth.py --osm=data/raw/demo/osm/osm_demo.json [MAP.json] [--list]
        also the rules that need the raw OpenStreetMap export (the Mac has it; the cloud has
        not): T1 turn restrictions the lane graph ignores, T2 lanes that may take an exit
        their `turn:lanes` does not allow. Reported only, never part of --check.

The rules, each a way the game's road differs from a real one (lanes are counted from the left,
as lane_graph.gd does; a "link" is the curve across a junction from one lane to the next edge's):

  R1 lane step     the lane count changes where an edge has one way on and no side road joins
                   (a real street adds or drops a lane by a taper and paint, mostly at a junction)
  R2 lane blip     a stretch under BLIP_LEN m whose lane count differs from the same street's
                   edge before it and after it, which agree (a lane that pops up and is gone);
                   not the piece inside a junction between a dual road's two halves
  R3 lane shift    a lane going straight on lands more than SHIFT_MAX m to the side of where its
                   own line leads (lane_graph.gd `next_lane` guesses the lane; OSM's turn:lanes
                   are not used), measured across the bisector so a bend in the road does not count
  R4 crossed links two lanes of one approach going straight on into one road cross each other
  R5 turn back     a link that turns by more than BACK_ANGLE rad onto another road at a node that
                   is no dead end (round a median's tip; real ones need a gap and no ban)
  R6 kink          a main road's centreline turns by more than KINK_DEG degrees at one point, or
                   wiggles left then right by more than WIGGLE_DEG at neighbouring points
  R7 short edge    an edge with under SHORT_M m to drive between its two junction curves
  R8 arrow         a turn arrow with no such exit at the next junction ahead (within ARROW_AHEAD m)
  R9 roundabout    a ring whose lane count changes inside it, or whose radius varies by more than
                   RING_ROUND of its mean (a ring that is not round); one finding per ring and fault
  R10 tight turn   a turn of TURN_MIN..BACK_ANGLE rad whose link is tighter than TIGHT_R m: the two
                   edges are cut back too little at the corner, so the car pivots on the spot

Findings inside a road design area (map key `road_design`) are counted like any other: a designed
street's lane graph still comes from the OSM ways.
Standard library only.
"""
import json
import math
import os
import sys
from collections import Counter, defaultdict

TOOLS = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(TOOLS)
MAP = os.path.join(ROOT, "game", "map", "centrum.json")

MAIN = {"primary", "secondary", "tertiary", "primary_link", "secondary_link", "tertiary_link"}
STRAIGHT = 0.5        # R1: rad; the one way on counts as the same street up to this turn
CHAIN = 0.35          # R2: rad; the same street's next edge
BLIP_LEN = 60.0       # R2
BOX_LEN = 30.0        # R2: a stretch this short between two crossings is the inside of a junction, not a blip
THROUGH = 0.25        # R3, R4: rad; a link this straight is "straight on"
SHIFT_MAX = 1.75      # R3: m, about half a lane
TURN_MIN = 0.6        # lane_graph.gd next_lane: a turn from here on takes the outer lane
BACK_ANGLE = 2.4      # R5: rad (137 degrees)
TIGHT_R = 3.5         # R10: m, under a small car's turning circle
KINK_DEG = 20.0       # R6
KINK_SEG = 0.5        # R6: m; shorter segments are noise
WIGGLE_DEG = 8.0      # R6
SHORT_M = 3.0         # R7
ARROW_REACH = 14.0    # R8: m from an arrow to its edge's centreline
ARROW_AHEAD = 120.0   # R8: m ahead to the junction the arrow is for
ARROW_MEDIAN = 45.0   # R8: m past the first branch where a left turn across a median may still be
SLIGHT = 0.2          # R8: rad
RING_MIN, RING_MAX = 30.0, 450.0   # R9: a ring's length round, m
RING_OVAL = 0.6       # R9: (largest - smallest radius) / mean over this is a block, not a ring...
RING_CORNER = 1.0     # R9: ...and so is a loop with a corner sharper than this (rad) at one point,
RING_NAMED = 0.75     # R9: unless it is named Rondo or Plac (OSM draws some of those as squares)
RING_ROUND = 0.15     # R9

RULES = [("R1", "lane step"), ("R2", "lane blip"), ("R3", "lane shift"), ("R4", "crossed links"),
         ("R5", "turn back"), ("R6", "kink"), ("R7", "short edge"), ("R8", "arrow"), ("R9", "roundabout"), ("R10", "tight turn")]
# --check ratchets (2026-11-13, main at 05b7c9c). Lower them, never raise them.
CHECK = {"R1": 379, "R2": 71, "R3": 403, "R4": 0, "R5": 144, "R6": 83, "R7": 262, "R8": 56, "R9": 21, "R10": 266}


def unit(a, b):
    dx, dz = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dz) or 1e-9
    return dx / ln, dz / ln


def angle(d0, d1):
    """The turn from d0 to d1 in rad; positive is to the right (x east, z south)."""
    return math.atan2(d0[0] * d1[1] - d0[1] * d1[0], d0[0] * d1[0] + d0[1] * d1[1])


def _cross(a, b, c, d):
    """True when segments ab and cd properly cross."""
    def side(p, q, r):
        return (q[0] - p[0]) * (r[1] - p[1]) - (q[1] - p[1]) * (r[0] - p[0])
    return side(a, b, c) * side(a, b, d) < 0 and side(c, d, a) * side(c, d, b) < 0


class Graph:
    """The lane graph as lane_graph.gd reads it (the edges out of the adjacency there are out here)."""

    def __init__(self, m):
        g = m["graph"]
        self.E = g["edges"]
        self.out = defaultdict(list)
        self.inn = defaultdict(list)
        by_ends = {}
        for i, e in enumerate(self.E):
            e["P"] = list(zip(e["p"][0::2], e["p"][1::2]))
            cum = [0.0]
            for a, b in zip(e["P"], e["P"][1:]):
                cum.append(cum[-1] + math.dist(a, b))
            e["cum"] = cum
            e["len"] = cum[-1]
            e["s1"] = max(e["s1"], e["s0"] + 0.1)
            e["d0"] = self._dir(e, e["s0"])
            e["d1"] = self._dir(e, e["s1"])
            if e.get("cf", 0) == 0:
                self.out[e["a"]].append(i)
                self.inn[e["b"]].append(i)
            by_ends[(e["a"], e["b"])] = i
        self.rev = [by_ends.get((e["b"], e["a"]), -1) for e in self.E]

    @staticmethod
    def _seg(e, s):
        cum = e["cum"]
        i = 0
        while i < len(cum) - 2 and cum[i + 1] < s:
            i += 1
        return i

    def _dir(self, e, s):
        i = self._seg(e, s)
        return unit(e["P"][i], e["P"][i + 1])

    def point(self, e, s, off):
        """The point s metres along edge e, `off` metres right of its centreline."""
        i = self._seg(e, s)
        a, b = e["P"][i], e["P"][i + 1]
        ln = e["cum"][i + 1] - e["cum"][i]
        t = (s - e["cum"][i]) / ln if ln > 1e-9 else 0.0
        d = unit(a, b)
        return a[0] + (b[0] - a[0]) * t - d[1] * off, a[1] + (b[1] - a[1]) * t + d[0] * off

    @staticmethod
    def lane_off(e, k):
        return e["o"] + k * e["lw"]

    @staticmethod
    def next_lane(e, k, f, turn):
        """lane_graph.gd `next_lane`."""
        n = f["n"]
        if n == 1:
            return 0
        if turn > TURN_MIN:
            return n - 1
        if turn < -TURN_MIN:
            return 0
        return max(0, min(n - 1, k + (n - e["n"]) // 2))

    def exits(self, ei):
        """The edges a car on edge ei may take at its end: all but the way back, which only a
        dead end allows (traffic.gd)."""
        e = self.E[ei]
        outs = [f for f in self.out[e["b"]] if f != self.rev[ei]]
        return outs if outs else [f for f in self.out[e["b"]]]

    def turn(self, ei, fi):
        return angle(self.E[ei]["d1"], self.E[fi]["d0"])


def finding(rule, x, z, name, text, worst=0.0):
    return {"rule": rule, "x": round(x, 1), "z": round(z, 1), "name": name, "text": text, "worst": round(worst, 2)}


def lane_counts(g):
    """R1 and R2."""
    out = []
    E = g.E
    nxt = {}
    for ei, e in enumerate(E):
        outs = [f for f in g.out[e["b"]] if f != g.rev[ei]]
        ins = [x for x in g.inn[e["b"]] if not outs or g.rev[x] != outs[0]]
        if len(outs) == 1 and len(ins) == 1:
            f = E[outs[0]]
            if f["n"] != e["n"] and abs(g.turn(ei, outs[0])) < STRAIGHT:
                p = e["P"][-1]
                out.append(finding("R1", p[0], p[1], e["name"], "%d lanes become %d, no side road (%s)"
                                   % (e["n"], f["n"], e["k"]), abs(f["n"] - e["n"])))
        best = None
        for fi in outs:
            t = abs(g.turn(ei, fi))
            if t < CHAIN and E[fi]["name"] == e["name"] and (best is None or t < best[0]):
                best = (t, fi)
        if best:
            nxt[ei] = best[1]
    for ei, fi in nxt.items():
        hi = nxt.get(fi)
        e, f = E[ei], E[fi]
        boxed = f["len"] < BOX_LEN and len(g.out[f["a"]]) + len(g.inn[f["a"]]) >= 4 and len(g.out[f["b"]]) + len(g.inn[f["b"]]) >= 4
        if hi is not None and f["len"] < BLIP_LEN and e["n"] == E[hi]["n"] != f["n"] and not boxed:
            p = f["P"][0]
            out.append(finding("R2", p[0], p[1], f["name"], "%d-%d-%d lanes over %.0f m"
                               % (e["n"], f["n"], e["n"], f["len"]), abs(f["n"] - e["n"])))
    return out


def links(g):
    """R3, R4, R5 and R10: the curves across the junctions."""
    out = []
    E = g.E
    for ei, e in enumerate(E):
        fs = g.exits(ei)
        dead_end = len(fs) == 1 and fs[0] == g.rev[ei]
        for fi in fs:
            f = E[fi]
            turn = g.turn(ei, fi)
            ends = []
            for k in range(e["n"]):
                j = g.next_lane(e, k, f, turn)
                ends.append((g.point(e, e["s1"], g.lane_off(e, k)), g.point(f, f["s0"], g.lane_off(f, j)), k, j))
            a0, b0 = ends[0][0], ends[0][1]
            if abs(turn) < THROUGH:
                bis = unit((0.0, 0.0), (e["d1"][0] + f["d0"][0], e["d1"][1] + f["d0"][1]))
                worst = None
                for a, b, k, j in ends:
                    side = abs((b[0] - a[0]) * -bis[1] + (b[1] - a[1]) * bis[0])
                    if side > SHIFT_MAX and math.dist(a, b) > 0.5 and (worst is None or side > worst[0]):
                        worst = (side, a, k, j)
                if worst:
                    out.append(finding("R3", worst[1][0], worst[1][1], e["name"],
                                       "lane %d of %d lands %.1f m aside in lane %d of %d (%s)"
                                       % (worst[2] + 1, e["n"], worst[0], worst[3] + 1, f["n"], e["k"]), worst[0]))
                for i in range(len(ends)):
                    for h in range(i + 1, len(ends)):
                        if ends[i][3] != ends[h][3] and _cross(ends[i][0], ends[i][1], ends[h][0], ends[h][1]):
                            out.append(finding("R4", a0[0], a0[1], e["name"], "lanes %d and %d cross going straight on"
                                               % (ends[i][2] + 1, ends[h][2] + 1), 1.0))
                            break
                    else:
                        continue
                    break
            elif abs(turn) > BACK_ANGLE and fi != g.rev[ei] and not dead_end:
                out.append(finding("R5", a0[0], a0[1], e["name"], "turns back %.0f degrees into %s, %.1f m across (%s)"
                                   % (math.degrees(abs(turn)), f["name"] or "a road", math.dist(a0, b0), e["k"]),
                                   math.degrees(abs(turn))))
            elif TURN_MIN < abs(turn) <= BACK_ANGLE and e["k"] != "living_street":
                a, b = ends[0][0], ends[0][1]
                r = math.dist(a, b) / (2.0 * math.sin(abs(turn) / 2.0))
                if r < TIGHT_R:
                    out.append(finding("R10", a[0], a[1], e["name"], "a turn of %.1f m radius into %s"
                                       % (r, f["name"] or "a road"), TIGHT_R - r))
    return out


def kinks(g):
    """R6 and R7."""
    out = []
    for e in g.E:
        if e["s1"] - e["s0"] < SHORT_M and e.get("cf", 0) == 0:
            p = e["P"][len(e["P"]) // 2]
            out.append(finding("R7", p[0], p[1], e["name"], "%.1f m to drive on a %.0f m edge"
                               % (e["s1"] - e["s0"], e["len"]), SHORT_M - (e["s1"] - e["s0"])))
        if e["k"] not in MAIN:
            continue
        P = e["P"]
        segs = [(a, b) for a, b in zip(P, P[1:]) if math.dist(a, b) >= KINK_SEG]
        turns = [(angle(unit(*s0), unit(*s1)), s1[0]) for s0, s1 in zip(segs, segs[1:])]
        for t, p in turns:
            if abs(t) > math.radians(KINK_DEG):
                out.append(finding("R6", p[0], p[1], e["name"], "a kink of %.0f degrees at one point" % math.degrees(abs(t)),
                                   math.degrees(abs(t))))
        for (t0, _), (t1, p) in zip(turns, turns[1:]):
            small = min(abs(t0), abs(t1))
            if t0 * t1 < 0 and math.radians(WIGGLE_DEG) < small <= math.radians(KINK_DEG):
                out.append(finding("R6", p[0], p[1], e["name"], "a wiggle, %.0f then %.0f degrees the other way"
                                   % (math.degrees(abs(t0)), math.degrees(abs(t1))), math.degrees(small)))
    return out


def arrows(g, m, ring):
    """R8. An exit counts for an arrow when it leaves to that side at all (SLIGHT rad: a fork's
    arrow), a left turn may be at the second node (across a median), and an arrow before a
    roundabout is not judged (left there means "round the ring")."""
    out = []
    grid = defaultdict(list)
    for i, e in enumerate(g.E):
        for a, b in zip(e["P"], e["P"][1:]):
            n = max(1, int(math.dist(a, b) / 6.0))
            d = unit(a, b)
            for t in range(n + 1):
                x, z = a[0] + (b[0] - a[0]) * t / n, a[1] + (b[1] - a[1]) * t / n
                grid[(int(x // 16), int(z // 16))].append((i, x, z, d))
    for s in m.get("symbols", []):
        if s.get("k") != "arrow":
            continue
        best = None
        cx, cz = int(s["x"] // 16), int(s["z"] // 16)
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for i, x, z, d in grid.get((cx + dx, cz + dz), ()):
                    if d[0] * s["d"][0] + d[1] * s["d"][1] < 0.8:
                        continue
                    q = math.hypot(x - s["x"], z - s["z"])
                    if best is None or q < best[0]:
                        best = (q, i)
        if best is None or best[0] > ARROW_REACH:
            continue
        ei = best[1]
        have, run, limit = set(), 0.0, ARROW_AHEAD
        seen = set()
        into_ring = False
        while ei not in seen and run < limit:
            seen.add(ei)
            run += g.E[ei]["len"]
            fs = [f for f in g.out[g.E[ei]["b"]] if f != g.rev[ei]]
            if not fs:
                break
            if any(f in ring for f in fs):
                into_ring = True
                break
            if len(fs) > 1:
                for f in fs:
                    t = g.turn(ei, f)
                    if abs(t) < TURN_MIN:
                        have.add("T")
                    if abs(t) > SLIGHT:
                        have.add("R" if t > 0 else "L")
                limit = min(limit, run + ARROW_MEDIAN)
            ei = min(fs, key=lambda f: abs(g.turn(ei, f)))
        missing = [c for c in s.get("t", "") if c not in have]
        if missing and have and not into_ring:
            e = g.E[best[1]]
            out.append(finding("R8", s["x"], s["z"], e["name"], "arrow %s, the junction ahead has only %s"
                               % (s["t"], "".join(sorted(have))), len(missing)))
    return out


def rings(g):
    """R9: closed loops of one-way edges that wind once round (a roundabout's ring)."""
    out = []
    E = g.E
    oneway = [i for i in range(len(E)) if g.rev[i] < 0 and E[i].get("cf", 0) == 0]
    found = {}
    for sgn in (1.0, -1.0):
        for s in oneway:
            path, cur, ok = [s], s, False
            for _ in range(40):
                cands = [(sgn * g.turn(cur, f), f) for f in g.out[E[cur]["b"]] if g.rev[f] < 0]
                if not cands:
                    break
                cur = max(cands)[1]
                if cur == s:
                    ok = True
                    break
                if cur in path:
                    break
                path.append(cur)
            if not ok or frozenset(path) in found:
                continue
            P = []
            for i in path:
                for p in E[i]["P"]:
                    if not P or math.dist(P[-1], p) > 0.2:
                        P.append(p)
            if math.dist(P[0], P[-1]) <= 0.2:
                P.pop()
            length = sum(E[i]["len"] for i in path)
            if not RING_MIN < length < RING_MAX or len(P) < 6:
                continue
            Q = P + P[:2]
            bends = [angle(unit(a, b), unit(b, c)) for a, b, c in zip(Q, Q[1:], Q[2:])]
            if abs(abs(sum(bends)) - 2.0 * math.pi) > 0.3:
                continue
            name = Counter(E[i]["name"] for i in path).most_common(1)[0][0]
            named = name.startswith(("Rondo", "Plac"))
            cx = sum(p[0] for p in P) / len(P)
            cz = sum(p[1] for p in P) / len(P)
            rs = [math.dist(p, (cx, cz)) for p in P]
            r = sum(rs) / len(rs)
            oval = (max(rs) - min(rs)) / r
            if oval > (RING_NAMED if named else RING_OVAL) or (not named and max(abs(t) for t in bends) > RING_CORNER):
                continue   # a block's one-way streets or a loop round a median's tip, not a ring
            found[frozenset(path)] = (cx, cz, r, min(rs), max(rs), path, name)
    for cx, cz, r, lo, hi, path, name in found.values():
        lanes = sorted({E[i]["n"] for i in path})
        if len(lanes) > 1:
            out.append(finding("R9", cx, cz, name, "ring of %.0f m radius: %s lanes round it"
                               % (r, "/".join(str(n) for n in lanes)), lanes[-1] - lanes[0]))
        if (hi - lo) / r > RING_ROUND:
            out.append(finding("R9", cx, cz, name, "ring not round: radius %.1f to %.1f m" % (lo, hi), (hi - lo) / r))
    return out, len(found), {i for v in found.values() for i in v[5]}


# --- the rules against the raw OpenStreetMap export -------------------------------------------

def osm_rules(g, osm_path):
    """T1 and T2. Graph edges are matched to OSM ways by their last two points (the bake keeps the
    ways' vertices; an edge whose end was moved by a later pass is left out and counted)."""
    sys.path.insert(0, TOOLS)
    import bake_osm  # noqa: E402  (the projection, turn_codes)

    with open(osm_path, encoding="utf-8") as fh:
        els = json.load(fh)["elements"]
    node_xz, ways, rels = {}, {}, []
    for el in els:
        if el["type"] == "node":
            node_xz[el["id"]] = bake_osm.project(el["lat"], el["lon"])
        elif el["type"] == "way" and el.get("tags", {}).get("highway") in bake_osm.TRAFFIC_SPEED:
            ways[el["id"]] = el
        elif el["type"] == "relation" and el.get("tags", {}).get("type") == "restriction":
            rels.append(el)
    at = defaultdict(list)
    for nid, (x, z) in node_xz.items():
        at[(round(x), round(z))].append(nid)

    def node_at(p):
        best = None
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                for nid in at.get((round(p[0]) + dx, round(p[1]) + dz), ()):
                    d = math.dist(node_xz[nid], p)
                    if d < 0.35 and (best is None or d < best[0]):
                        best = (d, nid)
        return best[1] if best else None

    pair_way = {}
    for wid, w in ways.items():
        ns = w.get("nodes", [])
        for a, b in zip(ns, ns[1:]):
            pair_way[(a, b)] = (wid, 1)
            pair_way[(b, a)] = (wid, -1)
    # Each edge's way at its end and at its start, with the direction it runs along the way.
    end_way, start_way, lost = {}, {}, 0
    for ei, e in enumerate(g.E):
        a, b = node_at(e["P"][-2]), node_at(e["P"][-1])
        hit = pair_way.get((a, b)) if a and b else None
        if hit:
            end_way[ei] = (hit[0], hit[1], b)
        else:
            lost += 1
        a, b = node_at(e["P"][0]), node_at(e["P"][1])
        hit = pair_way.get((a, b)) if a and b else None
        if hit:
            start_way[ei] = (hit[0], hit[1], a)
    out = []
    # T1: turn restrictions.
    kinds = Counter()
    for rel in rels:
        t = rel["tags"]
        kind = t.get("restriction") or next((v for k, v in t.items() if k.startswith("restriction:")), "")
        frm = [mb["ref"] for mb in rel.get("members", []) if mb["role"] == "from" and mb["type"] == "way"]
        to = [mb["ref"] for mb in rel.get("members", []) if mb["role"] == "to" and mb["type"] == "way"]
        via = [mb["ref"] for mb in rel.get("members", []) if mb["role"] == "via" and mb["type"] == "node"]
        if not kind or not frm or not to or not via:
            continue
        for ei, (wid, _, nid) in end_way.items():
            if wid not in frm or nid != via[0]:
                continue
            fs = [f for f in g.out[g.E[ei]["b"]] if f in start_way]
            banned = []
            for f in fs:
                same = start_way[f][0] in to
                if f == g.rev[ei] and len(g.exits(ei)) > 1:
                    continue   # the way back is only driven at a dead end
                if (kind.startswith("no_") and same) or (kind.startswith("only_") and not same):
                    banned.append(f)
            if banned:
                kinds[kind] += 1
                p = g.E[ei]["P"][-1]
                out.append(finding("T1", p[0], p[1], g.E[ei]["name"], "%s ignored: the graph still links to %s"
                                   % (kind, ", ".join(sorted({g.E[f]["name"] or "a road" for f in banned}))), len(banned)))
    # T2: turn:lanes against the exits every lane may take.
    with_tags = 0
    for ei, (wid, way_dir, _) in end_way.items():
        t = ways[wid]["tags"]
        value = t.get("turn:lanes:forward" if way_dir > 0 else "turn:lanes:backward")
        if value is None and bake_osm_oneway(t):
            value = t.get("turn:lanes")
        codes = bake_osm.turn_codes(value) if value else None
        e = g.E[ei]
        if not codes or len(codes) != e["n"]:
            continue
        with_tags += 1
        fs = [f for f in g.exits(ei) if f != g.rev[ei]]
        if len(fs) < 2:
            continue
        wrong = 0
        for f in fs:
            turn = g.turn(ei, f)
            c = "T" if abs(turn) < TURN_MIN else ("R" if turn > 0 else "L")
            wrong += sum(1 for code in codes if code and c not in code)
        if wrong:
            p = e["P"][-1]
            out.append(finding("T2", p[0], p[1], e["name"], "turn:lanes %s: %d lane and exit pairs the tags do not allow"
                               % ("|".join(c or "-" for c in codes), wrong), wrong))
    info = "osm: %d restriction relations, %d road ways, %d of %d edges matched to a way, %d edges with turn:lanes; T1 by kind %s" % (
        len(rels), len(ways), len(end_way), len(g.E), with_tags, dict(kinds))
    return out, info


def bake_osm_oneway(t):
    return t.get("oneway") in ("yes", "1", "true", "-1", "reverse") or t.get("junction") in ("roundabout", "circular")


def measure(m):
    g = Graph(m)
    ring_findings, n_rings, ring = rings(g)
    found = lane_counts(g) + links(g) + kinks(g) + arrows(g, m, ring)
    return g, found + ring_findings, n_rings


def main(argv):
    args = [a for a in argv if not a.startswith("--")]
    opts = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else "") for a in argv if a.startswith("--")}
    path = args[0] if args else MAP
    with open(path, encoding="utf-8") as fh:
        m = json.load(fh)
    g, found, n_rings = measure(m)
    info = ""
    if "--osm" in opts:
        more, info = osm_rules(g, opts["--osm"])
        found += more
    counts = Counter(f["rule"] for f in found)
    if "--list" in opts:
        want = set(opts["--list"].split(",")) if opts["--list"] else None
        for f in sorted(found, key=lambda f: (f["rule"], -f["worst"])):
            if want is None or f["rule"] in want:
                print("%s --at=%.0f,%.0f  %s: %s" % (f["rule"], f["x"], f["z"], f["name"] or "(no name)", f["text"]))
    if "--streets" in opts:
        km = Counter()
        for e in g.E:
            km[e["name"]] += e["len"] / 1000.0
        per = Counter(f["name"] for f in found if f["name"])
        rows = sorted(((per[n] / km[n], per[n], n) for n in per if km[n] >= 0.3), reverse=True)
        for rate, n, name in rows[:40]:
            print("%6.1f per km  %3d  %s (%.2f km)" % (rate, n, name, km[name]))
    if "--json" in opts:
        with open(opts["--json"], "w", encoding="utf-8") as fh:
            json.dump({"counts": dict(counts), "rings": n_rings, "findings": found}, fh, ensure_ascii=False)
    line = ", ".join("%s %d" % (r, counts.get(r, 0)) for r, _ in RULES)
    if "--osm" in opts:
        line += ", T1 %d, T2 %d" % (counts.get("T1", 0), counts.get("T2", 0))
        print("road_truth " + info)
    print("road_truth counts: %s (%d edges, %d rings)" % (line, len(g.E), n_rings))
    if "--check" in opts:
        over = ["%s %d > %d" % (r, counts.get(r, 0), CHECK[r]) for r, _ in RULES if counts.get(r, 0) > CHECK[r]]
        if over:
            print("road_truth: FAIL " + "; ".join(over) + " (python3 -I tools/road_truth.py --list=RULE shows them)")
            return 1
        print("road_truth: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
